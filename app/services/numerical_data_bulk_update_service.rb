# frozen_string_literal: true

#
# NumericalDataBulkUpdateService
#
# 数値管理データの一括更新を処理するサービスクラス
#
# @description
#   MonthlyBudget（月次予算）とDailyTarget（日別目標）の一括更新を
#   トランザクション内で安全に実行します。
#
# @usage
#   service = NumericalDataBulkUpdateService.new(user, params)
#   if service.call
#     # 成功処理
#   else
#     # エラーハンドリング: service.errors
#   end
#
# @features
#   - トランザクション管理による整合性保証
#   - カンマ区切り数値の自動変換
#   - バリデーションエラーの詳細収集
#   - 部分更新失敗時のロールバック
#
class NumericalDataBulkUpdateService
  # @return [Array<String>] エラーメッセージの配列
  attr_reader :errors

  #
  # サービスの初期化
  #
  # @param user [User] 現在のユーザー（権限チェック用）
  # @param params [ActionController::Parameters] 更新パラメータ
  #
  # @option params [Hash] :monthly_budgets MonthlyBudgetの更新データ（id => { budget: "1,000" }）
  # @option params [Hash] :daily_targets DailyTargetの更新データ（id => { target: "500" }）
  #
  # @example
  #   params = {
  #     monthly_budgets: { "1" => { budget: "100,000" } },
  #     daily_targets: { "2" => { target: "3,500" } }
  #   }
  #   service = NumericalDataBulkUpdateService.new(current_user, params)
  #
  def initialize(user, params)
    @user = user
    @params = params
    @errors = []
  end

  #
  # 一括更新を実行
  #
  # @return [Boolean] 成功時true、失敗時false
  #
  # @note
  #   トランザクション内で実行され、一つでも失敗するとすべてロールバックされます
  #
  # @example
  #   if service.call
  #     redirect_to numerical_managements_path, notice: "更新しました"
  #   else
  #     flash.now[:alert] = service.errors.join(", ")
  #     render :index
  #   end
  #
  def call
    ActiveRecord::Base.transaction do
      update_monthly_budgets
      update_daily_targets

      # エラーがある場合はロールバック
      raise ActiveRecord::Rollback if @errors.any?
    end

    @errors.empty?
  end

  private

  #
  # MonthlyBudgetレコードの一括更新
  #
  # @return [void]
  #
  # @note
  #   - カンマ区切り数値を自動変換（StripCommas concern）
  #   - バリデーションエラーは@errorsに追加
  #
  def update_monthly_budgets
    return unless @params[:monthly_budgets].present?

    @params[:monthly_budgets].each do |id, attributes|
      budget = MonthlyBudget.find_by(id: id)
      next unless budget

      # カンマ除去済みの値で更新
      unless budget.update(budget: strip_commas(attributes[:budget]))
        @errors << "月次予算ID #{id}: #{budget.errors.full_messages.join(', ')}"
      end
    end
  end

  #
  # DailyTargetレコードの一括更新
  #
  # @return [void]
  #
  # @note
  #   - カンマ区切り数値を自動変換（StripCommas concern）
  #   - バリデーションエラーは@errorsに追加
  #
  def update_daily_targets
    return unless @params[:daily_targets].present?

    @params[:daily_targets].each do |id, attributes|
      target = DailyTarget.find_by(id: id)
      next unless target

      # カンマ除去済みの値で更新
      unless target.update(target: strip_commas(attributes[:target]))
        @errors << "日別目標ID #{id}: #{target.errors.full_messages.join(', ')}"
      end
    end
  end

  #
  # 文字列からカンマを除去して数値化
  #
  # @param value [String, Numeric] 変換対象の値
  # @return [Numeric, nil] 数値またはnil
  #
  # @example
  #   strip_commas("1,000")  # => 1000
  #   strip_commas("500")    # => 500
  #   strip_commas(nil)      # => nil
  #
  def strip_commas(value)
    return nil if value.blank?
    return value if value.is_a?(Numeric)

    value.to_s.delete(',').presence
  end
end
