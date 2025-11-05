class Admin::UsersController < AuthenticatedController
  before_action :require_admin

  def index
    @users = User.all.order(created_at: :desc)
  end

  def destroy
    @user = User.find(params[:id])

    if @user == current_user
      redirect_to admin_users_path, alert: '自分自身は削除できません'
    else
      @user.destroy
      redirect_to admin_users_path, notice: "#{@user.name}のアカウントを削除しました"
    end
  end
end
