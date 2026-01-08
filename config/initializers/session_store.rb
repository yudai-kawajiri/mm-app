if Rails.env.production?
  # 本番環境：mm-app-system.com とその全てのサブドメインでログイン状態を共有
  Rails.application.config.session_store :cookie_store,
    key: "_mm_app_session",
    domain: :all,
    secure: true,
    httponly: true,
    same_site: :lax
else
  # 開発環境：localhost用
  Rails.application.config.session_store :cookie_store,
    key: "_mm_app_session",
    domain: :all,
    secure: false,
    httponly: true,
    same_site: :lax
end
