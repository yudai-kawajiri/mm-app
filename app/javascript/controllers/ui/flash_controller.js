/**
 * @file flash_controller.js
 * フラッシュメッセージの自動フェードアウト制御
 *
 * @module Controllers
 */

import { Controller } from "@hotwired/stimulus"

/**
 * Flash Controller
 *
 * フラッシュメッセージを自動的にフェードアウトさせるコントローラー。
 * メッセージタイプ（notice, alert, error）に応じて自動非表示の時間を制御する。
 *
 * 表示時間:
 * - notice: 5秒後に自動非表示
 * - alert: 7秒後に自動非表示
 * - error: 自動非表示しない（手動で閉じる必要がある）
 *
 * @example HTML での使用
 *   <div data-controller="flash" data-flash-type="notice">
 *     <div class="alert alert-success">保存しました</div>
 *   </div>
 *
 * @values
 *   type {String} - フラッシュメッセージのタイプ（notice, alert, error）
 */
export default class extends Controller {
  /**
   * 表示時間定数: notice メッセージの自動非表示時間（ミリ秒）
   */
  static NOTICE_DURATION_MS = 5000

  /**
   * 表示時間定数: alert メッセージの自動非表示時間（ミリ秒）
   */
  static ALERT_DURATION_MS = 7000

  /**
   * 表示時間定数: error メッセージの自動非表示時間（ミリ秒）
   *
   * 0 = 自動非表示しない（手動で閉じる必要がある）
   */
  static ERROR_DURATION_MS = 0

  /**
   * Bootstrap transition time（ミリ秒）
   *
   * Bootstrapの公式仕様値。フェードアウトアニメーションの時間。
   */
  static BOOTSTRAP_TRANSITION_TIME_MS = 150

  /**
   * コントローラー接続時の処理
   *
   * data-flash-type 属性からメッセージタイプを取得し、
   * 対応する自動非表示時間を設定する。
   */
  connect() {
    console.log('Flash message controller connected')

    // data-flash-type 属性からタイプを取得
    const flashType = this.element.dataset.flashType
    const duration = this.getDurationForType(flashType)

    console.log(`Flash type: ${flashType}, duration: ${duration}ms`)

    // duration が 0 の場合は自動的に消さない（エラーメッセージなど）
    if (duration > 0) {
      this.timeout = setTimeout(() => {
        this.fadeOut()
      }, duration)
    }
  }

  /**
   * コントローラー切断時の処理
   *
   * タイムアウトをクリアしてメモリリークを防ぐ。
   */
  disconnect() {
    if (this.timeout) {
      clearTimeout(this.timeout)
    }
  }

  /**
   * フラッシュタイプに応じた表示時間を取得
   *
   * @param {string} type - フラッシュタイプ（notice, alert, error）
   * @return {number} 表示時間（ミリ秒）
   * @private
   */
  getDurationForType(type) {
    switch (type) {
      case 'notice':
        return this.constructor.NOTICE_DURATION_MS
      case 'alert':
        return this.constructor.ALERT_DURATION_MS
      case 'error':
        return this.constructor.ERROR_DURATION_MS
      default:
        return this.constructor.NOTICE_DURATION_MS
    }
  }

  /**
   * フェードアウトアニメーション
   *
   * Bootstrap の fade クラスを削除してフェードアウトし、
   * アニメーション完了後に DOM から要素を削除する。
   */
  fadeOut() {
    // Bootstrap の fade クラスを削除してフェードアウト
    this.element.classList.remove('show')

    // アニメーション完了後に要素を削除
    setTimeout(() => {
      this.element.remove()
    }, this.constructor.BOOTSTRAP_TRANSITION_TIME_MS)
  }
}
