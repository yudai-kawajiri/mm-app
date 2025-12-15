# frozen_string_literal: true

class Admin::StoresController < AuthenticatedController
  before_action :require_company_admin
  before_action :set_store, only: [:show, :edit, :update, :destroy, :regenerate_invitation_code]

  def index
    @stores = current_user.tenant.stores
                         .left_joins(:users)
                         .select('stores.*, COUNT(users.id) as users_count')
                         .group('stores.id')
                         .order(:code)
  end

  def show
    @users = @store.users.includes(:tenant).order(:created_at)
  end

  def new
    @store = current_user.tenant.stores.build
  end

  def create
    @store = current_user.tenant.stores.build(store_params)

    if @store.save
      redirect_to admin_stores_path, notice: t('admin.stores.created')
    else
      render :new, status: :unprocessable_entity
    end
  end

  def edit; end

  def update
    if @store.update(store_params)
      redirect_to admin_stores_path, notice: t('admin.stores.updated')
    else
      render :edit, status: :unprocessable_entity
    end
  end

  def destroy
    if @store.users.exists?
      redirect_to admin_stores_path, alert: t('admin.stores.cannot_delete_with_users')
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
    @store = current_user.tenant.stores.find(params[:id])
  end

  def store_params
    params.require(:store).permit(:name, :code)
  end
end
