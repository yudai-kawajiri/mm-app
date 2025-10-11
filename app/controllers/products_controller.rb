class ProductsController < AuthenticatedController
  include PaginationConcern
  before_action :set_product, only: [:show, :edit, :update]

  def index
    @products =  apply_pagination(current_user.products
                              .search_by_name(search_params[:q])
                              .filter_by_category_id(search_params[:category_id])
    )
  end

  def new
    # ユーザーに紐づいた新しいProductインスタンスを準備
    @product = current_user.products.build
  end

  def create
    # ストロングパラメータのデータを使い作成
    @product = current_user.products.build(product_params)
    # 編集画面に遷移（商品原材料登録へ）
    if @product.save
      flash[:notice] = t('flash_messages.create.success', resource: Product.model_name.human, name: @product.name)
      redirect_to edit_product_product_material_path(@product)
    else
      flash.now[:alert] = t('flash_messages.create.failure', resource: Product.model_name.human)
      render :new, status: :unprocessable_entity
    end
  end

  def show
    # N+1対策: material と unit の情報を事前に includes で取得
    @product_materials = @product.product_materials.includes(:material, :unit).order(:id)
  end

  def edit
  end

  def update
    if @product.update(product_params)
      flash[:notice] = t('flash_messages.update.success', resource: Product.model_name.human, name: @product.name)
      redirect_to @product
    else
      flash.now[:alert] = t('flash_messages.update.failure', resource: Product.model_name.human)
      render :edit, status: :unprocessable_entity
    end
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

      # ネストフォームの属性を許可する
      product_materials_attributes: [
        :id,            # 既存レコードを特定し更新するため
        :material_id,   # 原材料ID
        :unit_id,       # 単位ID
        :quantity,      # 数量
        :_destroy       # 削除チェックボックス（allow_destroy: trueと連携）
    ]
  )
  end

  def set_product
    @product = current_user.products.find(params[:id])
  end

  def search_params
    params.permit(:q, :category_id)
  end

end
