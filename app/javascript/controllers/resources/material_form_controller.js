// Material Form Controller
//
// 原材料フォームの制御
//
// 機能:
// - measurement_type(重量ベース/個数ベース)の切り替え
// - フィールド表示/非表示の切り替え
// - 非表示フィールドの値クリア
//
// 使用例:
//   <div data-controller="resources--material-form">
//     <input type="radio" data-action="change->resources--material-form#toggleMeasurementFields" />
//     <div data-resources--material-form-target="weightField">...</div>
//     <div data-resources--material-form-target="countField">...</div>
//   </div>

import { Controller } from "@hotwired/stimulus"
import Logger from "utils/logger"

const LOG_MESSAGES = {
  CONTROLLER_CONNECTED: 'Material form controller connected',
  TOGGLING_FIELDS: 'Toggling measurement fields',
  WEIGHT_SELECTED: 'Weight measurement type selected',
  COUNT_SELECTED: 'Count measurement type selected',
  CLEARING_FIELD: (fieldName) => `Clearing ${fieldName} field`,
  FIELD_VALUE_CLEARED: (fieldName, oldValue) => `${fieldName} cleared (was: ${oldValue})`
}

export default class extends Controller {
  static targets = ['weightField', 'countField']

  // ============================================================
  // 初期化
  // ============================================================

  connect() {
    Logger.log(LOG_MESSAGES.CONTROLLER_CONNECTED)
    this.toggleMeasurementFields()
  }

  // ============================================================
  // measurement_type 切り替え
  // ============================================================

  toggleMeasurementFields() {
    Logger.log(LOG_MESSAGES.TOGGLING_FIELDS)

    const weightRadio = this.element.querySelector('input[type="radio"][value="weight"]')
    const countRadio = this.element.querySelector('input[type="radio"][value="count"]')

    if (!weightRadio || !countRadio) {
      Logger.warn('Radio buttons not found')
      return
    }

    const isWeight = weightRadio.checked
    const isCount = countRadio.checked

    if (!this.hasWeightFieldTarget || !this.hasCountFieldTarget) {
      Logger.warn('Field targets not found')
      return
    }

    if (isWeight) {
      Logger.log(LOG_MESSAGES.WEIGHT_SELECTED)
      // 重量ベースを表示、個数ベースを非表示
      this.weightFieldTarget.style.display = 'block'
      this.countFieldTarget.style.display = 'none'
      // 個数ベースの値をクリア
      this.clearFieldValue(this.countFieldTarget, 'pieces_per_order_unit')
    } else if (isCount) {
      Logger.log(LOG_MESSAGES.COUNT_SELECTED)
      // 個数ベースを表示、重量ベースを非表示
      this.weightFieldTarget.style.display = 'none'
      this.countFieldTarget.style.display = 'block'
      // 重量ベースの値をクリア
      this.clearFieldValue(this.weightFieldTarget, 'unit_weight_for_order')
    }
  }

  // ============================================================
  // フィールド値クリア
  // ============================================================

  clearFieldValue(fieldContainer, fieldName) {
    const input = fieldContainer.querySelector('input[type="text"]')
    if (input && input.value) {
      Logger.log(LOG_MESSAGES.CLEARING_FIELD(fieldName))
      const oldValue = input.value
      input.value = ''
      // input--number-inputコントローラーに変更を通知
      input.dispatchEvent(new Event('input', { bubbles: true }))
      Logger.log(LOG_MESSAGES.FIELD_VALUE_CLEARED(fieldName, oldValue))
    }
  }
}
