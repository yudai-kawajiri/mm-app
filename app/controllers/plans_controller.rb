class PlansController < ApplicationController
  def index
    # 未　全員閲覧できるようにするためcurrent_userはなし。他もどうするか考え中
    @plan = Plan.all.includes(:category, :user).order(plan_date: desc)

  end

  def new
    @plan = Plan.new
    # ネストフォーム用に、子レコードを最低1つビルドしておく
    @plan.product_plans.build
  end

  def create
    @plan = Plan.new(plan_params(:id))
    if @plan.save
      redirect_to @plan
    else
      render :new
    end
  end

  def edit
  end

  def update
  end

  private

  def plan_params
    params.require(:plan).permit(
      :plan_date,
      :category_id,
      :user_id,
      # ネストしたリソースで使用
      product_plans_attributes: [
        :product_id,
        :production_count
      ]
    )
  end
end
