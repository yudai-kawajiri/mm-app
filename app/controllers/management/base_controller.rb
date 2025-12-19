# frozen_string_literal: true

class Management::BaseController < ApplicationController
  before_action :authenticate_user!
  before_action :require_store_or_company_admin

  private

  def require_store_or_company_admin
    unless current_user&.store_admin? || current_user&.general? || current_user&.can_manage_company?
      redirect_to authenticated_root_path, alert: t("errors.messages.unauthorized")
    end
  end
end
