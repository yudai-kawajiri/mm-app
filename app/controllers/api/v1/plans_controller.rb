# frozen_string_literal: true

# API V1 Plans Controller
#
# 製造計画情報取得API
#
# 機能:
# - 製造計画の予想売上取得
# - 全ユーザーの計画にアクセス可能（共有データ）
#
# エンドポイント:
# - GET /api/v1/plans/:id/revenue
#
# 認証: AuthenticatedController を継承（ログイン必須）
module Api
  module V1
    class PlansController < AuthenticatedController
      skip_before_action :verify_authenticity_token

      # 製造計画の予想売上取得
      #
      # 製造計画画面で商品数量を変更した際に、予想売上を動的に計算する。
      # フロントエンドの JavaScript から呼ばれる。
      #
      # @return [JSON] 売上情報
      #   - revenue: 予想売上（円）
      #   - formatted_revenue: フォーマット済み売上（例: "¥10,000"）
      #
      # @raise [ActiveRecord::RecordNotFound] 計画が見つからない
      # @raise [StandardError] 予期しないエラー
      #
      # @example レスポンス例
      #   {
      #     "revenue": 14000,
      #     "formatted_revenue": "¥14,000"
      #   }
      def revenue
        Rails.logger.info "=== API Debug: Plan ID #{params[:id]} ==="

        # Plan を検索（全ユーザー共有）
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
        render json: { error: t("api.errors.plan_not_found") }, status: :not_found

      rescue StandardError => e
        Rails.logger.error "=== API Error: #{e.class} - #{e.message} ==="
        Rails.logger.error "Backtrace:\n#{e.backtrace.join("\n")}"
        render json: { error: t("api.errors.server_error") }, status: :internal_server_error
      end
    end
  end
end
