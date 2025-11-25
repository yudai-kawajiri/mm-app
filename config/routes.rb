Rails.application.routes.draw do
  # ====================
  # 認証（Devise）
  # ====================
  devise_for :users, controllers: { registrations: "users/registrations" }

  # 認証済みユーザー
  authenticated :user do
    root to: "dashboards#index", as: :authenticated_root
  end

  # 未認証ユーザー
  devise_scope :user do
    root to: "devise/sessions#new"
    get "/users", to: redirect("/")
  end

  # ====================
  # 管理者機能
  # ====================
  namespace :admin do
    resources :users, only: [ :index, :destroy ]
    resources :system_logs, only: [ :index ]
  end

  # ====================
  # 数値管理（Management名前空間）
  # ====================
  namespace :management do
    # 数値管理（ビュー専用）
    resources :numerical_managements, only: [ :index ] do
      collection do
        post :bulk_update
        patch :update_daily_target
      end
    end

    # 月間予算
    resources :monthly_budgets, only: [ :create, :update, :destroy ] do
      member do
        patch :update_discount_rates
      end
    end

    # 日別目標
    resources :daily_targets, only: [ :create, :update ]

    # 計画スケジュール
    resources :plan_schedules, only: [ :create, :update, :destroy ] do
      member do
        patch :actual_revenue  # ← update_ を削除
      end
    end
  end

  # ====================
  # リソース管理（Resources名前空間）
  # ====================
  namespace :resources do
    # カテゴリ
    resources :categories do
      member do
        post :copy
      end
    end

    # 単位
    resources :units do
      member do
        post :copy
      end
    end

    # 材料
    resources :materials do
      collection do
        post :reorder
      end

      member do
        post :copy
      end
    end

    # 発注グループ
    resources :material_order_groups do
      member do
        post :copy
      end
    end

    # 製品
    resources :products do
      collection do
        post :reorder
      end

      member do
        patch :update_status
        delete :purge_image
        post :copy
      end

      resources :product_materials, only: [ :index, :edit, :update ]
    end

    # 計画
    resources :plans do
      member do
        patch :update_status
        post :copy
        get :print
      end
    end
  end

  # ====================
  # API（v1）
  # ====================
  namespace :api do
    namespace :v1 do
      resources :products, only: [ :index, :show ] do
        member do
          get :fetch_plan_details
        end
      end

      resources :materials, only: [ :index, :show ] do
        member do
          get :fetch_product_unit_data
        end
      end

      resources :plans, only: [ :index, :show ] do
        member do
          get :revenue
        end
      end
    end
  end
end
