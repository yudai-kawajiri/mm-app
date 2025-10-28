import { Controller } from "@hotwired/stimulus"

// フラッシュメッセージを自動的にフェードアウトさせる
export default class extends Controller {
  static values = {
    duration: { type: Number, default: 5000 } // デフォルト5秒
  }

  connect() {
    console.log("💬 Flash message controller connected")

    // duration が 0 の場合は自動的に消さない（エラーメッセージなど）
    if (this.durationValue > 0) {
      this.timeout = setTimeout(() => {
        this.fadeOut()
      }, this.durationValue)
    }
  }

  disconnect() {
    if (this.timeout) {
      clearTimeout(this.timeout)
    }
  }

  fadeOut() {
    // Bootstrap の fade クラスを削除してフェードアウト
    this.element.classList.remove('show')

    // アニメーション完了後に要素を削除
    setTimeout(() => {
      this.element.remove()
    }, 150) // Bootstrap の transition time
  }
}
