# frozen_string_literal: true

class Admin::UsersController < Admin::BaseController
  before_action :set_user, only: [:show, :edit, :update, :destroy]
  before_action :set_stores, only: [:new, :create, :edit, :update]

  def index
    # システム管理者の場合
    if current_user.super_admin?
      # session[:current_tenant_id] でフィルタ
      if session[:current_tenant_id].present?
        users_scope = Tenant.find(session[:current_tenant_id]).users
        # 店舗選択がある場合はさらにフィルタ
        if session[:current_store_id].present?
          users_scope = users_scope.where(store_id: session[:current_store_id])
        end
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
    # 承認済みユーザーのみ表示
    @users = @user.store.users.where(approved: true).includes(:tenant).order(:created_at) if @user.store
  end

  def new
    @user = current_user.tenant.users.build
  end

  def create
    @user = current_user.tenant.users.build(user_params)
    @user.approved = false

    if @user.save
      AdminMailer.new_user_notification(@user).deliver_later
      redirect_to [:admin, @user], notice: t('helpers.notice.created', resource: User.model_name.human)
    else
      render :new, status: :unprocessable_entity
    end
  end

  def edit
  end

  def update
    if @user.update(user_params)
      redirect_to [:admin, @user], notice: t('helpers.notice.updated', resource: User.model_name.human)
    else
      render :edit, status: :unprocessable_entity
    end
  end

  def destroy
    @user.destroy!
    redirect_to admin_users_url, notice: t('helpers.notice.destroyed', resource: User.model_name.human), status: :see_other
  end

  private

  def set_user
    # システム管理者の場合
    if current_user.super_admin?
      if session[:current_tenant_id].present?
        @user = Tenant.find(session[:current_tenant_id]).users.find(params[:id])
      else
        @user = User.find(params[:id])
      end
    else
      # 会社管理者・店舗管理者
      @user = current_user.tenant.users.find(params[:id])
    end
  end

  def set_stores
    # システム管理者の場合
    if current_user.super_admin?
      if session[:current_tenant_id].present?
        @stores = Tenant.find(session[:current_tenant_id]).stores
      else
        @stores = Store.all
      end
    else
      # 会社管理者・店舗管理者
      @stores = current_user.tenant.stores
    end
  end

  def user_params
    params.require(:user).permit(:name, :email, :password, :password_confirmation, :role, :store_id)
  end
end
