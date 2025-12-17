# frozen_string_literal: true

class Admin::UsersController < Admin::BaseController
  before_action :set_user, only: [:show, :edit, :update, :destroy]
  before_action :set_stores, only: [:new, :create, :edit, :update]

  def index
    @users = accessible_users.order(created_at: :desc).page(params[:page])
  end

  def show
    # @user is already set by before_action
  end

  def new
    @user = User.new
    @user.tenant = current_user.tenant
  end

  def create
    @user = User.new(user_params)
    @user.tenant = current_user.tenant
    @user.password = SecureRandom.hex(16)

    if @user.save
      redirect_to admin_user_path(@user), notice: t('admin.users.messages.invited', name: @user.name)
    else
      render :new, status: :unprocessable_entity
    end
  end

  def edit; end

  def update
    if @user.update(user_params_for_update)
      redirect_to admin_user_path(@user), notice: t('admin.users.messages.updated', name: @user.name)
    else
      render :edit, status: :unprocessable_entity
    end
  end

  def destroy
    if @user == current_user
      redirect_to admin_users_path, alert: t('admin.users.messages.cannot_delete_self')
    else
      @user.destroy
      redirect_to admin_user_path(@user), notice: t('admin.users.messages.user_deleted', name: @user.name)
    end
  end

  private

  def accessible_users
    case current_user.role
    when 'store_admin'
      # 店舗管理者: 自分の店舗のユーザーのみ
      current_user.store.users
    when 'company_admin'
      # 会社管理者: 全ユーザー（current_store に関わらず）
      current_user.tenant.users.includes(:store)
    when 'super_admin'
      # システム管理者: 全ユーザー
      User.all.includes(:store)
    else
      User.none
    end
  end

  def set_user
    @user = accessible_users.find(params[:id])
  rescue ActiveRecord::RecordNotFound
    redirect_to admin_users_path, alert: t('admin.users.messages.user_not_found')
  end

  def set_stores
    @stores = case current_user.role
              when 'store_admin'
                [current_user.store]
              when 'company_admin'
                current_user.tenant.stores.order(:code)
              when 'super_admin'
                Store.all.includes(:tenant).order('tenants.name, stores.code')
              else
                []
              end
  end

  def user_params
    params.require(:user).permit(:name, :email, :role, :store_id, :phone)
  end

  def user_params_for_update
    params.require(:user).permit(:name, :email, :role, :store_id, :phone)
  end
end
