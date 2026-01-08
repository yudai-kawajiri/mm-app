# frozen_string_literal: true

# ログイン後のルーティングコントローラー
# 全ユーザーをダッシュボードにリダイレクト
# 権限別の表示制御はDashboardsControllerで実施
class RouterController < ApplicationController
  # before_action :authenticate_user!

  def index
    if current_company.present?
      # パスベース: /c/:company_slug/dashboards へリダイレクト
      redirect_to company_dashboards_path(company_slug: current_company.slug)
    else
      # 会社が取得できない場合はルートパスへリダイレクト
      # システム管理者の場合は admin ダッシュボードへ
      if current_user.super_admin?
        redirect_to company_dashboards_path(company_slug: "admin")
      else
        redirect_to company_dashboards_path(company_slug: current_user.company.slug), alert: t("errors.select_company")
      end
    end
  end
end
