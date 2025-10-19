module CategoryFetchable
  extend ActiveSupport::Concern

  private

  def fetch_categories_by_type(type_key)
    db_value = Category.category_types[type_key.to_sym]

    if db_value.present? || db_value == 0
      current_user.categories.where(category_type: db_value).order(:name)
    else
      Category.none
    end
  end
end
