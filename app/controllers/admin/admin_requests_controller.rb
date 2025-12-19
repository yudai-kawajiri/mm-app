# frozen_string_literal: true

class Admin::AdminRequestsController < Admin::BaseController
  before_action :set_admin_request, only: [:show, :approve, :reject]

  def index
    @admin_requests = if current_user.super_admin?
      # システム管理者: 選択したテナントのリクエストを表示（テナント未選択時は全て）
      if session[:current_tenant_id].present?
        AdminRequest.for_tenant(current_tenant)
      else
        AdminRequest.all
      end
    elsif current_user.company_admin?
      # 会社管理者: 店舗選択状態に応じてフィルタリング
      base_scope = AdminRequest.for_tenant(current_tenant)

      if session[:current_store_id].present?
        # 特定店舗選択時: その店舗のリクエストのみ
        base_scope.where(store_id: session[:current_store_id])
      else
        # 全店舗選択時: 全店舗のリクエストを表示
        base_scope
      end
    elsif current_user.store_admin?
      # 店舗管理者: 自分の店舗のリクエストのみ
      AdminRequest.for_tenant(current_tenant).where(store_id: current_user.store_id)
    else
      # 一般ユーザー: アクセス不可
      AdminRequest.none
    end

    @admin_requests = @admin_requests.includes(:user, :store).recent.page(params[:page])
  end

  def show
  end

  def new
    @admin_request = AdminRequest.new
  end

  def create
    @admin_request = AdminRequest.new(admin_request_params)
    @admin_request.user = current_user
    @admin_request.tenant = current_tenant
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
    # 却下理由を取得（パラメータになければデフォルト値）
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
end
