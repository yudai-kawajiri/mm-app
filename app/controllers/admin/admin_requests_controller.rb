# frozen_string_literal: true

class Admin::AdminRequestsController < Admin::BaseController
  before_action :set_admin_request, only: [:show, :approve, :reject]

  def index
    @admin_requests = accessible_admin_requests
    
    # 検索処理
    if params[:q].present?
      search_term = "%#{params[:q]}%"
      @admin_requests = @admin_requests.joins(:user, :company).where(
        'users.name LIKE ? OR companies.name LIKE ? OR companies.subdomain LIKE ?',
        search_term, search_term, search_term
      ).distinct
    end

    # ソート処理
    @admin_requests = case params[:sort_by]
    when 'company'
      @admin_requests.joins(:company).order('companies.name ASC')
    when 'store'
      @admin_requests.joins(:store).order('stores.name ASC')
    when 'created_at'
      @admin_requests.order(created_at: :desc)
    else
      @admin_requests.joins(:company).order('companies.name ASC')
    end

    @admin_requests = @admin_requests.includes(:user, :store, :company).page(params[:page]).per(20)
  end

  def show
  end

  def new
    @admin_request = AdminRequest.new
  end

  def create
    @admin_request = AdminRequest.new(admin_request_params)
    @admin_request.user = current_user
    @admin_request.company = current_company
    @admin_request.request_type = :store_admin_request

    if @admin_request.save
      redirect_to admin_admin_requests_path, notice: t('admin.admin_requests.messages.created')
    else
      render :new, status: :unprocessable_entity
    end
  end

  def approve
    if @admin_request.approve!(current_user)
      redirect_to admin_admin_requests_path, notice: t('admin.admin_requests.messages.approved')
    else
      redirect_to admin_admin_requests_path, alert: t('admin.admin_requests.messages.approve_failed')
    end
  end

  def reject
    reason = params[:reason].presence || t('admin.admin_requests.default_reject_reason')

    if @admin_request.reject!(current_user, reason: reason)
      redirect_to admin_admin_requests_path, notice: t('admin.admin_requests.messages.rejected')
    else
      redirect_to admin_admin_requests_path, alert: t('admin.admin_requests.messages.reject_failed')
    end
  end

  private

  def set_admin_request
    @admin_request = AdminRequest.find(params[:id])
  end

  def admin_request_params
    params.require(:admin_request).permit(:store_id, :message)
  end

  def accessible_admin_requests
    if current_user.super_admin?
      if session[:current_company_id].present?
        AdminRequest.for_company(Company.find(session[:current_company_id]))
      else
        AdminRequest.all
      end
    elsif current_user.company_admin?
      base_scope = AdminRequest.for_company(current_company)
      session[:current_store_id].present? ? base_scope.where(store_id: session[:current_store_id]) : base_scope
    elsif current_user.store_admin?
      AdminRequest.for_company(current_company).where(store_id: current_user.store_id)
    else
      AdminRequest.none
    end
  end
end
