# frozen_string_literal: true

# API V1 Products Controller
#
# 商品情報取得API
#
# 機能:
# - 製造計画作成時の商品選択で使用する価格・カテゴリ―情報取得
# - 全ユーザーの商品にアクセス可能（共有データ）
#
# エンドポイント:
# - GET /api/v1/products/:id/fetch_plan_details
#
# 認証: AuthenticatedController を継承（ログイン必須）
class Api::V1::ProductsController < AuthenticatedController
  # 商品の価格・カテゴリ―情報取得
  #
  # 製造計画フォームで商品選択時に、価格とカテゴリ―情報を動的に取得する。
  # フロントエンドの row_controller.js から呼ばれる。
  #
  # @return [JSON] 商品情報
  #   - price: 商品価格（円）
  #   - category_id: カテゴリ―ID
  #
  # @raise [ActiveRecord::RecordNotFound] 商品が見つからない
  # @raise [StandardError] 予期しないエラー
  #
  # @example レスポンス例
  #   {
  #     "price": 1000,
  #     "category_id": 2
  #   }
  def fetch_plan_details
    Rails.logger.info "=== fetch_plan_details API called ==="
    Rails.logger.info "Resources::Product ID: #{params[:id]}"

    # Resources::Product を検索（全ユーザー共有）
    product = Resources::Product.find(params[:id])
    Rails.logger.info "SUCCESS: Resources::Product found: #{product.name}"

    # JSON レスポンス
    render json: {
      price: product.price,
      category_id: product.category_id
    }
  rescue ActiveRecord::RecordNotFound => e
    # 商品が見つからない
    Rails.logger.error "ERROR: Resources::Product not found: #{params[:id]}"
    render json: { error: I18n.t("api.errors.product_not_found") }, status: :not_found
  rescue StandardError => e
    # 予期しないエラー
    Rails.logger.error "ERROR: Unexpected error in fetch_plan_details:"
    Rails.logger.error "  Error: #{e.message}"
    render json: { error: "Internal server error" }, status: :internal_server_error
  end
end
