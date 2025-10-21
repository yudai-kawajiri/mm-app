module ApplicationHelper
  def translate_enum_value(record, attribute)
    value = record.send(attribute)
    return '' if value.blank?
    I18n.t("activerecord.enums.#{record.model_name.i18n_key}.#{attribute}.#{value}")
  end

  # サイドバーのメニュー項目
  def sidebar_menu_items
    [
      { name: t('dashboard.menu.dashboard'), path: authenticated_root_path },
      { name: t('dashboard.menu.category_management'), path: categories_path },
      { name: t('dashboard.menu.unit_management'), path: units_path },
      { name: t('dashboard.menu.material_management'), path: materials_path },
      { name: t('dashboard.menu.product_management'), path: products_path },
      { name: t('dashboard.menu.plan_management'), path: plans_path }
    ]
  end

  # 現在のページに基づいてアクティブクラスを返す
  def sidebar_link_class(path)
    base_class = 'list-group-item list-group-item-action'
    # current_page?(path) ヘルパーを利用してハイライト判定
    current_page?(path) ? "#{base_class} active" : base_class
  end
end