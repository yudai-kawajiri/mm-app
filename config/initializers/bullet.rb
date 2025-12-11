# frozen_string_literal: true

if defined?(Bullet) && Rails.env.development?
  Bullet.enable = true
  Bullet.alert = false
  Bullet.bullet_logger = true
  Bullet.console = true
  Bullet.rails_logger = true
  Bullet.add_footer = true
end
