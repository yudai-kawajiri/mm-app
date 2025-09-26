Rails.application.routes.draw do
  # ダッシュボードへのGETルートを定義（コントローラとアクションを紐付け）
  get "dashboards/index"

  # Deviseの認証機能に必要な全ルーティングを生成
  devise_for :users

  # 認証済みユーザー向けのルート設定
  # Userモデルでログインしている場合（user_signed_in?がtrueの場合）に適用
  authenticated :user do
    # ルートパス ("/") を DashboardsControllerのindexアクションに設定
    root to: 'dashboards#index', as: :authenticated_root
  end







































    # ルートパス ("/") を Deviseのログイン画面（sessions#new）に設定
    root to: 'devise/sessions#new'
  end
