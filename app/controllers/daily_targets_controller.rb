# app/controllers/daily_targets_controller.rb
class DailyTargetsController < AuthenticatedController

  def create
    # Strong Parameters で受け取る
    permitted = daily_target_params
    target_date = parse_target_date(permitted[:target_date])
    return unless target_date

    monthly_budget = find_monthly_budget_for_date(target_date)
    return unless monthly_budget

    # find_or_initialize_by で既存レコード検索 or 新規作成
    @daily_target = DailyTarget.find_or_initialize_by(
      user: current_user,
      monthly_budget: monthly_budget,
      target_date: target_date
    )

    # Strong Parameters で受け取った値を設定
    @daily_target.assign_attributes(permitted.except(:target_date))

    if @daily_target.save
      message = @daily_target.previously_new_record? ? '作成' : '更新'
      redirect_to calendar_numerical_managements_path(month: target_date.strftime('%Y-%m')),
                  notice: "#{target_date.strftime('%-m月%-d日')}の目標を#{message}しました。"
    else
      Rails.logger.error "DailyTarget保存失敗: #{@daily_target.errors.full_messages.join(', ')}"
      redirect_to calendar_numerical_managements_path(month: target_date.strftime('%Y-%m')),
                  alert: "目標の保存に失敗しました: #{@daily_target.errors.full_messages.join(', ')}"
    end
  end

  def update
    # Strong Parameters で受け取る
    permitted = daily_target_params
    target_date = parse_target_date(permitted[:target_date])
    return unless target_date

    # 既存レコードを取得
    @daily_target = DailyTarget.find(params[:id])

    # 権限チェック
    unless @daily_target.user_id == current_user.id
      redirect_to calendar_numerical_managements_path,
                  alert: '権限がありません。'
      return
    end

    # Strong Parameters で受け取った値を設定
    @daily_target.assign_attributes(permitted.except(:target_date))

    if @daily_target.save
      redirect_to calendar_numerical_managements_path(month: target_date.strftime('%Y-%m')),
                  notice: "#{target_date.strftime('%-m月%-d日')}の目標を更新しました。"
    else
      Rails.logger.error "DailyTarget更新失敗: #{@daily_target.errors.full_messages.join(', ')}"
      redirect_to calendar_numerical_managements_path(month: target_date.strftime('%Y-%m')),
                  alert: "目標の更新に失敗しました: #{@daily_target.errors.full_messages.join(', ')}"
    end
  end

  private

  # Strong Parameters
  def daily_target_params
    params.require(:daily_target).permit(:target_date, :target_amount)
  end

  # 日付パース（共通化）
  def parse_target_date(date_string)
    return nil unless date_string.present?

    Date.parse(date_string)
  rescue ArgumentError, TypeError
    redirect_to calendar_numerical_managements_path,
                alert: '無効な日付形式です。'
    nil
  end

  # MonthlyBudget検索（共通化）
  def find_monthly_budget_for_date(date)
    monthly_budget = MonthlyBudget.find_by(
      user: current_user,
      budget_month: date.beginning_of_month
    )

    unless monthly_budget
      redirect_to calendar_numerical_managements_path(month: date.strftime('%Y-%m')),
                  alert: 'この月の予算が設定されていません。'
      return nil
    end

    monthly_budget
  end
end