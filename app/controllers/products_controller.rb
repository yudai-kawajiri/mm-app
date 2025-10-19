class ProductsController < AuthenticatedController
  include PaginationConcern
  before_action :set_product, only: [:show, :edit, :update, :destroy, :purge_image]
  # フォーム用の商品カテゴリーを設定
  before_action :set_form_categories, only: [:new, :edit, :update]
  # 一覧画面の検索カテゴリーを設定
  before_action :set_search_categories, only: [:index]

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
      redirect_to edit_product_product_materials_path(@product)
    else
      flash.now[:alert] = t('flash_messages.create.failure', resource: Product.model_name.human)
      render :new, status: :unprocessable_entity
    end
  end

  def show
    # N+1対策: material と unit の情報を事前に includes で取得
    @product_materials = @product.product_materials.includes(:material, :unit).order(:id)
    # 原材料カテゴリのタブ表示に必要なデータを取得
    @material_categories = Category.where(category_type: :material)
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

  def destroy
    # flash_messagesの書き方変更(後で共通化するか選択)
    # 削除前に名前を保持
    product_name = @product.name
    # リソース名（"商品"）を取得
    resource_name = Product.model_name.human

  if @product.destroy
    flash[:notice] = t('flash_messages.destroy.success', resource: resource_name, name: product_name)
    redirect_to products_url, status: :see_other
  else
    flash[:alert] = t('flash_messages.destroy.failure', resource: resource_name, name: product_name)
    redirect_to products_url, status: :unprocessable_entity
  end
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

  # 製造計画に必要な商品詳細（価格とカテゴリID）を返すAPIアクション
  def details_for_plan
    # set_product はこのアクションでは使用できないため、params[:id]で直接検索します
    # 未 ActiveRecord::RecordNotFound が発生する可能性があるため、例外処理を追加

    begin
      product = Product.find(params[:id])

      # 価格とカテゴリIDをJSONで返す
      render json: {
        price: product.price,
        category_id: product.category_id
      }
    rescue ActiveRecord::RecordNotFound
      # 商品IDが見つからない場合は 404 ステータスを返す
      render json: { error: "Product not found" }, status: :not_found
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

  # フォーム用のカテゴリーを設定
  def set_form_categories
    @product_categories = fetch_categories_by_type(:product)
  end

  def set_product
    @product = current_user.products.find(params[:id])
  end

  def search_params
    get_and_normalize_search_params(:q, :category_id)
  end

  # 検索フォーム用のカテゴリーを設定
  def set_search_categories
    @search_categories = fetch_categories_by_type(:product)
  end

end