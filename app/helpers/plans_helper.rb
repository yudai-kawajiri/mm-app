module PlansHelper
  # 計画のステータス表示（バッジ + 変更ドロップダウン）
  def render_plan_status_with_action(plan)
    # バッジの色を決定
    status_badge_class = case plan.status
    when "draft" then "bg-secondary"
    when "active" then "bg-success"
    when "completed" then "bg-primary"
    when "cancelled" then "bg-danger"
    else "bg-secondary"
    end

    # ステータスの日本語表示
    status_text = t("activerecord.enums.plan.status.#{plan.status}")

    content_tag(:div, class: "d-flex align-items-center") do
      # バッジ
      badge = content_tag(:span, status_text, class: "badge #{status_badge_class}")

      # ドロップダウン
      dropdown = content_tag(:div, class: "btn-group btn-group-sm ms-2", role: "group") do
        button = content_tag(:button, t('common.change'),
          type: "button",
          class: "btn btn-outline-secondary btn-sm dropdown-toggle",
          data: { bs_toggle: "dropdown" },
          aria: { expanded: false }
        )

        menu_items = Plan.statuses.keys.map do |status_key|
          status_label = t("activerecord.enums.plan.status.#{status_key}")
          content_tag(:li) do
            button_to status_label,
              update_status_plan_path(plan, status: status_key),
              method: :patch,
              class: "dropdown-item border-0 bg-transparent text-start w-100 p-2",
              form: { style: "display: inline; margin: 0;" }
          end
        end.join.html_safe

        menu = content_tag(:ul, menu_items, class: "dropdown-menu")

        button + menu
      end

      badge + dropdown
    end
  end
end