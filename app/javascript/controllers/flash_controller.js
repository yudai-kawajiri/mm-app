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
 * @description
 *   フラッシュメッセージを自動的にフェードアウトさせるコントローラー。
 *   指定された時間が経過すると、Bootstrap のアニメーションを使って
 *   メッセージを非表示にします。
 *
 * @example HTML での使用
 *   <div data-controller="flash" data-flash-duration-value="5000">
 *     <div class="alert alert-success">保存しました</div>
 *   </div>
 *
 * @example 自動非表示を無効化（エラーメッセージなど）
 *   <div data-controller="flash" data-flash-duration-value="0">
 *     <div class="alert alert-danger">エラーが発生しました</div>
 *   </div>
 *
 * @values
 *   duration {Number} - フェードアウトまでの時間（ミリ秒、デフォルト: 5000）
 *                       0の場合は自動的に消えない
 */
export default class extends Controller {
  static values = {
    duration: { type: Number, default: 5000 } // デフォルト5秒
  }

  /**
   * コントローラー接続時の処理
   *
   * @description
   *   duration が 0 より大きい場合、指定時間後に自動的にフェードアウト。
   *   0 の場合は自動非表示を行わない（手動で閉じる必要がある）。
   */
  connect() {
    console.log('Flash message controller connected')

    // duration が 0 の場合は自動的に消さない（エラーメッセージなど）
    if (this.durationValue > 0) {
      this.timeout = setTimeout(() => {
        this.fadeOut()
      }, this.durationValue)
    }
  }

  /**
   * コントローラー切断時の処理
   *
   * @description
   *   タイムアウトをクリアしてメモリリークを防ぐ
   */
  disconnect() {
    if (this.timeout) {
      clearTimeout(this.timeout)
    }
  }

  /**
   * フェードアウトアニメーション
   *
   * @description
   *   Bootstrap の fade クラスを削除してフェードアウトし、
   *   アニメーション完了後に DOM から要素を削除します。
   */
  fadeOut() {
    // Bootstrap の fade クラスを削除してフェードアウト
    this.element.classList.remove('show')

    // アニメーション完了後に要素を削除
    setTimeout(() => {
      this.element.remove()
    }, 150) // Bootstrap の transition time
  }
}
