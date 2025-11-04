class Api::V1::ProductsController < AuthenticatedController
  def details_for_plan
    begin
      product = current_user.products.find(params[:id])

      render json: {
        price: product.price,
        category_id: product.category_id
      }
    rescue ActiveRecord::RecordNotFound
      render json: { error: I18n.t('api.errors.product_not_found') }, status: :not_found
    end
  end
end