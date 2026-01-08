# frozen_string_literal: true

# ログイン後のルーティングコントローラー
# 全ユーザーをダッシュボードにリダイレクト
# 権限別の表示制御はDashboardsControllerで実施
class RouterController < ApplicationController
  # before_action :authenticate_user!

  def index

    Rails.logger.info "=" * 80
    Rails.logger.info "[ROUTER DEBUG] Session: #{session.to_hash.inspect}"
    Rails.logger.info "[ROUTER DEBUG] Cookies: #{cookies.to_hash.keys.inspect}"
    Rails.logger.info "[ROUTER DEBUG] user_signed_in?: #{user_signed_in?}"
    Rails.logger.info "[ROUTER DEBUG] current_user: #{current_user.inspect}"
    Rails.logger.info "[ROUTER DEBUG] warden.user: #{request.env['warden']&.user.inspect}"
    Rails.logger.info "=" * 80

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
