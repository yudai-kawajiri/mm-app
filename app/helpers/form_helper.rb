module FormHelper
  # 電話番号フィールド専用のヘルパー
  # 全てのフォームで統一した電話番号入力フィールドを提供
  #
  # 使用例:
  #   <%= phone_field_group(f, :phone,
  #       label: t('activerecord.attributes.company.phone'),
  #       placeholder: t('admin.companies.form.phone_placeholder'),
  #       required: false
  #   ) %>
  #
  # @param form [FormBuilder] フォームビルダー
  # @param attribute [Symbol] 属性名 (例: :phone, :company_phone)
  # @param options [Hash] その他のオプション
  # @return [String] HTML
  def phone_field_group(form, attribute, **options)
    form_group_lg(form, attribute,
      field_type: :text_field,
      type: "tel",
      pattern: "[0-9]*",
      **options
    )
  end
end
