Rails.application.routes.draw do
  get "materials/index"
  get "materials/show"
  get "materials/new"
  get "materials/create"
  get "materials/edit"
  get "materials/update"
  get "materials/destroy"

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

  # Material のルーティング
  resources :materials
end
