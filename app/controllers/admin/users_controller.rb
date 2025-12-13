# frozen_string_literal: true

# Admin Users Controller
#
# ユーザー管理機能
class Admin::UsersController < AuthenticatedController
  before_action :require_admin
  before_action :set_user, only: [:edit, :update, :destroy]
  before_action :set_stores, only: [:new, :create, :edit, :update]

  def index
    @users = accessible_users.includes(:store).order(created_at: :desc)
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

  # 権限に応じてアクセス可能なユーザーを返す
  def accessible_users
    case current_user.role
    when 'store_admin'
      # 店舗管理者: 自店舗のユーザーのみ
      current_user.store.users
    when 'company_admin'
      # 会社管理者: 店舗選択時はその店舗のみ、未選択時は全店舗
      if current_store.present?
        current_store.users
      else
        current_user.tenant.users
      end
    when 'super_admin'
      # スーパー管理者: 全ユーザー
      User.all
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
                # 店舗管理者: 自店舗のみ選択可能
                [current_user.store]
              when 'company_admin'
                # 会社管理者: 自社全店舗から選択可能
                current_user.tenant.stores.order(:code)
              when 'super_admin'
                # スーパー管理者: 全店舗から選択可能
                Store.all.includes(:tenant).order('tenants.name, stores.code')
              else
                []
              end
  end

  def user_params
    params.require(:user).permit(:name, :email, :role, :store_id)
  end

  def user_params_for_update
    params.require(:user).permit(:name, :email, :role, :store_id)
  end
end
