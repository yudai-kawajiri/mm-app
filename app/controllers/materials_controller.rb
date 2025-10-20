class MaterialsController <  AuthenticatedController

  find_resource :material, only: [:show, :edit, :update, :destroy]

  def index
    @materials = apply_pagination(current_user.materials
                              .search_and_filter(search_params)
    )
  end

  def show
    # before_actionで完結
  end

  def new
    # フォームに渡すための、新しい空の Material インスタンスを準備
    @material = Material.new
  end

  def create
    # 'build'でインスタンスにデータを属性として割り当ててから安全に保存
    @material = current_user.materials.build(material_params)
    respond_to_save(@material, success_path: @material)
  end

  def edit
    # before_actionで完結
  end

  def update
    @material.assign_attributes(material_params)
    respond_to_save(@material, success_path: @material)
  end

  def destroy
    respond_to_destroy(@material, success_path: materials_url)
  end

  private
  # ストロングパラメータ設定
  def material_params
    params.require(:material).permit(
    :name, :unit_for_product_id,
    :unit_weight_for_product,
    :unit_for_order_id,
    :unit_weight_for_order,
    :category_id,
    :description
  )
  end

  def search_params
    get_and_normalize_search_params(:q,:category_id)
  end

end
