// Stimulus アプリケーション設定
//
// Stimulusアプリケーションインスタンスの初期化と設定を行う
// 開発環境ではデバッグモードを有効化し、ブラウザコンソールから
// Stimulusインスタンスにアクセス可能にする
//
// 機能:
// - 開発環境でのデバッグモード有効化
// - コントローラー接続時のコンソールログ
// - window.Stimulusでのグローバルアクセス
//
// 使用例（ブラウザコンソールからのアクセス）:
//   // 登録済みコントローラーの確認
//   window.Stimulus.router.modules
//
//   // コントローラーインスタンスの取得
//   const controller = window.Stimulus.getControllerForElementAndIdentifier(element, "flash")

import "@hotwired/turbo-rails"
import { Application } from "@hotwired/stimulus"
import Logger from "utils/logger"

// グローバルオブジェクト名
const GLOBAL_OBJECT = {
  STIMULUS: 'Stimulus'
}

// デバッグモード設定
const DEBUG_CONFIG = {
  ENABLED: true  // 開発環境では常にデバッグモードを有効化
}

// ログメッセージ
const LOG_MESSAGES = {
  DEBUG_MODE_ENABLED: 'Stimulus debug mode enabled'
}

// Stimulusアプリケーションを起動
const application = Application.start()

// Rails環境変数を使用してデバッグモードを設定
// 開発環境では常にデバッグモードを有効化
application.debug = DEBUG_CONFIG.ENABLED

// デバッグ用: ブラウザコンソールからStimulusにアクセス可能
window[GLOBAL_OBJECT.STIMULUS] = application
Logger.log(LOG_MESSAGES.DEBUG_MODE_ENABLED)

export { application }

// コントローラーの読み込み（importmap経由）
import "controllers/index"
