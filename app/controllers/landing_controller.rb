# frozen_string_literal: true

class LandingController < ApplicationController
  layout "application"

  def index
    # ログイン済みの場合
    if user_signed_in?
      # ログアウト直後はリダイレクトしない
      return if params[:logout] == "success"

      # 会社が存在する場合は、ダッシュボードにリダイレクト
      if current_user.company
        redirect_to company_root_path(company_slug: current_user.company.slug)
      else
        # 会社がない場合はログアウト
        sign_out(current_user)
        flash[:alert] = t("landing.errors.company_not_found")
      end
    end
  end
end
