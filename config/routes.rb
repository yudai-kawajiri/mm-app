# frozen_string_literal: true

Rails.application.routes.draw do
  # ========================================
  # アプリケーション責任者依頼（全サブドメイン共通）
  # ========================================
  resources :application_requests, only: [:new, :create] do
    collection do
      get 'accept', to: 'application_requests#accept'
      post 'accept', to: 'application_requests#accept_confirm'
    end
  end

  # ========================================
  # サブドメインなし: 公開ページ
  # ========================================
  constraints subdomain: '' do
    # 未認証ユーザー用ルート
    root to: "landing#index"

    # 静的ページ
    get 'terms', to: 'static_pages#terms', as: :terms
    get 'privacy', to: 'static_pages#privacy', as: :privacy

    # お問い合わせ
    resources :contacts, only: [:new, :create]
  end

  # ========================================
  # サブドメインあり: テナント専用ページ
  # ========================================
  constraints subdomain: /.+/ do
    # 認証 (Devise)
    devise_for :users, controllers: { registrations: "users/registrations" }

    # 認証済みユーザー用ルート
    authenticated :user do
      root to: "dashboards#index", as: :authenticated_root

      # 店舗切り替え
      post 'switch_store', to: 'stores#switch'

      # ユーザー設定・ヘルプ
      get "/settings", to: "settings#index", as: :settings
      get "/help", to: "help#index", as: :help

      # 管理者メニュー (Admin Namespace)
      namespace :admin do
        resources :tenants
        resources :admin_requests, only: [:index, :new, :create, :show] do
          member do
            post :approve
            post :reject
          end
        end
        resources :users, only: [:index, :new, :create, :show, :edit, :update, :destroy]
        resources :stores do
          member do
            post :regenerate_invitation_code
          end
        end
        resources :system_logs, only: [:index]
      end

      # 数値管理 (Management Namespace)
      namespace :management do
        resources :numerical_managements, only: [:index] do
          collection do
            patch :bulk_update
            patch :update_daily_target
          end
        end

        resources :monthly_budgets, only: [:create, :update, :destroy] do
          member do
            patch :update_discount_rates
          end
        end

        resources :daily_targets, only: [:create, :update]

        resources :plan_schedules, only: [:create, :update, :destroy] do
          member do
            patch :actual_revenue
          end
        end
      end

      # リソース管理 (Resources Namespace)
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

          resources :product_materials, only: [:index, :edit, :update]
        end

        resources :plans do
          member do
            patch :update_status
            post :copy
            get :print
          end
        end
      end

      # API (API Namespace)
      namespace :api do
        namespace :v1 do
          resources :products, only: [:index, :show] do
            member do
              get :fetch_plan_details
            end
          end

          resources :materials, only: [:index, :show] do
            member do
              get :fetch_product_unit_data
            end
          end

          resources :plans, only: [:index, :show] do
            member do
              get :revenue
            end
          end
        end
      end
    end

    # 未認証ユーザーはログインページへリダイレクト
    unauthenticated :user do
      root to: "devise/sessions#new", as: :unauthenticated_root
    end
  end
end
