# frozen_string_literal: true

# Copyable
#
# リソースのコピー機能を提供するConcern
# 課題: レコード複製時に名前の重複を避け、関連データも含めた完全なコピーを作成する必要がある
# 解決: 一意な名前を自動生成し、トランザクション内で関連レコードを含めてコピー
#
# 使用例:
#   copyable_config(
#     uniqueness_scope: [:category_id, :store_id],
#     associations_to_copy: [:plan_products]
#   )
module Copyable
  extend ActiveSupport::Concern

  # 背景: ひらがなのみのバリデーションがあるため、11回目以降は漢数字ではなく「こぴー」を繰り返す
  COPY_COUNT_THRESHOLD = 10

  # 背景: 同名レコードが大量にある場合の無限ループを防止
  MAX_COPY_ATTEMPTS = 100

  included do
    class_attribute :copy_config, default: {
      name_format: ->(original_name, copy_count) { "#{original_name} #{I18n.t('copyable.copy_suffix', count: copy_count)}" },
      uniqueness_scope: :name,
      uniqueness_check_attributes: [ :name ],
      associations_to_copy: [],
      association_copy_attributes: {},
      status_on_copy: nil,
      additional_attributes: {},
      skip_attributes: [ :created_at, :updated_at, :id ]
    }
  end

  class_methods do
    def copyable_config(**options)
      self.copy_config = copy_config.merge(options)
    end
  end

  def create_copy(user:)
    ActiveRecord::Base.transaction do
      unique_attrs = generate_unique_attributes(1)

      new_record = dup
      new_record.name = unique_attrs[:name]
      new_record.reading = unique_attrs[:reading] if unique_attrs[:reading] && new_record.respond_to?(:reading=)
      new_record.user_id = user.id if new_record.respond_to?(:user_id=)

      if copy_config[:status_on_copy].present? && new_record.respond_to?(:status=)
        new_record.status = copy_config[:status_on_copy]
      end

      # 背景: メソッド呼び出し、Proc、静的値の3パターンをサポートすることで柔軟性を確保
      copy_config[:additional_attributes].each do |attr, value|
        if value.is_a?(Symbol) && respond_to?(value, true)
          new_record.send("#{attr}=", send(value))
        elsif value.respond_to?(:call)
          new_record.send("#{attr}=", value.call(self, new_record))
        else
          new_record.send("#{attr}=", value)
        end
      end

      new_record.save!
      copy_associations(new_record)

      new_record
    end
  end

  private

  # 課題: "商品A (コピー1)" をコピーすると "商品A (コピー1) (コピー1)" になってしまう
  # 解決: 正規表現でコピー接尾辞を削除し、元の名前から連番を生成
  def generate_unique_attributes(copy_count)
    base_name = name
    base_reading = reading if respond_to?(:reading)

    # "(コピー1)" のパターンをマッチ: スペース + "(コピー" + 数字 + ")"
    copy_suffix_pattern = /\s*\(コピー\d+\)\z/
    # 元の名前からコピー接尾辞を削除し、余分な空白も削除
    original_name = base_name.gsub(copy_suffix_pattern, "").strip

    # 元の読み仮名からコピー接尾辞を削除
    reading_copy_text = I18n.t('copyable.reading_copy_text')
    original_reading = base_reading ? base_reading.sub(/#{reading_copy_text}.*\z/, "").strip : nil

    if base_name =~ /\(コピー(\d+)\)\z/
      copy_count = $1.to_i + 1
    else
      copy_count = 1
    end
    result = nil

    loop do
      # 元の名前（コピー部分を除去したもの）をベースに生成
      new_name = copy_config[:name_format].call(original_name, copy_count)
      # 元の読み仮名（こぴー部分を除去したもの）をベースに生成
      new_reading = original_reading ? generate_reading_for_copy(original_reading, copy_count) : nil

      # 一意性チェック
      unless attributes_exist?(new_name, new_reading)
        result = { name: new_name, reading: new_reading }
        break
      end

      copy_count += 1

      if copy_count > MAX_COPY_ATTEMPTS
        raise I18n.t('copyable.errors.max_attempts_exceeded', max_attempts: MAX_COPY_ATTEMPTS)
      end
    end

    result
  end

  def generate_reading_for_copy(original_reading, copy_count)
    reading_copy_text = I18n.t('copyable.reading_copy_text')
    reading_numbers = I18n.t('copyable.reading_numbers')

    if copy_count <= COPY_COUNT_THRESHOLD
      "#{original_reading}#{reading_copy_text}#{reading_numbers[copy_count]}"
    else
      repeat_count = (copy_count - COPY_COUNT_THRESHOLD)
      "#{original_reading}#{reading_copy_text}#{reading_copy_text * repeat_count}"
    end
  end

  # 課題: モデルごとにバリデーションが異なる（Planはreadingのみ、Productはname+reading）
  # 解決: 各属性を個別にチェックし、どれか1つでも重複があればtrueを返す
  # 背景: name AND readingの両方が一致するレコードを探すと、Planのようにreadingのみ
  #       uniquenessバリデーションがあるモデルで誤判定が発生する
  def attributes_exist?(name, reading = nil)
    base_conditions = {}

    # スコープ条件を追加（category_id, store_id など）
    scope = copy_config[:uniqueness_scope]
    if scope.is_a?(Array)
      scope.each do |scope_attr|
        base_conditions[scope_attr] = send(scope_attr) if respond_to?(scope_attr)
      end
    elsif scope.is_a?(Symbol)
      base_conditions[scope] = send(scope) if respond_to?(scope)
    end

    # 各属性ごとに個別に存在チェック（OR判定）
    # 背景: モデルのバリデーションは各属性を個別にチェックするため、
    #       name AND reading の両方一致ではなく、どちらか一方でも一致すれば重複と判定
    copy_config[:uniqueness_check_attributes].each do |attr|
      check_conditions = base_conditions.dup

      case attr
      when :name
        check_conditions[:name] = name
      when :reading
        next unless reading  # reading が nil ならスキップ
        check_conditions[:reading] = reading
      else
        check_conditions[attr] = send(attr) if respond_to?(attr)
      end

      # この属性の組み合わせで既存レコードがあればtrueを返す
      # 背景: 元のレコード自身を除外しないと、同じscope内で常にマッチしてしまう
      if self.class.where(check_conditions).where.not(id: self.id).exists?
        return true
      end
    end

    false
  end

  def copy_associations(new_record)
    copy_config[:associations_to_copy].each do |association_name|
      association = self.class.reflect_on_association(association_name)
      next unless association

      original_records = send(association_name)
      next if original_records.blank?

      original_records.each do |original_record|
        copy_association_record(new_record, association_name, original_record)
      end
    end
  end

  # 背景: id/timestamps/外部キーは自動生成されるため除外、その他の属性は全てコピー
  def copy_association_record(new_record, association_name, original_record)
    copy_attributes = if copy_config[:association_copy_attributes][association_name].present?
                        copy_config[:association_copy_attributes][association_name]
    else
                        original_record.attributes.keys.map(&:to_sym) -
                          [ :id, :created_at, :updated_at ] -
                          [ association_foreign_key(association_name) ]
    end

    attributes = copy_attributes.index_with { |attr| original_record.send(attr) }
    new_record.send(association_name).create!(attributes)
  end

  def association_foreign_key(association_name)
    association = self.class.reflect_on_association(association_name)
    association&.foreign_key&.to_sym
  end
end
