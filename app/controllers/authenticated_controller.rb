class AuthenticatedController < ApplicationController
  before_action :authenticate_user!

  include CategoryFetchable
  include SearchAndFilterConcern
  include PaginationConcern
  include ResourceFinderConcern
  include CrudResponderConcern
  include SearchableController

  def set_search_term_for_view
    if defined?(search_params) && search_params[:q].present?
      @search_term = search_params[:q]
    end
  end

  def load_categories_for(category_type, as: nil, scope: :current_user)
    categories = if scope == :current_user
                   current_user.categories.where(category_type: category_type)
    else
                   Category.where(category_type: category_type)
    end
    categories = categories.order(:name)

    prefix = as || category_type
    variable_name = "@#{prefix}_categories"

    instance_variable_set(variable_name, categories)

    @search_categories = categories if as == :search || as.nil?

    categories
  end
end
