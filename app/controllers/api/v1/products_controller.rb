# app/controllers/api/v1/products_controller.rb
class Api::V1::ProductsController < AuthenticatedController
  # GET /api/v1/products/:id/fetch_plan_details
  def fetch_plan_details
    begin
      product = current_user.products.find(params[:id])

      Rails.logger.info "=== fetch_plan_details API called ==="
      Rails.logger.info "Product ID: #{params[:id]}"
      Rails.logger.info "✅ Product found: #{product.name}"

      render json: {
        price: product.price,
        category_id: product.category_id
      }
    rescue ActiveRecord::RecordNotFound => e
      Rails.logger.error "❌ Product not found: #{params[:id]}"
      render json: { error: I18n.t('api.errors.product_not_found') }, status: :not_found
    rescue StandardError => e
      Rails.logger.error "❌ Unexpected error in fetch_plan_details:"
      Rails.logger.error "  Error: #{e.message}"
      render json: { error: "Internal server error" }, status: :internal_server_error
    end
  end
end
