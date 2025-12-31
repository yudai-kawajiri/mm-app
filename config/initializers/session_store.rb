Rails.application.config.session_store :cookie_store,
  key: "_mm_app_session",
  secure: Rails.env.production?,
  httponly: true,
  same_site: :lax
