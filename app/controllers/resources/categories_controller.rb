# frozen_string_literal: true

# CategoriesController
#
# カテゴリー（Category）のCRUD操作を管理
#
# 機能:
#   - カテゴリーの一覧表示（検索・タイプフィルタ・ページネーション・ソート機能）
#   - カテゴリーの作成・編集・削除
#   - カテゴリーのコピー
class Resources::CategoriesController < AuthenticatedController
  include SortableController

  # 検索パラメータの定義
  define_search_params :q, :category_type, :sort_by

  # ソートオプションの定義
  define_sort_options(
    name: -> { order(:name) },
    category_type: -> { order(:category_type, :name) },
    created_at: -> { order(created_at: :desc) }
  )

  # リソース検索（show, edit, update, destroy, copy）
  find_resource :category, only: [:show, :edit, :update, :destroy, :copy]

  # カテゴリー一覧
  #
  # @return [void]
  def index
    # 基本クエリ
    @categories = Resources::Category.all

    # ソート適用
    @categories = apply_sort(@categories, default: 'name')

    # カテゴリー種別フィルタリング
    if params[:category_type].present?
      @categories = @categories.where(category_type: params[:category_type])
    end

    # 名前検索
    if params[:q].present?
      @categories = @categories.where("name LIKE ?", "%#{params[:q]}%")
    end

    # ページネーション
    @categories = @categories.page(params[:page])
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
    respond_to_save(@category, success_path: resources_categories_path)
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
    @category.assign_attributes(category_params)
    respond_to_save(@category, success_path: resources_categories_path)
  end

  # カテゴリーを削除
  #
  # @return [void]
  def destroy
    respond_to_destroy(@category, success_path: resources_categories_url)
  end

  # カテゴリーをコピー
  #
  # @return [void]
  def copy
    copied = @category.create_copy(user: current_user)
    redirect_to resources_categories_path, notice: t('flash_messages.copy.success',
                                                      resource: @category.class.model_name.human)
  rescue ActiveRecord::RecordInvalid => e
    Rails.logger.error "Category copy failed: #{e.record.errors.full_messages.join(', ')}"
    redirect_to resources_categories_path, alert: t('flash_messages.copy.failure',
                                                    resource: @category.class.model_name.human)
  end


  private

  # Strong Parameters
  #
  # @return [ActionController::Parameters]
  def category_params
    params.require(:resources_category).permit(:name, :category_type, :description)
  end
end
