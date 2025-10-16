class PlansController < AuthenticatedController
  before_action :authenticate_user!, except: [:index]
  before_action :set_plan_categories, only: [:new]

  def index
    # 未　全員閲覧できるようにするためcurrent_userはなし。他もどうするか考え中
    @plans = Plan.all.includes(:category, :user).order(created_at: :desc)

  end

  def new
    @plan = Plan.new
    @plan.status = nil
    @tabs_categories = Category.where(category_type: 'product')

  end

  def create
    @plan =  current_user.plans.build(plan_params)
    if @plan.save
      flash[:notice] = t("flash_messages.create.success", resource: Plan.model_name.human, name: @plan.name)
      redirect_to plans_path
    else
      flash.now[:alert] = t("flash_messages.create.failure", resource: Plan.model_name.human)
      @tabs_categories = Category.where(category_type: 'product')
      set_plan_categories # <-- この行を追加！
      render :new, status: :unprocessable_entity
    end
  end

  def edit
  end

  def update
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

  def set_plan_categories
    # 必要なデータをコントローラーで取得する
    @plan_categories = Category.where(category_type: 'plan')
  end
end
