class PlansController < AuthenticatedController
  before_action :authenticate_user!, except: [:index]
  def index
    # 未　全員閲覧できるようにするためcurrent_userはなし。他もどうするか考え中
    @plans = Plan.all.includes(:category, :user).order(created_at: :desc)

  end

  def new
    @plan = Plan.new
    @tabs_categories = Category.where(category_type: 'product')

  end

  def create
    @plan =  current_user.plans.build(plan_params)
    if @plan.save
      redirect_to plans_path
    else
      # エラー確認のため
      flash.now[:error] = @plan.errors.full_messages.join("、")
      @tabs_categories = Category.where(category_type: 'product')
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
end
