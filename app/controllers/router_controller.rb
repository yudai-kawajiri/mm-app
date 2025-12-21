# frozen_string_literal: true

# ログイン後のルーティングコントローラー
# 全ユーザーをダッシュボードにリダイレクト
# 権限別の表示制御はDashboardsControllerで実施
class RouterController < ApplicationController
  before_action :authenticate_user!

  def index
    if current_company.present?
      # パスベース: /c/:company_subdomain/dashboards へリダイレクト
      redirect_to company_dashboards_path(company_slug: current_company.slug)
    else
      # 会社が取得できない場合は選択画面へ
      redirect_to select_company_path, alert: "会社を選択してください"
    end
  end
end
