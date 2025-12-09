# frozen_string_literal: true

# I18n設定
I18n.available_locales = [ :ja, :en ]
I18n.default_locale = :ja

# フォールバックロケール設定
I18n.fallbacks = [ I18n.default_locale ]
