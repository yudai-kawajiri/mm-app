Rails.application.routes.draw do

  # controllersオプションを追加し、RegistrationsControllerを指定
  devise_for :users, controllers: {
    registrations: 'users/registrations' # usersフォルダ内のregistrations_controllerを使う
  }
  # 認証済みユーザー向けのルート設定
  authenticated :user do
    # ルートパス ("/") を DashboardsControllerのindexアクションに設定
    root to: "dashboards#index", as: :authenticated_root
  end

  # 未認証ユーザー向けのルート設定
  devise_scope :user do
    # ルートパス ("/") を Deviseのログイン画面（sessions#new）に設定
    root to: "devise/sessions#new"

    # GET /users リクエストをログインページ（/）へリダイレクトしてエラーを防ぐ
    get '/users', to: redirect('/')
  end

  # 数値管理
  resources :numerical_managements, only: [:index] do
    collection do
      patch :update_budget     # 予算更新
    end
    member do
      patch :update_actual     # 実績入力
    end
  end
  # 数値管理
  resources :numerical_managements, only: [:index] do
    collection do
      get :calendar  # カレンダービュー
      post :update_budget
      post :assign_plan_to_date  # 計画を日付に配置
    end
    member do
      patch :update_actual
    end
  end

  # 月間予算
  resources :monthly_budgets, only: [:create, :update]  # ← この行を追加

  # 日別目標の編集
  resources :daily_targets, only: [:update]
  resources :plan_schedules, only: [:create, :update] 

  # APIルーティングの追加
  # /api/v1/ のネームスペースでAPIを分離
  namespace :api do
    namespace :v1 do
      # Product API: GET /api/v1/products/:id/details_for_plan
      resources :products, only: [] do
        member do
          get :details_for_plan
        end
      end

      # Material API: GET /api/v1/materials/:id/product_unit_data
      resources :materials, only: [] do
        member do
          get :product_unit_data
        end
      end
    end
  end

  # showアクションを含む全アクション
  resources :categories

  # showアクションを含む全アクション
  resources :units

  # Materialのルーティング
  resources :materials

  # Productのルーティング
  resources :products do
    # 特定の商品の画像のみを削除するためのカスタムルート
    # （/products/:id/purge_image というDELETEリクエストに対応）
    member do
      delete 'purge_image', to: 'products#purge_image', as: :purge_image
    end
    # ネストされたリソースを定義
    #（/products/:product_id/product_materials/show などに対応）
    resource :product_materials, only: [:show, :edit, :update]
  end

  # Planのルーティング
  resources :plans
end
