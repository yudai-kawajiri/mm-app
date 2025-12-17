# frozen_string_literal: true

class Users::SessionsController < Devise::SessionsController
  skip_before_action :verify_authenticity_token, only: [:destroy]
  
  # GET /users/sign_in
  def new
    # 既にログインしている場合は一旦ログアウト
    if user_signed_in?
      sign_out(current_user)
      flash[:notice] = '前回のセッションからログアウトしました。再度ログインしてください。'
    end
    super
  end
  
  # DELETE /users/sign_out
  def destroy
    signed_out = (Devise.sign_out_all_scopes ? sign_out : sign_out(resource_name))
    
    # ログアウト成功パラメータを付けて localhost へ強制リダイレクト
    redirect_to "http://localhost:#{request.port}/?logout=success", allow_other_host: true and return
  end
end
