# app/controllers/daily_targets_controller.rb
class DailyTargetsController < ApplicationController
  before_action :set_daily_target, only: [:update]

  def update
    if @daily_target.update(daily_target_params)
      redirect_to calendar_numerical_managements_path(month: @daily_target.target_date.strftime('%Y-%m')),
                  notice: "#{@daily_target.target_date.strftime('%-m月%-d日')}の目標を更新しました。"
    else
      redirect_to calendar_numerical_managements_path(month: @daily_target.target_date.strftime('%Y-%m')),
                  alert: "目標の更新に失敗しました: #{@daily_target.errors.full_messages.join(', ')}"
    end
  end

  private

  def set_daily_target
    @daily_target = DailyTarget.find(params[:id])
  end

  def daily_target_params
    params.require(:daily_target).permit(:target_amount)
  end
end
