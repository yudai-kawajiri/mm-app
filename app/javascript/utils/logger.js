/**
 * @file utils/logger.js
 * デバッグログ出力ユーティリティ
 *
 * @module Utils
 */

/**
 * Logger クラス
 *
 * デバッグモード制御可能なロガーユーティリティ。
 * 開発環境ではログを出力し、本番環境では抑制する。
 *
 * 機能:
 * - デバッグモードのON/OFF制御
 * - 条件付きログ出力（log, warn）
 * - 常時出力エラーログ（error）
 *
 * @example 使用例
 *   import Logger from "utils/logger"
 *
 *   Logger.log('情報メッセージ')      // デバッグモード時のみ出力
 *   Logger.warn('警告メッセージ')     // デバッグモード時のみ出力
 *   Logger.error('エラーメッセージ')  // 常に出力
 */
class Logger {
  /**
   * デバッグモードの状態を取得
   *
   * @return {boolean} デバッグモードが有効な場合true
   */
  static get isDebug() {
    return true  // 開発中は常に true
  }

  /**
   * ログ出力（デバッグモード時のみ）
   *
   * @param {...*} args - 出力する引数（複数可）
   */
  static log(...args) {
    if (this.isDebug) {
      console.log(...args)
    }
  }

  /**
   * 警告出力（デバッグモード時のみ）
   *
   * @param {...*} args - 出力する引数（複数可）
   */
  static warn(...args) {
    if (this.isDebug) {
      console.warn(...args)
    }
  }

  /**
   * エラー出力（常に出力）
   *
   * @param {...*} args - 出力する引数（複数可）
   */
  static error(...args) {
    console.error(...args)
  }
}

export default Logger
