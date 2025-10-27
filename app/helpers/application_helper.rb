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
      number_to_currency(resource.price, precision: 0)
    elsif data.respond_to?(:call)
      # 3. Procの場合の処理
      data.call(resource)
    else
      # 4. カラムの場合の処理
      resource.send(data)
    end
  end

  # === フォームヘルパーメソッド ===
  
  # 標準的なラベルを生成（h5クラス付き）
  def form_label_lg(form, attribute, options = {})
    options[:class] = "form-label h5 #{options[:class]}".strip
    form.label(attribute, options)
  end

  # 標準的なテキストフィールドを生成（lgサイズ）
  def form_text_field_lg(form, attribute, options = {})
    options[:class] = "form-control form-control-lg #{options[:class]}".strip
    form.text_field(attribute, options)
  end

  # 標準的なナンバーフィールドを生成（lgサイズ）
  def form_number_field_lg(form, attribute, options = {})
    options[:class] = "form-control form-control-lg #{options[:class]}".strip
    form.number_field(attribute, options)
  end

  # 標準的なセレクトボックスを生成（lgサイズ）
  def form_select_lg(form, attribute, choices, select_options = {}, html_options = {})
    html_options[:class] = "form-select form-select-lg #{html_options[:class]}".strip
    form.select(attribute, choices, select_options, html_options)
  end

  # 標準的なコレクションセレクトを生成（lgサイズ）
  def form_collection_select_lg(form, attribute, collection, value_method, text_method, select_options = {}, html_options = {})
    html_options[:class] = "form-select form-select-lg #{html_options[:class]}".strip
    form.collection_select(attribute, collection, value_method, text_method, select_options, html_options)
  end

  # 標準的なテキストエリアを生成（lgサイズ）
  def form_text_area_lg(form, attribute, options = {})
    options[:class] = "form-control form-control-lg #{options[:class]}".strip
    form.text_area(attribute, options)
  end

  # フォームグループ（ラベル + フィールド）を一括生成
  def form_group_lg(form, attribute, field_type: :text_field, **options, &block)
    wrapper_class = options.delete(:wrapper_class) || 'mb-4'
    label_text = options.delete(:label)
    
    content_tag(:div, class: wrapper_class) do
      label_html = form_label_lg(form, attribute, label_text ? { value: label_text } : {})
      
      field_html = if block_given?
        capture(&block)
      else
        case field_type
        when :text_field
          form_text_field_lg(form, attribute, options)
        when :number_field
          form_number_field_lg(form, attribute, options)
        when :text_area
          form_text_area_lg(form, attribute, options)
        when :select
          choices = options.delete(:choices) || []
          select_options = options.delete(:select_options) || {}
          form_select_lg(form, attribute, choices, select_options, options)
        when :collection_select
          collection = options.delete(:collection) || []
          value_method = options.delete(:value_method) || :id
          text_method = options.delete(:text_method) || :name
          select_options = options.delete(:select_options) || { prompt: t('helpers.prompt.select') }
          form_collection_select_lg(form, attribute, collection, value_method, text_method, select_options, options)
        end
      end
      
      label_html + field_html
    end
  end

end
