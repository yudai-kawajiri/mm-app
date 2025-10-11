import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  // destroy: _destroy hiddenフィールド
  static targets = [ "destroy" ]

  remove(event) {
    event.preventDefault()

    // 既存レコード（_destroy targetがある）の場合
    if (this.destroyTarget) {
      // _destroy フィールドを '1' に設定して非表示
      this.destroyTarget.value = '1'
      this.element.style.display = 'none'
    }else {
      // 新規レコードの場合
      // DOMから要素を完全に削除
      this.element.remove()
    }
  }
}
