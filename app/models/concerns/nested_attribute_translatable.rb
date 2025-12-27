# frozen_string_literal: true

# ネストされた属性のエラーメッセージをI18n対応
# 例: "Product materials quantity" → "商品原材料 数量"
module NestedAttributeTranslatable
  extend ActiveSupport::Concern

  class_methods do
    def nested_attribute_translation(association_name, nested_model_name)
      @nested_translations ||= {}
      @nested_translations[association_name.to_s] = nested_model_name.constantize
    rescue NameError => e
      Rails.logger.error "NestedAttributeTranslatable: Model not found - #{nested_model_name}: #{e.message}"
      nil
    end

    # ネストされた属性を日本語に変換
    def human_attribute_name(attribute, options = {})
      return super unless @nested_translations

      translated = translate_nested_attribute(attribute)
      translated || super
    end

    private

    def translate_nested_attribute(attribute)
      @nested_translations.each do |association, nested_model|
        next unless nested_model

        if (match = attribute.to_s.match(/^#{Regexp.escape(association)}\.(.+)$/))
          nested_attr = match[1]
          nested_name = nested_model.human_attribute_name(nested_attr)
          return "#{nested_model.model_name.human} #{nested_name}"
        end
      end
      nil
    end
  end
end
