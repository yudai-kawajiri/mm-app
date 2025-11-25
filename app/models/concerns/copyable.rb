# frozen_string_literal: true

# Copyable
#
# リソースのコピー機能を提供するConcern
#
# 使用例:
#   class Resources::Product < ApplicationRecord
#     include Copyable
#
#     copyable_config(
#       associations_to_copy: [:product_materials],
#       status_on_copy: :draft,
#       additional_attributes: {
#         item_number: :generate_next_item_number
#       }
#     )
#   end
#
#   # コピー実行
#   product = Resources::Product.find(1)
#   copied_product = product.create_copy(user: current_user)
#   # => 名前が "商品名 (コピー1)" となり、product_materialsもコピーされる
#
# 使用モデル: Product, Plan, Material, Category, Unit, MaterialOrderGroup
module Copyable
  extend ActiveSupport::Concern

  included do
    # コピー機能のデフォルト設定
    # 各モデルで copyable_config を使ってカスタマイズ可能
    class_attribute :copy_config, default: {
      name_format: lambda { |original_name, copy_count|
        I18n.t("activerecord.concerns.copyable.copy_name_format",
                name: original_name,
                count: copy_count)
      },
      uniqueness_scope: :name,
      uniqueness_check_attributes: [ :name ],
      associations_to_copy: [],
      association_copy_attributes: {},
      additional_attributes: {},
      skip_attributes: [ :created_at, :updated_at, :id ]
    }
  end

  class_methods do
    # コピー機能の設定
    #
    # @param options [Hash] 設定オプション
    # @option options [Proc] :name_format コピー名のフォーマット（デフォルト: "名前 (コピー1)"）
    # @option options [Symbol, Array<Symbol>] :uniqueness_scope 一意性チェックのスコープ
    # @option options [Array<Symbol>] :uniqueness_check_attributes 一意性チェック対象の属性
    # @option options [Array<Symbol>] :associations_to_copy コピーする関連モデル
    # @option options [Hash] :association_copy_attributes 関連モデルのコピー対象属性
    # @option options [Hash] :additional_attributes 追加で設定する属性
    # @option options [Symbol] :status_on_copy コピー時のステータス
    #
    # @example 基本的な設定
    #   copyable_config(
    #     associations_to_copy: [:product_materials],
    #     status_on_copy: :draft
    #   )
    def copyable_config(**options)
      options[:association_copy_attributes] ||= {}
      self.copy_config = copy_config.merge(options)
    end
  end

  # レコードのコピーを作成する
  #
  # @param user [User] コピーを作成するユーザー（必須）
  # @return [ActiveRecord::Base] コピーされた新しいレコード
  # @raise [ArgumentError] userがnilの場合
  # @raise [ActiveRecord::RecordInvalid] 保存に失敗した場合
  #
  # @example
  #   product = Resources::Product.find(1)
  #   copied = product.create_copy(user: current_user)
  def create_copy(user:)
    raise ArgumentError, "user cannot be nil" if user.nil?

    ActiveRecord::Base.transaction do
      unique_attrs = generate_unique_attributes
      new_record = dup

      # 一意性チェック対象の属性を設定
      unique_attrs.each do |attr, value|
        new_record.send("#{attr}=", value)
      end

      if new_record.respond_to?(:user_id=)
        new_record.user_id = user.id
      end

      if copy_config[:status_on_copy].present? && new_record.respond_to?(:status=)
        new_record.status = copy_config[:status_on_copy]
      end

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

  # 一意な属性値を生成する
  #
  # uniqueness_check_attributes で指定された属性すべてに対して
  # ユニークな値を生成する
  #
  # @return [Hash] 属性名と値のハッシュ
  def generate_unique_attributes
    copy_count = 1
    unique_attrs = {}

    loop do
      unique_attrs = {}

      copy_config[:uniqueness_check_attributes].each do |attr|
        unique_attrs[attr] = generate_copy_value(attr, send(attr), copy_count)
      end

      break unless attributes_exist?(unique_attrs)
      copy_count += 1
    end

    unique_attrs
  end

  # コピー用の値を生成
  #
  # @param attr [Symbol] 属性名
  # @param original_value [String] 元の値
  # @param copy_count [Integer] コピー番号
  # @return [String] コピー用の値
  def generate_copy_value(attr, original_value, copy_count)
    case attr
    when :name
      copy_config[:name_format].call(original_value, copy_count)
    when :reading
      # 読み仮名には「こぴー」を繰り返し追加（数字は使えない）
      "#{original_value}#{'こぴー' * copy_count}"
    else
      # その他の属性は元の値をそのまま使用
      original_value
    end
  end

  # 指定された属性の組み合わせが既に存在するかチェック
  #
  # @param attributes [Hash] チェックする属性のハッシュ
  # @return [Boolean] 存在する場合true
  def attributes_exist?(attributes)
    conditions = attributes.dup

    scope = copy_config[:uniqueness_scope]
    if scope.is_a?(Array)
      scope.each do |scope_attr|
        conditions[scope_attr] = send(scope_attr) if respond_to?(scope_attr)
      end
    elsif scope.is_a?(Symbol) && !attributes.key?(scope)
      conditions[scope] = send(scope) if respond_to?(scope)
    end

    self.class.exists?(conditions)
  end

  # 関連レコードをコピーする
  #
  # associations_to_copy で指定された関連モデルを
  # 新しいレコードにコピーする
  #
  # @param new_record [ActiveRecord::Base] コピー先のレコード
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

  # 関連レコードの1件をコピーする
  #
  # @param new_record [ActiveRecord::Base] コピー先のレコード
  # @param association_name [Symbol] 関連名
  # @param original_record [ActiveRecord::Base] コピー元の関連レコード
  def copy_association_record(new_record, association_name, original_record)
    association_copy_attrs = copy_config[:association_copy_attributes]

    copy_attributes = if association_copy_attrs[association_name].present?
                        association_copy_attrs[association_name]
    else
                        # デフォルト: すべての属性（id, timestamps, 外部キーを除く）
                        original_record.attributes.keys.map(&:to_sym) -
                          [ :id, :created_at, :updated_at ] -
                          [ association_foreign_key(association_name) ]
    end

    attributes = copy_attributes.index_with { |attr| original_record.send(attr) }
    new_record.send(association_name).create!(attributes)
  end

  # 関連の外部キーを取得
  #
  # @param association_name [Symbol] 関連名
  # @return [Symbol, nil] 外部キー名
  def association_foreign_key(association_name)
    association = self.class.reflect_on_association(association_name)
    association&.foreign_key&.to_sym
  end
end
