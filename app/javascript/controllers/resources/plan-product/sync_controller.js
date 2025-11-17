// Plan Product Sync Controller
//
// 製造計画：タブ間同期コントローラー
//
// 使用例:
//   <tr data-controller="resources--plan-product--sync">
//     <select
//       data-row-unique-id="123"
//       data-action="change->resources--plan-product--sync#syncProductToOtherTabs"
//     >
//       <option value="">選択</option>
//     </select>
//     <input
//       type="number"
//       data-row-unique-id="123"
//       data-action="input->resources--plan-product--sync#syncQuantityToOtherTabs"
//     />
//   </tr>
//
// 責務:
// - 商品選択の全タブ同期
// - 数量入力の全タブ同期
// - イベント発火による連鎖更新
//
// データフロー:
// 1. ユーザーがAタブで商品を選択
// 2. syncProductToOtherTabs() が発火
// 3. 同じ row-unique-id を持つ全タブのセレクトボックスに同期
// 4. 各セレクトボックスで change イベント発火
// 5. row_controller が価格を取得・小計計算

import { Controller } from "@hotwired/stimulus"
import Logger from "utils/logger"

// 定数定義
const DATA_ATTRIBUTE = {
  ROW_UNIQUE_ID: 'rowUniqueId'
}

const SELECTOR = {
  SELECT_BY_ROW_ID: (rowId) => `select[data-row-unique-id="${rowId}"]`,
  INPUT_BY_ROW_ID: (rowId) => `input[data-resources--plan-product--row-target="productionCount"][data-row-unique-id="${rowId}"]`
}

const EVENT_TYPE = {
  CHANGE: 'change',
  INPUT: 'input'
}

const EVENT_OPTIONS = {
  BUBBLES: { bubbles: true }
}

const LOG_MESSAGES = {
  SYNC_PRODUCT: (productId, rowId) => `Sync product: ${productId} for row: ${rowId}`,
  SYNC_QUANTITY: (quantity, rowId) => `Sync quantity: ${quantity} for row: ${rowId}`
}

export default class extends Controller {
  // ============================================================
  // 商品選択の同期
  // ============================================================

  // 商品選択を他のタブに同期
  // 同じ row-unique-id を持つ全てのセレクトボックスに
  // 選択された商品を同期する
  syncProductToOtherTabs(event) {
    const selectElement = event.currentTarget
    const selectedProductId = selectElement.value
    const uniqueRowId = selectElement.dataset[DATA_ATTRIBUTE.ROW_UNIQUE_ID]

    Logger.log(LOG_MESSAGES.SYNC_PRODUCT(selectedProductId, uniqueRowId))

    const allMatchingSelects = document.querySelectorAll(SELECTOR.SELECT_BY_ROW_ID(uniqueRowId))

    allMatchingSelects.forEach(select => {
      if (select !== selectElement && select.value !== selectedProductId) {
        select.value = selectedProductId

        // イベントを発火（ただし同期は防ぐ）
        const changeEvent = new Event(EVENT_TYPE.CHANGE, EVENT_OPTIONS.BUBBLES)
        select.dispatchEvent(changeEvent)
      }
    })
  }

  // ============================================================
  // 数量入力の同期
  // ============================================================

  // 数量を他のタブに同期
  // 同じ row-unique-id を持つ全ての数量入力フィールドに
  // 入力された数量を同期する
  syncQuantityToOtherTabs(event) {
    const inputElement = event.currentTarget
    const quantity = inputElement.value
    const uniqueRowId = inputElement.dataset[DATA_ATTRIBUTE.ROW_UNIQUE_ID]

    Logger.log(LOG_MESSAGES.SYNC_QUANTITY(quantity, uniqueRowId))

    const allMatchingInputs = document.querySelectorAll(SELECTOR.INPUT_BY_ROW_ID(uniqueRowId))

    allMatchingInputs.forEach(input => {
      if (input !== inputElement && input.value !== quantity) {
        input.value = quantity

        // イベントを発火（ただし同期は防ぐ）
        const inputEvent = new Event(EVENT_TYPE.INPUT, EVENT_OPTIONS.BUBBLES)
        input.dispatchEvent(inputEvent)
      }
    })
  }
}
