class Admin::UsersController < AuthenticatedController
  before_action :require_admin

  def index
    @users = User.all.order(created_at: :desc)
  end

  def destroy
    @user = User.find(params[:id])

    if @user == current_user
      redirect_to admin_users_path, alert: t('admin.users.messages.cannot_delete_self')
    else
      @user.destroy
      redirect_to admin_users_path, notice: t('admin.users.messages.user_deleted', name: @user.name)
    end
  end
end