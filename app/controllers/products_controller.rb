class ProductsController < AuthenticatedController

  def index
    @products = current_user.products.all
  end

  def new
    # ユーザーに紐づいた新しいProductインスタンスを準備
    @product = current_user.products.build
  end

  def create
    # ストロングパラメータのデータを使い作成
    @product = current_user.products.build(product_params)
    # 詳細画面に遷移（レシピ登録へ）
    if @product.save
      redirect_to @product
    else
      render :new
    end
  end

  def show
  end

  def edit
  end

  private

  def product_params
    params.require(:product).permit(
      :name,
      :item_number,
      :price,
      :category_id,
  )
  end

end
