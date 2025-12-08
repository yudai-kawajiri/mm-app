# frozen_string_literal: true

#
# ApplicationHelper
#
# アプリケーション全体で使用される共通ヘルパーメソッド群
#
# @description
#   ビュー全体で共有される基本的なヘルパーメソッドを提供します。
#   - Enum値の翻訳
#   - サイドバーメニュー構築
#   - リソーステーブル表示
#   - 標準フォームコンポーネント
#   - バリデーション対応フォームグループ
#
# @features
#   - i18n対応のEnum翻訳
#   - 権限ベースのメニュー表示
#   - アクティブリンク判定
#   - 統一されたフォームスタイル（Bootstrapベース）
#   - 文字数カウンター機能
#   - 自動バリデーション表示
#
module ApplicationHelper
  # ============================================================
  # Enum翻訳
  # ============================================================

  #
  # Enum値をi18nで翻訳して返す
  #
  # @param record [ActiveRecord::Base] モデルインスタンス
  # @param attribute [Symbol] Enum属性名
  # @return [String] 翻訳されたEnum値、または空文字列
  #
  # @example
  #   translate_enum_value(@plan, :status)
  #   # => "下書き" (for status: "draft")
  #
  # @description
  #   翻訳キーは "activerecord.enums.モデル名.属性名.値" の形式
  #
  def translate_enum_value(record, attribute)
    value = record.send(attribute)
    return "" if value.blank?

    I18n.t("activerecord.enums.#{record.model_name.i18n_key}.#{attribute}.#{value}")
  end

  # ============================================================
  # サイドバーメニュー
  # ============================================================

  #
  # サイドバーのメニュー項目を構築
  #
  # @return [Array<Hash>] メニュー項目の配列
  #
  # @option [String] :name メニュー名（i18n翻訳済み）
  # @option [String] :path メニューのパス
  # @option [Array<Hash>] :submenu サブメニュー項目（オプション）
  #
  # @description
  #   - 管理者権限（admin）の場合のみ管理メニューが表示される
  #   - 各メニュー項目はi18nキー "dashboard.menu.*" で翻訳される
  #
  # @example
  #   sidebar_menu_items.each do |item|
  #     # メニューをレンダリング
  #   end
  #
  def sidebar_menu_items
    items = [
      { name: t("dashboard.menu.dashboard"), path: authenticated_root_path },
      {
        name: t("dashboard.menu.category_management"),
        path: resources_categories_path,
        submenu: [
          { name: t("dashboard.menu.category_list"), path: resources_categories_path },
          { name: t("dashboard.menu.new_category"), path: new_resources_category_path }
        ]
      },
      {
        name: t("dashboard.menu.material_management"),
        path: resources_materials_path,
        submenu: [
          {
            name: t("dashboard.menu.unit_management"),
            path: resources_units_path,
            submenu: [
              { name: t("dashboard.menu.unit_list"), path: resources_units_path },
              { name: t("dashboard.menu.new_unit"), path: new_resources_unit_path }
            ]
          },
          {
            name: t("dashboard.menu.order_group_management"),
            path: resources_material_order_groups_path,
            submenu: [
              { name: t("dashboard.menu.order_group_list"), path: resources_material_order_groups_path },
              { name: t("dashboard.menu.new_order_group"), path: new_resources_material_order_group_path }
            ]
          },
          { name: t("dashboard.menu.material_list"), path: resources_materials_path },
          { name: t("dashboard.menu.new_material"), path: new_resources_material_path }
        ]
      },
      {
        name: t("dashboard.menu.product_management"),
        path: resources_products_path,
        submenu: [
          { name: t("dashboard.menu.product_list"), path: resources_products_path },
          { name: t("dashboard.menu.new_product"), path: new_resources_product_path }
        ]
      },
      {
        name: t("dashboard.menu.plan_management"),
        path: resources_plans_path,
        submenu: [
          { name: t("dashboard.menu.plan_list"), path: resources_plans_path },
          { name: t("dashboard.menu.new_plan"), path: new_resources_plan_path }
        ]
      },
      {
        name: t("dashboard.menu.numerical_management"),
        path: management_numerical_managements_path,
        submenu: [
          { name: t("dashboard.menu.numerical_dashboard"), path: management_numerical_managements_path }
        ]
      }
    ]

    # Admin専用メニューを追加
    if current_user&.admin?
      items << {
        name: t("dashboard.menu.admin_management"),
        path: admin_users_path,
        submenu: [
          { name: t("dashboard.menu.user_management"), path: admin_users_path },
          { name: t("dashboard.menu.system_logs"), path: admin_system_logs_path }
        ]
      }
    end

    items
  end

  #
  # サイドバーリンクがアクティブかどうかを判定
  #
  # @param item [Hash] メニュー項目
  # @option item [String] :path メインパス
  # @option item [Array<Hash>] :submenu サブメニュー項目
  # @return [Boolean] アクティブな場合true
  #
  # @description
  #   - サブメニューがある場合、いずれかのサブメニューがアクティブならtrueを返す
  #   - サブメニューがない場合、自身のパスで判定
  #
  # @example
  #   sidebar_link_active?(item) ? "active" : ""
  #
  def sidebar_link_active?(item)
    if item[:submenu]
      # サブメニューのいずれかがアクティブか判定（3階層対応）
      item[:submenu].any? do |sub|
        if sub[:submenu]
          # 第3階層をチェック
          sub[:submenu].any? { |third| current_page?(third[:path]) }
        else
          current_page?(sub[:path])
        end
      end
    elsif item[:path]
      current_page?(item[:path])
    else
      false
    end
  end
  #
  # サイドバーリンクのCSSクラスを返す
  #
  # @param path [String] リンクのパス
  # @return [String] CSSクラス文字列
  #
  # @example
  #   sidebar_link_class(resources_categories_path)
  #   # => "list-group-item list-group-item-action active"
  #
  def sidebar_link_class(path)
    base_class = "list-group-item list-group-item-action"
    current_page?(path) ? "#{base_class} active" : base_class
  end

  #
  # サイドバーサブメニューのCSSクラスを返す
  #
  # @param path [String] サブメニューのパス
  # @return [String] CSSクラス文字列（左パディング付き）
  #
  # @example
  #   sidebar_submenu_link_class(new_resources_category_path)
  #   # => "list-group-item list-group-item-action ps-5 active"
  #
  def sidebar_submenu_link_class(path)
    base_class = "list-group-item list-group-item-action ps-5"
    current_page?(path) ? "#{base_class} active" : base_class
  end

  #
  # サブメニューのインジケーター（└ 記号）を返す
  #
  # @return [String] HTMLタグ
  #
  # @example
  #   submenu_indicator
  #   # => "<span class='submenu-indicator'>└ </span>"
  #
  def submenu_indicator
    content_tag(:span, "└ ", class: "submenu-indicator")
  end

  # ============================================================
  # リソーステーブル表示
  # ============================================================

  #
  # リソースリストのテーブルセルデータを整形して返す
  #
  # @param resource [ActiveRecord::Base] リソースオブジェクト
  # @param column_definition [Hash] カラム定義
  # @option column_definition [Symbol, Proc] :data データ取得方法
  # @return [String, ActiveSupport::SafeBuffer] 表示用HTML
  #
  # @description
  #   以下の特殊カラムタイプに対応：
  #   - :image - Active Storageの画像サムネイル表示
  #   - :price - 通貨フォーマット表示
  #   - Proc - カスタムレンダリング
  #
  # @example
  #   render_resource_data(@product, { data: :image })
  #   # => <img src="..." class="img-thumbnail" />
  #
  #   render_resource_data(@product, { data: :price })
  #   # => "¥1,000"
  #
  #   render_resource_data(@product, { data: ->(r) { r.name.upcase } })
  #   # => "PRODUCT NAME"
  #
  def render_resource_data(resource, column_definition)
    data = column_definition[:data]

    if data == :image
      # 画像カラムの処理
      if resource.image.attached?
        image_tag resource.image.variant(resize_to_limit: [ 50, 50 ]), class: "img-thumbnail"
      else
        "-"
      end
    elsif data == :price
      # 金額表示カラムの処理
      number_to_currency(resource.price, precision: 0)
    elsif data.respond_to?(:call)
      # Procの場合の処理
      data.call(resource)
    else
      # 通常のカラムの処理
      resource.send(data)
    end
  end

  # ============================================================
  # 標準フォームコンポーネント（Bootstrap lg サイズ統一）
  # ============================================================

  #
  # 標準ラベルを生成（h5 + text-muted スタイル）
  #
  # @param form [ActionView::Helpers::FormBuilder] フォームビルダー
  # @param attribute [Symbol] 属性名
  # @param options [Hash] オプション
  # @return [String] ラベルHTML
  #
  def form_label_lg(form, attribute, options = {})
    options[:class] = "form-label h5 text-muted #{options[:class]}".strip
    form.label(attribute, options)
  end

  #
  # 標準テキストフィールドを生成（lgサイズ）
  #
  # @param form [ActionView::Helpers::FormBuilder] フォームビルダー
  # @param attribute [Symbol] 属性名
  # @param options [Hash] HTML属性オプション
  # @return [String] テキストフィールドHTML
  #
  def form_text_field_lg(form, attribute, options = {})
    options[:class] = "form-control form-control-lg #{options[:class]}".strip
    form.text_field(attribute, options)
  end

  #
  # 標準ナンバーフィールドを生成（lgサイズ）
  #
  # @param form [ActionView::Helpers::FormBuilder] フォームビルダー
  # @param attribute [Symbol] 属性名
  # @param options [Hash] HTML属性オプション
  # @return [String] ナンバーフィールドHTML
  #
  def form_number_field_lg(form, attribute, options = {})
    options[:class] = "form-control form-control-lg #{options[:class]}".strip
    form.number_field(attribute, options)
  end

  #
  # 標準セレクトボックスを生成（lgサイズ）
  #
  # @param form [ActionView::Helpers::FormBuilder] フォームビルダー
  # @param attribute [Symbol] 属性名
  # @param choices [Array] 選択肢の配列
  # @param select_options [Hash] selectメソッドのオプション
  # @param html_options [Hash] HTML属性オプション
  # @return [String] セレクトボックスHTML
  #
  def form_select_lg(form, attribute, choices, select_options = {}, html_options = {})
    html_options[:class] = "form-select form-select-lg #{html_options[:class]}".strip
    form.select(attribute, choices, select_options, html_options)
  end

  #
  # 標準コレクションセレクトを生成（lgサイズ）
  #
  # @param form [ActionView::Helpers::FormBuilder] フォームビルダー
  # @param attribute [Symbol] 属性名
  # @param collection [Array] コレクション
  # @param value_method [Symbol] 値取得メソッド
  # @param text_method [Symbol] 表示テキスト取得メソッド
  # @param select_options [Hash] selectメソッドのオプション
  # @param html_options [Hash] HTML属性オプション
  # @return [String] コレクションセレクトHTML
  #
  def form_collection_select_lg(form, attribute, collection, value_method, text_method, select_options = {}, html_options = {})
    html_options[:class] = "form-select form-select-lg #{html_options[:class]}".strip
    form.collection_select(attribute, collection, value_method, text_method, select_options, html_options)
  end

  #
  # 標準テキストエリアを生成（lgサイズ）
  #
  # @param form [ActionView::Helpers::FormBuilder] フォームビルダー
  # @param attribute [Symbol] 属性名
  # @param options [Hash] HTML属性オプション
  # @return [String] テキストエリアHTML
  #
  def form_text_area_lg(form, attribute, options = {})
    options[:class] = "form-control form-control-lg #{options[:class]}".strip
    form.text_area(attribute, options)
  end

  # ============================================================
  # 統合フォームグループ（ラベル + フィールド + バリデーション）
  # ============================================================

  #
  # フォームグループを一括生成（ラベル + フィールド + バリデーション + 文字数カウンター）
  #
  # @param form [ActionView::Helpers::FormBuilder] フォームビルダー
  # @param attribute [Symbol] 属性名
  # @param field_type [Symbol] フィールドタイプ（:text_field, :number_field, :text_area, :select, :collection_select）
  # @param options [Hash] オプション
  #
  # @option options [String] :wrapper_class ラッパーdivのクラス（デフォルト: "mb-4"）
  # @option options [String] :label ラベルテキスト（省略時は自動翻訳）
  # @option options [String] :help_text ヘルプテキスト
  # @option options [String] :prefix プレフィックス（例: "¥"）
  # @option options [Boolean] :character_counter 文字数カウンター表示（デフォルト: false）
  # @option options [Integer] :max_length 最大文字数（character_counter有効時）
  # @option options [Array] :choices セレクトボックスの選択肢（:select時）
  # @option options [Hash] :select_options selectメソッドのオプション
  # @option options [Array] :collection コレクション（:collection_select時）
  # @option options [Symbol] :value_method 値取得メソッド（:collection_select時）
  # @option options [Symbol] :text_method 表示テキスト取得メソッド（:collection_select時）
  #
  # @yield ブロックが渡された場合はカスタムフィールドをレンダリング
  # @return [String] フォームグループHTML
  #
  # @description
  #   - モデルのバリデーションから自動的に必須フィールドを判定
  #   - エラーがある場合は is-invalid クラスを自動追加
  #   - 文字数カウンターはStimulusコントローラー連携
  #
  # @example 基本的なテキストフィールド
  #   form_group_lg(f, :name, field_type: :text_field)
  #
  # @example 文字数カウンター付きテキストエリア
  #   form_group_lg(f, :description,
  #     field_type: :text_area,
  #     character_counter: true,
  #     max_length: 500
  #   )
  #
  # @example プレフィックス付き金額フィールド
  #   form_group_lg(f, :price,
  #     field_type: :number_field,
  #     prefix: "¥"
  #   )
  #
  # @example コレクションセレクト
  #   form_group_lg(f, :category_id,
  #     field_type: :collection_select,
  #     collection: @categories,
  #     value_method: :id,
  #     text_method: :name
  #   )
  #
  def form_group_lg(form, attribute, field_type: :text_field, **options, &block)
    wrapper_class = options.delete(:wrapper_class) || "mb-4"
    label_text = options.delete(:label)
    help_text = options.delete(:help_text)
    prefix = options.delete(:prefix)
    character_counter = options.delete(:character_counter) || false
    max_length = options.delete(:max_length)

    # 必須かどうかを判定（モデルのバリデーションから自動判定）
    required = form.object.class.validators_on(attribute).any? { |v| v.is_a?(ActiveModel::Validations::PresenceValidator) }

    # エラーがある場合、is-invalid クラスを追加
    if form.object.errors[attribute].any?
      options[:class] = "#{options[:class]} is-invalid".strip
    end

    # 必須フィールドには required 属性を追加
    options[:required] = true if required

    # data オプションの正しいマージ
    options[:data] ||= {}
    options[:data][:form_validation_target] = "field" if required

    # 文字数カウンター用の設定
    if character_counter && max_length
      options[:maxlength] = max_length
      options[:data][:"input--character-counter-target" ] = "input"
      existing_action = options[:data][:action]
      counter_action = "input->input--character-counter#updateCount"
      options[:data][:action] = existing_action ? "#{existing_action} #{counter_action}" : counter_action
    end

    # ラッパーの data 属性
    wrapper_data = {}
    if character_counter && max_length
      wrapper_data[:controller] = "input--character-counter"
      wrapper_data[:"input--character-counter-max-value"] = max_length
    end

    content_tag(:div, class: wrapper_class, data: wrapper_data) do
      # ラベル
      label_html = form_label_lg(form, attribute, label_text ? { value: label_text } : {})

      # フィールド
      field_html = if block_given?
        capture(&block)
      else
        case field_type
        when :text_field
          form_text_field_lg(form, attribute, options)
        when :number_field
          # prefix がある場合は input-group で囲む
          if prefix
            content_tag(:div, class: "input-group input-group-lg") do
              concat content_tag(:span, prefix, class: "input-group-text")
              concat form_number_field_lg(form, attribute, options)
            end
          else
            form_number_field_lg(form, attribute, options)
          end
        when :text_area
          form_text_area_lg(form, attribute, options)
        when :select
          choices = options.delete(:choices) || []
          select_options = options.delete(:select_options) || {}
          options[:class] = (options[:class] || "form-control form-control-lg").gsub("form-control", "form-select")
          form_select_lg(form, attribute, choices, select_options, options)
        when :collection_select
          collection = options.delete(:collection) || []
          value_method = options.delete(:value_method) || :id
          text_method = options.delete(:text_method) || :name
          select_options = options.delete(:select_options) || { prompt: t("helpers.prompt.select") }
          options[:class] = (options[:class] || "form-control form-control-lg").gsub("form-control", "form-select")
          form_collection_select_lg(form, attribute, collection, value_method, text_method, select_options, options)
        end
      end

      # 文字数カウンター表示
      counter_html = if character_counter && max_length
        content_tag(:div, class: "form-text text-end") do
          current = content_tag(:span, "0", data: { "input--character-counter-target": "count" })
          remaining = content_tag(:span, max_length.to_s, class: "text-muted", data: { "input--character-counter-target": "remaining" })

        t("helpers.character_counter.hint",
          current: current,
          max: max_length,
          remaining: remaining
        ).html_safe
      end

      else
        "".html_safe
      end

      # ヘルプテキスト
      help_html = if help_text
        content_tag(:div, help_text, class: "form-text")
      else
        "".html_safe
      end

      # エラーメッセージ
      error_html = if form.object.errors[attribute].any?
        content_tag(:div, form.object.errors[attribute].first, class: "invalid-feedback")
      else
        "".html_safe
      end

      label_html + field_html + counter_html + help_html + error_html
    end
  end

  # ============================================================
  # 通貨フォーマット
  # ============================================================

  #
  # 金額を日本円形式にフォーマット
  #
  # @param amount [Numeric, nil] 金額
  # @return [String] フォーマット済み通貨文字列（例: "¥1,000"）
  #
  # @example
  #   format_currency(1000)      # => "¥1,000"
  #   format_currency(1234567)   # => "¥1,234,567"
  #   format_currency(0)         # => "¥0"
  #   format_currency(nil)       # => "¥0"
  #
  def format_currency(amount)
    number_to_currency(amount || 0, unit: "¥", precision: 0, delimiter: ",")
  end

  #
  # 達成率に応じたBootstrapテキストカラークラスを返す
  #
  # @param achievement_rate [Numeric] 達成率（パーセント）
  # @return [String] Bootstrapカラークラス
  #
  # @description
  #   閾値による判定ロジック：
  #   - 100%以上: text-success（緑）
  #   - 80%以上100%未満: text-warning（黄）
  #   - 80%未満: text-danger（赤）
  #
  # @example
  #   achievement_rate_color_class(105)
  #   # => "text-success"
  #
  #   achievement_rate_color_class(85)
  #   # => "text-warning"
  #
  #   achievement_rate_color_class(50)
  #   # => "text-danger"
  #
  def achievement_rate_color_class(achievement_rate)
    return "text-success" if achievement_rate >= 100
    return "text-warning" if achievement_rate >= 80

    "text-danger"
  end

  # ============================================================
  # リソースパーシャルパス生成
  # ============================================================

  #
  # 名前空間付きモデルの正しいパーシャルパスを生成
  #
  # @param resource [ActiveRecord::Base] モデルインスタンス
  # @param partial_name [String] パーシャル名（デフォルト: "fields"）
  # @return [String] パーシャルパス
  #
  # @example
  #   resource_partial_path(@category, "fields")
  #   # => "resources/categories/fields"
  #
  def resource_partial_path(resource, partial_name = "fields")
    model_name = resource.class.name.underscore
    "#{model_name.pluralize}/#{partial_name}"
  end
end
# frozen_string_literal: true

#
# ApplicationHelper
#
# アプリケーション全体で使用される共通ヘルパーメソッド群
#
# @description
#   ビュー全体で共有される基本的なヘルパーメソッドを提供します。
#   - Enum値の翻訳
#   - サイドバーメニュー構築
#   - リソーステーブル表示
#   - 標準フォームコンポーネント
#   - バリデーション対応フォームグループ
#
# @features
#   - i18n対応のEnum翻訳
#   - 権限ベースのメニュー表示
#   - アクティブリンク判定
#   - 統一されたフォームスタイル（Bootstrapベース）
#   - 文字数カウンター機能
#   - 自動バリデーション表示
#
module ApplicationHelper
  # ============================================================
  # Enum翻訳
  # ============================================================

  #
  # Enum値をi18nで翻訳して返す
  #
  # @param record [ActiveRecord::Base] モデルインスタンス
  # @param attribute [Symbol] Enum属性名
  # @return [String] 翻訳されたEnum値、または空文字列
  #
  # @example
  #   translate_enum_value(@plan, :status)
  #   # => "下書き" (for status: "draft")
  #
  # @description
  #   翻訳キーは "activerecord.enums.モデル名.属性名.値" の形式
  #
  def translate_enum_value(record, attribute)
    value = record.send(attribute)
    return "" if value.blank?

    I18n.t("activerecord.enums.#{record.model_name.i18n_key}.#{attribute}.#{value}")
  end

  # ============================================================
  # サイドバーメニュー
  # ============================================================

  #
  # サイドバーのメニュー項目を構築
  #
  # @return [Array<Hash>] メニュー項目の配列
  #
  # @option [String] :name メニュー名（i18n翻訳済み）
  # @option [String] :path メニューのパス
  # @option [Array<Hash>] :submenu サブメニュー項目（オプション）
  #
  # @description
  #   - 管理者権限（admin）の場合のみ管理メニューが表示される
  #   - 各メニュー項目はi18nキー "dashboard.menu.*" で翻訳される
  #
  # @example
  #   sidebar_menu_items.each do |item|
  #     # メニューをレンダリング
  #   end
  #
  def sidebar_menu_items
    items = [
      { name: t("dashboard.menu.dashboard"), path: authenticated_root_path },
      {
        name: t("dashboard.menu.category_management"),
        path: resources_categories_path,
        submenu: [
          { name: t("dashboard.menu.category_list"), path: resources_categories_path },
          { name: t("dashboard.menu.new_category"), path: new_resources_category_path }
        ]
      },
      {
        name: t("dashboard.menu.material_master_management"),
        path: resources_materials_path,
        submenu: [
          {
            name: t("dashboard.menu.unit_management"),
            path: resources_units_path,
            submenu: [
              { name: t("dashboard.menu.unit_list"), path: resources_units_path },
              { name: t("dashboard.menu.new_unit"), path: new_resources_unit_path }
            ]
          },
          {
            name: t("dashboard.menu.order_group_management"),
            path: resources_material_order_groups_path,
            submenu: [
              { name: t("dashboard.menu.order_group_list"), path: resources_material_order_groups_path },
              { name: t("dashboard.menu.new_order_group"), path: new_resources_material_order_group_path }
            ]
          },
          {
            name: t("dashboard.menu.material_management"),
            path: resources_materials_path,
            submenu: [
              { name: t("dashboard.menu.material_list"), path: resources_materials_path },
              { name: t("dashboard.menu.new_material"), path: new_resources_material_path }
            ]
          }
        ]
      },
      {
        name: t("dashboard.menu.product_management"),
        path: resources_products_path,
        submenu: [
          { name: t("dashboard.menu.product_list"), path: resources_products_path },
          { name: t("dashboard.menu.new_product"), path: new_resources_product_path }
        ]
      },
      {
        name: t("dashboard.menu.plan_management"),
        path: resources_plans_path,
        submenu: [
          { name: t("dashboard.menu.plan_list"), path: resources_plans_path },
          { name: t("dashboard.menu.new_plan"), path: new_resources_plan_path }
        ]
      },
      {
        name: t("dashboard.menu.numerical_management"),
        path: management_numerical_managements_path,
        submenu: [
          { name: t("dashboard.menu.numerical_dashboard"), path: management_numerical_managements_path }
        ]
      }
    ]

    # Admin専用メニューを追加
    if current_user&.admin?
      items << {
        name: t("dashboard.menu.admin_management"),
        path: admin_users_path,
        submenu: [
          { name: t("dashboard.menu.user_management"), path: admin_users_path },
          { name: t("dashboard.menu.system_logs"), path: admin_system_logs_path }
        ]
      }
    end

    items
  end

  #
  # サイドバーリンクがアクティブかどうかを判定
  #
  # @param item [Hash] メニュー項目
  # @option item [String] :path メインパス
  # @option item [Array<Hash>] :submenu サブメニュー項目
  # @return [Boolean] アクティブな場合true
  #
  # @description
  #   - サブメニューがある場合、いずれかのサブメニューがアクティブならtrueを返す
  #   - サブメニューがない場合、自身のパスで判定
  #
  # @example
  #   sidebar_link_active?(item) ? "active" : ""
  #
  def sidebar_link_active?(item)
    if item[:submenu]
      # サブメニューのいずれかがアクティブか判定（3階層対応）
      item[:submenu].any? do |sub|
        if sub[:submenu]
          # 第3階層をチェック
          sub[:submenu].any? { |third| current_page?(third[:path]) }
        else
          current_page?(sub[:path])
        end
      end
    elsif item[:path]
      current_page?(item[:path])
    else
      false
    end
  end
  #
  # サイドバーリンクのCSSクラスを返す
  #
  # @param path [String] リンクのパス
  # @return [String] CSSクラス文字列
  #
  # @example
  #   sidebar_link_class(resources_categories_path)
  #   # => "list-group-item list-group-item-action active"
  #
  def sidebar_link_class(path)
    base_class = "list-group-item list-group-item-action"
    current_page?(path) ? "#{base_class} active" : base_class
  end

  #
  # サイドバーサブメニューのCSSクラスを返す
  #
  # @param path [String] サブメニューのパス
  # @return [String] CSSクラス文字列（左パディング付き）
  #
  # @example
  #   sidebar_submenu_link_class(new_resources_category_path)
  #   # => "list-group-item list-group-item-action ps-5 active"
  #
  def sidebar_submenu_link_class(path)
    base_class = "list-group-item list-group-item-action ps-5"
    current_page?(path) ? "#{base_class} active" : base_class
  end

  #
  # サブメニューのインジケーター（└ 記号）を返す
  #
  # @return [String] HTMLタグ
  #
  # @example
  #   submenu_indicator
  #   # => "<span class='submenu-indicator'>└ </span>"
  #
  def submenu_indicator
    content_tag(:span, "└ ", class: "submenu-indicator")
  end

  # ============================================================
  # リソーステーブル表示
  # ============================================================

  #
  # リソースリストのテーブルセルデータを整形して返す
  #
  # @param resource [ActiveRecord::Base] リソースオブジェクト
  # @param column_definition [Hash] カラム定義
  # @option column_definition [Symbol, Proc] :data データ取得方法
  # @return [String, ActiveSupport::SafeBuffer] 表示用HTML
  #
  # @description
  #   以下の特殊カラムタイプに対応：
  #   - :image - Active Storageの画像サムネイル表示
  #   - :price - 通貨フォーマット表示
  #   - Proc - カスタムレンダリング
  #
  # @example
  #   render_resource_data(@product, { data: :image })
  #   # => <img src="..." class="img-thumbnail" />
  #
  #   render_resource_data(@product, { data: :price })
  #   # => "¥1,000"
  #
  #   render_resource_data(@product, { data: ->(r) { r.name.upcase } })
  #   # => "PRODUCT NAME"
  #
  def render_resource_data(resource, column_definition)
    data = column_definition[:data]

    if data == :image
      # 画像カラムの処理
      if resource.image.attached?
        image_tag resource.image.variant(resize_to_limit: [ 50, 50 ]), class: "img-thumbnail"
      else
        "-"
      end
    elsif data == :price
      # 金額表示カラムの処理
      number_to_currency(resource.price, precision: 0)
    elsif data.respond_to?(:call)
      # Procの場合の処理
      data.call(resource)
    else
      # 通常のカラムの処理
      resource.send(data)
    end
  end

  # ============================================================
  # 標準フォームコンポーネント（Bootstrap lg サイズ統一）
  # ============================================================

  #
  # 標準ラベルを生成（h5 + text-muted スタイル）
  #
  # @param form [ActionView::Helpers::FormBuilder] フォームビルダー
  # @param attribute [Symbol] 属性名
  # @param options [Hash] オプション
  # @return [String] ラベルHTML
  #
  def form_label_lg(form, attribute, options = {})
    options[:class] = "form-label h5 text-muted #{options[:class]}".strip
    form.label(attribute, options)
  end

  #
  # 標準テキストフィールドを生成（lgサイズ）
  #
  # @param form [ActionView::Helpers::FormBuilder] フォームビルダー
  # @param attribute [Symbol] 属性名
  # @param options [Hash] HTML属性オプション
  # @return [String] テキストフィールドHTML
  #
  def form_text_field_lg(form, attribute, options = {})
    options[:class] = "form-control form-control-lg #{options[:class]}".strip
    form.text_field(attribute, options)
  end

  #
  # 標準ナンバーフィールドを生成（lgサイズ）
  #
  # @param form [ActionView::Helpers::FormBuilder] フォームビルダー
  # @param attribute [Symbol] 属性名
  # @param options [Hash] HTML属性オプション
  # @return [String] ナンバーフィールドHTML
  #
  def form_number_field_lg(form, attribute, options = {})
    options[:class] = "form-control form-control-lg #{options[:class]}".strip
    form.number_field(attribute, options)
  end

  #
  # 標準セレクトボックスを生成（lgサイズ）
  #
  # @param form [ActionView::Helpers::FormBuilder] フォームビルダー
  # @param attribute [Symbol] 属性名
  # @param choices [Array] 選択肢の配列
  # @param select_options [Hash] selectメソッドのオプション
  # @param html_options [Hash] HTML属性オプション
  # @return [String] セレクトボックスHTML
  #
  def form_select_lg(form, attribute, choices, select_options = {}, html_options = {})
    html_options[:class] = "form-select form-select-lg #{html_options[:class]}".strip
    form.select(attribute, choices, select_options, html_options)
  end

  #
  # 標準コレクションセレクトを生成（lgサイズ）
  #
  # @param form [ActionView::Helpers::FormBuilder] フォームビルダー
  # @param attribute [Symbol] 属性名
  # @param collection [Array] コレクション
  # @param value_method [Symbol] 値取得メソッド
  # @param text_method [Symbol] 表示テキスト取得メソッド
  # @param select_options [Hash] selectメソッドのオプション
  # @param html_options [Hash] HTML属性オプション
  # @return [String] コレクションセレクトHTML
  #
  def form_collection_select_lg(form, attribute, collection, value_method, text_method, select_options = {}, html_options = {})
    html_options[:class] = "form-select form-select-lg #{html_options[:class]}".strip
    form.collection_select(attribute, collection, value_method, text_method, select_options, html_options)
  end

  #
  # 標準テキストエリアを生成（lgサイズ）
  #
  # @param form [ActionView::Helpers::FormBuilder] フォームビルダー
  # @param attribute [Symbol] 属性名
  # @param options [Hash] HTML属性オプション
  # @return [String] テキストエリアHTML
  #
  def form_text_area_lg(form, attribute, options = {})
    options[:class] = "form-control form-control-lg #{options[:class]}".strip
    form.text_area(attribute, options)
  end

  # ============================================================
  # 統合フォームグループ（ラベル + フィールド + バリデーション）
  # ============================================================

  #
  # フォームグループを一括生成（ラベル + フィールド + バリデーション + 文字数カウンター）
  #
  # @param form [ActionView::Helpers::FormBuilder] フォームビルダー
  # @param attribute [Symbol] 属性名
  # @param field_type [Symbol] フィールドタイプ（:text_field, :number_field, :text_area, :select, :collection_select）
  # @param options [Hash] オプション
  #
  # @option options [String] :wrapper_class ラッパーdivのクラス（デフォルト: "mb-4"）
  # @option options [String] :label ラベルテキスト（省略時は自動翻訳）
  # @option options [String] :help_text ヘルプテキスト
  # @option options [String] :prefix プレフィックス（例: "¥"）
  # @option options [Boolean] :character_counter 文字数カウンター表示（デフォルト: false）
  # @option options [Integer] :max_length 最大文字数（character_counter有効時）
  # @option options [Array] :choices セレクトボックスの選択肢（:select時）
  # @option options [Hash] :select_options selectメソッドのオプション
  # @option options [Array] :collection コレクション（:collection_select時）
  # @option options [Symbol] :value_method 値取得メソッド（:collection_select時）
  # @option options [Symbol] :text_method 表示テキスト取得メソッド（:collection_select時）
  #
  # @yield ブロックが渡された場合はカスタムフィールドをレンダリング
  # @return [String] フォームグループHTML
  #
  # @description
  #   - モデルのバリデーションから自動的に必須フィールドを判定
  #   - エラーがある場合は is-invalid クラスを自動追加
  #   - 文字数カウンターはStimulusコントローラー連携
  #
  # @example 基本的なテキストフィールド
  #   form_group_lg(f, :name, field_type: :text_field)
  #
  # @example 文字数カウンター付きテキストエリア
  #   form_group_lg(f, :description,
  #     field_type: :text_area,
  #     character_counter: true,
  #     max_length: 500
  #   )
  #
  # @example プレフィックス付き金額フィールド
  #   form_group_lg(f, :price,
  #     field_type: :number_field,
  #     prefix: "¥"
  #   )
  #
  # @example コレクションセレクト
  #   form_group_lg(f, :category_id,
  #     field_type: :collection_select,
  #     collection: @categories,
  #     value_method: :id,
  #     text_method: :name
  #   )
  #
  def form_group_lg(form, attribute, field_type: :text_field, **options, &block)
    wrapper_class = options.delete(:wrapper_class) || "mb-4"
    label_text = options.delete(:label)
    help_text = options.delete(:help_text)
    prefix = options.delete(:prefix)
    character_counter = options.delete(:character_counter) || false
    max_length = options.delete(:max_length)

    # 必須かどうかを判定（モデルのバリデーションから自動判定）
    required = form.object.class.validators_on(attribute).any? { |v| v.is_a?(ActiveModel::Validations::PresenceValidator) }

    # エラーがある場合、is-invalid クラスを追加
    if form.object.errors[attribute].any?
      options[:class] = "#{options[:class]} is-invalid".strip
    end

    # 必須フィールドには required 属性を追加
    options[:required] = true if required

    # data オプションの正しいマージ
    options[:data] ||= {}
    options[:data][:form_validation_target] = "field" if required

    # 文字数カウンター用の設定
    if character_counter && max_length
      options[:maxlength] = max_length
      options[:data][:"input--character-counter-target" ] = "input"
      existing_action = options[:data][:action]
      counter_action = "input->input--character-counter#updateCount"
      options[:data][:action] = existing_action ? "#{existing_action} #{counter_action}" : counter_action
    end

    # ラッパーの data 属性
    wrapper_data = {}
    if character_counter && max_length
      wrapper_data[:controller] = "input--character-counter"
      wrapper_data[:"input--character-counter-max-value"] = max_length
    end

    content_tag(:div, class: wrapper_class, data: wrapper_data) do
      # ラベル
      label_html = form_label_lg(form, attribute, label_text ? { value: label_text } : {})

      # フィールド
      field_html = if block_given?
        capture(&block)
      else
        case field_type
        when :text_field
          form_text_field_lg(form, attribute, options)
        when :number_field
          # prefix がある場合は input-group で囲む
          if prefix
            content_tag(:div, class: "input-group input-group-lg") do
              concat content_tag(:span, prefix, class: "input-group-text")
              concat form_number_field_lg(form, attribute, options)
            end
          else
            form_number_field_lg(form, attribute, options)
          end
        when :text_area
          form_text_area_lg(form, attribute, options)
        when :select
          choices = options.delete(:choices) || []
          select_options = options.delete(:select_options) || {}
          options[:class] = (options[:class] || "form-control form-control-lg").gsub("form-control", "form-select")
          form_select_lg(form, attribute, choices, select_options, options)
        when :collection_select
          collection = options.delete(:collection) || []
          value_method = options.delete(:value_method) || :id
          text_method = options.delete(:text_method) || :name
          select_options = options.delete(:select_options) || { prompt: t("helpers.prompt.select") }
          options[:class] = (options[:class] || "form-control form-control-lg").gsub("form-control", "form-select")
          form_collection_select_lg(form, attribute, collection, value_method, text_method, select_options, options)
        end
      end

      # 文字数カウンター表示
      counter_html = if character_counter && max_length
        content_tag(:div, class: "form-text text-end") do
          current = content_tag(:span, "0", data: { "input--character-counter-target": "count" })
          remaining = content_tag(:span, max_length.to_s, class: "text-muted", data: { "input--character-counter-target": "remaining" })

        t("helpers.character_counter.hint",
          current: current,
          max: max_length,
          remaining: remaining
        ).html_safe
      end

      else
        "".html_safe
      end

      # ヘルプテキスト
      help_html = if help_text
        content_tag(:div, help_text, class: "form-text")
      else
        "".html_safe
      end

      # エラーメッセージ
      error_html = if form.object.errors[attribute].any?
        content_tag(:div, form.object.errors[attribute].first, class: "invalid-feedback")
      else
        "".html_safe
      end

      label_html + field_html + counter_html + help_html + error_html
    end
  end

  # ============================================================
  # 通貨フォーマット
  # ============================================================

  #
  # 金額を日本円形式にフォーマット
  #
  # @param amount [Numeric, nil] 金額
  # @return [String] フォーマット済み通貨文字列（例: "¥1,000"）
  #
  # @example
  #   format_currency(1000)      # => "¥1,000"
  #   format_currency(1234567)   # => "¥1,234,567"
  #   format_currency(0)         # => "¥0"
  #   format_currency(nil)       # => "¥0"
  #
  def format_currency(amount)
    number_to_currency(amount || 0, unit: "¥", precision: 0, delimiter: ",")
  end

  #
  # 達成率に応じたBootstrapテキストカラークラスを返す
  #
  # @param achievement_rate [Numeric] 達成率（パーセント）
  # @return [String] Bootstrapカラークラス
  #
  # @description
  #   閾値による判定ロジック：
  #   - 100%以上: text-success（緑）
  #   - 80%以上100%未満: text-warning（黄）
  #   - 80%未満: text-danger（赤）
  #
  # @example
  #   achievement_rate_color_class(105)
  #   # => "text-success"
  #
  #   achievement_rate_color_class(85)
  #   # => "text-warning"
  #
  #   achievement_rate_color_class(50)
  #   # => "text-danger"
  #
  def achievement_rate_color_class(achievement_rate)
    return "text-success" if achievement_rate >= 100
    return "text-warning" if achievement_rate >= 80

    "text-danger"
  end

  # ============================================================
  # リソースパーシャルパス生成
  # ============================================================

  #
  # 名前空間付きモデルの正しいパーシャルパスを生成
  #
  # @param resource [ActiveRecord::Base] モデルインスタンス
  # @param partial_name [String] パーシャル名（デフォルト: "fields"）
  # @return [String] パーシャルパス
  #
  # @example
  #   resource_partial_path(@category, "fields")
  #   # => "resources/categories/fields"
  #
  def resource_partial_path(resource, partial_name = "fields")
    model_name = resource.class.name.underscore
    "#{model_name.pluralize}/#{partial_name}"
  end
end
