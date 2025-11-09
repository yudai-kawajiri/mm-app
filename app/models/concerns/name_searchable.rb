# frozen_string_literal: true

# NameSearchable
#
# 名前検索とカテゴリーフィルタリングの共通機能を提供するConcern
#
# 使用例:
#   Product.search_by_name("マグロ")
#   Material.filter_by_category_id(1)
#   Plan.search_and_filter(name: "ランチ", category_id: 2)
#
# 使用モデル: Product, Material, Plan, Unit, Category など
module NameSearchable
  extend ActiveSupport::Concern

  included do
    # 名前による部分一致検索
    #
    # @param name [String, nil] 検索する名前（部分一致）
    # @return [ActiveRecord::Relation] 検索結果
    scope :search_by_name, lambda { |name|
      if name.present?
        where("name ILIKE ?", "%#{sanitize_sql_like(name)}%")
      else
        all
      end
    }

    # カテゴリーIDによる絞り込み
    #
    # @param category_id [Integer, String, nil] カテゴリーID
    # @return [ActiveRecord::Relation] 絞り込み結果
    scope :filter_by_category_id, lambda { |category_id|
      if category_id.present?
        where(category_id: category_id)
      else
        all
      end
    }

    # カテゴリー種別による絞り込み
    #
    # @param category_type [String, nil] カテゴリー種別
    # @return [ActiveRecord::Relation] 絞り込み結果
    scope :filter_by_category_type, lambda { |category_type|
      if category_type.present?
        joins(:category).where(categories: { category_type: category_type })
      else
        all
      end
    }

    # 名前とカテゴリーによる複合検索
    #
    # @param options [Hash] 検索条件のオプション
    # @option options [String] :name 検索する名前（部分一致）
    # @option options [Integer, String] :category_id カテゴリーID
    # @option options [String] :category_type カテゴリー種別
    # @return [ActiveRecord::Relation] 検索結果
    scope :search_and_filter, lambda { |options = {}|
      result = all
      result = result.search_by_name(options[:name]) if options[:name].present?
      result = result.filter_by_category_id(options[:category_id]) if options[:category_id].present?
      result = result.filter_by_category_type(options[:category_type]) if options[:category_type].present?
      result
    }
  end
end
