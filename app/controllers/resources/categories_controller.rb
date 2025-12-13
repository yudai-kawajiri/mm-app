# frozen_string_literal: true

class Resources::CategoriesController < AuthenticatedController
  include SortableController

  define_search_params :q, :category_type, :sort_by

  define_sort_options(
    name: -> { order(:reading) },
    category_type: -> { order(:category_type, :reading) },
    created_at: -> { order(created_at: :desc) }
  )

  find_resource :category, only: [ :show, :edit, :update, :destroy, :copy ]

  def index
    @categories = scoped_categories

    @categories = apply_sort(@categories, default: "name")

    if params[:category_type].present?
      @categories = @categories.where(category_type: params[:category_type])
    end

    if params[:q].present?
      @categories = @categories.search_by_name(params[:q])
    end

    @categories = @categories.page(params[:page])
  end

  def new
    @category = Resources::Category.new
    @category.user_id = current_user.id
    @category.tenant_id = current_tenant.id
    @category.store_id = current_store&.id
  end

  def create
    @category = Resources::Category.new(category_params)
    @category.user_id = current_user.id
    @category.tenant_id = current_tenant.id
    @category.store_id = current_store&.id if @category.store_id.blank?
    respond_to_save(@category)
  end

  def show; end

  def edit; end

  def update
    @category.assign_attributes(category_params)
    respond_to_save(@category)
  end

  def destroy
    respond_to_destroy(@category, success_path: resources_categories_url)
  end

  def copy
    @category.create_copy(user: current_user)
    redirect_to resources_categories_path, notice: t("flash_messages.copy.success",
                                                      resource: @category.class.model_name.human)
  rescue ActiveRecord::RecordInvalid => e
    Rails.logger.error "Category copy failed: #{e.record.errors.full_messages.join(', ')}"
    redirect_to resources_categories_path, alert: t("flash_messages.copy.failure",
                                                    resource: @category.class.model_name.human)
  end

  private

  def category_params
    params.require(:resources_category).permit(:name, :reading, :category_type, :description)
  end
end
