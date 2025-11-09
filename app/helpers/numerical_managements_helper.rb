# frozen_string_literal: true

#
# NumericalManagementsHelper
#
# 数値管理画面で使用されるヘルパーメソッド群
#
# @description
#   数値管理（予算、実績、達成率）の表示に関するヘルパーメソッドを提供します。
#   - 達成率に応じたカラークラス判定
#
# @features
#   - Bootstrap対応のカラークラス自動判定
#   - 閾値ベースの視覚的フィードバック
#
module NumericalManagementsHelper
  # ============================================================
  # 達成率表示
  # ============================================================

  #
  # 達成率に応じたBootstrapテキストカラークラスを返す
  #
  # @param achievement_rate [Numeric] 達成率（パーセント）
  # @return [String] Bootstrapカラークラス
  #
  # @note
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
    return 'text-success' if achievement_rate >= 100
    return 'text-warning' if achievement_rate >= 80

    'text-danger'
  end
end
