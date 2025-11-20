# frozen_string_literal: true

# API V1 Materials Controller
#
# 原材料情報取得API
#
# 機能:
# - 商品作成時の原材料選択で使用する単位情報取得
# - ユーザーが所有する原材料のみアクセス可能
#
# エンドポイント:
# - GET /api/v1/materials/:id/fetch_product_unit_data
#
# 認証: AuthenticatedController を継承（ログイン必須）
class Api::V1::MaterialsController < AuthenticatedController
  # 原材料の単位情報取得
  #
  # 商品作成フォームで原材料選択時に、単位情報を動的に取得する。
  # フロントエンドの material_controller.js から呼ばれる。
  #
  # @return [JSON] 単位情報
  #   - unit_id: 単位ID
  #   - unit_name: 単位名（例: "kg", "個"）
  #   - default_unit_weight: デフォルト単位重量
  #
  # @raise [ActiveRecord::RecordNotFound] 原材料が見つからない、または権限がない
  # @raise [StandardError] 予期しないエラー
  #
  # @example レスポンス例
  #   {
  #     "unit_id": 1,
  #     "unit_name": "kg",
  #     "default_unit_weight": 100
  #   }
  def fetch_product_unit_data
    Rails.logger.info "=== fetch_product_unit_data API called ==="
    Rails.logger.info "Material ID: #{params[:id]}"
    Rails.logger.info "Current User: #{current_user&.id}"

    # 認証チェック
    unless current_user
      Rails.logger.error "ERROR: current_user is nil"
      render json: { error: "Unauthorized" }, status: :unauthorized
      return
    end

    # Material を検索（権限チェック含む）
    @material = current_user.materials.find(params[:id])
    Rails.logger.info "SUCCESS: Material found: #{@material.name}"

    # 単位情報を取得
    unit_name = @material.production_unit&.name
    unit_id = @material.production_unit_id

    Rails.logger.info "  unit_for_product: #{@material.unit_for_product.inspect}"
    Rails.logger.info "  unit_for_product_id: #{unit_id}"

    # デフォルト重量を取得
    default_unit_weight = @material.default_unit_weight || 0

    Rails.logger.info "Returning: unit_id=#{unit_id}, unit_name=#{unit_name}, default_unit_weight=#{default_unit_weight}"

    # JSON レスポンス
    render json: {
      unit_id: unit_id,
      unit_name: unit_name,
      default_unit_weight: default_unit_weight
    }
  rescue ActiveRecord::RecordNotFound => e
    # 原材料が見つからない、または権限がない
    Rails.logger.error "ERROR: Material not found: #{params[:id]}"
    Rails.logger.error e.message
    render json: { error: "Material not found or access denied" }, status: :not_found
  rescue StandardError => e
    # 予期しないエラー
    Rails.logger.error "ERROR: Unexpected error in fetch_product_unit_data:"
    Rails.logger.error "  Error class: #{e.class}"
    Rails.logger.error "  Error message: #{e.message}"
    Rails.logger.error "  Backtrace:"
    Rails.logger.error e.backtrace.first(10).join("\n")
    render json: { error: "Internal server error: #{e.message}" }, status: :internal_server_error
  end
end
