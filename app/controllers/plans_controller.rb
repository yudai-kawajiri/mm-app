class PlansController < AuthenticatedController

  # define_search_params を使って許可するキーを定義
  define_search_params :q, :category_id

  find_resource :plan, only: [:show, :edit, :update, :destroy]
  before_action -> { load_categories_for('plan', as: :plan) }, only: [:index, :new, :edit, :create, :update]
  before_action -> { load_categories_for('product', as: :product) }, only: [:new, :edit, :create, :update]
  before_action :load_plan_products, only: [:show]

  def index
    @plans = apply_pagination(
    Plan.for_index.search_and_filter(search_params)
    )
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
    @plan.plan_products.build unless @plan.plan_products.any?
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
      plan_products_attributes: [
        :id,
        :_destroy,
        :product_id,
        :production_count
      ]
    )
  end

  # N+1対策: plan_productsを事前ロード
  def load_plan_products
    @plan_products = @plan.plan_products.includes(:product)
  end

end