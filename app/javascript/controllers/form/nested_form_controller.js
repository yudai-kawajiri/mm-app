// Nested Form Controller
//
// カテゴリタブごとの動的フィールド追加管理
//
// 使用例:
//   <div data-controller="form--nested-form">
//     <template id="material-template" data-form--nested-form-target="template">
//       <tr data-row-unique-id="NEW_RECORD">
//         <input name="plan[materials][NEW_RECORD][name]" />
//       </tr>
//     </template>
//
//     <tbody
//       data-form--nested-form-target="target"
//       data-category-id="1"
//     ></tbody>
//
//     <button
//       data-action="click->form--nested-form#add"
//       data-category-id="1"
//       data-template-id="material-template"
//     >追加</button>
//   </div>
//
// 機能:
// - カテゴリタブごとの動的フィールド追加
// - ALLタブへの自動同期
// - ユニークIDの自動生成
// - テンプレートのNEW_RECORD置換
// - 合計再計算のディスパッチ

import { Controller } from "@hotwired/stimulus"
import Logger from "utils/logger"

const DEFAULT_CATEGORY_ID = '0'
const ID_PREFIX = 'new_'
const RANDOM_MULTIPLIER = 1000
const RECALCULATION_DELAY_MS = 100

export default class extends Controller {
  static targets = ["target", "template"]

  // フィールド追加処理
  // カテゴリタブとALLタブに新しいフォーム行を追加
  add(event) {
    event.preventDefault()

    const button = event.currentTarget
    const categoryId = button.dataset.categoryId
    const templateId = button.dataset.templateId

    Logger.log(`Adding new field for category: ${categoryId}`)

    // ALLタブでは追加不可
    if (categoryId === DEFAULT_CATEGORY_ID) {
      Logger.warn('Cannot add items in ALL tab')
      return
    }

    // テンプレートを取得
    const template = document.getElementById(templateId)
    if (!template) {
      Logger.error(`Template not found: ${templateId}`)
      return
    }

    // ターゲットコンテナを取得
    const categoryContainer = this.findTargetContainer(categoryId)
    if (!categoryContainer) {
      Logger.error(`Target container not found for category: ${categoryId}`)
      return
    }

    // ユニークIDを生成
    const uniqueId = `${ID_PREFIX}${Date.now()}_${Math.floor(Math.random() * RANDOM_MULTIPLIER)}`

    // テンプレートを複製してNEW_RECORDを置換
    let content = template.innerHTML
    const newId = new Date().getTime()
    content = content.replace(/NEW_RECORD/g, newId)

    // ユニークIDを設定（製造計画と商品管理の両方に対応）
    content = content.replace(/data-row-unique-id="[^"]*"/g, `data-row-unique-id="${uniqueId}"`)
    content = content.replace(new RegExp(`data-unique-id="${ID_PREFIX}[^"]*"`, 'g'), `data-unique-id="${uniqueId}"`)

    // カテゴリタブに追加
    categoryContainer.insertAdjacentHTML('beforeend', content)
    Logger.log(`Added to category ${categoryId} tab`)

    // ALLタブにも追加
    const allContainer = this.findTargetContainer(DEFAULT_CATEGORY_ID)
    if (allContainer) {
      allContainer.insertAdjacentHTML('beforeend', content)
      Logger.log('Also added to ALL tab')
    }

    // 合計を再計算（製造計画の場合のみ）
    const hasCalculation = document.querySelector('[data-resources--plan-product--totals-target]')
    if (hasCalculation) {
      setTimeout(() => {
        this.dispatch('recalculate', { prefix: 'resources--plan-product--totals', bubbles: true })
      }, RECALCULATION_DELAY_MS)
    }

    Logger.log(`New field added with unique ID: ${uniqueId}`)
  }

  // カテゴリIDに対応するターゲットコンテナを検索
  // 両方のIDパターン（nav-X と category-pane-X）に対応
  findTargetContainer(categoryId) {
    // タブペインを検索
    let tabPane = document.querySelector(`#nav-${categoryId}`)
    if (!tabPane) {
      tabPane = document.querySelector(`#category-pane-${categoryId}`)
    }

    if (!tabPane) {
      Logger.warn(`Tab pane not found for category: ${categoryId}`)
      return null
    }

    // コンテナを検索
    const container = tabPane.querySelector(
      `[data-form--nested-form-target="target"][data-category-id="${categoryId}"]`
    )
    if (!container) {
      Logger.warn(`Container not found in tab pane for category: ${categoryId}`)
    }
    return container
  }
}
