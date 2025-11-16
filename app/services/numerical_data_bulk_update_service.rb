# frozen_string_literal: true

#
# NumericalDataBulkUpdateService
#
# 数値管理データの一括更新を処理するサービスクラス
#
class NumericalDataBulkUpdateService
  attr_reader :errors

  def initialize(user, params)
    @user = user
    @params = params
    @errors = []
  end

  def call
    ActiveRecord::Base.transaction do
      update_monthly_budgets
      update_daily_targets
      update_plan_schedule_actuals

      raise ActiveRecord::Rollback if @errors.any?
    end

    @errors.empty?
  end

  private

  #
  # MonthlyBudgetレコードの一括更新
  #
  def update_monthly_budgets
    return unless @params[:monthly_budgets].present?

    @params[:monthly_budgets].each do |id, attributes|
      budget = Management::MonthlyBudget.find_by(id: id)
      next unless budget

      unless budget.update(target_amount: strip_commas(attributes[:target_amount]))
        @errors << I18n.t('services.numerical_data_bulk_update.errors.monthly_budget_update_failed',
                          id: id,
                          errors: budget.errors.full_messages.join(', '))
      end
    end
  end

  #
  # DailyTargetレコードの一括更新・作成
  #
  def update_daily_targets
    return unless @params[:daily_targets].present?

    @params[:daily_targets].each do |key, attributes|
      target_amount = strip_commas(attributes[:target_amount])
      next if target_amount.to_i.zero?

      # キーが数値ならID、日付文字列なら新規作成
      if key.to_s =~ /^\d+$/ && key.to_i > 0
        # 既存レコードの更新
        target = Management::DailyTarget.find_by(id: key)
        if target
          unless target.update(target_amount: target_amount)
            @errors << I18n.t('services.numerical_data_bulk_update.errors.daily_target_update_failed',
                              id: key,
                              errors: target.errors.full_messages.join(', '))
          end
        end
      else
        # 新規作成（キーは日付文字列）
        target_date = Date.parse(attributes[:target_date])
        monthly_budget = @user.monthly_budgets.find_or_create_by!(
          budget_month: target_date.beginning_of_month
        ) do |budget|
          budget.target_amount = 0
        end

        target = Management::DailyTarget.find_or_initialize_by(
          user: @user,
          monthly_budget: monthly_budget,
          target_date: target_date
        )

        unless target.update(target_amount: target_amount)
          @errors << I18n.t('services.numerical_data_bulk_update.errors.daily_target_save_failed',
                            date: target_date,
                            errors: target.errors.full_messages.join(', '))
        end
      end
    rescue Date::Error
      @errors << I18n.t('services.numerical_data_bulk_update.errors.invalid_date',
                        date: attributes[:target_date])
    end
  end

  #
  # PlanScheduleの実績更新
  #
  def update_plan_schedule_actuals
    return unless @params[:plan_schedule_actuals].present?

    @params[:plan_schedule_actuals].each do |id, attributes|
      schedule = Planning::PlanSchedule.find_by(id: id)
      next unless schedule

      unless schedule.update(actual_revenue: strip_commas(attributes[:actual_revenue]))
        @errors << I18n.t('services.numerical_data_bulk_update.errors.plan_schedule_update_failed',
                          id: id,
                          errors: schedule.errors.full_messages.join(', '))
      end
    end
  end

  #
  # 文字列からカンマを除去して数値化
  #
  def strip_commas(value)
    return nil if value.blank?
    return value if value.is_a?(Numeric)

    value.to_s.delete(',').presence
  end
end
