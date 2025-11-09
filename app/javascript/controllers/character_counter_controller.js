/**
 * @file character_counter_controller.js
 * テキストエリアの文字数カウントと色分け表示
 *
 * @module Controllers
 */

import { Controller } from "@hotwired/stimulus"

/**
 * Character Counter Controller
 *
 * @description
 *   テキストエリアの文字数をリアルタイムでカウントし、
 *   残り文字数に応じて色を変更します。
 *
 * @example HTML での使用
 *   <div data-controller="character-counter" data-character-counter-max-value="500">
 *     <textarea
 *       data-character-counter-target="input"
 *       data-action="input->character-counter#updateCount"
 *       maxlength="500"
 *     ></textarea>
 *     <div class="form-text">
 *       <span data-character-counter-target="count">0</span> / 500 文字
 *       （残り <span data-character-counter-target="remaining">500</span> 文字）
 *     </div>
 *   </div>
 *
 * @targets
 *   input - カウント対象のテキストエリア/インプット
 *   count - 現在の文字数表示
 *   remaining - 残り文字数表示
 *
 * @values
 *   max {Number} - 最大文字数
 *
 * @features
 *   - リアルタイム文字数カウント
 *   - 残り文字数の色分け表示
 *     - 10%未満: 赤色（text-danger）
 *     - 20%未満: 黄色（text-warning）
 *     - それ以上: グレー（text-muted）
 */
export default class extends Controller {
  static targets = ["input", "count", "remaining"]
  static values = {
    max: Number // 最大文字数
  }

  /**
   * コントローラー接続時の処理
   *
   * @description
   *   初期値を設定して文字数カウントを表示
   */
  connect() {
    console.log('Character counter controller connected')
    // 初期値を設定
    this.updateCount()
  }

  /**
   * 文字数カウントを更新
   *
   * @description
   *   現在の入力文字数を取得し、カウント表示と残り文字数を更新。
   *   残り文字数が少なくなると警告色に変化します。
   */
  updateCount() {
    const currentLength = this.inputTarget.value.length
    const maxLength = this.maxValue || this.inputTarget.maxLength

    // カウント表示を更新
    if (this.hasCountTarget) {
      this.countTarget.textContent = currentLength
    }

    // 残り文字数表示を更新
    if (this.hasRemainingTarget && maxLength > 0) {
      const remaining = maxLength - currentLength
      this.remainingTarget.textContent = remaining

      // 残り文字数が少なくなったら警告色に
      if (remaining < maxLength * 0.1) {
        // 残り10%未満で赤色
        this.remainingTarget.classList.add('text-danger')
        this.remainingTarget.classList.remove('text-warning', 'text-muted')
      } else if (remaining < maxLength * 0.2) {
        // 残り20%未満で黄色
        this.remainingTarget.classList.add('text-warning')
        this.remainingTarget.classList.remove('text-danger', 'text-muted')
      } else {
        // それ以外は通常色
        this.remainingTarget.classList.add('text-muted')
        this.remainingTarget.classList.remove('text-danger', 'text-warning')
      }
    }
  }
}
