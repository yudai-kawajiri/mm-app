class Api::V1::MaterialsController < AuthenticatedController
  # GET /api/v1/materials/:id/product_unit_data
  def product_unit_data
    # current_user にスコープして検索 (セキュリティとデータ分離を確保)
    begin
      @material = current_user.materials.find(params[:id])

      # 1. 単位名を取得
      unit_name = @material.unit_for_product&.name
      unit_id = @material.unit_for_product_id

      # 2. 数量/重量を取得（unit_weight_for_product）
      quantity_value = @material.unit_weight_for_product || 0

      # JSON 形式で単位名と数量の両方を返す
      render json: {
        unit_id: unit_id,
        unit_name: unit_name,
        quantity: quantity_value,
        unit_weight: quantity_value
      }
    rescue ActiveRecord::RecordNotFound
      # 検索失敗時
      render json: { error: "Material not found or access denied" }, status: :not_found
    end
  end
end
