class ApplicationController < ActionController::Base

  # レイアウトを動的に切り替える設定を移植
  layout :layout_by_resource

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

  # Deviseでのログイン成功後に遷移するパスを明示的に指定
  def after_sign_in_path_for(resource)
    # 認証済みユーザーのルートパスへ遷移
    authenticated_root_path
  end

  # 認証状態に応じてレイアウトを切り替えるメソッド
  def layout_by_resource
    # Deviseのコントローラー（ログイン、新規登録など）であり、かつ未認証の場合
    if devise_controller? && !user_signed_in?
      'application'
    # 認証済みの画面の場合
    elsif user_signed_in?
      'authenticated_layout'
    # その他（Devise以外のコントローラーなど）の場合
    else
      'application'
    end
  end

end
