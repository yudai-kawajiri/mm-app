class PlansController < AuthenticatedController

  # define_search_params を使って許可するキーを定義
  define_search_params :q, :category_id

  before_action :set_plan_categories, only: [:index, :new, :edit, :create, :update]
  before_action :set_plan, only: [:show, :edit, :update, :destroy]
  # ネストフォーム用データ準備
  before_action :set_product_categories, only: [:new, :edit, :create, :update]

  def index
    @plans = apply_pagination(
      Plan.all.includes(:category, :user)
        .order(created_at: :desc)
        .search_and_filter(search_params)
    )
    # 検索結果のフィードバック表示のため、共通メソッドで @search_term を設定
    set_search_term_for_view
  end

  def new
    @plan = current_user.plans.build
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

  # 未 メソッド内でn+1対応
  def set_plan
    @plan = Plan.includes(product_plans: :product).find(params[:id])
    # 計画に含まれる商品を取得
    @plan_products = @plan.product_plans
  end

  def set_plan_categories
    @search_categories = current_user.categories.where(category_type: 'plan').order(:name)
    @plan_categories = @search_categories
  end

  def set_product_categories
    @product_categories = current_user.categories.where(category_type: 'product').order(:name)
  end
end