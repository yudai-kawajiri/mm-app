# frozen_string_literal: true

#
# ProductsHelper
#
# 商品管理機能用のビューヘルパー
#
# @description
#   商品（Product）の表示・操作に関連するヘルパーメソッドを提供します。
#   特にステータス管理とその変更UIに関する機能を含みます。
#
# @features
#   - ステータスバッジ表示
#   - ステータス変更ドロップダウン
#   - i18n対応のステータス表示
#
module ProductsHelper
  # ステータスとバッジカラーのマッピング
  PRODUCT_STATUS_BADGE_COLORS = {
    "draft" => "bg-secondary",
    "selling" => "bg-success",
    "discontinued" => "bg-danger"
  }.freeze

  #
  # 商品のステータス表示（バッジ + 変更ドロップダウン）
  #
  # @param product [Product] 商品オブジェクト
  # @return [String] ステータスバッジと変更ドロップダウンのHTML
  #
  # @description
  #   ステータスごとに異なる色のバッジを表示：
  #   - draft（下書き）: グレー（bg-secondary）
  #   - active（販売中）: 緑（bg-success）
  #   - discontinued（販売終了）: 赤（bg-danger）
  #
  # @example ビューでの使用
  #   <%= render_product_status_with_action(@product) %>
  #   # => <div class="d-flex align-items-center">
  #   #      <span class="badge bg-success">販売中</span>
  #   #      <div class="btn-group btn-group-sm ms-2">...</div>
  #   #    </div>
  #
  def render_product_status_with_action(product)
    # バッジの色を決定（定数から取得、デフォルトはbg-secondary）
    status_badge_class = PRODUCT_STATUS_BADGE_COLORS.fetch(product.status, "bg-secondary")

    # ステータスの日本語表示（i18n対応）
    status_text = t("activerecord.enums.resources/product.status.#{product.status}")

    content_tag(:div, class: "d-flex align-items-center") do
      # ステータスバッジ
      badge = content_tag(:span, status_text, class: "badge #{status_badge_class}")

      # ステータス変更ドロップダウン
      dropdown = content_tag(:div, class: "btn-group btn-group-sm ms-2", role: "group") do
        # ドロップダウントグルボタン
        button = content_tag(:button, t("common.change"),
          type: "button",
          class: "btn btn-outline-secondary btn-sm dropdown-toggle",
          data: { bs_toggle: "dropdown" },
          aria: { expanded: false }
        )

        # ドロップダウンメニュー項目（すべてのステータスを選択可能）
        menu_items = Resources::Product.statuses.keys.map do |status_key|
          status_label = t("activerecord.enums.resources/product.status.#{status_key}")
          content_tag(:li) do
            button_to status_label,
              update_status_resources_product_path(current_company.slug, product, status: status_key),
              method: :patch,
              class: "dropdown-item border-0 bg-transparent text-start w-100 p-2",
              form: { class: "d-inline" }
          end
        end.join.html_safe

        # ドロップダウンメニュー
        menu = content_tag(:ul, menu_items, class: "dropdown-menu")

        button + menu
      end

      badge + dropdown
    end
  end
end
