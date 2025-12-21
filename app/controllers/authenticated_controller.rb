# frozen_string_literal: true

class AuthenticatedController < ApplicationController
  before_action :authenticate_user!

  include CategoryFetchable
  include SearchAndFilterConcern
  include PaginationConcern
  include ResourceFinderConcern
  include CrudResponderConcern
  include SearchableController

  def set_search_term_for_view
    @search_term = search_params[:q] if defined?(search_params) && search_params[:q].present?
  end

  def load_categories_for(category_type, as: nil, scope: :all)
    categories = Resources::Category.where(category_type: category_type).order(:name)
    prefix = as || category_type
    instance_variable_set("@#{prefix}_categories", categories)
    @search_categories = categories if as == :search || as.nil?
    categories
  end

  private

  def require_admin
    unless current_user&.store_admin? || current_user&.can_manage_company?
      redirect_to root_path, alert: t("flash_messages.not_authorized")
    end
  end

  def require_company_admin
    unless current_user&.can_manage_company?
      redirect_to root_path, alert: t("flash_messages.not_authorized")
    end
  end

  # 店舗ユーザー専用（システム管理者・会社管理者は不可）
  def require_store_user
    return unless current_user
    if current_user.super_admin? || current_user.company_admin?
      redirect_to authenticated_root_path, alert: t("flash_messages.not_authorized")
    end
  end
end
