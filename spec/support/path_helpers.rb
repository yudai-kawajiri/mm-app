# frozen_string_literal: true

# spec/support/path_helpers.rb
# 会社スコープ付きパスヘルパー

module PathHelpers
  def scoped_path(path_method, *args, **options)
    # 特殊なパスのマッピング
    path_mapping = {
      # Materials
      new_resources_material: :new_company_resources_material,
      edit_resources_material: :edit_company_resources_material,
      reorder_resources_materials: :reorder_company_resources_materials,
      copy_resources_material: :copy_company_resources_material,
      resources_materials: :company_resources_materials,
      resources_material: :company_resources_material,
      
      # Categories
      resources_categories: :company_resources_categories,
      resources_category: :company_resources_category,
      new_resources_category: :new_company_resources_category,
      edit_resources_category: :edit_company_resources_category,
      
      # Products
      resources_products: :company_resources_products,
      resources_product: :company_resources_product,
      new_resources_product: :new_company_resources_product,
      edit_resources_product: :edit_company_resources_product,
      copy_resources_product: :copy_company_resources_product,
      reorder_resources_products: :reorder_company_resources_products,
      purge_image_resources_product: :purge_image_company_resources_product,
      
      # Plans
      resources_plans: :company_resources_plans,
      resources_plan: :company_resources_plan,
      new_resources_plan: :new_company_resources_plan,
      edit_resources_plan: :edit_company_resources_plan,
      copy_resources_plan: :copy_company_resources_plan,
      update_status_resources_plan: :update_status_company_resources_plan,
      print_resources_plan: :print_company_resources_plan,
      
      # Units
      resources_units: :company_resources_units,
      resources_unit: :company_resources_unit,
      new_resources_unit: :new_company_resources_unit,
      edit_resources_unit: :edit_company_resources_unit,
      
      # Daily Targets
      management_daily_targets: :company_management_daily_targets,
      management_daily_target: :company_management_daily_target,
      
      # Plan Schedules
      management_plan_schedules: :company_management_plan_schedules,
      management_plan_schedule: :company_management_plan_schedule,
      actual_revenue_management_plan_schedule: :actual_revenue_company_management_plan_schedule,
      
      # Numerical Management
      management_numerical_managements: :company_management_numerical_managements,
      management_numerical_management: :company_management_numerical_management,
      numerical_managements: :company_numerical_managements,
      numerical_management: :company_numerical_management,
      
      # Monthly Budgets
      monthly_budgets: :company_monthly_budgets,
      monthly_budget: :company_monthly_budget,
      new_monthly_budget: :new_company_monthly_budget,
      edit_monthly_budget: :edit_company_monthly_budget,
      
      # Material Order Groups
      resources_material_order_groups: :company_resources_material_order_groups,
      resources_material_order_group: :company_resources_material_order_group,
      new_resources_material_order_group: :new_company_resources_material_order_group,
      edit_resources_material_order_group: :edit_company_resources_material_order_group,
      copy_resources_material_order_group: :copy_company_resources_material_order_group,
      
      # Dashboards
      dashboards: :company_dashboards,
      root: :company_root,
      
      # Settings
      settings: :company_settings,
      help: :company_help,
      
      # API endpoints
      fetch_product_unit_data_api_v1_material: :fetch_product_unit_data_company_api_v1_material,
      fetch_plan_details_api_v1_product: :fetch_plan_details_company_api_v1_product,
      revenue_api_v1_plan: :revenue_company_api_v1_plan,
    }
    
    # マッピングがあれば使用
    mapped_method = path_mapping[path_method] || "company_#{path_method}".to_sym
    
    company_slug = options[:company_slug] ||
                   @company&.slug ||
                   company&.slug ||
                   @user&.company&.slug ||
                   @current_user&.company&.slug ||
                   'test-company'

    # パスまたはURLを生成
    method_name = mapped_method.to_s.end_with?('_url') ? mapped_method : "#{mapped_method}_path"
    
    send(method_name, *args, company_slug: company_slug, **options)
  end

  # 認証済みユーザー用のパスヘルパー
  def authenticated_scoped_path(path_method, *args, **options)
    scoped_path(path_method, *args, **options)
  end

  # Edit scoped path helper
  def edit_scoped_path(route_name, *args)
    scoped_path("edit_#{route_name}".to_sym, *args)
  end

  # Copy scoped path helper
  def copy_scoped_path(route_name, *args)
    scoped_path("copy_#{route_name}".to_sym, *args)
  end

  # Devise のログインパス
  def new_user_session_path
    "/users/sign_in"
  end

  # Devise のユーザー編集パス
  def edit_user_registration_path
    company_slug = @company&.slug || @user&.company&.slug || @current_user&.company&.slug || 'test-company'
    "/c/#{company_slug}/users/edit"
  end
end

RSpec.configure do |config|
  config.include PathHelpers, type: :request
  config.include PathHelpers, type: :system
  
  config.before(:each, type: :request) do
    # テスト用のデフォルト会社を設定
    @company ||= begin
      if defined?(company)
        company
      elsif defined?(@user) && @user&.company
        @user.company
      end
    end
  end
end
