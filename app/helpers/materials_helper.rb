# frozen_string_literal: true

#
# MaterialsHelper
#
# 材料管理機能用のビューヘルパー
#
# @description
#   材料の表示・編集に関連するヘルパーメソッドを提供します。
#
# @note
#   現在、材料固有のヘルパーメソッドは定義されていません。
#   将来的に材料表示のカスタマイズやフォーマット処理が必要になった場合、
#   このモジュールにメソッドを追加してください。
#
# @example 将来的な使用例
#   # 材料の在庫状況バッジ
#   def material_stock_badge(material)
#     if material.stock_quantity <= material.reorder_point
#       content_tag(:span, "要発注", class: "badge bg-danger")
#     elsif material.stock_quantity <= material.warning_point
#       content_tag(:span, "残少", class: "badge bg-warning")
#     else
#       content_tag(:span, "在庫あり", class: "badge bg-success")
#     end
#   end
#
#   # 材料の単価表示（単位付き）
#   def material_price_with_unit(material)
#     "#{number_to_currency(material.price, precision: 0)} / #{material.unit.name}"
#   end
#
module MaterialsHelper
end
