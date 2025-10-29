module Api
  module V1
    class PlansController < ApplicationController
      # CSRF保護を無効化（API用）
      skip_before_action :verify_authenticity_token

      # GET /api/v1/plans/:id/revenue
      # 計画IDから期待売上を取得
      def revenue
        plan = Plan.find_by(id: params[:id])

        if plan
          render json: {
            revenue: plan.expected_revenue,
            formatted_revenue: "¥#{plan.expected_revenue.to_s(:delimited)}"
          }
        else
          render json: { error: '計画が見つかりません' }, status: :not_found
        end
      rescue StandardError => e
        render json: { error: e.message }, status: :internal_server_error
      end
    end
  end
end
