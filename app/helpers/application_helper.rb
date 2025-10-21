module ApplicationHelper
  def translate_enum_value(record, attribute)
    value = record.send(attribute)
    return '' if value.blank?
    I18n.t("activerecord.enums.#{record.model_name.i18n_key}.#{attribute}.#{value}")
  end
end