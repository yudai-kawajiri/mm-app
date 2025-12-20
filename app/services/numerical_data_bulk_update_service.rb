# frozen_string_literal: true

#
# NumericalDataBulkUpdateService
#
# 数値管理データの一括更新を処理するサービスクラス
#
class NumericalDataBulkUpdateService
  attr_reader :errors

  def initialize(user, params, store_id = nil)
    @user = user
    @params = params
    @store_id = store_id
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
        @errors << I18n.t("services.numerical_data_bulk_update.errors.monthly_budget_update_failed",
                          id: id,
                          errors: budget.errors.full_messages.join(", "))
      end
    end
  end

  #
  # DailyTargetレコードの一括更新・作成
  #
  def update_daily_targets
    return unless @params[:daily_targets].present?

    Rails.logger.debug "===== update_daily_targets ====="
    Rails.logger.debug "@params[:daily_targets]: #{@params[:daily_targets].inspect}"

    @params[:daily_targets].each do |key, attributes|
      target_amount = strip_commas(attributes[:target_amount])

      Rails.logger.debug "Processing key: #{key}, target_amount: #{target_amount}"

      # キーが数値ならID、日付文字列なら新規作成
      if key.to_s =~ /^\d+$/ && key.to_i > 0
        # 既存レコードの更新(0を許可)
        target = Management::DailyTarget.find_by(id: key)
        if target
          Rails.logger.debug "Updating existing target ID: #{key}"
          unless target.update(target_amount: target_amount)
            Rails.logger.error "Failed to update target ID: #{key}, errors: #{target.errors.full_messages}"
            @errors << I18n.t("services.numerical_data_bulk_update.errors.daily_target_update_failed",
                              id: key,
                              errors: target.errors.full_messages.join(", "))
          end
        end
      else
        # 新規作成(0の場合はスキップ)
        next if target_amount.to_i.zero?

        Rails.logger.debug "Creating new target for date: #{attributes[:target_date]}"

        # 新規作成(キーは日付文字列)
        target_date = Date.parse(attributes[:target_date])

        # 修正: company_id と store_id を追加
        monthly_budget = Management::MonthlyBudget.find_or_create_by!(
          budget_month: target_date.beginning_of_month,
          company_id: @user.company_id,
          store_id: @store_id
        ) do |budget|
          budget.target_amount = 0
          budget.user_id = @user.id
        end

        target = Management::DailyTarget.find_or_initialize_by(
          monthly_budget: monthly_budget,
          target_date: target_date
        )

        target.user_id = @user.id if target.new_record?

        Rails.logger.debug "Target new_record?: #{target.new_record?}, target_amount: #{target_amount}"

        unless target.update(target_amount: target_amount)
          Rails.logger.error "Failed to save new target for date: #{target_date}, errors: #{target.errors.full_messages}"
          @errors << I18n.t("services.numerical_data_bulk_update.errors.daily_target_save_failed",
                            date: target_date,
                            errors: target.errors.full_messages.join(", "))
        else
          Rails.logger.debug "Successfully saved target for date: #{target_date}"
        end
      end
    rescue Date::Error => e
      Rails.logger.error "Date parse error: #{e.message}, date: #{attributes[:target_date]}"
      @errors << I18n.t("services.numerical_data_bulk_update.errors.invalid_date",
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
        @errors << I18n.t("services.numerical_data_bulk_update.errors.plan_schedule_update_failed",
                          id: id,
                          errors: schedule.errors.full_messages.join(", "))
      end
    end
  end

  #
  # 文字列からカンマを除去して数値化
  #
  def strip_commas(value)
    return nil if value.blank?
    return value if value.is_a?(Numeric)

    value.to_s.delete(",").presence
  end
end
