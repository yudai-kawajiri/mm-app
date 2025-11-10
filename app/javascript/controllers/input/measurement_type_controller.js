/**
 * @file measurement_type_controller.js
 * 計測方法（重量/個数）の切り替え制御
 *
 * @module Controllers
 */

import { Controller } from "@hotwired/stimulus"

/**
 * Measurement Type Controller
 *
 * @description
 *   計測方法（重量ベース/個数ベース）の切り替えを制御するコントローラー。
 *   選択に応じて対応するフィールド群の表示/非表示とクリアを行います。
 *
 * @example HTML での使用
 *   <div data-controller="measurement-type">
 *     <!-- ラジオボタン -->
 *     <input
 *       type="radio"
 *       name="material[measurement_type]"
 *       value="weight"
 *       data-action="change->measurement-type#toggleFields"
 *     /> 重量ベース
 *     <input
 *       type="radio"
 *       name="material[measurement_type]"
 *       value="count"
 *       data-action="change->measurement-type#toggleFields"
 *     /> 個数ベース
 *
 *     <!-- 重量ベースのフィールド -->
 *     <div data-measurement-type-target="weightFields">
 *       <span data-measurement-type-target="weightLabel">単価（円/g）</span>
 *       <input type="number" name="material[price_per_gram]" />
 *     </div>
 *
 *     <!-- 個数ベースのフィールド -->
 *     <div data-measurement-type-target="countFields">
 *       <span data-measurement-type-target="countLabel">単価（円/個）</span>
 *       <input type="number" name="material[price_per_piece]" />
 *     </div>
 *   </div>
 *
 * @targets
 *   weightFields - 重量ベースのフィールド群
 *   countFields - 個数ベースのフィールド群
 *   weightLabel - 重量ベースのラベル
 *   countLabel - 個数ベースのラベル
 *
 * @features
 *   - ラジオボタン切り替えによるフィールド表示制御
 *   - 非表示になったフィールドの自動クリア
 *   - ラベルの動的切り替え
 *   - unit_for_order_id は両方で共通使用のため保持
 */
export default class extends Controller {
  static targets = [
    "weightFields",    // 重量ベースのフィールド群
    "countFields",     // 個数ベースのフィールド群
    "weightLabel",     // 重量ベースのラベル
    "countLabel"       // 個数ベースのラベル
  ]

  /**
   * コントローラー接続時の処理
   *
   * @description
   *   初期表示時に選択されている計測方法に応じて表示を切り替え
   */
  connect() {
    console.log('Measurement type controller connected')
    console.log('weightLabelTarget exists:', this.hasWeightLabelTarget)
    console.log('countLabelTarget exists:', this.hasCountLabelTarget)
    // 初期表示時に選択されている計測方法に応じて表示を切り替え
    this.toggleFields()
  }

  /**
   * 計測方法が変更されたときの処理
   *
   * @description
   *   選択された計測方法（weight/count）に応じて：
   *   - 対応するフィールド群を表示
   *   - 非対応のフィールド群を非表示＋クリア
   *   - ラベルを切り替え
   */
  toggleFields() {
    const selectedType = this.element.querySelector('input[name*="[measurement_type]"]:checked')?.value
    console.log('toggleFields called, selectedType:', selectedType)

    if (selectedType === 'weight') {
      // 重量ベース選択時
      this.weightFieldsTarget.style.display = ''
      this.countFieldsTarget.style.display = 'none'

      // ラベルを切り替え
      if (this.hasWeightLabelTarget && this.hasCountLabelTarget) {
        this.weightLabelTarget.style.display = 'inline'
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
        this.countLabelTarget.style.display = 'inline'
        console.log('Label switched to count')
      }

      console.log('Switching to count, clearing weight fields...')
      // 重量ベースのフィールドをクリア
      this.clearFields(this.weightFieldsTarget)
    }
  }

  /**
   * フィールドの値をクリアするヘルパーメソッド
   *
   * @param {HTMLElement} container - クリア対象のコンテナ要素
   *
   * @description
   *   指定されたコンテナ内の以下の要素をクリア：
   *   - input[type="number"] の値
   *   - select の値（ただし unit_for_order_id を除く）
   *
   * @note
   *   unit_for_order_id は両方の計測方法で共通使用のため保持
   */
  clearFields(container) {
    console.log('clearFields called, container:', container)

    // number型の入力フィールドをクリア
    const numberInputs = container.querySelectorAll('input:not([name*="unit_for_order"])')
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
