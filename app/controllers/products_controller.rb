class ProductsController < AuthenticatedController

  # define_search_params を使って許可するキーを定義
  define_search_params :q, :category_id

  find_resource :product, only: [:show, :edit, :update, :destroy, :purge_image]
  before_action :set_product_categories, only: [:index, :new, :create, :edit, :update]
  before_action :set_material_categories, only: [:new, :create, :show, :edit, :update]

  def index
    @products = apply_pagination(
      Product.includes(:category)
        .search_and_filter(search_params)
    )
    set_search_term_for_view
  end

  def new
    # ユーザーに紐づいた新しいProductインスタンスを準備
    @product = current_user.products.build
  end

  def create
    # ストロングパラメータのデータを使い作成
    @product = current_user.products.build(product_params)
    respond_to_save(@product, success_path: @product)
  end

  def show
    # N+1対策: material と unit の情報を事前に includes で取得
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

# ユーザーが編集画面を保存する前に、ブラウザ側からJavaScriptを使って画像を即座に削除する
  def purge_image
    # set_product (before_action) で @product は設定済み
    if @product.image.attached?
      @product.image.purge # Active Storageの添付ファイルを削除
      head :no_content # 成功（204 No Content）を返す
    else
      head :not_found # 画像がない場合は404
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

  # 検索フォームと商品カテゴリ用
  def set_product_categories
    @search_categories = current_user.categories.where(category_type: 'product').order(:name)
    @product_categories = @search_categories
  end

  # ネストフォーム用
  def set_material_categories
    @material_categories = current_user.categories.where(category_type: 'material').order(:name)
  end
end