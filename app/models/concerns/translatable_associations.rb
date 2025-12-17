module TranslatableAssociations
  extend ActiveSupport::Concern

  included do
    before_destroy :check_associations_for_destroy
  end

  private

  def check_associations_for_destroy
    self.class.reflect_on_all_associations(:has_many).each do |assoc|
      next unless assoc.options[:dependent] == :restrict_with_error
      
      if send(assoc.name).exists?
        association_key = "activerecord.associations.#{self.class.name.underscore}.#{assoc.name}"
        translated = I18n.t(association_key, default: I18n.t("activerecord.models.#{assoc.class_name.underscore}", default: assoc.class_name.humanize))
        
        errors.add(:base, I18n.t("helpers.messages.restrict_dependent_destroy.has_many", record: translated))
        throw(:abort)
      end
    end
  end
end
