import { Controller } from "@hotwired/stimulus"

// テキストエリアの文字数をリアルタイムでカウント
export default class extends Controller {
  static targets = ["input", "count", "remaining"]
  static values = {
    max: Number // 最大文字数
  }

  connect() {
    console.log("🔢 Character counter controller connected")
    // 初期値を設定
    this.updateCount()
  }

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
