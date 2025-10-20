class CategoriesController < AuthenticatedController

  find_resource :category, only: [:edit, :update, :destroy]

  def index
    # モジュールにソート責任を移譲
    @categories = apply_pagination(
      current_user.categories
                              .search_and_filter(search_params)
    )

    # 検索結果のフィードバック表示のため、検索結果をビューに渡す
    @search_term = search_params[:q]
  end

  def new
    @category = current_user.categories.build
  end

  def create
    @category = current_user.categories.build(category_params)

    if @category.save
      # I18nキーは 'flash_messages' で統一されており、nameも正しく渡されています
      redirect_to categories_path, notice: t('flash_messages.create.success',
                                              resource: Category.model_name.human,
                                              name: @category.name)
    else
      flash.now[:alert] = t('flash_messages.create.failure',
                            resource: Category.model_name.human)
      # ステータスコード 422 を明示的に指定
    render :new, status: :unprocessable_entity
    end
  end

  def edit
    # @category の取得は before_action :set_category に移動
  end

  def update
    if @category.update(category_params)
      redirect_to categories_path, notice: t('flash_messages.update.success',
                                              resource: Category.model_name.human,
                                              name: @category.name)
    else
      flash.now[:alert] = t('flash_messages.update.failure',
                            resource: Category.model_name.human)
      # 失敗時: ステータスコード 422 を明示的に指定
      render :edit, status: :unprocessable_entity
    end
  end

  def destroy
    if @category.destroy
      redirect_to categories_url, notice: t('flash_messages.destroy.success',
                                          resource: Category.model_name.human,
                                          name: @category.name)
    else
      flash[:alert] = @category.errors.full_messages.to_sentence
      redirect_to categories_url
    end
  end


  private

  def category_params
    # name と category_type を受付
    params.require(:category).permit(:name, :category_type)
  end

  # 検索パラメーター専用のストロングパラメーターを定義し、セキュリティを確保
  def search_params
    get_and_normalize_search_params(:q, :category_type)
  end
end
