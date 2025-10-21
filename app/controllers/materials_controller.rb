class MaterialsController <  AuthenticatedController

  # define_search_params を使って許可するキーを定義
  define_search_params :q, :category_id
  before_action :set_material_categories, only: [:index, :new, :edit, :create, :update]
  find_resource :material, only: [:show, :edit, :update, :destroy]

  def index
    @search_categories = Category.where(category_type: 'material').order(:name)
    @materials = apply_pagination(
      Material.all
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

  # カテゴリリストを準備
  def set_material_categories
    @search_categories = current_user.categories.where(category_type: 'material').order(:name)
  end
end
