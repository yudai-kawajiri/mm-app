class CategoriesController < AuthenticatedController
  # privateメソッドの set_category を、edit, update, destroy アクションの前に実行する
  before_action :set_category, only: [:edit, :update, :destroy]

  def index
    # モジュールにソート責任を移譲
    @categories = current_user.categories
                              # モデル層に検索を指示し、結果をフィルタリング
                              .search_by_name(search_params[:q])
                              # カテゴリ種別による絞り込みをモジュールから
                              .filter_by_category_type(search_params[:category_type])
    end
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
      redirect_to categories_path, notice: t('flash_messages.create.success', resource: Category.model_name.human, name: @category.name)
    else
      flash.now[:alert] = t('flash_messages.create.failure', resource: Category.model_name.human)
      # ステータスコード 422 を明示的に指定
    render :new, status: :unprocessable_entity
    end
  end

  def edit
    # @category の取得は before_action :set_category に移動
  end

  def update
    if @category.update(category_params)
      redirect_to categories_path, notice: t('flash_messages.update.success', resource: Category.model_name.human, name: @category.name)
    else
      flash.now[:alert] = t('flash_messages.update.failure', resource: Category.model_name.human)
      # ステータスコード 422 を明示的に指定
      render :edit, status: :unprocessable_entity
    end
  end

  def destroy
    @category.destroy
    redirect_to categories_url, notice: t('flash_messages.destroy.success', resource: Category.model_name.human, name: @category.name)
  end


  private

  # 重複していた @category の取得処理をまとめる
  def set_category
    # 編集・更新・削除対象のレコードを、current_userのカテゴリーの中から探す
    @category = current_user.categories.find(params[:id])
  end

  def category_params
    # name と category_type を受付
    params.require(:category).permit(:name, :category_type)
  end

  # 検索パラメーター専用のストロングパラメーターを定義し、セキュリティを確保
  def search_params
    params.permit(:q, :category_type)
  end
end
