# frozen_string_literal: true

# AuthenticatedController
#
# 認証が必要なコントローラーの基底クラス
#
# 使用例:
#   class ProductsController < AuthenticatedController
#     def index
#       @products = current_user.products
#     end
#   end
#
# 機能:
#   - 認証必須（before_action :authenticate_user!）
#   - 共通Concernsの一括include
#   - カテゴリー読み込みヘルパー
#   - 管理者権限チェック
#
# 使用Concerns:
#   - CategoryFetchable: カテゴリー取得
#   - SearchAndFilterConcern: 検索パラメータ正規化
#   - PaginationConcern: ページネーション
#   - ResourceFinderConcern: リソース検索
#   - CrudResponderConcern: CRUD共通レスポンス
#   - SearchableController: 検索パラメータ定義
class AuthenticatedController < ApplicationController
  # 認証必須
  before_action :authenticate_user!

  # 共通Concernsをinclude
  include CategoryFetchable
  include SearchAndFilterConcern
  include PaginationConcern
  include ResourceFinderConcern
  include CrudResponderConcern
  include SearchableController

  # 検索キーワードをビュー用にセット
  #
  # search_params[:q] が存在する場合、@search_term に設定
  #
  # @return [void]
  def set_search_term_for_view
    if defined?(search_params) && search_params[:q].present?
      @search_term = search_params[:q]
    end
  end

  # カテゴリーを読み込んでインスタンス変数に設定
  #
  # @param category_type [String, Symbol] カテゴリー種別（:product, :material, :plan）
  # @param as [Symbol, nil] インスタンス変数名のプレフィックス
  # @param scope [Symbol] スコープ（:current_user または :all）
  # @return [ActiveRecord::Relation] カテゴリーのコレクション
  #
  # @example
  #   load_categories_for(:product)
  #   # => @product_categories に設定
  #
  # @example
  #   load_categories_for(:product, as: :search)
  #   # => @search_categories に設定
  #
  # @example
  #   load_categories_for(:product, scope: :all)
  #   # => 全ユーザーのカテゴリーを取得
  def load_categories_for(category_type, as: nil, scope: :current_user)
    categories = if scope == :current_user
                    current_user.categories.where(category_type: category_type)
                  else
                    Resources::Category.where(category_type: category_type)
                  end
    categories = categories.order(:name)

    # インスタンス変数名を決定
    prefix = as || category_type
    variable_name = "@#{prefix}_categories"

    # インスタンス変数に設定
    instance_variable_set(variable_name, categories)

    # 検索用の場合は @search_categories にも設定
    @search_categories = categories if as == :search || as.nil?

    categories
  end

  private

  # 管理者権限チェック
  #
  # 管理者でない場合、ルートパスにリダイレクト
  #
  # @return [void]
  def require_admin
    unless current_user&.admin?
      redirect_to root_path, alert: t('flash_messages.not_authorized')
    end
  end
end
