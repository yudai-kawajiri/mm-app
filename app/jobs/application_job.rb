# frozen_string_literal: true

#
# 機能: アプリケーション全体のジョブ基底クラス
#
# 用途:
# - すべてのバックグラウンドジョブの親クラス
# - 共通のエラーハンドリング設定
# - リトライ・破棄ポリシーの定義
#
# 設定可能な項目:
# - retry_on: 特定のエラー時に自動リトライ
# - discard_on: 特定のエラー時にジョブを破棄
#
# 使用例:
#   class MyJob < ApplicationJob
#     def perform(user_id)
#       # ジョブ処理
#     end
#   end
#
class ApplicationJob < ActiveJob::Base
  # Automatically retry jobs that encountered a deadlock
  # デッドロック発生時に自動リトライ（必要に応じてコメント解除）
  # retry_on ActiveRecord::Deadlocked

  # Most jobs are safe to ignore if the underlying records are no longer available
  # レコードが存在しない場合はジョブを破棄（必要に応じてコメント解除）
  # discard_on ActiveJob::DeserializationError
end
