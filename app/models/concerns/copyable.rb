# frozen_string_literal: true

# Copyable
#
# リソースのコピー機能を提供するConcern
#
# 使用例:
#   class Product < ApplicationRecord
#     include Copyable
#
#     copyable_config(
#       name_format: ->(original_name, copy_count) { "#{original_name} (コピー#{copy_count})" },
#       uniqueness_scope: :name,
#       associations_to_copy: [:product_materials],
#       additional_attributes: { item_number: :generate_unique_item_number, status: 'active' }
#     )
#   end
#
#   product.create_copy(user: current_user)
module Copyable
  extend ActiveSupport::Concern

  included do
    # コピー設定のデフォルト値
    class_attribute :copy_config, default: {
      name_format: ->(original_name, copy_count) { "#{original_name} (コピー#{copy_count})" },
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
    # コピー設定を定義
    #
    # @param config [Hash] 設定オプション
    # @option config [Proc] :name_format 名前のフォーマット（original_name, copy_countを受け取る）
    # @option config [Symbol, Array<Symbol>] :uniqueness_scope 一意性チェックのスコープ
    # @option config [Array<Symbol>] :uniqueness_check_attributes 一意性チェックする属性
    # @option config [Array<Symbol>] :associations_to_copy コピーする関連
    # @option config [Hash] :association_copy_attributes 関連ごとのコピー属性
    # @option config [Symbol, String, nil] :status_on_copy コピー時のステータス
    # @option config [Hash] :additional_attributes 追加で設定する属性
    # @option config [Array<Symbol>] :skip_attributes スキップする属性
    # @return [void]
    def copyable_config(**options)
      self.copy_config = copy_config.merge(options)
    end
  end

  # このレコードのコピーを作成
  #
  # @param user [User] コピーを作成するユーザー
  # @return [ActiveRecord::Base] 新しいレコード
  # @raise [ActiveRecord::RecordInvalid] 保存に失敗した場合
  def create_copy(user:)
    ActiveRecord::Base.transaction do
      # 新しい名前と読み仮名を生成
      unique_attrs = generate_unique_attributes

      # レコードを複製
      new_record = dup
      new_record.name = unique_attrs[:name]
      new_record.reading = unique_attrs[:reading] if unique_attrs[:reading] && new_record.respond_to?(:reading=)
      new_record.user_id = user.id if new_record.respond_to?(:user_id=)

      # ステータスを設定
      if copy_config[:status_on_copy].present? && new_record.respond_to?(:status=)
        new_record.status = copy_config[:status_on_copy]
      end

      # 追加属性を設定
      copy_config[:additional_attributes].each do |attr, value|
        if value.is_a?(Symbol) && respond_to?(value, true)
          new_record.send("#{attr}=", send(value))
        elsif value.respond_to?(:call)
          new_record.send("#{attr}=", value.call(self, new_record))
        else
          new_record.send("#{attr}=", value)
        end
      end

      # 保存
      new_record.save!

      # 関連レコードをコピー
      copy_associations(new_record)

      new_record
    end
  end

  private

  # 一意な属性を生成（名前と読み仮名）
  #
  # @return [Hash] 一意な属性のハッシュ
  def generate_unique_attributes
    base_name = name
    base_reading = reading if respond_to?(:reading)

    # 元の名前から「(コピー〇)」部分を削除して、真のベース名を取得
    original_name = base_name.sub(/\s*\(コピー\d+\).*\z/, "")

    # 元の読み仮名から「こぴー」部分を削除して、真のベース読み仮名を取得
    original_reading = base_reading ? base_reading.sub(/こぴー.*\z/, "") : nil

    copy_count = 1

    loop do
      # 元の名前（コピー部分を除去したもの）をベースに生成
      new_name = copy_config[:name_format].call(original_name, copy_count)
      # 元の読み仮名（こぴー部分を除去したもの）をベースに生成
      new_reading = original_reading ? generate_reading_for_copy(original_reading, copy_count) : nil

      # 一意性チェック
      break { name: new_name, reading: new_reading } unless attributes_exist?(new_name, new_reading)
      copy_count += 1
    end
  end

  # コピー用の読み仮名を生成
  #
  # @param original_reading [String] 元の読み仮名（「こぴー」が含まれていない純粋なもの）
  # @param copy_count [Integer] コピー番号
  # @return [String] 新しい読み仮名
  def generate_reading_for_copy(original_reading, copy_count)
    # 元の読み仮名に「こぴー」を1回だけ追加して、その後に番号を示す「いち」「に」などを追加
    # 11回以上は「こぴー」を繰り返す（ひらがなのみのバリデーション対応）
    reading_numbers = [ "", "いち", "に", "さん", "よん", "ご", "ろく", "なな", "はち", "きゅう", "じゅう" ]
    if copy_count <= 10
      "#{original_reading}こぴー#{reading_numbers[copy_count]}"
    else
      # 11回目以降は「こぴー」を繰り返す（例: こぴーこぴー、こぴーこぴーこぴー）
      repeat_count = (copy_count - 10)
      "#{original_reading}こぴー#{'こぴー' * repeat_count}"
    end
  end

  # 属性の組み合わせが既に存在するかチェック
  #
  # @param name [String] チェックする名前
  # @param reading [String, nil] チェックする読み仮名
  # @return [Boolean] 存在する場合true
  def attributes_exist?(name, reading = nil)
    conditions = {}

    # uniqueness_check_attributesの条件を追加
    copy_config[:uniqueness_check_attributes].each do |attr|
      case attr
      when :name
        conditions[:name] = name
      when :reading
        conditions[:reading] = reading if reading
      else
        conditions[attr] = send(attr) if respond_to?(attr)
      end
    end

    # uniqueness_scopeの条件を追加
    scope = copy_config[:uniqueness_scope]
    if scope.is_a?(Array)
      scope.each do |scope_attr|
        conditions[scope_attr] = send(scope_attr) if respond_to?(scope_attr)
      end
    elsif scope.is_a?(Symbol) && scope != :name && scope != :reading
      conditions[scope] = send(scope) if respond_to?(scope)
    end

    self.class.exists?(conditions)
  end

  # 関連レコードをコピー
  #
  # @param new_record [ActiveRecord::Base] 新しいレコード
  # @return [void]
  def copy_associations(new_record)
    copy_config[:associations_to_copy].each do |association_name|
      association = self.class.reflect_on_association(association_name)
      next unless association

      # 関連レコードを取得
      original_records = send(association_name)
      next if original_records.blank?

      # 各レコードをコピー
      original_records.each do |original_record|
        copy_association_record(new_record, association_name, original_record)
      end
    end
  end

  # 単一の関連レコードをコピー
  #
  # @param new_record [ActiveRecord::Base] 新しい親レコード
  # @param association_name [Symbol] 関連名
  # @param original_record [ActiveRecord::Base] 元のレコード
  # @return [void]
  def copy_association_record(new_record, association_name, original_record)
    # コピーする属性を取得
    copy_attributes = if copy_config[:association_copy_attributes][association_name].present?
                        copy_config[:association_copy_attributes][association_name]
    else
                        # デフォルト: すべての属性（id, timestamps, 外部キーを除く）
                        original_record.attributes.keys.map(&:to_sym) -
                          [ :id, :created_at, :updated_at ] -
                          [ association_foreign_key(association_name) ]
    end

    # 属性をコピー
    attributes = copy_attributes.index_with { |attr| original_record.send(attr) }

    # 新しいレコードを作成
    new_record.send(association_name).create!(attributes)
  end

  # 関連の外部キーを取得
  #
  # @param association_name [Symbol] 関連名
  # @return [Symbol] 外部キー名
  def association_foreign_key(association_name)
    association = self.class.reflect_on_association(association_name)
    association&.foreign_key&.to_sym
  end
end
