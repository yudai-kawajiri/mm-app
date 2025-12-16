# frozen_string_literal: true

class Users::SessionsController < Devise::SessionsController
  # DELETE /users/sign_out
  def destroy
    signed_out = (Devise.sign_out_all_scopes ? sign_out : sign_out(resource_name))
    set_flash_message! :notice, :signed_out if signed_out
    
    # localhostへ強制リダイレクト（allow_other_host: trueで許可）
    redirect_to "http://localhost:#{request.port}/", allow_other_host: true and return
  end
end
