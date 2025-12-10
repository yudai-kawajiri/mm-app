# frozen_string_literal: true

# Static Pages Controller
#
# 静的ページ管理
#
# 機能:
# - 利用規約ページの表示
# - プライバシーポリシーページの表示
#
# 認証: 未ログインユーザーもアクセス可能
class StaticPagesController < ApplicationController
  # 利用規約ページ
  #
  # @return [void]
  def terms
    # 利用規約を表示
  end

  # プライバシーポリシーページ
  #
  # @return [void]
  def privacy
    # プライバシーポリシーを表示
  end
end
