# frozen_string_literal: true

module Admin
  class AdminRequestsController < ApplicationController
    before_action :authenticate_user!
    before_action :set_admin_request, only: [:show, :approve, :reject]
    before_action :authorize_company_admin!, only: [:index, :show, :approve, :reject]
    before_action :authorize_general_user!, only: [:new, :create]

    def index
      @admin_requests = AdminRequest
        .for_tenant(current_tenant)
        .includes(:user, :store, :approved_by)
        .recent
        .page(params[:page])
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
      if @admin_request.can_be_approved?
        @admin_request.approve!(current_user)
        redirect_to admin_admin_requests_path,
                    notice: t('admin.admin_requests.messages.approved', name: @admin_request.user.name)
      else
        redirect_to admin_admin_requests_path,
                    alert: t('admin.admin_requests.messages.already_processed')
      end
    end

    def reject
      reason = params[:admin_request][:rejection_reason]

      if reason.present? && @admin_request.can_be_approved?
        @admin_request.reject!(current_user, reason: reason)
        redirect_to admin_admin_requests_path,
                    notice: t('admin.admin_requests.messages.rejected')
      else
        redirect_to admin_admin_request_path(@admin_request),
                    alert: t('admin.admin_requests.messages.already_processed')
      end
    end

    private

    def set_admin_request
      @admin_request = AdminRequest.for_tenant(current_tenant).find(params[:id])
    end

    def admin_request_params
      params.require(:admin_request).permit(:store_id, :message)
    end

    def authorize_company_admin!
      redirect_to root_path, alert: t('errors.unauthorized') unless current_user.company_admin? || current_user.super_admin?
    end

    def authorize_general_user!
      redirect_to root_path, alert: t('errors.unauthorized') if current_user.company_admin? || current_user.super_admin?
    end
  end
end
