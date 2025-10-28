class CategoriesController < AuthenticatedController

  # define_search_params を使って許可するキーを定義
  define_search_params :q, :category_type

  find_resource :category, only: [:show, :edit, :update, :destroy]

  def index
    # モジュールにソート責任を移譲
    @categories = apply_pagination(
      Category.for_index.search_and_filter(search_params)
    )

    # 検索結果のフィードバック表示のため、共通メソッドで @search_term を設定
    set_search_term_for_view
  end

  def new
    @category = current_user.categories.build
  end

  def create
    @category = current_user.categories.build(category_params)
    respond_to_save(@category, success_path: categories_url)
  end

  def show; end


  def edit
    # @category の取得は before_action :set_category に移動
  end

  def update
    @category.assign_attributes(category_params)
    respond_to_save(@category, success_path: categories_url)
  end

  def destroy
    respond_to_destroy(@category, success_path: categories_url)
  end


  private

  def category_params
    # name と category_type を受付
    params.require(:category).permit(:name, :category_type, :description)
  end
end
