# frozen_string_literal: true

# ログイン後のルーティングコントローラー
# 全ユーザーをダッシュボードにリダイレクト
# 権限別の表示制御はDashboardsControllerで実施
class RouterController < ApplicationController
  before_action :authenticate_user!

  def index
    redirect_to '/dashboards'
  end
end
