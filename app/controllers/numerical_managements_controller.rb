class NumericalManagementsController < ApplicationController
  before_action :authenticate_user!

  def index
    # パラメータから年月を取得、なければ当月
    if params[:target_month].present?
      @target_date = Date.parse(params[:target_month] + "-01")
    else
      @target_date = Date.today.beginning_of_month
    end
  end
end

