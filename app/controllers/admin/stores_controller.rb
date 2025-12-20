# frozen_string_literal: true

class Admin::StoresController < Admin::BaseController
  before_action :set_store, only: [:show, :edit, :update, :destroy, :regenerate_invitation_code]
  before_action :authorize_store_management, only: [:new, :create, :edit, :update, :destroy, :regenerate_invitation_code]

  def index
    # システム管理者の場合
    if current_user.super_admin?
      # session[:current_tenant_id] でフィルタ
      if session[:current_tenant_id].present?
        @stores = Tenant.find(session[:current_tenant_id]).stores
      else
        # 全テナントの店舗を表示
        @stores = Store.all
      end
    elsif current_user.store_admin?
      # 店舗管理者は自店舗のみ表示
      @stores = current_user.tenant.stores.where(id: current_user.store_id)
    else
      # 会社管理者
      @stores = current_user.tenant.stores
    end

    @stores = @stores.left_joins(:users)
                      .select('stores.*, COUNT(users.id) as users_count')
                      .group('stores.id')
                      .order(:code)
  end
  def show
    # 承認済みユーザーのみ表示
    @users = @store.users.where(approved: true).includes(:tenant).order(:created_at)
  end

  def new
    @store = current_user.tenant.stores.build
  end

  def create
    @store = current_user.tenant.stores.build(store_params)

    if @store.save
      redirect_to admin_store_path(@store), notice: t('admin.stores.created')
    else
      render :new, status: :unprocessable_entity
    end
  end

  def edit; end

  def update
    if @store.update(store_params)
      redirect_to admin_store_path(@store), notice: t('admin.stores.updated')
    else
      render :edit, status: :unprocessable_entity
    end
  end

  def destroy
    if @store.users.exists?
      redirect_to admin_store_path(@store), alert: t('admin.stores.cannot_delete_with_users')
    else
      @store.destroy
      redirect_to admin_stores_path, notice: t('admin.stores.destroyed')
    end
  end

  def regenerate_invitation_code
    @store.regenerate_invitation_code!
    redirect_to admin_store_path(@store), notice: t('admin.stores.invitation_code_regenerated')
  end

  private

  def set_store
    # 店舗管理者は自店舗のみアクセス可能
    if current_user.store_admin?
      @store = current_user.tenant.stores.where(id: current_user.store_id).find(params[:id])
    else
      @store = current_user.tenant.stores.find(params[:id])
    end
  rescue ActiveRecord::RecordNotFound
    redirect_to admin_stores_path, alert: t('admin.stores.not_found_or_unauthorized')
  end

  def store_params
    params.require(:store).permit(:name, :code)
  end

  def authorize_store_management
    # 店舗管理者は作成・編集・削除不可
    if current_user.store_admin?
      redirect_to admin_stores_path, alert: t('errors.messages.unauthorized')
    end
  end
end
