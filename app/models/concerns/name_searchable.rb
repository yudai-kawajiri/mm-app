module NameSearchable
  extend ActiveSupport::Concern

  included do
    scope :search_by_name, ->(query) do
      if query.present?
        # SQL組込前にインジェクション対策した値を部分一致検索
        sanitized_query = sanitize_sql_like(query)
        # 開発者が意図するワイルドカード%を明示的に結合
        term = "%#{sanitized_query}%"
        where("name ILIKE ?", term)
      end
    end

    # 共通のカテゴリーIDによる絞り込みスコープを追加
    scope :filter_by_category_id, ->(category_id) do
      if category_id.present?
        where(category_id: category_id)
      end
    end
  end
end