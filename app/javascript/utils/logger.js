// Logger - デバッグログ出力ユーティリティ
//
// デバッグモード制御可能なロガーユーティリティ
// 開発環境ではログを出力し、本番環境では抑制する
//
// 機能:
// - デバッグモードのON/OFF制御
// - 条件付きログ出力（log, warn）
// - 常時出力エラーログ（error）
//
// 使用例:
//   import Logger from "utils/logger"
//   Logger.log('情報メッセージ')      // デバッグモード時のみ出力
//   Logger.warn('警告メッセージ')     // デバッグモード時のみ出力
//   Logger.error('エラーメッセージ')  // 常に出力

// デバッグモード設定
const DEBUG_MODE = {
  ENABLED: true  // 開発中は常に true
}

// Logger クラス
class Logger {
  // デバッグモードの状態を取得
  static get isDebug() {
    return DEBUG_MODE.ENABLED
  }

  // ログ出力（デバッグモード時のみ）
  static log(...args) {
    if (this.isDebug) {
      console.log(...args)
    }
  }

  // 警告出力（デバッグモード時のみ）
  static warn(...args) {
    if (this.isDebug) {
      console.warn(...args)
    }
  }

  // エラー出力（常に出力）
  static error(...args) {
    console.error(...args)
  }
}

export default Logger
