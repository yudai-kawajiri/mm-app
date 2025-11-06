import { Controller } from "@hotwired/stimulus"

// 発注グループの選択方法（既存/新規）の切り替えを制御
export default class extends Controller {
  static targets = [
    "existingField",  // 既存グループ選択フィールド
    "newField"        // 新規グループ名入力フィールド
  ]

  connect() {
    // 初期表示時に選択されている方法に応じて表示を切り替え
    this.toggleFields()
  }

  // 選択方法が変更されたときに呼ばれる
  toggleFields() {
    const selectedMethod = this.element.querySelector('input[name="order_group_method"]:checked')?.value

    if (selectedMethod === 'existing') {
      // 既存から選択
      this.existingFieldTarget.style.display = ''
      this.newFieldTarget.style.display = 'none'
      // 新規入力フィールドのみクリア（既存選択は保持）
      const newInput = this.newFieldTarget.querySelector('input')
      if (newInput) newInput.value = ''
    } else if (selectedMethod === 'new') {
      // 新規作成
      this.existingFieldTarget.style.display = 'none'
      this.newFieldTarget.style.display = ''
      // 既存選択フィールドはクリアしない（値を保持）
    }
  }
}