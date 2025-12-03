// Measurement Type Controller
//
// 計測方法（重量ベース/個数ベース）の切り替えを制御するStimulusコントローラー
//
// 使用例:
//   <div data-controller="input--measurement-type">
//     <select data-input--measurement-type-target="typeSelect" data-action="change->input--measurement-type#toggle">
//       <option value="weight">重量ベース</option>
//       <option value="count">個数ベース</option>
//     </select>
//     <div data-input--measurement-type-target="weightFields">...</div>
//     <div data-input--measurement-type-target="countFields">...</div>
//   </div>
//
// 機能:
// - 計測タイプ選択に応じて対応するフィールド群を表示/非表示
// - 非表示フィールドの入力値を自動クリア
// - ページロード時に初期状態を設定

import { Controller } from "@hotwired/stimulus"
import Logger from "utils/logger"

// 定数定義
const MEASUREMENT_TYPE = {
  WEIGHT: 'weight',
  COUNT: 'count'
}

const DISPLAY_STYLE = {
  SHOW: '',
  HIDE: 'none',
  INLINE: 'inline'
}

const LOG_MESSAGES = {
  INITIALIZED: 'Measurement type controller initialized',
  TYPE_CHANGED: 'Measurement type changed'
}

export default class extends Controller {
  static targets = ["typeSelect", "weightFields", "countFields"]

  // コントローラー接続時の初期化
  connect() {
    Logger.log(LOG_MESSAGES.INITIALIZED)
    this.toggle()
  }

  // 計測タイプに応じてフィールドの表示/非表示を切り替え
  toggle() {
    const selectedType = this.typeSelectTarget.value
    Logger.log(LOG_MESSAGES.TYPE_CHANGED, { selectedType })

    if (selectedType === MEASUREMENT_TYPE.WEIGHT) {
      this.showWeightFields()
      this.hideCountFields()
    } else if (selectedType === MEASUREMENT_TYPE.COUNT) {
      this.hideWeightFields()
      this.showCountFields()
    }
  }

  // 重量ベースフィールドを表示
  showWeightFields() {
    this.weightFieldsTarget.style.display = DISPLAY_STYLE.INLINE
  }

  // 重量ベースフィールドを非表示にして入力値をクリア
  hideWeightFields() {
    this.weightFieldsTarget.style.display = DISPLAY_STYLE.HIDE
    this.clearInputs(this.weightFieldsTarget)
  }

  // 個数ベースフィールドを表示
  showCountFields() {
    this.countFieldsTarget.style.display = DISPLAY_STYLE.INLINE
  }

  // 個数ベースフィールドを非表示にして入力値をクリア
  hideCountFields() {
    this.countFieldsTarget.style.display = DISPLAY_STYLE.HIDE
    this.clearInputs(this.countFieldsTarget)
  }

  // 指定要素内の全入力フィールドの値をクリア
  clearInputs(container) {
    const inputs = container.querySelectorAll('input, select, textarea')
    inputs.forEach(input => {
      if (input.type === 'checkbox' || input.type === 'radio') {
        input.checked = false
      } else {
        input.value = ''
      }
    })
  }
}
