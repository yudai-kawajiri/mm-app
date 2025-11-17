// Form Submit Controller
//
// フォーム送信時の重複行無効化処理
//
// 使用例:
//   <form data-controller="form--submit">
//     <tr data-unique-id="123">...</tr>
//     <tr data-unique-id="123">...</tr> <!-- 重複：無効化される -->
//   </form>
//
// 機能:
// - 重複行の自動検出
// - 2つ目以降の行のフィールド無効化
// - _destroy=1の行はスキップ
// - hiddenフィールドは無効化しない

import { Controller } from "@hotwired/stimulus"
import Logger from "utils/logger"

const DESTROY_FLAG_VALUE = '1'
const FIRST_ROW_INDEX = 1

export default class extends Controller {
  // コントローラー接続時の処理
  // フォームにsubmitイベントリスナーを登録
  connect() {
    Logger.log("Form submit controller connected")

    const form = this.element
    form.addEventListener('submit', this.handleSubmit.bind(this))
  }

  // フォーム送信時の処理
  // unique-idごとにグループ化し、重複がある場合は2つ目以降を無効化
  handleSubmit(event) {
    Logger.log("Form submitting, removing duplicates...")

    // すべてのネストフォームフィールドを取得
    const allRows = this.element.querySelectorAll('tr[data-unique-id], tr[data-row-unique-id]')

    if (allRows.length === 0) {
      Logger.log("No nested fields found, proceeding with submit")
      return true
    }

    // unique_idごとにグループ化
    const rowsByUniqueId = new Map()

    allRows.forEach(row => {
      const uniqueId = row.dataset.uniqueId || row.dataset.rowUniqueId

      if (!uniqueId) return

      // _destroy=1の行はスキップ
      const destroyInput = row.querySelector('[data-form--nested-form-item-target="destroy"]')
      if (destroyInput && destroyInput.value === DESTROY_FLAG_VALUE) {
        return
      }

      if (!rowsByUniqueId.has(uniqueId)) {
        rowsByUniqueId.set(uniqueId, [])
      }

      rowsByUniqueId.get(uniqueId).push(row)
    })

    // 重複がある場合、2つ目以降の行のフィールドを無効化
    let duplicatesFound = 0

    rowsByUniqueId.forEach((rows, uniqueId) => {
      if (rows.length > FIRST_ROW_INDEX) {
        Logger.log(`Found ${rows.length} duplicates for ${uniqueId}`)

        // 最初の1つを残し、残りを無効化
        for (let i = FIRST_ROW_INDEX; i < rows.length; i++) {
          const row = rows[i]

          // この行の全てのinput/select/textareaを無効化（hidden以外）
          const inputs = row.querySelectorAll('input:not([type="hidden"]), select, textarea')
          inputs.forEach(input => {
            input.disabled = true
            Logger.log(`Disabled field: ${input.name}`)
          })

          duplicatesFound++
        }
      }
    })

    if (duplicatesFound > 0) {
      Logger.log(`Disabled ${duplicatesFound} duplicate rows`)
    } else {
      Logger.log("No duplicates found")
    }

    return true
  }

  // handleSubmitのエイリアス
  // HTMLから呼ばれるdisableSubmitメソッド
  disableSubmit(event) {
    return this.handleSubmit(event)
  }
}
