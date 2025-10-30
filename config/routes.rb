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

  # 数値管理（整理して統合）
  resources :numerical_managements, only: [:index] do
    collection do
      get :calendar              # カレンダービュー
      post :update_budget        # 予算更新・作成
      delete :destroy_budget     # ← 追加: 予算削除
      post :assign_plan_to_date  # 計画を日付に配置
    end
    member do
      patch :update_actual       # 実績入力
    end
  end

  # 月間予算（削除可能 - numerical_managementsで管理）
  # resources :monthly_budgets, only: [:create, :update]  # ← コメントアウトまたは削除

  # 日別目標の編集
  resources :daily_targets, only: [:create, :update]
  resources :plan_schedules, only: [:create, :update]

  # APIルーティングの追加
  namespace :api do
    namespace :v1 do
      resources :products, only: [] do
        member do
          get :details_for_plan
        end
      end

      resources :materials, only: [] do
        member do
          get :product_unit_data
        end
      end

      resources :plans, only: [] do
        member do
          get :revenue
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
    member do
      delete 'purge_image', to: 'products#purge_image', as: :purge_image
      post :copy
    end
    resource :product_materials, only: [:show, :edit, :update]
  end

  # Planのルーティング
  resources :plans do
    member do
      patch :update_status
      post :copy
    end
  end

end
