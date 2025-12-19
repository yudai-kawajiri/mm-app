class Admin::UsersController < ApplicationController
  before_action :authenticate_user!
  before_action :set_user, only: [:show, :edit, :update, :destroy]
  before_action :set_stores, only: [:new, :edit, :create, :update]
  before_action :authorize_user_management

  def index
    # システム管理者の場合
    if current_user.super_admin?
      # session[:current_tenant_id] でフィルタ
      if session[:current_tenant_id].present?
        users_scope = Tenant.find(session[:current_tenant_id]).users
      else
        # 全テナントのユーザーを表示
        users_scope = User.all
      end
    else
      # 会社管理者・店舗管理者
      users_scope = current_user.tenant.users

      # 店舗管理者は自店舗のユーザーのみ表示
      if current_user.store_admin?
        users_scope = users_scope.where(store_id: current_user.store_id)
      # 会社管理者は選択中の店舗でフィルタ
      elsif current_user.company_admin? && session[:current_store_id].present?
        users_scope = users_scope.where(store_id: session[:current_store_id])
      end
    end

    # 承認済みユーザーのみ表示
    users_scope = users_scope.where(approved: true)

    @users = users_scope.page(params[:page]).per(20)
  end

  def show
  end

  def new
    @user = User.new

    # 店舗管理者は自店舗のユーザーのみ作成可能
    if current_user.store_admin?
      @user.store_id = current_user.store_id
      @user.role = :general # デフォルトで一般ユーザー
    # 会社管理者が特定店舗を選択している場合
    elsif current_user.company_admin? && session[:current_store_id].present?
      @user.store_id = session[:current_store_id]
    end
  end

  def edit
  end

  def create
    @user = User.new(user_params)
    @user.tenant = current_user.tenant
    @user.approved = true

    # 店舗管理者の制限
    if current_user.store_admin?
      @user.store_id = current_user.store_id
      @user.role = :general # 一般ユーザーのみ作成可能
    # 会社管理者が特定店舗を選択している場合
    elsif current_user.company_admin? && session[:current_store_id].present?
      @user.store_id = session[:current_store_id]
    end

    # パスワード未入力時はランダム生成
    generated_password = nil
    if params[:user][:password].blank?
      generated_password = SecureRandom.urlsafe_base64(12)
      @user.password = generated_password
      @user.password_confirmation = generated_password
    end

    if @user.save
      session[:generated_password] = generated_password if generated_password.present?
      redirect_to admin_user_path(@user), notice: t('admin.users.created', name: @user.name)
    else
      render :new, status: :unprocessable_entity
    end
  end

  def update
    # 店舗管理者は自店舗のユーザーのみ編集可能
    if current_user.store_admin? && @user.store_id != current_user.store_id
      redirect_to admin_users_path, alert: t('errors.messages.unauthorized')
      return
    end

    # パスワードが空欄の場合は更新しない
    update_params = user_params
    if params[:user][:password].blank? && params[:user][:password_confirmation].blank?
      update_params = update_params.except(:password, :password_confirmation)
    end

    if @user.update(update_params)
      redirect_to admin_user_path(@user), notice: t('admin.users.updated', name: @user.name)
    else
      render :edit, status: :unprocessable_entity
    end
  end

  def destroy
    # 店舗管理者は自店舗のユーザーのみ削除可能
    if current_user.store_admin? && @user.store_id != current_user.store_id
      redirect_to admin_users_path, alert: t('errors.messages.unauthorized')
      return
    end

    @user.destroy
    reset_session if current_user == @user
    redirect_to admin_users_path, notice: t('admin.users.destroyed', name: @user.name)
  end

  private

  def set_user
    if current_user.super_admin?
      # システム管理者は全ユーザーから検索
      if session[:current_tenant_id].present?
        @user = Tenant.find(session[:current_tenant_id]).users.find(params[:id])
      else
        @user = User.find(params[:id])
      end
    else
      # 会社管理者・店舗管理者は自分のテナント内のみ
      @user = current_user.tenant.users.find(params[:id])
    end
  end

  def set_stores
    if current_user.super_admin?
      # システム管理者は選択中のテナントの店舗を取得
      if session[:current_tenant_id].present?
        @stores = Tenant.find(session[:current_tenant_id]).stores
      else
        @stores = Store.all
      end
    elsif current_user.tenant.present?
      @stores = current_user.tenant.stores
    else
      @stores = Store.none
    end
  end
  def user_params
    permitted = [:name, :email, :password, :password_confirmation]

    # 店舗管理者は role と store_id を変更できない
    unless current_user.store_admin?
      permitted += [:role, :store_id]
    end

    params.require(:user).permit(*permitted)
  end

  def authorize_user_management
    unless current_user.store_admin? || current_user.company_admin? || current_user.super_admin?
      redirect_to root_path, alert: t('errors.messages.unauthorized')
    end
  end
end
