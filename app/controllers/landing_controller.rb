# frozen_string_literal: true

class LandingController < ApplicationController
  layout "application"

  def index
    # ログイン済みユーザーはテナントのダッシュボードにリダイレクト
    if user_signed_in? && current_user.tenant
      redirect_to authenticated_root_url(subdomain: current_user.tenant.subdomain), allow_other_host: true
    end
  end
end
