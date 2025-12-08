# frozen_string_literal: true

#
# Management::PlanSchedulesController
#
# 計画スケジュールのCRUD操作と実績入力を管理
#
# 機能:
#   - 計画のスケジュール登録（1日1計画）
#   - 計画の変更（上書き）
#   - 商品数量調整機能（スナップショット作成）
#   - 実績売上の入力
#   - 計画高の自動計算
#
class Management::PlanSchedulesController < AuthenticatedController
  include NumericSanitizer

  #
  # 計画スケジュールを作成
  #
  # 1日1計画のみ（同じ日の計画は上書き）
  # 商品数量調整がある場合はスナップショット作成
  #
  # @return [void]
  #
  def create
    permitted = sanitized_plan_schedule_params
    scheduled_date = parse_scheduled_date(permitted[:scheduled_date])
    return unless scheduled_date

    unless permitted[:plan_id].present?
      redirect_to management_numerical_managements_path(
        year: scheduled_date.year,
        month: scheduled_date.month
      ),
                  alert: I18n.t("api.errors.missing_required_info")
      return
    end

    plan = Resources::Plan.find(permitted[:plan_id])

    @plan_schedule = Planning::PlanSchedule.find_or_initialize_by(
      scheduled_date: scheduled_date
    )
    @plan_schedule.user_id ||= current_user.id  # 新規作成時のみ user_id を設定

    @plan_schedule.assign_attributes(
      plan: plan,
      status: @plan_schedule.persisted? ? @plan_schedule.status : :scheduled
    )

    if @plan_schedule.save
      # 商品数量調整がある場合、スナップショットを作成
      if params[:plan_schedule][:products].present?
        @plan_schedule.create_snapshot_from_products(params[:plan_schedule][:products])
      else
        # 商品数量調整がない場合、計画からスナップショットを作成
        @plan_schedule.create_snapshot_from_plan
      end

      action = @plan_schedule.previously_new_record? ? I18n.t("numerical_managements.messages.plan_assigned") : I18n.t("numerical_managements.messages.plan_assigned")

      redirect_to management_numerical_managements_path(
        year: scheduled_date.year,
        month: scheduled_date.month
      ), notice: action
    else
      redirect_to management_numerical_managements_path(
        year: scheduled_date.year,
        month: scheduled_date.month
      ),
                  alert: I18n.t("flash_messages.plan_schedule.create.failure")
    end
  end

  #
  # 計画スケジュールを更新
  #
  # 商品数量調整がある場合はスナップショット更新
  #
  # @return [void]
  #
  def update
    permitted = sanitized_plan_schedule_params
    scheduled_date = parse_scheduled_date(permitted[:scheduled_date])
    return unless scheduled_date

    @plan_schedule = Planning::PlanSchedule.find(params[:id])
    plan = Resources::Plan.find(permitted[:plan_id])

    @plan_schedule.assign_attributes(
      plan: plan
    )

    if @plan_schedule.save
      # 商品数量調整がある場合、スナップショットを更新
      if permitted[:products].present?
        @plan_schedule.create_snapshot_from_products(params[:plan_schedule][:products])
      else
        # 商品数量調整がない場合、計画からスナップショットを更新
        @plan_schedule.create_snapshot_from_plan
      end

      redirect_to management_numerical_managements_path(
        year: scheduled_date.year,
        month: scheduled_date.month
      ), notice: I18n.t("numerical_managements.messages.plan_assigned")
    else
      redirect_to management_numerical_managements_path(
        year: scheduled_date.year,
        month: scheduled_date.month
      ),
                  alert: I18n.t("flash_messages.plan_schedule.update.failure")
    end
  end

  #
  # 実績入力専用アクション
  #
  # RESTful命名規則に準拠
  # 実績入力時、スナップショットが未作成の場合は自動作成
  #
  # @return [void]
  #
  def actual_revenue
    @plan_schedule = Planning::PlanSchedule.find(params[:id])
    permitted = sanitized_plan_schedule_params

    if @plan_schedule.update(permitted.slice(:actual_revenue))
      # 実績入力時、スナップショットが未作成の場合は自動作成
      unless @plan_schedule.has_snapshot?
        @plan_schedule.create_snapshot_from_plan
      end

      redirect_to management_numerical_managements_path(
        year: @plan_schedule.scheduled_date.year,
        month: @plan_schedule.scheduled_date.month
      ), notice: t("numerical_managements.messages.actual_revenue_updated")
    else
      redirect_to management_numerical_managements_path(
        year: @plan_schedule.scheduled_date.year,
        month: @plan_schedule.scheduled_date.month
      ), alert: t("numerical_managements.messages.actual_revenue_update_failed")
    end
  end

  private

  #
  # Strong Parameters
  #
  # @return [ActionController::Parameters]
  #
  def plan_schedule_params
    # planning_plan_schedule でも plan_schedule でも受け付ける
    key = params.key?(:planning_plan_schedule) ? :planning_plan_schedule : :plan_schedule
    params.require(key).permit(:scheduled_date, :plan_id, :actual_revenue, :description, products: {})
  end

  #
  # サニタイズ済みパラメータ
  #
  # NumericSanitizerで全角→半角、カンマ削除、スペース削除
  #
  # @return [ActionController::Parameters]
  #
  def sanitized_plan_schedule_params
    sanitize_numeric_params(
      plan_schedule_params,
      with_comma: [ :actual_revenue ]
    )
  end

  #
  # 日付パース
  #
  # @param date_string [String] 日付文字列
  # @return [Date, nil] パース結果
  #
  def parse_scheduled_date(date_string)
    return nil unless date_string.present?

    Date.parse(date_string)
  rescue ArgumentError, TypeError
    redirect_to management_numerical_managements_path(
      year: Date.current.year,
      month: Date.current.month
    ),
                alert: I18n.t("api.errors.invalid_date")
    nil
  end

  #
  # 商品パラメータからスナップショットを作成
  #
  # @param products_params [Hash] 商品パラメータ { "product_id" => "数量" }
  # @return [void]
  #
  def create_snapshot_from_products(products_params)
    products_data = products_params.map do |product_id, production_count|
      { product_id: product_id.to_i, production_count: production_count.to_i }
    end

    @plan_schedule.update_products_snapshot(products_data)
  end
end
