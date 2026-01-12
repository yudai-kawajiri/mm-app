# frozen_string_literal: true

# spec/support/path_helpers.rb
# 会社スコープ付きパスヘルパー

module PathHelpers
  def scoped_path(path_method, *args, **options)
    company_slug = options[:company_slug] ||
                    @company&.slug ||
                    company&.slug ||
                    @user&.company&.slug ||
                    @current_user&.company&.slug ||
                    'test-company'

    # パスメソッド名を文字列に変換
    path_str = path_method.to_s

    # 特別なケース: dashboards は company_dashboards にマッピング
    actual_method = if path_str == 'dashboards'
      'company_dashboards'
    else
      # company_ プレフィックスを削除（すでにある場合）
      path_str.sub(/^company_/, '')
    end

    # パスまたはURLを生成
    method_name = actual_method.to_s.end_with?('_url') ? actual_method : "#{actual_method}_path"

    # company_slug をパラメータとして渡す
    send(method_name, *args, company_slug: company_slug, **options)
  end

  # 認証済みユーザー用のパスヘルパー
  def authenticated_scoped_path(path_method, *args, **options)
    scoped_path(path_method, *args, **options)
  end

  # Edit scoped path helper
  def edit_scoped_path(route_name, *args)
    scoped_path("edit_#{route_name}".to_sym, *args)
  end

  # Copy scoped path helper
  def copy_scoped_path(route_name, *args)
    scoped_path("copy_#{route_name}".to_sym, *args)
  end

  # Devise のログインパス
  def new_user_session_path
    "/users/sign_in"
  end

  # Devise のユーザー編集パス
  def edit_user_registration_path
    company_slug = @company&.slug || @user&.company&.slug || @current_user&.company&.slug || 'test-company'
    "/c/#{company_slug}/users/edit"
  end
end

RSpec.configure do |config|
  config.include PathHelpers, type: :request
  config.include PathHelpers, type: :system

  config.before(:each, type: :request) do
    # テスト用のデフォルト会社を設定
    @company ||= begin
      if defined?(company)
        company
      elsif defined?(@user) && @user&.company
        @user.company
      end
    end
  end
end
