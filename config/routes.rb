Rails.application.routes.draw do
  # ====================
  # 認証（Devise）
  # ====================
  devise_for :users, controllers: {
    registrations: "users/registrations"
  }

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
    resources :system_logs, only: [:index]
  end

  # ====================
  # 数値管理（ビュー専用）
  # ====================
  resources :numerical_managements, only: [ :index ] do
    collection do
      post :bulk_update
      patch :update_daily_target
    end
  end

  # ====================
  # 数値管理リソース（RESTful）
  # ====================
  # 月間予算
  resources :monthly_budgets, only: [ :create, :update, :destroy ]

  # 日別目標
  resources :daily_targets, only: [ :create, :update ]

  # 計画スケジュール
  resources :plan_schedules, only: [ :create, :update, :destroy ] do
    member do
      patch :update_actual_revenue  # 実績入力
    end
  end

  # ====================
  # マスタデータ
  # ====================
  # カテゴリ
  resources :categories

  # 単位
  resources :units

  # 材料
  resources :materials do
    collection do
      post :reorder
    end
  end

  # 発注グループ
  resources :material_order_groups

  # 製品
  resources :products do
    collection do
      post :reorder
    end

    member do
      delete :purge_image  # 画像削除
      post :copy           # 複製
    end

    # 製品-材料の関連管理
    resources :product_materials, only: [ :index, :edit, :update ]
  end

  # 計画
  resources :plans do
    member do
      patch :update_status  # ステータス更新
      post :copy            # 複製
      get :print            # 印刷用ページ
    end
  end

  # ====================
  # API（v1）
  # ====================
  namespace :api do
    namespace :v1 do
      # 製品API
      resources :products, only: [ :index, :show ] do
        member do
          get :fetch_plan_details  # 計画用の製品詳細を取得
        end
      end

      # 材料API
      resources :materials, only: [ :index, :show ] do
        member do
          get :fetch_product_unit_data  # 製品単位データを取得
        end
      end

      # 計画API
      resources :plans, only: [ :index, :show ] do
        member do
          get :fetch_revenue  # 売上データを取得
        end
      end
    end
  end
end
