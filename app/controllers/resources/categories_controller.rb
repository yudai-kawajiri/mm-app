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
  before_action :set_category, only: [ :show, :edit, :update, :destroy, :copy ]

  def index
    Rails.logger.info "[DEBUG INDEX] @categories count before scoped: (calling scoped_categories now)"
    @categories = scoped_categories
    Rails.logger.info "[DEBUG INDEX] @categories count after scoped: #{@categories.count}"

    @categories = apply_sort(@categories, default: "name")

    if params[:category_type].present?
      @categories = @categories.where(category_type: params[:category_type])
    end

    if params[:q].present?
      @categories = @categories.search_by_name(params[:q])
    end

    @categories = @categories.page(params[:page])
  end

  def show
  end

  def new
    @category = Resources::Category.new
  end

  def create
    @category = Resources::Category.new(category_params)
    @category.user_id = current_user.id
    @category.company_id = current_company.id
    @category.store_id = current_store&.id || current_user.store_id

    respond_to_save(@category)
  end

  def edit
  end

  def update
    Rails.logger.debug "=== UPDATE DEBUG ==="
    Rails.logger.debug "Before assign: store_id = #{@category.store_id.inspect}"
    @category.assign_attributes(category_params)
    Rails.logger.debug "After assign: store_id = #{@category.store_id.inspect}"
    
    # 強制的に store_id を設定（念のため）
    @category.store_id ||= current_store&.id
    Rails.logger.debug "After force: store_id = #{@category.store_id.inspect}"
    Rails.logger.debug "===================="
    respond_to_save(@category)
  end

  def destroy
    respond_to_destroy(@category, success_path: resources_categories_path)
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


  def scoped_categories
    Rails.logger.info "[DEBUG CONTROLLER SCOPED] current_user.role = #{current_user.role}"
    Rails.logger.info "[DEBUG CONTROLLER SCOPED] session[:current_store_id] = #{session[:current_store_id].inspect}"
    
    case current_user.role
    when 'store_admin', 'general'
      Resources::Category.where(store_id: current_user.store_id)
    when 'company_admin'
      if session[:current_store_id].present?
        Resources::Category.where(company_id: current_company.id, store_id: session[:current_store_id])
      else
        Resources::Category.where(company_id: current_company.id)
      end
    else
      Resources::Category.none
    end
  end
  private

  def set_category
    @category = current_user.company.categories.find(params[:id])
  end

  def category_params
    params.require(:resources_category).permit(:name, :reading, :category_type, :description)
  end
end
