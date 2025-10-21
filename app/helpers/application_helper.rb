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

  # 現在のページに基づいてアクティブクラスを返すメソッド
  def sidebar_link_class(path)
    base_class = 'list-group-item list-group-item-action'
    # current_page?(path) ヘルパーを利用してハイライト判定
    current_page?(path) ? "#{base_class} active" : base_class
  end

  # リソースリストのテーブルセルに表示するデータを整形して返却するメソッド
  def render_resource_data(resource, column_definition)
    data = column_definition[:data]

    if data == :image
      # 1. 画像カラムの処理
      if resource.image.attached?
        # 画像が添付されていればサムネイルを表示
        image_tag resource.image.variant(resize_to_limit: [50, 50]), class: "img-thumbnail"
      else
        "-"
      end
    elsif data == :price
      # 2. 金額表示カラムの処理
      number_to_currency(resource.price)
    elsif data.respond_to?(:call)
      # 3. Procの場合の処理
      data.call(resource)
    else
      # 4. カラムの場合の処理
      resource.send(data)
    end
  end

end