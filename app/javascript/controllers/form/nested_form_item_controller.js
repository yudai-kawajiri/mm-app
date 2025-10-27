// app/javascript/controllers/form/nested_form_item_controller.js
import { Controller } from "@hotwired/stimulus"
import Logger from "utils/logger"

/**
 * ネストフォームの子コントローラー
 * 各行の削除ボタンを制御
 */
export default class extends Controller {
  static targets = ["destroy"]

  /**
   * 行を削除（論理削除）
   * @param {Event} event - クリックイベント
   */
  remove(event) {
    event.preventDefault()

    const row = this.element
    const uniqueId = row.dataset.uniqueId || row.dataset.rowUniqueId

    Logger.log(`🗑️ Removing row: ${uniqueId}`)

    // _destroy フラグを立てる
    if (this.hasDestroyTarget) {
      this.destroyTarget.value = "1"
    }

    // この行を非表示
    row.style.display = "none"

    // 同じunique-idを持つ他のタブの行も削除
    if (uniqueId) {
      this.removeFromOtherTabs(uniqueId)
    }

    // 合計を再計算（製造計画管理の場合のみ）
    const hasCalculation = document.querySelector('[data-resources--plan-product--totals-target]')
    if (hasCalculation) {
      setTimeout(() => {
        this.dispatch('recalculate', { prefix: 'resources--plan-product--totals', bubbles: true })
      }, 100)
    }

    Logger.log(`✅ Row removed: ${uniqueId}`)
  }

  /**
   * 他のタブから同じ行を削除
   * @param {string} uniqueId - ユニークID
   */
  removeFromOtherTabs(uniqueId) {
    const selector = `tr[data-unique-id="${uniqueId}"], tr[data-row-unique-id="${uniqueId}"]`
    const allMatchingRows = document.querySelectorAll(selector)

    allMatchingRows.forEach(row => {
      if (row !== this.element) {
        const destroyInput = row.querySelector('[data-form--nested-form-item-target="destroy"]')
        if (destroyInput) {
          destroyInput.value = "1"
        }
        row.style.display = "none"
        Logger.log(`  ↳ Also removed from other tab`)
      }
    })
  }
}
