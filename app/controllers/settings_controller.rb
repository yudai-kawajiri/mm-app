# frozen_string_literal: true

# 設定ページのコントローラー
class SettingsController < ApplicationController
  before_action :authenticate_user!

  def index
    # 設定メニューの表示
  end
end
