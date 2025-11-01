class Api::V1::MaterialsController < AuthenticatedController
  # GET /api/v1/materials/:id/product_unit_data
  def product_unit_data
    Rails.logger.info "=== product_unit_data API called ==="
    Rails.logger.info "Material ID: #{params[:id]}"
    Rails.logger.info "Current User: #{current_user&.id}"

    begin
      # current_user が存在するか確認
      unless current_user
        Rails.logger.error "❌ current_user is nil"
        render json: { error: "Unauthorized" }, status: :unauthorized
        return
      end

      # Material を検索
      @material = current_user.materials.find(params[:id])
      Rails.logger.info "✅ Material found: #{@material.name}"

      # 単位名を取得
      unit_name = @material.unit_for_product&.name
      unit_id = @material.unit_for_product_id

      Rails.logger.info "  unit_for_product: #{@material.unit_for_product.inspect}"
      Rails.logger.info "  unit_for_product_id: #{unit_id}"

      # 数量/重量を取得
      quantity_value = @material.unit_weight_for_product || 0

      # 小数点を整数化（12.0 → 12）
      quantity_value = quantity_value.to_i if quantity_value == quantity_value.to_i

      Rails.logger.info "✅ Returning: unit_id=#{unit_id}, unit_name=#{unit_name}, unit_weight=#{quantity_value}"

      # JSON 形式で返す
      render json: {
        unit_id: unit_id,
        unit_name: unit_name,
        quantity: quantity_value,
        unit_weight: quantity_value
      }
    rescue ActiveRecord::RecordNotFound => e
      Rails.logger.error "❌ Material not found: #{params[:id]}"
      Rails.logger.error e.message
      render json: { error: "Material not found or access denied" }, status: :not_found
    rescue StandardError => e
      Rails.logger.error "❌ Unexpected error in product_unit_data:"
      Rails.logger.error "  Error class: #{e.class}"
      Rails.logger.error "  Error message: #{e.message}"
      Rails.logger.error "  Backtrace:"
      Rails.logger.error e.backtrace.first(10).join("\n")
      render json: { error: "Internal server error: #{e.message}" }, status: :internal_server_error
    end
  end
end
