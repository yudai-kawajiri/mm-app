// Stimulus Application の初期化とデバッグモード設定
//
// Stimulusフレームワークの起動とグローバル設定を行う
// 開発環境では常にデバッグモードを有効化し、ブラウザコンソールからアクセス可能にする

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

// Rails の環境変数を使用してデバッグモードを設定
// 開発環境では常にデバッグモードを有効化
application.debug = DEBUG_CONFIG.ENABLED

// デバッグ用: ブラウザコンソールから Stimulus にアクセス可能
window[GLOBAL_OBJECT.STIMULUS] = application
Logger.log(LOG_MESSAGES.DEBUG_MODE_ENABLED)

export { application }
