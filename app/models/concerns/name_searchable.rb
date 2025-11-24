# frozen_string_literal: true

# NameSearchable
#
# 名前検索とカテゴリーフィルタリングの共通機能を提供するConcern
module NameSearchable
  extend ActiveSupport::Concern

  included do
    # 名前または読み仮名による部分一致検索
    scope :search_by_name, lambda { |name|
      if name.present?
        # readingカラムがある場合は読み仮名も検索対象に含める
        if column_names.include?("reading")
          where("#{table_name}.name ILIKE ? OR #{table_name}.reading ILIKE ?",
                "%#{sanitize_sql_like(name)}%",
                "%#{sanitize_sql_like(name)}%")
        else
          where("#{table_name}.name ILIKE ?", "%#{sanitize_sql_like(name)}%")
        end
      else
        all
      end
    }

    scope :filter_by_category_id, lambda { |category_id|
      if category_id.present?
        where(category_id: category_id)
      else
        all
      end
    }

    scope :filter_by_category_type, lambda { |category_type|
      if category_type.present?
        if name == "Resources::Category"
          where(category_type: category_type)
        elsif reflect_on_association(:category)
          joins(:category).where(categories: { category_type: category_type })
        else
          all
        end
      else
        all
      end
    }

    scope :search_and_filter, lambda { |options = {}|
      result = all
      search_term = options[:q] || options[:name]
      result = result.search_by_name(search_term) if search_term.present?
      result = result.filter_by_category_id(options[:category_id]) if options[:category_id].present?
      result = result.filter_by_category_type(options[:category_type]) if options[:category_type].present?
      result
    }
  end
end
