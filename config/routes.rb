Rails.application.routes.draw do

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

  # showアクションのみを除外
  resources :categories, except: [:show]

  # Material のルーティングも将来のために定義しておく
  resources :materials
end
