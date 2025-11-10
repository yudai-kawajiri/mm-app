# frozen_string_literal: true

# CategoriesController
#
# カテゴリーのCRUD操作を管理
#
# 機能:
#   - カテゴリーの一覧表示（検索・種別フィルタ・ページネーション）
#   - カテゴリーの作成・編集・削除
#   - 種別による分類（material, product, plan）
class Resources::CategoriesController < AuthenticatedController
  # 検索パラメータの定義
  define_search_params :q, :category_type

  # リソース検索
  find_resource :category, only: [:show, :edit, :update, :destroy]

  # カテゴリー一覧
  #
  # @return [void]
  def index
    @categories = apply_pagination(
      Resources::Category.for_index.search_and_filter(search_params)
    )
    set_search_term_for_view
  end

  # 新規カテゴリー作成フォーム
  #
  # @return [void]
  def new
    @category = current_user.categories.build
  end

  # カテゴリーを作成
  #
  # @return [void]
  def create
    @category = current_user.categories.build(category_params)

    if @category.save
      redirect_to resources_category_path(@category),
                  notice: t('flash_messages.create.success',
                           resource: Resources::Category.model_name.human,
                           name: @category.name)
    else
      render :new, status: :unprocessable_entity
    end
  end

  # カテゴリー詳細
  #
  # @return [void]
  def show; end

  # カテゴリー編集フォーム
  #
  # @return [void]
  def edit; end

  # カテゴリーを更新
  #
  # @return [void]
  def update
    if @category.update(category_params)
      redirect_to resources_category_path(@category),
                  notice: t('flash_messages.update.success',
                           resource: Resources::Category.model_name.human,
                           name: @category.name)
    else
      render :edit, status: :unprocessable_entity
    end
  end

  # カテゴリーを削除
  #
  # @return [void]
  def destroy
    name = @category.name
    @category.destroy!
    redirect_to resources_categories_path,
                notice: t('flash_messages.destroy.success',
                         resource: Resources::Category.model_name.human,
                         name: name)
  end

  private

  # Strong Parameters
  #
  # @return [ActionController::Parameters]
  def category_params
    params.require(:resources_category).permit(:name, :category_type, :description)
  end
end
