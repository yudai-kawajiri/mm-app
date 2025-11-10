module Api
  module V1
    class PlansController < ApplicationController
      skip_before_action :verify_authenticity_token

      def revenue
        Rails.logger.info "=== API Debug: Plan ID #{params[:id]} ==="

        plan = Resources::Plan.find(params[:id])
        Rails.logger.info "=== Plan found: #{plan.name} ==="

        revenue = plan.expected_revenue
        Rails.logger.info "=== Revenue calculated: #{revenue} ==="

        render json: {
          revenue: revenue,
          formatted_revenue: "¥#{ActionController::Base.helpers.number_with_delimiter(revenue)}"
        }

      rescue ActiveRecord::RecordNotFound
        Rails.logger.error "=== Plan not found: ID #{params[:id]} ==="
        render json: { error: t('api.errors.plan_not_found') }, status: :not_found

      rescue StandardError => e
        Rails.logger.error "=== API Error: #{e.class} - #{e.message} ==="
        Rails.logger.error "Backtrace:\n#{e.backtrace.join("\n")}"
        render json: { error: t('api.errors.server_error') }, status: :internal_server_error
      end
    end
  end
end
