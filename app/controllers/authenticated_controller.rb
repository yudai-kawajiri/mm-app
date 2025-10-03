class AuthenticatedController < ApplicationController
  # 認証必須のチェックを移植して
  before_action :authenticate_user!
end
