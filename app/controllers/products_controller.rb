class ProductsController < AuthenticatedController
  include PaginationConcern

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
    # 詳細画面に遷移（レシピ登録へ）
    if @product.save
      flash[:notice] = t('flash_messages.create.success', resource: Product.model_name.human, name: @product.name)
      redirect_to @product
    else
      flash.now[:alert] = t('flash_messages.create.failure', resource: Product.model_name.human)
      render :new, status: :unprocessable_entity
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
      :status,       #  追加
      :description,  #  追加
      :category_id,
      :image
  )
  end

  def search_params
    params.permit(:q, :category_id)
  end

end
