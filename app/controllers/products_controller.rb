class ProductsController < AuthenticatedController
  # define_search_params を使って許可するキーを定義
  define_search_params :q, :category_id

  # ★修正: copyを追加
  find_resource :product, only: [ :show, :edit, :update, :destroy, :purge_image, :copy ]

  before_action -> { load_categories_for("product", as: :product) }, only: [ :index, :new, :create, :edit, :update ]
  before_action -> { load_categories_for("material", as: :material) }, only: [ :new, :create, :show, :edit, :update ]

  def index
    @products = apply_pagination(
      Product.for_index.search_and_filter(search_params)
    )
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

    # 商品名の連番生成
    base_name = original_product.name
    copy_count = 1
    new_name = "#{base_name} (コピー#{copy_count})"

    # 同じ名前が存在する限り連番を増やす
    while Product.exists?(name: new_name, category_id: original_product.category_id)
      copy_count += 1
      new_name = "#{base_name} (コピー#{copy_count})"
    end

    # 商品をコピー
    new_product = original_product.dup
    new_product.name = new_name
    new_product.user_id = current_user.id

    # 品番を一時的に仮の値にする（後でユーザーが編集）
    temp_item_number = "C#{copy_count}"[0..3]  # "C1", "C2", "C3"...

    # 仮の品番も重複チェック
    while Product.exists?(item_number: temp_item_number, category_id: original_product.category_id)
      copy_count += 1
      temp_item_number = "C#{copy_count}"[0..3]
    end

    new_product.item_number = temp_item_number

    ActiveRecord::Base.transaction do
      new_product.save!

      # 原材料構成もコピー
      original_product.product_materials.each do |product_material|
        new_product.product_materials.create!(
          material_id: product_material.material_id,
          unit_id: product_material.unit_id,
          quantity: product_material.quantity,
          unit_weight: product_material.unit_weight  # ← 追加
        )
      end
    end

    redirect_to products_path, notice: "商品「#{original_product.name}」をコピーしました（新規商品名: #{new_product.name}）。品番「#{temp_item_number}」は仮の値です。編集画面で変更してください。"
  rescue ActiveRecord::RecordInvalid => e
    redirect_to products_path, alert: "商品のコピーに失敗しました: #{e.record.errors.full_messages.join(', ')}"
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
end
