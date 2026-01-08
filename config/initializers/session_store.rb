if Rails.env.production?
  # 本番環境：Redis セッションストア
  Rails.application.config.session_store :redis_store,
    servers: ENV.fetch("REDIS_URL", "redis://localhost:6379/0"),
    expire_after: 90.minutes,
    key: "_mm_app_session",
    threadsafe: true,
    secure: true,
    httponly: true,
    same_site: :lax
else
  # 開発環境：Cookie ストア
  Rails.application.config.session_store :cookie_store,
    key: "_mm_app_session",
    domain: :all,
    secure: false,
    httponly: true,
    same_site: :lax
end
