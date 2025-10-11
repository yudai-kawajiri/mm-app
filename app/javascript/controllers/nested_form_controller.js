import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  // target: 挿入先 (div), template: ひな形 (templateタグ)
  static targets = [ "target", "template" ]

  add(event) {
    // 遷移の前に実施
    event.preventDefault()

    let content = this.templateTarget.innerHTML

    // NEW_RECORDをユニークなID（タイムスタンプ）に置換
    content = content.replace(/NEW_RECORD/g, new Date().getTime())

    // フォームの指定位置に行を挿入
    this.targetTarget.insertAdjacentHTML('beforeend', content)
  }
}