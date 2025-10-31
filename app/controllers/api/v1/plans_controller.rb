module Api
  module V1
    class PlansController < ApplicationController
      # CSRF保護を無効化（API用）
      skip_before_action :verify_authenticity_token

      # GET /api/v1/plans/:id/revenue
      # 計画IDから期待売上を取得
      def revenue
        Rails.logger.info "=== API Debug: Plan ID #{params[:id]} ==="

        plan = Plan.find(params[:id])

        Rails.logger.info "=== Plan found: #{plan.name} ==="
        revenue = plan.expected_revenue
        Rails.logger.info "=== Revenue calculated: #{revenue} ==="

        render json: {
          revenue: revenue,
          formatted_revenue: "¥#{ActionController::Base.helpers.number_with_delimiter(revenue)}"
        }

      rescue ActiveRecord::RecordNotFound
        Rails.logger.error "=== Plan not found: ID #{params[:id]} ==="
        render json: { error: "計画が見つかりません" }, status: :not_found
      rescue StandardError => e
        Rails.logger.error "=== API Error: #{e.class} - #{e.message} ==="
        Rails.logger.error "Backtrace:\n#{e.backtrace.join("\n")}"
        render json: { error: "サーバーエラーが発生しました" }, status: :internal_server_error
      end
    end
  end
end
