Rails.application.routes.draw do
  devise_for :users, controllers: { registrations: "users/registrations" }

  authenticated :user do
    root to: "dashboards#index", as: :authenticated_root
    post 'switch_store', to: 'stores#switch'
  end

  devise_scope :user do
    root to: "landing#index"
    get "/users", to: redirect("/")
  end

  get 'terms', to: 'static_pages#terms', as: :terms
  get 'privacy', to: 'static_pages#privacy', as: :privacy

  get "/settings", to: "settings#index", as: :settings
  get "/help", to: "help#index", as: :help

  resources :contacts, only: [:new, :create]

  namespace :admin do
    resources :users, only: [ :index, :new, :create, :edit, :update, :destroy ]
    resources :stores
    resources :system_logs, only: [ :index ]
  end

  namespace :management do
    resources :numerical_managements, only: [ :index ] do
      collection do
        patch :bulk_update
        patch :update_daily_target
      end
    end

    resources :monthly_budgets, only: [ :create, :update, :destroy ] do
      member do
        patch :update_discount_rates
      end
    end

    resources :daily_targets, only: [ :create, :update ]

    resources :plan_schedules, only: [ :create, :update, :destroy ] do
      member do
        patch :actual_revenue
      end
    end
  end

  namespace :resources do
    resources :categories do
      member do
        post :copy
      end
    end

    resources :units do
      member do
        post :copy
      end
    end

    resources :materials do
      collection do
        post :reorder
      end

      member do
        post :copy
      end
    end

    resources :material_order_groups do
      member do
        post :copy
      end
    end

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

    resources :plans do
      member do
        patch :update_status
        post :copy
        get :print
      end
    end
  end

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
