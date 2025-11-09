# frozen_string_literal: true

# DailyTargetsController
#
# 日別目標のCRUD操作を管理
#
# 機能:
#   - 日別目標の作成・更新
#   - 月次予算との紐付け
#   - 権限チェック
class DailyTargetsController < AuthenticatedController
  # 日別目標を作成
  #
  # find_or_initialize_by で既存レコード検索 or 新規作成
  #
  # @return [void]
  def create
    permitted = daily_target_params
    target_date = parse_target_date(permitted[:target_date])
    return unless target_date

    monthly_budget = find_monthly_budget_for_date(target_date)
    return unless monthly_budget

    @daily_target = DailyTarget.find_or_initialize_by(
      user: current_user,
      monthly_budget: monthly_budget,
      target_date: target_date
    )

    @daily_target.assign_attributes(permitted.except(:target_date))

    if @daily_target.save
      message = @daily_target.previously_new_record? ? I18n.t('common.created') : I18n.t('common.updated')
      redirect_to numerical_managements_path(month: target_date.strftime("%Y-%m")),
                  notice: I18n.t('numerical_managements.messages.daily_target_saved',
                                date: target_date.strftime('%-m月%-d日'),
                                action: message)
    else
      Rails.logger.error "DailyTarget保存失敗: #{@daily_target.errors.full_messages.join(', ')}"
      redirect_to numerical_managements_path(month: target_date.strftime("%Y-%m")),
                  alert: I18n.t('numerical_managements.messages.daily_target_save_failed',
                                errors: @daily_target.errors.full_messages.join(', '))
    end
  end

  # 日別目標を更新
  #
  # @return [void]
  def update
    permitted = daily_target_params
    target_date = parse_target_date(permitted[:target_date])
    return unless target_date

    @daily_target = DailyTarget.find(params[:id])

    # 権限チェック
    unless @daily_target.user_id == current_user.id
      redirect_to numerical_managements_path,
                  alert: I18n.t('api.errors.unauthorized')
      return
    end

    @daily_target.assign_attributes(permitted.except(:target_date))

    if @daily_target.save
      redirect_to numerical_managements_path(month: target_date.strftime("%Y-%m")),
                  notice: I18n.t('numerical_managements.messages.daily_target_updated_with_date',
                                date: target_date.strftime('%-m月%-d日'))
    else
      Rails.logger.error "DailyTarget更新失敗: #{@daily_target.errors.full_messages.join(', ')}"
      redirect_to numerical_managements_path(month: target_date.strftime("%Y-%m")),
                  alert: I18n.t('numerical_managements.messages.daily_target_update_failed',
                                errors: @daily_target.errors.full_messages.join(', '))
    end
  end

  private

  # Strong Parameters
  #
  # @return [ActionController::Parameters]
  def daily_target_params
    params.require(:daily_target).permit(:target_date, :target_amount)
  end

  # 日付パース
  #
  # @param date_string [String] 日付文字列
  # @return [Date, nil] パース結果
  def parse_target_date(date_string)
    return nil unless date_string.present?

    Date.parse(date_string)
  rescue ArgumentError, TypeError
    redirect_to numerical_managements_path,
                alert: I18n.t('api.errors.invalid_date')
    nil
  end

  # 月次予算を検索
  #
  # @param date [Date] 対象日
  # @return [MonthlyBudget, nil] 月次予算
  def find_monthly_budget_for_date(date)
    monthly_budget = MonthlyBudget.find_by(
      user: current_user,
      budget_month: date.beginning_of_month
    )

    unless monthly_budget
      redirect_to numerical_managements_path(month: date.strftime("%Y-%m")),
                  alert: I18n.t('numerical_managements.messages.budget_not_set')
      return nil
    end

    monthly_budget
  end
end
