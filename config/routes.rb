# frozen_string_literal: true

Rails.application.routes.draw do
  # ========================================
  # 認証 (Devise)
  # ========================================
  # カスタム登録コントローラで tenant_id の自動設定を実装
  devise_for :users, controllers: { registrations: "users/registrations" }

  # ========================================
  # 認証済みユーザー用ルート
  # ========================================
  authenticated :user do
    root to: "dashboards#index", as: :authenticated_root

    # 店舗切り替え: サイドバーから POST で店舗選択を変更
    # session[:current_store_id] を更新し、データスコープを切り替える
    post 'switch_store', to: 'stores#switch'
  end

  # ========================================
  # 未認証ユーザー用ルート
  # ========================================
  devise_scope :user do
    root to: "landing#index"
    # /users へのアクセスはトップページにリダイレクト
    get "/users", to: redirect("/")
  end

  # ========================================
  # 静的ページ
  # ========================================
  get 'terms', to: 'static_pages#terms', as: :terms
  get 'privacy', to: 'static_pages#privacy', as: :privacy

  # ========================================
  # ユーザー設定・ヘルプ
  # ========================================
  get "/settings", to: "settings#index", as: :settings
  get "/help", to: "help#index", as: :help

  # ========================================
  # お問い合わせ
  # ========================================
  resources :contacts, only: [:new, :create]

  # ========================================
  # 管理者メニュー (Admin Namespace)
  # ========================================
  # 会社管理者のみアクセス可能
  # ユーザー管理、店舗管理、システムログを提供
  namespace :admin do
    resources :admin_requests, only: [:index, :new, :create, :show] do
      member do
        post :approve
        post :reject
      end
    end
    resources :users, only: [:index, :new, :create, :edit, :update, :destroy]
    resources :stores
    resources :system_logs, only: [:index]
  end

  # ========================================
  # 数値管理 (Management Namespace)
  # ========================================
  # 月間予算、日次目標、計画スケジュールを管理
  # bulk_update: 複数レコードの一括更新
  namespace :management do
    resources :numerical_managements, only: [:index] do
      collection do
        patch :bulk_update
        patch :update_daily_target
      end
    end

    resources :monthly_budgets, only: [:create, :update, :destroy] do
      member do
        # 値引率の更新（特定月の予算調整）
        patch :update_discount_rates
      end
    end

    resources :daily_targets, only: [:create, :update]

    resources :plan_schedules, only: [:create, :update, :destroy] do
      member do
        # 実績売上の登録（計画と実績の紐付け）
        patch :actual_revenue
      end
    end
  end

  # ========================================
  # リソース管理 (Resources Namespace)
  # ========================================
  # 商品、原材料、計画などのマスタデータ管理
  # copy: データ複製機能（店舗間でのデータ共有を想定）
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
        # 原材料の表示順序を変更
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
        # 商品の表示順序を変更
        post :reorder
      end

      member do
        # 商品ステータスの更新（有効/無効の切り替え）
        patch :update_status
        # 商品画像の削除
        delete :purge_image
        post :copy
      end

      # 商品構成材料の管理（ネストリソース）
      resources :product_materials, only: [:index, :edit, :update]
    end

    resources :plans do
      member do
        # 計画ステータスの更新（確定/未確定の切り替え）
        patch :update_status
        post :copy
        # 計画の印刷プレビュー
        get :print
      end
    end
  end

  # ========================================
  # API (API Namespace)
  # ========================================
  # フロントエンド JavaScript 用の JSON API
  # fetch_plan_details, fetch_product_unit_data: 非同期データ取得用
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
