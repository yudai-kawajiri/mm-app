module PaginationConcern
  extend ActiveSupport::Concern
  # フィルタリング後のデータをURLと設定に基づいてページネーションを適用
  def apply_pagination(collection, max_per_page: 20)
    collection.page(params[:page]).per(max_per_page)
  end
end
