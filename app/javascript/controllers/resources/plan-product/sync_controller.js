// app/javascript/controllers/resources/plan-product/sync_controller.js
import { Controller } from "@hotwired/stimulus"
import Logger from "utils/logger"

/**
 * 製造計画：タブ間同期コントローラー
 * 商品選択・数量入力を全タブに同期
 */
export default class extends Controller {
  // ============================================================
  // 商品選択の同期
  // ============================================================

  /**
   * 商品選択を他のタブに同期
   * @param {Event} event - change イベント
   */
  syncProductToOtherTabs(event) {
    const selectElement = event.currentTarget
    const selectedProductId = selectElement.value
    const uniqueRowId = selectElement.dataset.rowUniqueId

    Logger.log(`🔄 Sync product: ${selectedProductId} for row: ${uniqueRowId}`)

    const allMatchingSelects = document.querySelectorAll(`select[data-row-unique-id="${uniqueRowId}"]`)

    allMatchingSelects.forEach(select => {
      if (select !== selectElement && select.value !== selectedProductId) {
        select.value = selectedProductId

        // イベントを発火（ただし同期は防ぐ）
        const changeEvent = new Event('change', { bubbles: true })
        select.dispatchEvent(changeEvent)
      }
    })
  }

  // ============================================================
  // 数量入力の同期
  // ============================================================

  /**
   * 数量を他のタブに同期
   * @param {Event} event - input イベント
   */
  syncQuantityToOtherTabs(event) {
    const inputElement = event.currentTarget
    const quantity = inputElement.value
    const uniqueRowId = inputElement.dataset.rowUniqueId

    Logger.log(`🔄 Sync quantity: ${quantity} for row: ${uniqueRowId}`)

    const allMatchingInputs = document.querySelectorAll(
      `input[data-resources--plan-product--row-target="productionCount"][data-row-unique-id="${uniqueRowId}"]`
    )

    allMatchingInputs.forEach(input => {
      if (input !== inputElement && input.value !== quantity) {
        input.value = quantity

        // イベントを発火（ただし同期は防ぐ）
        const inputEvent = new Event('input', { bubbles: true })
        input.dispatchEvent(inputEvent)
      }
    })
  }
}
