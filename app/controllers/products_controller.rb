class ProductsController < AuthenticatedController
  define_search_params :q, :category_id
  find_resource :product, only: [ :show, :edit, :update, :destroy, :purge_image, :copy ]

  before_action -> { load_categories_for("product", as: :product) }, only: [ :index, :new, :create, :edit, :update ]
  before_action -> { load_categories_for("material", as: :material) }, only: [ :new, :create, :show, :edit, :update ]

  def index
    @products = apply_pagination(
      Product.includes(:category).search_and_filter(search_params).ordered
    )
    @search_categories = @product_categories  # ← 追加
    set_search_term_for_view
  end

  def new
    @product = current_user.products.build
  end

  def create
    @product = current_user.products.build(product_params)
    respond_to_save(@product, success_path: @product)
  end

  def show
    @product_materials = @product.product_materials.includes(:material, :unit).order(:id)
  end

  def edit; end

  def update
    @product.assign_attributes(product_params)
    respond_to_save(@product, success_path: @product)
  end

  def destroy
    respond_to_destroy(@product, success_path: products_url)
  end

  def purge_image
    if @product.image.attached?
      @product.image.purge
      head :no_content
    else
      head :not_found
    end
  end

  def copy
    original_product = @product
    base_name = original_product.name
    copy_count = 1
    new_name = "#{base_name} (#{I18n.t('common.copy')}#{copy_count})"

    while Product.exists?(name: new_name, category_id: original_product.category_id)
      copy_count += 1
      new_name = "#{base_name} (#{I18n.t('common.copy')}#{copy_count})"
    end

    new_product = original_product.dup
    new_product.name = new_name
    new_product.user_id = current_user.id

    temp_item_number = "C#{copy_count}"[0..3]

    while Product.exists?(item_number: temp_item_number, category_id: original_product.category_id)
      copy_count += 1
      temp_item_number = "C#{copy_count}"[0..3]
    end

    new_product.item_number = temp_item_number

    ActiveRecord::Base.transaction do
      new_product.save!

      original_product.product_materials.each do |product_material|
        new_product.product_materials.create!(
          material_id: product_material.material_id,
          unit_id: product_material.unit_id,
          quantity: product_material.quantity,
          unit_weight: product_material.unit_weight
        )
      end
    end

    redirect_to products_path, notice: I18n.t('products.messages.copy_success', original_name: original_product.name, new_name: new_product.name, item_number: temp_item_number)
  rescue ActiveRecord::RecordInvalid => e
    redirect_to products_path, alert: I18n.t('products.messages.copy_failed', errors: e.record.errors.full_messages.join(', '))
  end

  def reorder
    product_ids = reorder_params[:product_ids]

    Rails.logger.debug "=== Received product_ids: #{product_ids.inspect}"

    Product.update_display_orders(product_ids)
    head :ok
  end

  private

  def product_params
    params.require(:product).permit(
      :name,
      :item_number,
      :price,
      :status,
      :description,
      :category_id,
      :image,
      product_materials_attributes: [
        :id,
        :material_id,
        :unit_id,
        :quantity,
        :unit_weight,
        :_destroy
      ]
    )
  end

  def reorder_params
    params.permit(product_ids: [])
  end
end