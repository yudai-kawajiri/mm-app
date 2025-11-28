# frozen_string_literal: true

# ヘルプ・使い方ページのコントローラー
class HelpController < ApplicationController
  before_action :authenticate_user!

  def index
    # 使い方動画とFAQの表示
  end
end
