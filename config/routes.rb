Rails.application.routes.draw do

  # Deviseのルート定義
  devise_for :users

  # アプリケーションのルート設定

  # Deviseのログイン画面をアプリケーションのルート ( "/") に設定する
  # devise_scopeを使うことで、DeviseにUserモデルのコンテキストを教えている
  devise_scope :user do
    root to: 'devise/sessions#new' # ログイン画面 (/users/sign_in) へルーティング
  end
end

