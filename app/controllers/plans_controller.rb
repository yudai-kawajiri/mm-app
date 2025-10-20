class PlansController < AuthenticatedController

  before_action :set_plan_categories, only: [:index, :new, :edit, :create, :update]
  before_action :set_plan, only: [:show, :edit, :update, :destroy]

  def index
    Rails.logger.debug "--- Search Params: #{search_params.inspect} ---"
    # 未　全員閲覧できるようにするためcurrent_userはなし。他もどうするか考え中
    plans = Plan.all.includes(:category, :user)
              .order(created_at: :desc)
              plans = plans.search_and_filter(search_params)
    @plans = apply_pagination(plans)
  end

  def new
    @plan = Plan.new
    @plan.status = nil
  end

  def create
    @plan =  current_user.plans.build(plan_params)
    respond_to_save(@plan, success_path: @plan)
  end

  def show; end

  def edit
    # 未 コントローラの仕事？ビューの仕事？
    @plan.product_plans.build unless @plan.product_plans.any?
  end

  def update
    @plan.assign_attributes(plan_params)
    respond_to_save(@plan, success_path: @plan)
  end

  def destroy
    respond_to_destroy(@plan, success_path: plans_url)
  end

  private

  def plan_params
    params.require(:plan).permit(
      :category_id,
      :user_id,
      :name,
      :description,
      :status,
      # ネストしたリソースで使用
      product_plans_attributes: [
        :id,
        :_destroy,
        :product_id,
        :production_count
      ]
    )
  end

  def search_params
    get_and_normalize_search_params(:q, :category_id)
  end

  # 未 メソッド内でn+1対応
  def set_plan
    @plan = Plan.includes(product_plans: :product).find(params[:id])
    # 計画に含まれる商品を取得
    @plan_products = @plan.product_plans
  end
end