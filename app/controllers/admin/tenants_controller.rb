class Admin::TenantsController < ApplicationController
  before_action :authenticate_user!
  before_action :authorize_super_admin!
  before_action :set_tenant, only: [:show, :edit, :update, :destroy]

  def index
    @tenants = Tenant.all

    # ソート処理
    case params[:sort_by]
    when 'subdomain'
      @tenants = @tenants.order(subdomain: :asc)
    when 'created_at'
      @tenants = @tenants.order(created_at: :desc)
    else
      @tenants = @tenants.order(created_at: :desc) # デフォルト: 登録日降順
    end

    @tenants = @tenants.page(params[:page]).per(20)
  end


  def show
  end

  def new
    @tenant = Tenant.new
  end

  def create
    @tenant = Tenant.new(tenant_params)
    
    if @tenant.save
      redirect_to admin_tenant_path(@tenant), notice: t('admin.tenants.messages.created')
    else
      render :new, status: :unprocessable_entity
    end
  end

  def edit
  end

  def update
    if @tenant.update(tenant_params)
      redirect_to admin_tenant_path(@tenant), notice: t('admin.tenants.messages.updated')
    else
      render :edit, status: :unprocessable_entity
    end
  end

  def destroy
    if @tenant.destroy
      redirect_to admin_tenants_path, notice: t('admin.tenants.messages.destroyed')
    else
      redirect_to admin_tenant_path(@tenant), alert: @tenant.errors.full_messages.join(', ')
    end
  end

  private

  def set_tenant
    @tenant = Tenant.find(params[:id])
  end

  def tenant_params
    params.require(:tenant).permit(:name, :subdomain)
  end

  def authorize_super_admin!
    unless current_user.super_admin?
      redirect_to authenticated_root_path, alert: t('errors.unauthorized')
    end
  end
end
