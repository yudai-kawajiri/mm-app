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

  # モデルクラスメソッドとして定義
  module ClassMethods
    def search_and_filter(params)
      # 全てのレコードを取得
      results = all

      # 検索キーワードがある場合のみ適用
      results = results.search_by_name(params[:q]) if params[:q].present?

      # category_id フィルタを適用
      results = results.filter_by_category_id(params[:category_id]) if params[:category_id].present?

      # 共通の category_type フィルタを適用
      results = results.filter_by_category_type(params[:category_type]) if params[:category_type].present?

      results
    end
  end
end