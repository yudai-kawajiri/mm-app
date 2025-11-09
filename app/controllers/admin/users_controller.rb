# frozen_string_literal: true

# Admin Users Controller
#
# ユーザー管理（管理者専用）
#
# 機能:
# - 全ユーザーの一覧表示
# - ユーザーの削除（自分自身は削除不可）
#
# 認証: 管理者のみアクセス可能（before_action :require_admin）
class Admin::UsersController < AuthenticatedController
  before_action :require_admin

  # ユーザー一覧表示
  #
  # 全ユーザーを作成日時の降順で表示する。
  #
  # @return [void]
  def index
    @users = User.all.order(created_at: :desc)
  end

  # ユーザー削除
  #
  # 指定されたユーザーを削除する。
  # ただし、自分自身は削除できない（安全装置）。
  #
  # @param params [Hash] パラメータ
  # @option params [Integer] :id 削除対象のユーザーID
  #
  # @return [void]
  def destroy
    @user = User.find(params[:id])

    # 自分自身の削除を防止
    if @user == current_user
      redirect_to admin_users_path, alert: t('admin.users.messages.cannot_delete_self')
    else
      @user.destroy
      redirect_to admin_users_path, notice: t('admin.users.messages.user_deleted', name: @user.name)
    end
  end
end
