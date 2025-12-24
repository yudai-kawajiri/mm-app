Rails.application.routes.draw do
  # ヘルスチェック
  get "up" => "rails/health#show", as: :rails_health_check

  # PWA
  get "service-worker" => "rails/pwa#service_worker", as: :pwa_service_worker
  get "manifest" => "rails/pwa#manifest", as: :pwa_manifest

  # ルートドメイン: ランディングページと新規会社申請
  root to: "landing#index"

  resources :application_requests, only: [ :new, :create ] do
    collection do
      get :thanks
      get :accept
      post :accept, action: :accept_confirm
    end
  end

  get :terms, to: "static_pages#terms"
  get :privacy, to: "static_pages#privacy"
  resources :contacts, only: [ :new, :create ]

  # Devise設定（すべてskip、company scopeで個別定義）
  devise_for :users, skip: :all

  # 会社スコープ内の認証機能
  scope "/c/:company_slug", as: :company do
    devise_scope :user do
      # ログイン
      get "/users/sign_in", to: "users/sessions#new", as: :new_user_session
      post "/users/sign_in", to: "users/sessions#create", as: :user_session
      delete "/users/sign_out", to: "users/sessions#destroy", as: :destroy_user_session

      # サインアップ
      get "/users/sign_up", to: "users/registrations#new", as: :new_user_registration
      post "/users", to: "users/registrations#create", as: :user_registration
      get "/users/edit", to: "users/registrations#edit", as: :edit_user_registration
      patch "/users", to: "users/registrations#update"
      put "/users", to: "users/registrations#update"
      delete "/users", to: "users/registrations#cancel"

      # パスワードリセット
      get "/users/password/new", to: "users/passwords#new", as: :new_user_password
      post "/users/password", to: "users/passwords#create", as: :user_password
      get "/users/password/edit", to: "users/passwords#edit", as: :edit_user_password
      patch "/users/password", to: "users/passwords#update"
      put "/users/password", to: "users/passwords#update"
    end
  end

  # 認証後のルーティング（会社スコープ）
  authenticated :user do
    # 会社スコープ内のルーティング
    scope "/c/:company_slug", as: :company do
      root to: "router#index", as: :root

      post :switch_store, to: "stores#switch"
      post :switch_company, to: "companies#switch"

      # ダッシュボード
      resources :dashboards, only: [ :index ]

      get :settings, to: "settings#index"
      get :help, to: "help#index"

      namespace :admin do
        resources :companies
        resources :admin_requests, only: [ :index, :new, :create, :show ] do
          member do
            post :approve
            post :reject
          end
        end
        resources :users
        resources :stores do
          member do
            post :regenerate_invitation_code
          end
        end
        resources :system_logs, only: [ :index ]
      end

      namespace :resources do
        resources :materials do
          post :copy, on: :member
          collection do
            post :reorder
          end
        end
        resources :products do
          post :copy, on: :member
          member do
            delete :purge_image
          end
          collection do
            post :reorder
          end
        end
        resources :categories do
          post :copy, on: :member
        end
        resources :units
        resources :product_materials, only: [ :index, :edit, :update ]
        resources :material_order_groups do
          post :copy, on: :member
        end
      end

      namespace :resources do
        resources :plans do
          resources :plan_products, only: [ :index, :create, :update, :destroy, :edit ]
          resources :plan_schedules, only: [ :index, :create, :update, :destroy ]
          post :copy, on: :member
          member do
            patch :update_status
          end
        end
      end

      namespace :management do
        resources :monthly_budgets, only: [ :index, :create, :update ] do
          collection do
            patch :update_discount_rates
          end
        end
        resources :daily_targets, only: [ :index, :create, :update ]
        resources :numerical_managements, only: [ :index ]
      end

      namespace :api do
        namespace :v1 do
          resources :plans, only: [] do
            member do
              get :revenue
            end
          end
          resources :plan_schedules, only: [] do
            member do
              get :revenue
            end
          end
          resources :daily_targets, only: [ :show, :update ]
          resources :products, only: [ :show ]
          resources :materials, only: [ :index, :show ] do
            member do
              get :fetch_product_unit_data
            end
          end
        end
      end
    end
  end

  resource :user_settings, only: [ :show, :update, :edit ]
end
