Rails.application.routes.draw do

  # --- Devise (認証機能) のルート定義 ---

  # Userモデルのサインアップ、ログイン、ログアウトなどのルーティングを定義
  devise_for :users

  # --- アプリケーションのルート設定 ---

  # アプリケーションのルートパス ("/") にアクセスがあった場合、Deviseのログイン画面を表示
  root to: "devise/sessions#new"

  # --- Rails 標準機能のルート ---

  # ヘルスチェック用のルート。外部監視ツールなどがアプリの稼働状況を確認するために使用。
  get "up" => "rails/health#show", as: :rails_health_check

end
