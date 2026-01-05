# frozen_string_literal: true

require "ostruct"
require "csv"
class Resources::PlansController < AuthenticatedController
  include SortableController

  define_search_params :q, :category_id, :sort_by

  define_sort_options(
    name: -> { order(:name) },
    status: -> { order(:status, :reading) },
    category: -> { joins(:category).order("categories.reading", :reading) },
    created_at: -> { order(created_at: :desc) }
  )

  find_resource :plan, only: [ :show, :edit, :update, :destroy, :copy, :print, :update_status, :export_csv ]
  before_action :set_plan, only: [ :show, :edit, :update, :destroy, :copy, :print, :update_status, :export_csv ]
  before_action :require_store_user, unless: -> { action_name == "print" && params[:plan_schedule_id].present? }

  # 【Eager Loading】
  # N+1クエリを防ぐため、category を事前ロード
  def index
    @plan_categories = scoped_categories.for_plans.ordered
    base_query = scoped_plans.includes(:category)
    base_query = base_query.search_and_filter(search_params) if defined?(search_params)
    sorted_query = apply_sort(base_query, default: "name")
    @plans = apply_pagination(sorted_query)
    set_search_term_for_view if respond_to?(:set_search_term_for_view, true)
  end

  def new
    @plan = Resources::Plan.new
    @plan.user_id = current_user.id
    @plan.company_id = current_company.id
    @plan.store_id = current_user.store_id
    @plan_categories = scoped_categories.for_plans.ordered
    @product_categories = scoped_categories.for_products.ordered
  end

  def create
    @plan = Resources::Plan.new(plan_params)
    @plan.user_id = current_user.id
    @plan.company_id = current_company.id
    @plan.store_id = current_user.store_id if @plan.store_id.blank?

    @plan_categories = scoped_categories.for_plans.ordered
    @product_categories = scoped_categories.for_products.ordered

    respond_to_save(@plan, success_path: -> { scoped_path(:resources_plan_path, @plan) })
  end

  def show
    @plan_products = @plan.plan_products.includes(:product)
    @product_categories = scoped_categories.for_products.ordered
  end

  def edit
    @plan_categories = scoped_categories.for_plans.ordered
    @product_categories = scoped_categories.for_products.ordered
  end

  def update
    @plan.assign_attributes(plan_params)

    @plan_categories = scoped_categories.for_plans.ordered
    @product_categories = scoped_categories.for_products.ordered

    respond_to_save(@plan, success_path: -> { scoped_path(:resources_plan_path, @plan) })
  end

  def destroy
    respond_to_destroy(@plan, success_path: company_resources_plans_path(company_slug: current_company.slug))
  end

  def copy
    @plan.create_copy(user: current_user)
    redirect_to company_resources_plans_path(company_slug: current_company.slug),
                notice: t("flash_messages.copy.success", resource: @plan.class.model_name.human)
  rescue ActiveRecord::RecordInvalid => e
    Rails.logger.error "Plan copy failed: #{e.record.errors.full_messages.join(', ')}"
    redirect_to company_resources_plans_path(company_slug: current_company.slug),
                alert: t("flash_messages.copy.failure", resource: @plan.class.model_name.human)
  end

  def update_status
    if @plan.update(status: params[:status])
      redirect_to company_resources_plans_path(company_slug: current_company.slug),
                  notice: t("flash_messages.resources.plans.messages.status_updated",
                            name: @plan.name,
                            status: t("activerecord.enums.resources/plan.status.#{@plan.status}"))
    else
      error_messages = @plan.errors.full_messages.join("、")
      redirect_to company_resources_plans_path(company_slug: current_company.slug),
                  alert: error_messages
    end
  end

  # 印刷画面を表示
  #
  # 【印刷元の判定】
  # - 日別詳細から: スナップショットデータを使用（過去のデータを再現）
  # - 計画詳細から: 最新のマスタデータを使用
  #
  # 【達成率の計算】
  # 日別詳細からの印刷時のみ、目標額との達成率を表示
  def print
    # 削除済みプランの印刷処理
    if params[:plan_schedule_id].present?
      @plan_schedule = Planning::PlanSchedule.find(params[:plan_schedule_id])
      @scheduled_date = params[:date].present? ? Date.parse(params[:date]) : Date.current
      daily_target = Management::DailyTarget.find_by(target_date: @scheduled_date)
      @budget = daily_target&.target_amount
      render_deleted_plan_print
      return
    end

    from_daily = params[:from_daily] == "true" || params[:date].present?

    if from_daily
      if params[:date].present?
        @scheduled_date = Date.parse(params[:date])
        @plan_schedule = @plan.plan_schedules.find_by(scheduled_date: @scheduled_date)
        daily_target = Management::DailyTarget.find_by(target_date: @scheduled_date)
        @budget = daily_target&.target_amount
      else
        @scheduled_date = nil
        @plan_schedule = nil
        @budget = nil
      end
    else
      @plan_schedule = nil
      @scheduled_date = nil
      @budget = nil
    end

    if from_daily && @plan_schedule&.has_snapshot?
      @plan_products_for_print = @plan_schedule.snapshot_products
                                              .sort_by { |item| [ item[:product].display_order || Resources::Plan::DEFAULT_DISPLAY_ORDER, item[:product].id ] }
    else
      @plan_products_for_print = @plan.plan_products
                                      .includes(product: { image_attachment: :blob })
                                      .joins(:product)
                                      .order("products.display_order ASC, products.id ASC")
                                      .map do |pp|
        {
          product: pp.product,
          production_count: pp.production_count,
          price: pp.product.price,
          subtotal: pp.production_count * pp.product.price
        }
      end
    end

    @planned_revenue = @plan_products_for_print.sum { |item| item[:subtotal] }
    @total_product_cost = @planned_revenue

    Rails.logger.debug "🔍 from_daily: #{from_daily}"
    Rails.logger.debug "🔍 @budget: #{@budget.inspect}"
    Rails.logger.debug "🔍 @planned_revenue: #{@planned_revenue}"
    Rails.logger.debug "🔍 @plan_products_for_print.count: #{@plan_products_for_print.count}"

    if from_daily && @budget && @budget > 0
      @achievement_rate = ((@planned_revenue.to_f / @budget) * 100).round(1)
    else
      @achievement_rate = nil
    end

    @materials_summary = @plan.calculate_materials_summary

    render layout: "print"
  end

  def export_csv
    # 数値管理からの呼び出しの場合、日付情報を取得
    from_daily = params[:date].present?

    if from_daily
      @scheduled_date = Date.parse(params[:date])
      @plan_schedule = @plan.plan_schedules.find_by(scheduled_date: @scheduled_date)
      daily_target = Management::DailyTarget.find_by(target_date: @scheduled_date)
      @budget = daily_target&.target_amount
    end

    # 製造計画の商品データを取得
    plan_products = @plan.plan_products
                        .includes(product: { image_attachment: :blob })
                        .joins(:product)
                        .order("products.display_order ASC, products.id ASC")

    # 原材料サマリーを取得
    materials_summary = @plan.calculate_materials_summary

    # 計画高と達成率を計算
    total_revenue = plan_products.sum { |pp| pp.production_count * pp.product.price }
    achievement_rate = if from_daily && @budget && @budget > 0
                        ((total_revenue.to_f / @budget) * 100).round(1)
                      else
                        nil
                      end

    csv_data = CSV.generate(headers: true, encoding: Encoding::SJIS) do |csv|
      # ========== ヘッダー情報（数値管理からの場合） ==========
      if from_daily
        csv << [encode_for_csv("#{I18n.t('plans.csv.info.plan_name')}: #{@plan.name}")]
        csv << [encode_for_csv("#{I18n.t('plans.csv.info.scheduled_date')}: #{@scheduled_date ? I18n.l(@scheduled_date, format: :long) : '-'}")]
        csv << [encode_for_csv("#{I18n.t('plans.csv.info.budget')}: #{@budget ? format_currency_for_csv(@budget.to_i) : '-'}")]
        csv << [encode_for_csv("#{I18n.t('plans.csv.info.planned_revenue')}: #{format_currency_for_csv(total_revenue.to_i)}")]
        csv << [encode_for_csv("#{I18n.t('plans.csv.info.achievement_rate')}: #{achievement_rate ? "#{achievement_rate}%" : '-'}")]
        csv << []
      end

      # ========== 製造計画書（商品一覧） ==========
      csv << [I18n.t('plans.csv.sections.product_list')]
      csv << []
      csv << [
        I18n.t('plans.csv.headers.product.category'),
        I18n.t('plans.csv.headers.product.item_number'),
        I18n.t('plans.csv.headers.product.name'),
        I18n.t('plans.csv.headers.product.production_count'),
        I18n.t('plans.csv.headers.product.unit_price'),
        I18n.t('plans.csv.headers.product.subtotal')
      ]

      plan_products.each do |pp|
        subtotal = pp.production_count * pp.product.price
        csv << [
          pp.product.category&.name || "-",
          "=\"#{pp.product.item_number}\"",
          pp.product.name,
          pp.production_count,
          pp.product.price,
          subtotal
        ]
      end

      csv << ["", "", I18n.t('plans.csv.total'), "", "", total_revenue]
      csv << []
      csv << []
      csv << [I18n.t('plans.csv.sections.material_list')]
      csv << []
      csv << [
        I18n.t('plans.csv.headers.material.order_group'),
        I18n.t('plans.csv.headers.material.name'),
        I18n.t('plans.csv.headers.material.total_quantity'),
        I18n.t('plans.csv.headers.material.quantity_unit'),
        I18n.t('plans.csv.headers.material.total_weight'),
        I18n.t('plans.csv.headers.material.weight_unit'),
        I18n.t('plans.csv.headers.material.order_quantity'),
        I18n.t('plans.csv.headers.material.order_unit')
      ]

      materials_summary.each do |material|
        csv << [
          material[:order_group_name] || "-",
          material[:material_name],
          material[:total_quantity],
          I18n.t('plans.csv.units.piece'),
          material[:total_weight] || 0,
          I18n.t('plans.csv.units.gram'),
          material[:required_order_quantity],
          material[:order_unit_name]
        ]
      end
    end

    filename = "#{@plan.name}_#{I18n.t('plans.csv.filename_suffix')}_#{Time.current.strftime('%Y%m%d')}.csv"
    send_data csv_data, filename: filename, type: "text/csv"
  end

  def set_plan
    @plan = scoped_plans.find(params[:id])
  end

  def scoped_plans
    case current_user.role
    when "store_admin", "general"
      Resources::Plan.where(store_id: current_user.store_id)
    when "company_admin"
      if session[:current_store_id].present?
        Resources::Plan.where(company_id: current_company.id, store_id: session[:current_store_id])
      else
        Resources::Plan.where(company_id: current_company.id)
      end
    when "super_admin"
      Resources::Plan.all
    else
      Resources::Plan.none
    end
  end

  # 削除済みプランの印刷レンダリング
  def render_deleted_plan_print
    snapshot = @plan_schedule.plan_products_snapshot

    @plan_products_for_print = (snapshot["products"] || []).map do |product|
      {
        product: OpenStruct.new(
          name: product["name"],
          item_number: product["item_number"],
          image: OpenStruct.new(attached?: false)
        ),
        production_count: product["production_count"],
        price: product["price"],
        subtotal: product["subtotal"] || (product["production_count"] * product["price"])
      }
    end
    @planned_revenue = @plan_products_for_print.sum { |item| item[:subtotal] }

    if @budget && @budget > 0
      @achievement_rate = ((@planned_revenue.to_f / @budget) * 100).round(1)
    else
      @achievement_rate = nil
    end

    @plan = OpenStruct.new(
      name: snapshot["plan_name"] || I18n.t('plans.deleted_plan_name'),
      category: OpenStruct.new(name: snapshot["category_name"] || "-")
    )

    @materials_summary = if snapshot["materials_summary"].present?
                          snapshot["materials_summary"].map(&:deep_symbolize_keys)
    else
                          []
    end
    render layout: "print"
  end

  private

  def plan_params
    params.require(:resources_plan).permit(
      :name,
      :reading,
      :category_id,
      :status,
      :description
    ).tap do |whitelisted|
      products = params[:resources_plan][:plan_products_attributes]
      if products.present?
        filtered_products = products.permit!.to_h.reject do |_key, attrs|
          next false if attrs["_destroy"].to_s == "1" || attrs["_destroy"].to_s == "true"
          attrs["product_id"].blank? && attrs["production_count"].blank?
        end

        whitelisted[:plan_products_attributes] = filtered_products.transform_values do |attrs|
          if attrs["production_count"].present?
            attrs["production_count"] = normalize_number_param(attrs["production_count"])
          end
          attrs
        end
      end
    end
  end

  # パラメータの数値を正規化
  #
  # 全角→半角、カンマ・スペース削除
  def normalize_number_param(value)
    return value.to_i if value.is_a?(Numeric)

    cleaned = value.to_s.tr("０-９", "0-9").tr("ー−", "-").gsub(/[,\s　．。.]/, "")
    return nil if cleaned.blank?

    cleaned.to_i
  end

  # CSV用に文字列をSJISエンコード
  def encode_for_csv(str)
    str.to_s.encode(Encoding::SJIS, invalid: :replace, undef: :replace)
  end

  # CSV用に金額をフォーマット
  def format_currency_for_csv(amount)
    formatted = amount.to_s.reverse.gsub(/(\d{3})(?=\d)/, '\1,').reverse
    "￥#{formatted}"
  end
end
