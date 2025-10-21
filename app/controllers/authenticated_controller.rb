class AuthenticatedController < ApplicationController
  # 認証必須のチェックを移植して
  before_action :authenticate_user!

  # カテゴリー取得共通ロジックを組み込む
  include CategoryFetchable

  # 検索フィルタリングロジックを組み込む
  include SearchAndFilterConcern

  # ページネーションを使用
  include PaginationConcern

  # リソースの取得
  include ResourceFinderConcern

  # CRUDアクションの共通化
  include CrudResponderConcern

  # 検索パラメータの共通化
  include SearchableController

  # 検索クエリをビューに渡すための共通処理
  def set_search_term_for_view
    # search_params メソッドが定義されているか、かつ :q パラメータが存在するか確認
    if defined?(search_params) && search_params[:q].present?
      @search_term = search_params[:q]
    end
  end
end
