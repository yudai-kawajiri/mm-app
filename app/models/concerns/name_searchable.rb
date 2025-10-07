module NameSearchable
  extend ActiveSupport::Concern

  included do
    # デフォルトで名前の昇順に並べる
    default_scope { order(name: :asc) }

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

    # カテゴリー種別による絞り込みのスコープ
    scope :filter_by_category_type, ->(category_type) do
      # category_type が存在する場合のみ絞り込み適用
      # タイポ修正
      where(category_type: category_type) if category_type.present?
    end
  end
end