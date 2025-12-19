# frozen_string_literal: true

Rails.application.routes.draw do
  # 利用規約、プライバシーポリシー、お問い合わせは全環境で共通
  get :terms, to: 'static_pages#terms'
  get :privacy, to: 'static_pages#privacy'
  resources :contacts, only: [:new, :create]

  constraints subdomain: '' do
    root to: "landing#index"

    resources :application_requests, only: [:new, :create] do
      collection do
        get :thanks
        get :accept
        post :accept, action: :accept_confirm
      end
    end
  end

  constraints subdomain: /.+/ do
    devise_for :users, controllers: { registrations: "users/registrations", sessions: "users/sessions" }

    authenticated :user do
      root to: "dashboards#index", as: :authenticated_root

      post :switch_store, to: 'stores#switch'
      post :switch_tenant, to: 'tenants#switch'

      get :settings, to: "settings#index"
      get :help, to: "help#index"

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

    unauthenticated :user do
      root to: redirect('/users/sign_in'), as: :unauthenticated_root
    end
  end
end
