// Character Counter Controller
//
// テキストエリアの文字数カウントと色分け表示
//
// 使用例:
//   <div data-controller="input--character-counter" data-input--character-counter-max-value="500">
//     <textarea
//       data-input--character-counter-target="input"
//       data-action="input->input--character-counter#updateCount"
//       maxlength="500"
//     ></textarea>
//     <div class="form-text">
//       <span data-input--character-counter-target="count">0</span> / 500 文字
//       （残り <span data-input--character-counter-target="remaining">500</span> 文字）
//     </div>
//   </div>
//
// 機能:
// - リアルタイム文字数カウント
// - 残り文字数の色分け表示
//   - 10%未満: 赤色（text-danger）
//   - 20%未満: 黄色（text-warning）
//   - それ以上: グレー（text-muted）

import { Controller } from "@hotwired/stimulus"
import Logger from "utils/logger"

const THRESHOLD = {
  DANGER: 0.1,
  WARNING: 0.2
}

const CSS_CLASS = {
  DANGER: 'text-danger',
  WARNING: 'text-warning',
  MUTED: 'text-muted'
}

export default class extends Controller {
  static targets = ["input", "count", "remaining"]
  static values = {
    max: Number
  }

  // コントローラー接続時の処理
  // 初期値を設定して文字数カウントを表示
  connect() {
    Logger.log('Character counter controller connected')
    this.updateCount()
  }

  // 文字数カウントを更新
  // 現在の入力文字数を取得し、カウント表示と残り文字数を更新
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

      // 残り文字数に応じて色を変更
      this.updateRemainingColor(remaining, maxLength)
    }
  }

  // 残り文字数の色を更新
  // 残り文字数の割合に応じて警告色を適用
  updateRemainingColor(remaining, maxLength) {
    const ratio = remaining / maxLength

    if (ratio < THRESHOLD.DANGER) {
      this.remainingTarget.classList.add(CSS_CLASS.DANGER)
      this.remainingTarget.classList.remove(CSS_CLASS.WARNING, CSS_CLASS.MUTED)
    } else if (ratio < THRESHOLD.WARNING) {
      this.remainingTarget.classList.add(CSS_CLASS.WARNING)
      this.remainingTarget.classList.remove(CSS_CLASS.DANGER, CSS_CLASS.MUTED)
    } else {
      this.remainingTarget.classList.add(CSS_CLASS.MUTED)
      this.remainingTarget.classList.remove(CSS_CLASS.DANGER, CSS_CLASS.WARNING)
    }
  }
}
