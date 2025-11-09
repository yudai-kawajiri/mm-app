# frozen_string_literal: true

# StripCommas
#
# 数値入力フィールドからカンマとスペースを自動削除するConcern
#
# 使用例:
#   class Plan < ApplicationRecord
#     include StripCommas
#     strip_commas_from :target_amount, :planned_revenue
#   end
#
# 使用モデル: Plan, Dailyなど数値入力を扱うモデル
module StripCommas
  extend ActiveSupport::Concern

  class_methods do
    # カンマ削除対象のカラムを指定
    #
    # バリデーション前に指定された属性からカンマとスペースを削除し、
    # 数値として有効な場合は整数に変換する
    #
    # @param attributes [Array<Symbol>] カンマを削除する属性名
    # @return [void]
    #
    # @example
    #   strip_commas_from :target_amount, :planned_revenue
    def strip_commas_from(*attributes)
      before_validation do
        attributes.each do |attribute|
          value = send(attribute)
          next if value.blank?

          # 文字列に変換してカンマとスペースを削除
          cleaned = value.to_s.gsub(/[,\s]/, '')

          # 数値として有効な場合のみ整数に変換
          send("#{attribute}=", cleaned.to_i) if cleaned.match?(/^\d+$/)
        end
      end
    end
  end
end
