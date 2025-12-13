# frozen_string_literal: true

class Admin::UsersController < AuthenticatedController
  before_action :require_admin
  before_action :set_user, only: [:edit, :update, :destroy]
  before_action :set_stores, only: [:new, :create, :edit, :update]

  def index
    @users = if current_user.store_admin?
                current_user.store.users.includes(:store).order(created_at: :desc)
              else
                current_user.tenant.users.includes(:store).order(created_at: :desc)
              end
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
      redirect_to admin_users_path, notice: t('admin.users.messages.invited', name: @user.name)
    else
      render :new, status: :unprocessable_entity
    end
  end

  def edit; end

  def update
    if @user.update(user_params_for_update)
      redirect_to admin_users_path, notice: t('admin.users.messages.updated', name: @user.name)
    else
      render :edit, status: :unprocessable_entity
    end
  end

  def destroy
    if @user == current_user
      redirect_to admin_users_path, alert: t('admin.users.messages.cannot_delete_self')
    else
      @user.destroy
      redirect_to admin_users_path, notice: t('admin.users.messages.user_deleted', name: @user.name)
    end
  end

  private

  def set_user
    @user = if current_user.store_admin?
              current_user.store.users.find(params[:id])
            else
              current_user.tenant.users.find(params[:id])
            end
  end

  def set_stores
    @stores = if current_user.store_admin?
                [current_user.store]
              else
                current_user.tenant.stores.order(:code)
              end
  end

  def user_params
    params.require(:user).permit(:name, :email, :role, :store_id)
  end

  def user_params_for_update
    params.require(:user).permit(:name, :email, :role, :store_id)
  end
end
