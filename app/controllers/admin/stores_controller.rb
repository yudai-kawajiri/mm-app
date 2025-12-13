# frozen_string_literal: true

class Admin::StoresController < AuthenticatedController
  before_action :require_company_admin
  before_action :set_store, only: [:edit, :update, :destroy]

  def index
    @stores = current_user.tenant.stores.order(:code)
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
      redirect_to admin_stores_path, notice: t('admin.stores.deleted')
    end
  end

  private

  def set_store
    @store = current_user.tenant.stores.find(params[:id])
  end

  def store_params
    params.require(:store).permit(:name, :code)
  end
end
