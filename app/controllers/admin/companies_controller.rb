class Admin::CompaniesController < ApplicationController
  before_action :authenticate_user!
  before_action :authorize_super_admin!
  before_action :set_company, only: [:show, :edit, :update, :destroy]

  def index
    @companies = Company.all

    # ソート処理
    case params[:sort_by]
    when 'subdomain'
      @companies = @companies.order(subdomain: :asc)
    when 'created_at'
      @companies = @companies.order(created_at: :desc)
    else
      @companies = @companies.order(created_at: :desc) # デフォルト: 登録日降順
    end

    @companies = @companies.page(params[:page]).per(20)
  end


  def show
  end

  def new
    @company = Company.new
  end

  def create
    @company = Company.new(tenant_params)
    
    if @company.save
      redirect_to admin_tenant_path(@company), notice: t('admin.companies.messages.created')
    else
      render :new, status: :unprocessable_entity
    end
  end

  def edit
  end

  def update
    if @company.update(tenant_params)
      redirect_to admin_tenant_path(@company), notice: t('admin.companies.messages.updated')
    else
      render :edit, status: :unprocessable_entity
    end
  end

  def destroy
    if @company.destroy
      redirect_to admin_tenants_path, notice: t('admin.companies.messages.destroyed')
    else
      redirect_to admin_tenant_path(@company), alert: @company.errors.full_messages.join(', ')
    end
  end

  private

  def set_company
    @company = Company.find(params[:id])
  end

  def tenant_params
    params.require(:company).permit(:name, :subdomain)
  end

  def authorize_super_admin!
    unless current_user.super_admin?
      redirect_to authenticated_root_path, alert: t('errors.unauthorized')
    end
  end
end
