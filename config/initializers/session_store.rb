Rails.application.config.session_store :cookie_store,
  key: "_mm_app_session",
  domain: :all,
  same_site: :lax,
  secure: Rails.env.production?,
  httponly: true
