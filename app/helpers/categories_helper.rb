# frozen_string_literal: true

#
# CategoriesHelper
#
# カテゴリー管理機能用のビューヘルパー
#
# @description
#   カテゴリー表示・編集に関連するヘルパーメソッドを提供します。
#
# @note
#   現在、カテゴリー固有のヘルパーメソッドは定義されていません。
#   将来的にカテゴリー表示のカスタマイズやフォーマット処理が必要になった場合、
#   このモジュールにメソッドを追加してください。
#
# @example 将来的な使用例
#   # カテゴリーのアイコン表示
#   def category_icon(category)
#     content_tag(:i, "", class: "bi bi-#{category.icon_name}")
#   end
#
#   # カテゴリーの色付きバッジ
#   def category_badge(category)
#     content_tag(:span, category.name, class: "badge", style: "background-color: #{category.color}")
#   end
#
module CategoriesHelper
end
