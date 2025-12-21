# frozen_string_literal: true

class LandingController < ApplicationController
  layout "application"

  def index
    # params[:logout] == 'success' の場合のメッセージ表示は
    # app/views/landing/index.html.erb で ERB により行われるため、
    # ここでは flash.now への設定は不要

    # サブドメインなし環境でログイン済みの場合
    if user_signed_in? && request.subdomain.blank?
      # params[:logout] がある場合はリダイレクトしない（ログアウト直後）
      return if params[:logout] == "success"

      # テナントが存在する場合は、そのサブドメインにリダイレクト
      if current_user.company
        redirect_to authenticated_root_url(subdomain: current_user.company.subdomain), allow_other_host: true
      else
        # テナントがない場合はログアウト
        sign_out(current_user)
        flash[:alert] = "テナントが見つかりません。再度ログインしてください。"
      end
    end
  end
end
