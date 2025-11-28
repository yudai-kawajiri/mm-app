// Stimulus アプリケーション設定
import "@hotwired/turbo-rails"
import { Application } from "@hotwired/stimulus"
import Logger from "utils/logger"
import CurrencyFormatter from "utils/currency_formatter"

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
application.debug = DEBUG_CONFIG.ENABLED

// デバッグ用: ブラウザコンソールからStimulusにアクセス可能
window[GLOBAL_OBJECT.STIMULUS] = application
Logger.log(LOG_MESSAGES.DEBUG_MODE_ENABLED)

window.CurrencyFormatter = CurrencyFormatter

export { application }
