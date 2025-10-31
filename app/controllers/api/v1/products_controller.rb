class Api::V1::ProductsController < AuthenticatedController
  # GET /api/v1/products/:id/details_for_plan
  # 製造計画に必要な商品詳細（価格とカテゴリID）を返すAPIアクション
  def details_for_plan
    begin
      # current_user にスコープして検索（セキュリティ確保）
      product = current_user.products.find(params[:id])

      # 価格とカテゴリIDをJSONで返す
      render json: {
        price: product.price,
        category_id: product.category_id
      }
    rescue ActiveRecord::RecordNotFound
      # 検索失敗時
      render json: { error: "Product not found or access denied" }, status: :not_found
    end
  end
end
