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
  def terms; end

  # プライバシーポリシーページ
  #
  # @return [void]
  def privacy; end
end
