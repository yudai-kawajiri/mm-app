import { Controller } from "@hotwired/stimulus"

// 計測方法（重量/個数）の切り替えを制御
export default class extends Controller {
  static targets = [
    "weightFields",    // 重量ベースのフィールド群
    "countFields"      // 個数ベースのフィールド群
  ]

  connect() {
    // 初期表示時に選択されている計測方法に応じて表示を切り替え
    this.toggleFields()
  }

  // 計測方法が変更されたときに呼ばれる
  toggleFields() {
    const selectedType = this.element.querySelector('input[name="material[measurement_type]"]:checked')?.value

    if (selectedType === 'weight') {
      // 重量ベース選択時
      this.weightFieldsTarget.style.display = ''
      this.countFieldsTarget.style.display = 'none'
    } else if (selectedType === 'count') {
      // 個数ベース選択時
      this.weightFieldsTarget.style.display = 'none'
      this.countFieldsTarget.style.display = ''
    }
  }
}
