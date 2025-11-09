# frozen_string_literal: true

#
# DashboardsHelper
#
# ダッシュボード表示用のビューヘルパー
#
# @description
#   ダッシュボード画面での統計情報表示、チャート描画、
#   サマリーカード表示に関連するヘルパーメソッドを提供します。
#
# @note
#   現在、ダッシュボード固有のヘルパーメソッドは定義されていません。
#   将来的にダッシュボード表示のカスタマイズが必要になった場合、
#   このモジュールにメソッドを追加してください。
#
# @example 将来的な使用例
#   # 統計カードの表示
#   def stat_card(title, value, icon:, color: "primary")
#     content_tag(:div, class: "card text-#{color}") do
#       content_tag(:div, class: "card-body") do
#         concat content_tag(:i, "", class: "bi bi-#{icon}")
#         concat content_tag(:h3, value)
#         concat content_tag(:p, title)
#       end
#     end
#   end
#
#   # 達成率バッジの表示
#   def achievement_badge(rate)
#     color = rate >= 100 ? "success" : rate >= 80 ? "warning" : "danger"
#     content_tag(:span, "#{rate}%", class: "badge bg-#{color}")
#   end
#
module DashboardsHelper
end
