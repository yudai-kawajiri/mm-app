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
      Logger.log(`✅ Set _destroy=1 for: ${this.destroyTarget.name}`)
    } else {
      Logger.error('❌ Destroy target not found')
    }

    // この行を非表示
    row.style.display = "none"

    // 同じunique-idを持つ他のタブの行も削除
    if (uniqueId) {
      this.removeFromOtherTabs(uniqueId)
    }

    // 合計を再計算（製造計画管理の場合のみ）
    this.recalculateTotalsIfNeeded()

    Logger.log(`✅ Row removed: ${uniqueId}`)
  }

  /**
   * 他のタブから同じ行を削除
   * @param {string} uniqueId - ユニークID
   */
  removeFromOtherTabs(uniqueId) {
    const selector = `tr[data-unique-id="${uniqueId}"], tr[data-row-unique-id="${uniqueId}"]`
    const allMatchingRows = document.querySelectorAll(selector)

    Logger.log(`🔍 Found ${allMatchingRows.length} matching rows with ID: ${uniqueId}`)

    allMatchingRows.forEach(row => {
      if (row !== this.element) {
        const destroyInput = row.querySelector('[data-form--nested-form-item-target="destroy"]')
        if (destroyInput) {
          destroyInput.value = "1"
          Logger.log(`  ↳ Set _destroy=1 in other tab: ${destroyInput.name}`)
        }
        row.style.display = "none"
        Logger.log(`  ↳ Hidden matching row in other tab`)
      }
    })
  }

  /**
   * 製造計画の合計を再計算（該当する場合のみ）
   */
  recalculateTotalsIfNeeded() {
    // 製造計画の totals コントローラーを探す
    const parentElement = document.querySelector('[data-controller~="resources--plan-product--totals"]')

    if (parentElement) {
      Logger.log('📊 Recalculating totals after row removal')

      const parentController = this.application.getControllerForElementAndIdentifier(
        parentElement,
        'resources--plan-product--totals'
      )

      if (parentController && typeof parentController.recalculate === 'function') {
        // 少し遅延させて DOM が更新された後に実行
        setTimeout(() => {
          parentController.recalculate({ type: 'row-removed' })
          Logger.log('✅ Totals recalculated')
        }, 100)
      } else {
        Logger.warn('⚠️ Totals controller not found or invalid')
      }
    }
  }
}