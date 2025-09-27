class ApplicationController < ActionController::Base
  # 全てのアクションで認証チェックを行う
  before_action :authenticate_user!

  # Devise利用時のストロングパラメータを設定するためのフック
  before_action :configure_permitted_parameters, if: :devise_controller?

  protected # privateではない理由は継承クラス（Deviseクラスから呼び出しOKにするため）

  # Deviseのパラメータを許可するメソッド
  def configure_permitted_parameters
    # 新規登録の際に、nameのデータ操作を許可する
    devise_parameter_sanitizer.permit(:sign_up, keys: [ :name ])

    # アカウント編集の際に、nameのデータ操作を許可する
    devise_parameter_sanitizer.permit(:account_update, keys: [ :name ])
  end
end
