# frozen_string_literal: true

# 削除制限時のI18n対応エラーメッセージ
module TranslatableAssociations
  extend ActiveSupport::Concern

  included do
    before_destroy :check_associations_for_destroy
  end

  private

  # dependent: :restrict_with_error の関連が存在する場合、
  # I18n対応のエラーメッセージで削除を防止
  def check_associations_for_destroy
    restricted_associations.each do |assoc|
      next unless send(assoc.name).exists?

      translated = translate_association_name(assoc)
      errors.add(:base, I18n.t("helpers.messages.restrict_dependent_destroy.has_many",
                               record: translated))
    end

    throw(:abort) if errors.any?
  end

  # dependent: :restrict_with_error が設定された関連を取得
  def restricted_associations
    self.class.reflect_on_all_associations(:has_many)
        .select { |assoc| assoc.options[:dependent] == :restrict_with_error }
  end

  # 関連名をI18nで翻訳
  def translate_association_name(assoc)
    I18n.t("activerecord.associations.#{model_i18n_key}.#{assoc.name}",
           default: model_name_for(assoc))
  end

  def model_i18n_key
    self.class.name.underscore
  end

  def model_name_for(assoc)
    I18n.t("activerecord.models.#{assoc.class_name.underscore}",
            default: assoc.class_name.humanize)
  end
end
