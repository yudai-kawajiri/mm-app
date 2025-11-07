import { Controller } from "@hotwired/stimulus"

// 計測方法（重量/個数）の切り替えを制御
export default class extends Controller {
  static targets = [
    "weightFields",    // 重量ベースのフィールド群
    "countFields",     // 個数ベースのフィールド群
    "weightLabel",     // 重量ベースのラベル
    "countLabel"       // 個数ベースのラベル
  ]

  connect() {
    console.log('measurement-type controller connected')
    console.log('weightLabelTarget exists:', this.hasWeightLabelTarget)
    console.log('countLabelTarget exists:', this.hasCountLabelTarget)
    // 初期表示時に選択されている計測方法に応じて表示を切り替え
    this.toggleFields()
  }

  // 計測方法が変更されたときに呼ばれる
  toggleFields() {
    const selectedType = this.element.querySelector('input[name="material[measurement_type]"]:checked')?.value
    console.log('toggleFields called, selectedType:', selectedType)

    if (selectedType === 'weight') {
      // 重量ベース選択時
      this.weightFieldsTarget.style.display = ''
      this.countFieldsTarget.style.display = 'none'

      // ラベルを切り替え
      if (this.hasWeightLabelTarget && this.hasCountLabelTarget) {
        this.weightLabelTarget.style.display = ''
        this.countLabelTarget.style.display = 'none'
        console.log('Label switched to weight')
      }

      console.log('Switching to weight, clearing count fields...')
      // 個数ベースのフィールドをクリア
      this.clearFields(this.countFieldsTarget)
    } else if (selectedType === 'count') {
      // 個数ベース選択時
      this.weightFieldsTarget.style.display = 'none'
      this.countFieldsTarget.style.display = ''

      // ラベルを切り替え
      if (this.hasWeightLabelTarget && this.hasCountLabelTarget) {
        this.weightLabelTarget.style.display = 'none'
        this.countLabelTarget.style.display = ''
        console.log('Label switched to count')
      }

      console.log('Switching to count, clearing weight fields...')
      // 重量ベースのフィールドをクリア
      this.clearFields(this.weightFieldsTarget)
    }
  }

  // フィールドの値をクリアするヘルパーメソッド
  clearFields(container) {
    console.log('clearFields called, container:', container)

    // number型の入力フィールドをクリア
    const numberInputs = container.querySelectorAll('input[type="number"]')
    console.log('Found number inputs:', numberInputs.length)

    numberInputs.forEach(input => {
      console.log('Clearing input:', input.name, 'value was:', input.value)
      input.value = ''
    })

    // select要素をクリア（発注単位のセレクトボックス）
    const selects = container.querySelectorAll('select')
    console.log('Found selects:', selects.length)

    selects.forEach(select => {
      // unit_for_order_idはクリアしない（両方で共通使用のため）
      if (!select.name.includes('unit_for_order_id')) {
        console.log('Clearing select:', select.name, 'value was:', select.value)
        select.value = ''
      } else {
        console.log('Skipping select:', select.name)
      }
    })
  }
}