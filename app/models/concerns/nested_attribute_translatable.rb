# frozen_string_literal: true

# NestedAttributeTranslatable
#
# ネストされた属性のエラーメッセージを日本語化するためのConcern
#
# 使用例:
#   class Resources::Product < ApplicationRecord
#     include NestedAttributeTranslatable
#
#     nested_attribute_translation :product_materials, 'Planning::ProductMaterial'
#   end
#
# これにより、"Product materials quantity を入力してください"
# が「商品原材料 数量を入力してください」に変換されます
module NestedAttributeTranslatable
  extend ActiveSupport::Concern

  class_methods do
    # ネストされた属性の翻訳設定
    #
    # @param association_name [Symbol] 関連名（例: :product_materials）
    # @param nested_model_name [String] ネストされたモデル名（例: 'Planning::ProductMaterial'）
    #
    # @example Productモデルでの使用例
    #   nested_attribute_translation :product_materials, 'Planning::ProductMaterial'
    def nested_attribute_translation(association_name, nested_model_name)
      @nested_translations ||= {}
      @nested_translations[association_name.to_s] = nested_model_name.constantize
    end

    # 属性名を人間が読める形式に変換
    #
    # ネストされた属性（例: "product_materials.quantity"）を
    # 日本語の属性名（例: "商品原材料 数量"）に変換する
    #
    # @param attribute [String, Symbol] 属性名
    # @param options [Hash] オプション（Rails標準のhuman_attribute_nameと互換）
    # @return [String] 人間が読める形式の属性名
    #
    # @example ネストされた属性の変換
    #   Product.human_attribute_name('product_materials.quantity')
    #   # => "商品原材料 数量"
    def human_attribute_name(attribute, options = {})
      return super unless @nested_translations

      # ネストされた属性をチェック（例: "product_materials.quantity"）
      @nested_translations.each do |association, nested_model|
        if attribute.to_s =~ /^#{association}\.(.+)$/
          nested_attr = ::Regexp.last_match(1)
          nested_name = nested_model.human_attribute_name(nested_attr)
          return "#{nested_model.model_name.human} #{nested_name}"
        end
      end

      super
    end
  end
end
