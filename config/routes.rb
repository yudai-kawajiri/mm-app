Rails.application.routes.draw do
  get "categories/index"
  get "categories/show"
  get "categories/new"
  get "categories/edit"
  # ダッシュボードへのGETルートを定義（コントローラとアクションを紐付け）
  get "dashboards/index"

  # Deviseの認証機能に必要な全ルーティングを生成
  devise_for :users

  # 認証済みユーザー向けのルート設定
  authenticated :user do
    # ルートパス ("/") を DashboardsControllerのindexアクションに設定
    root to: "dashboards#index", as: :authenticated_root
  end

  # 未認証ユーザー向けのルート設定
  devise_scope :user do
    # ルートパス ("/") を Deviseのログイン画面（sessions#new）に設定
    root to: "devise/sessions#new"
  end

  # Category の CRUD ルーティングを一括定義
  resources :categories

  # Material のルーティングも将来のために定義しておく
  resources :materials
end
