// Nested Form Item Controller
//
// ネストフォームの各行の削除管理
//
// 使用例:
//   <tr data-controller="form--nested-form-item" data-unique-id="123">
//     <td>
//       <input
//         type="hidden"
//         name="plan[materials][123][_destroy]"
//         value="0"
//         data-form--nested-form-item-target="destroy"
//       />
//       <button data-action="click->form--nested-form-item#remove">削除</button>
//     </td>
//   </tr>
//
// 機能:
// - 論理削除（_destroy = 1）
// - 複数タブの同期削除（同じunique-idを持つ行）
// - 合計再計算のトリガー（製造計画管理の場合）

import { Controller } from "@hotwired/stimulus"
import Logger from "utils/logger"

const RECALCULATION_DELAY_MS = 100
const DESTROY_FLAG_VALUE = "1"
const DISPLAY_NONE = "none"

export default class extends Controller {
  static targets = ["destroy"]

  // 行を削除（論理削除）
  // _destroyフラグを設定し、行を非表示にする
  remove(event) {
    event.preventDefault()

    const row = this.element
    const uniqueId = row.dataset.uniqueId || row.dataset.rowUniqueId

    Logger.log(`Removing row: ${uniqueId}`)

    // _destroyフラグを立てる
    if (this.hasDestroyTarget) {
      this.destroyTarget.value = DESTROY_FLAG_VALUE
      Logger.log(`Set _destroy=${DESTROY_FLAG_VALUE} for: ${this.destroyTarget.name}`)
    } else {
      Logger.error('Destroy target not found')
    }

    // この行を非表示
    row.style.display = DISPLAY_NONE

    // 同じunique-idを持つ他のタブの行も削除
    if (uniqueId) {
      this.removeFromOtherTabs(uniqueId)
    }

    // 合計を再計算（製造計画管理の場合のみ）
    this.recalculateTotalsIfNeeded()

    Logger.log(`Row removed: ${uniqueId}`)
  }

  // 他のタブから同じ行を削除
  // data-unique-idまたはdata-row-unique-idが一致する行を検索して削除
  removeFromOtherTabs(uniqueId) {
    const selector = `tr[data-unique-id="${uniqueId}"], tr[data-row-unique-id="${uniqueId}"]`
    const allMatchingRows = document.querySelectorAll(selector)

    Logger.log(`Found ${allMatchingRows.length} matching rows with ID: ${uniqueId}`)

    allMatchingRows.forEach(row => {
      if (row !== this.element) {
        const destroyInput = row.querySelector('[data-form--nested-form-item-target="destroy"]')
        if (destroyInput) {
          destroyInput.value = DESTROY_FLAG_VALUE
          Logger.log(`Set _destroy=${DESTROY_FLAG_VALUE} in other tab: ${destroyInput.name}`)
        }
        row.style.display = DISPLAY_NONE
        Logger.log(`Hidden matching row in other tab`)
      }
    })
  }

  // 製造計画の合計を再計算（該当する場合のみ）
  // resources--plan-product--totalsコントローラーが存在する場合のみ実行
  recalculateTotalsIfNeeded() {
    const parentElement = document.querySelector('[data-controller~="resources--plan-product--totals"]')

    if (parentElement) {
      Logger.log('Recalculating totals after row removal')

      const parentController = this.application.getControllerForElementAndIdentifier(
        parentElement,
        'resources--plan-product--totals'
      )

      if (parentController && typeof parentController.recalculate === 'function') {
        setTimeout(() => {
          parentController.recalculate({ type: 'row-removed' })
          Logger.log('Totals recalculated')
        }, RECALCULATION_DELAY_MS)
      } else {
        Logger.warn('Totals controller not found or invalid')
      }
    }
  }
}
