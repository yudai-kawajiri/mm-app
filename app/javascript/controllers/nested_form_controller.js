//  商品の行の追加・削除

import { Controller } from "@hotwired/stimulus"

export default class extends Controller {

  // 1. 追加イベント
  add(event) {
    event.preventDefault()

    //  クリックされたボタンから categoryId と templateId を取得
    const categoryId = event.target.dataset.categoryId
    const templateId = event.target.dataset.templateId

    if (!categoryId || !templateId) {
      console.error("Missing categoryId or templateId on button.")
      return
    }

    // 2. DOM全体から、対応する template と target コンテナを動的に検索
    //    targetコンテナ: data-nested-form-target="target" と data-category-id が一致するもの
    //    template: idが一致するもの (DOM全体から取得)
    const targetContainer = this.element.querySelector(`[data-nested-form-target="target"][data-category-id="${categoryId}"]`)
    const template = document.getElementById(templateId)

    if (!targetContainer || !template) {
      console.error(`Target container (Category ID: ${categoryId}) or template (ID: ${templateId}) not found.`)
      return
    }

    // 3. テンプレート処理と挿入
    let content = template.innerHTML

    // NEW_RECORDをユニークなID（タイムスタンプ）に置換
    content = content.replace(/NEW_RECORD/g, new Date().getTime())

    // フォームの指定位置に行を挿入
    targetContainer.insertAdjacentHTML('beforeend', content)

    console.log(`New field added to Category ID: ${categoryId}`)
  }
}