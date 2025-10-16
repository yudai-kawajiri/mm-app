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

  # showアクションのみを除外
  resources :categories, except: [:show]

  # showアクションのみを除外
  resources :units, except: [:show]

  # Materialのルーティング
  resources :materials

  # Productのルーティング
  resources :products do
    # 特定の商品の画像のみを削除するためのカスタムルート
    # （/products/:id/purge_image というDELETEリクエストに対応）
    member do
      delete 'purge_image', to: 'products#purge_image', as: :purge_image

      # 製造計画の非同期計算に必要な情報を取得するAPI
      get :details_for_plan
    end
    # ネストされたリソースを定義
    #（/products/:product_id/product_materials/show などに対応）
    resource :product_materials, only: [:show, :edit, :update]
  end

  # Planのルーティング
  resources :plans
end
