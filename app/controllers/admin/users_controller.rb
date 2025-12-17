class Admin::UsersController < ApplicationController
  before_action :authenticate_user!
  before_action :set_user, only: [:show, :edit, :update, :destroy]
  before_action :set_stores, only: [:new, :edit, :create, :update]
  before_action :authorize_user_management

  def index
    users_scope = current_user.tenant.users
    
    # 店舗管理者は自店舗のユーザーのみ表示
    if current_user.store_admin? && current_store
      users_scope = users_scope.where(store_id: current_store.id)
    # 会社管理者は選択中の店舗でフィルタ
    elsif current_user.company_admin? && session[:current_store_id].present?
      users_scope = users_scope.where(store_id: session[:current_store_id])
    end
    
    @users = users_scope.page(params[:page]).per(20)
  end


  def show
  end

  def new
    @user = User.new
  end

  def edit
  end

  def create
    @user = User.new(user_params)
    @user.tenant = current_user.tenant
    @user.approved_at = Time.current if @user.respond_to?(:approved_at)
    
    # パスワード未入力時はランダム生成
    generated_password = nil
    if params[:user][:password].blank?
      generated_password = SecureRandom.urlsafe_base64(12)
      @user.password = generated_password
      @user.password_confirmation = generated_password
    end

    if @user.save
      session[:generated_password] = generated_password if generated_password.present?
      redirect_to admin_user_path(@user), notice: "ユーザー #{@user.name} を作成しました"
    else
      render :new, status: :unprocessable_entity
    end
  end

  def update
    # パスワードが空欄の場合は更新しない
    update_params = user_params
    if params[:user][:password].blank? && params[:user][:password_confirmation].blank?
      update_params = update_params.except(:password, :password_confirmation)
    end

    if @user.update(update_params)
      redirect_to admin_user_path(@user), notice: "ユーザー #{@user.name} を更新しました"
    else
      render :edit, status: :unprocessable_entity
    end
  end

  def destroy
    @user.destroy
    reset_session if current_user == @user
    redirect_to admin_users_path, notice: "ユーザー #{@user.name} を削除しました"
  end

  private

  def set_user
    @user = current_user.tenant.users.find(params[:id])
  end

  def set_stores
    @stores = current_user.tenant.stores
  end

  def user_params
    params.require(:user).permit(:name, :email, :role, :store_id, :password, :password_confirmation)
  end

  def authorize_user_management
    unless current_user.super_admin? || current_user.company_admin?
      redirect_to root_path, alert: "この操作を行う権限がありません"
    end
  end
end
