# frozen_string_literal: true

# 名前検索とカテゴリーフィルタ
module NameSearchable
  extend ActiveSupport::Concern

  included do
    scope :search_by_name, lambda { |name|
      return all if name.blank?

      if column_names.include?("reading")
        where("LOWER(#{table_name}.name) LIKE LOWER(?) OR LOWER(#{table_name}.reading) LIKE LOWER(?)",
              "%#{sanitize_sql_like(name)}%",
              "%#{sanitize_sql_like(name)}%")
      else
        where("LOWER(#{table_name}.name) LIKE LOWER(?)", "%#{sanitize_sql_like(name)}%")
      end
    }

    scope :filter_by_category_id, lambda { |category_id|
      return all if category_id.blank?
      where(category_id: category_id)
    }

    scope :filter_by_category_type, lambda { |category_type|
      return all if category_type.blank?

      if name == "Resources::Category"
        where(category_type: category_type)
      elsif reflect_on_association(:category)
        joins(:category).where(categories: { category_type: category_type })
      else
        all
      end
    }

    scope :search_and_filter, lambda { |options = {}|
      search_term = options[:q] || options[:name]

      all
        .then { |scope| search_term.present? ? scope.search_by_name(search_term) : scope }
        .then { |scope| options[:category_id].present? ? scope.filter_by_category_id(options[:category_id]) : scope }
        .then { |scope| options[:category_type].present? ? scope.filter_by_category_type(options[:category_type]) : scope }
    }
  end
end
