source "https://rubygems.org"

# 主要グループ

# Active Model has_secure_passwordを使用する場合に必要 (今回はDeviseを使用するためコメントアウト)
# gem "bcrypt", "~> 3.1.7"

# キャッシュを通じて起動時間を短縮（config/boot.rbで必要）
gem "bootsnap", require: false

# CSSのバンドルと処理を行う [https://github.com/rails/cssbundling-rails]
gem "cssbundling-rails"

# 認証機能（ログイン、ユーザー登録、パスワードリセットなど）のためのGem
gem "devise"

# イーナムの翻訳簡素化
gem "enum_help"

# JavaScript の管理
gem "importmap-rails"


# JSON APIを簡単に構築するためのGem [https://github.com/rails/jbuilder]
gem "jbuilder"

# JavaScriptのバンドルとトランスパイルを行う [https://github.com/rails/jsbundling-rails]
gem "jsbundling-rails"

# DockerコンテナとしてデプロイするためのGem [https://kamal-deploy.org]
gem "kamal", require: false

# ページネーション機能を提供するGem [https://github.com/kaminari/kaminari]
gem "kaminari", "1.2.2"

# ネストフォーム機能を提供するGem
gem "cocoon"

# cocoonはjQueryに依存するため、Rails 7/8環境で必要
gem "jquery-rails"

# KaminariのBootstrap5対応ビューテンプレート [https://github.com/bootstrap-ruby/bootstrap_form]
gem "bootstrap5-kaminari-views"

# データベースとしてPostgreSQLを使用するためのGem
gem "pg", "~> 1.1"

# Railsのモダンなアセットパイプライン [https://github.com/rails/propshaft]
gem "propshaft"

# WebサーバーとしてPumaを使用
gem "puma", ">= 5.0"

# Railsのバージョン指定
gem "rails", "~> 8.1.0"

# Active Storageの画像変換機能（variants）を使用する場合に必要
gem "image_processing", "~> 1.2"

# MiniMagick本体のGemを追加
# gem "mini_magick"

# Rails.cache, Active Job, Action Cableのためのデータベースバックアップアダプタ (Action Cable用)
gem "solid_cable"

# Rails.cache, Active Job, Action Cableのためのデータベースバックアップアダプタ (Cache用)
gem "solid_cache"

# Rails.cache, Active Job, Action Cableのためのデータベースバックアップアダプタ (Active Job/Queue用)
gem "solid_queue"

# HotwireのJavaScriptフレームワーク [https://stimulus.hotwired.dev]
gem "stimulus-rails"

# PumaにHTTPアセットキャッシング/圧縮機能などを追加 [https://github.com/basecamp/thruster/]
gem "thruster", require: false

# Hotwireのページ高速化ライブラリ [https://turbo.hotwired.dev]
gem "turbo-rails"

# WindowsやJRuby環境でタイムゾーン情報ファイルを提供
gem "tzinfo-data", platforms: %i[ windows jruby ]


# --- 開発環境とテスト環境で必要なGem ---
group :development, :test do
  # セキュリティ脆弱性の静的解析ツール [https://brakemanscanner.org/]
  gem "brakeman", require: false

  # 実行を停止し、変数の値を確認するための対話型デバッガ
  gem "byebug", platforms: [ :mri, :mingw, :x64_mingw ]

  # .envファイルから環境変数をロードし、APIキーなどの機密情報を安全に管理
  gem "dotenv-rails"

  # デバッグに使用するGem [https://guides.rubyonrails.org/debugging_rails_applications.html]
  gem "debug", platforms: %i[ mri windows ], require: "debug/prelude"

  # OpenWeatherMap APIとの通信に使用
  gem "httparty"

  # Rubyのコーディング規約チェック（RuboCop Rails Omakaseスタイル）
  gem "rubocop-rails-omakase", require: false
end


# --- 開発環境で必要なGem ---
group :development do
  # 例外ページでコンソールを使用可能にする [https://github.com/rails/web-console]
  gem "web-console"

  # メール送信内容をブラウザで確認するGem
  gem "mailcatcher"
end


# --- テスト環境で必要なGem ---
group :test do
  # システムテスト（ブラウザ操作をシミュレーションするテスト）に使用
  gem "capybara"
  # Capybaraがブラウザを操作するために使用するドライバー
  gem "selenium-webdriver"
end