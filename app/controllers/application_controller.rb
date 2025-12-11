# frozen_string_literal: true

# ApplicationController
#
# 全コントローラーの基底クラス
#
# 機能:
#   - 動的レイアウト切り替え（認証状態に応じて）
#   - Devise パラメータ設定
#   - PaperTrail 変更者記録
#   - ログイン後のリダイレクト制御
class ApplicationController < ActionController::Base
  # レイアウトを動的に切り替え
  layout :layout_by_resource

  # Devise利用時のストロングパラメータ設定
  before_action :configure_permitted_parameters, if: :devise_controller?

  # PaperTrailで変更者を記録
  before_action :set_paper_trail_whodunnit

  before_action :redirect_if_authenticated, if: -> { devise_controller? && action_name == "new" && controller_name == "sessions" }


  protected

  # Deviseのパラメータを許可
  #
  # protectedにしている理由: Deviseコントローラーから呼び出し可能にするため
  #
  # @return [void]
  def configure_permitted_parameters
    # 新規登録時に name と invitation_code を許可
    devise_parameter_sanitizer.permit(:sign_up, keys: [ :name, :invitation_code ])

    # アカウント編集時に name を許可
    devise_parameter_sanitizer.permit(:account_update, keys: [ :name ])
  end

  # ログイン成功後のリダイレクト先
  #
  # @param resource [User] ログインしたユーザー
  # @return [String] リダイレクト先のパス
  def after_sign_in_path_for(resource)
    authenticated_root_path
  end

  # ログアウト後のリダイレクト先
  #
  # @param resource_or_scope [Symbol, User] リソースまたはスコープ
  # @return [String] リダイレクト先のパス（ランディングページ）
  def after_sign_out_path_for(resource_or_scope)
    root_path
  end

  # 認証状態に応じてレイアウトを切り替え
  #
  # @return [String] レイアウト名
  #   - "print": 印刷アクション時
  #   - "application": 未認証時
  #   - "authenticated_layout": 認証済み時
  def layout_by_resource
    # 印刷アクション: 専用レイアウト
    return "print" if action_name == "print"

    # Deviseコントローラー + 未認証: 標準レイアウト
    if devise_controller? && !user_signed_in?
      "application"
    # 認証済み: 認証専用レイアウト
    elsif user_signed_in?
      "authenticated_layout"
    # その他: 標準レイアウト
    else
      "application"
    end
  end

  # PaperTrailで変更者を記録
  #
  # @return [Integer, nil] 変更者のユーザーID（未認証時はnil）
  def user_for_paper_trail
    user_signed_in? ? current_user.id : nil
  end

  private

  # ログイン済みユーザーがログイン画面にアクセスした場合のリダイレクト
  def redirect_if_authenticated
    return unless user_signed_in?

    flash[:notice] = t("devise.failure.already_authenticated")
    redirect_to authenticated_root_path
  end
end
