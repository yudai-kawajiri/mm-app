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
  # 数値管理（ビュー専用）
  # ====================
  resources :numerical_managements, only: [ :index ] do
    collection do
      get :calendar  # カレンダービュー
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
      patch :actual_revenue  # 実績入力（PATCH /plan_schedules/:id/actual_revenue）
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
      post :reorder  # 並び替え用
    end
  end

  # 製品
  resources :products do
    collection do
      post :reorder  # 並び替え用
    end

    member do
      delete :purge_image  # 画像削除
      post :copy           # 複製
    end

    # 製品-材料の管理
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
          get :details_for_plan  # GET /api/v1/products/:id/details_for_plan
        end
      end

      # 材料API
      resources :materials, only: [ :index, :show ] do
        member do
          get :product_unit_data  # GET /api/v1/materials/:id/product_unit_data
        end
      end

      # 計画API
      resources :plans, only: [ :index, :show ] do
        member do
          get :revenue  # GET /api/v1/plans/:id/revenue
        end
      end
    end
  end
end
