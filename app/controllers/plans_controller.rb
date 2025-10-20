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
    if @plan.save
      flash[:notice] = t("flash_messages.create.success", resource: Plan.model_name.human, name: @plan.name)
      redirect_to @plan
    else
      flash.now[:alert] = t("flash_messages.create.failure", resource: Plan.model_name.human)
      set_plan_categories
      render :new, status: :unprocessable_entity
    end
  end

  def show; end

  def edit
    # 未 コントローラの仕事？ビューの仕事？
    @plan.product_plans.build unless @plan.product_plans.any?
  end

  def update
    if @plan.update(plan_params)
      flash[:notice] = t("flash_messages.update.success", resource: Plan.model_name.human, name: @plan.name)
      redirect_to plan_path(@plan)
    else
      flash.now[:alert] = t("flash_messages.update.failure", resource: Plan.model_name.human)
      @plan.product_plans.build unless @plan.product_plans.any?
      render :edit, status: :unprocessable_entity
    end
  end

  def destroy
    @plan.destroy
    flash[:notice] = t("flash_messages.destroy.success", resource: Plan.model_name.human, name: @plan.name)
    redirect_to plans_url, status: :see_other
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

  # カテゴリー取得メソッド
  def set_plan_categories
    # 計画カテゴリーは検索とフォームの両方で使うため、@search_categories に統一
    @search_categories = fetch_categories_by_type(:plan)

    # 商品カテゴリーはネストフォームで使用するため、@product_categories を設定
    @product_categories = fetch_categories_by_type(:product)
  end
end