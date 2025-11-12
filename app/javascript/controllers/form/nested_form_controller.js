/**
 * @file form/nested_form_controller.js
 * ネストフォームの親コントローラー - 動的フィールド追加管理
 *
 * @module Controllers/Form
 */

import { Controller } from "@hotwired/stimulus"
import Logger from "utils/logger"

/**
 * Nested Form Controller (Parent)
 *
 * @description
 *   ネストフォームの親コントローラー。
 *   「原材料を追加」「商品を追加」ボタンを制御し、
 *   カテゴリタブごとに動的にフォームフィールドを追加します。
 *
 * @example HTML での使用
 *   <div data-controller="form--nested-form">
 *     <!-- テンプレート -->
 *     <template id="material-template" data-form--nested-form-target="template">
 *       <tr data-row-unique-id="NEW_RECORD">
 *         <input name="plan[materials][NEW_RECORD][name]" />
 *       </tr>
 *     </template>
 *
 *     <!-- カテゴリタブ -->
 *     <div id="nav-1">
 *       <tbody
 *         data-form--nested-form-target="target"
 *         data-category-id="1"
 *       ></tbody>
 *     </div>
 *
 *     <!-- 追加ボタン -->
 *     <button
 *       data-action="click->form--nested-form#add"
 *       data-category-id="1"
 *       data-template-id="material-template"
 *     >追加</button>
 *   </div>
 *
 * @targets
 *   target - フィールド追加先のコンテナ（tbody）
 *   template - フィールドのテンプレート（template要素）
 *
 * @features
 *   - カテゴリタブごとの動的フィールド追加
 *   - ALLタブへの自動同期
 *   - ユニークIDの自動生成
 *   - テンプレートのNEW_RECORD置換
 *   - 合計再計算のディスパッチ
 *
 * @requires utils/logger - ログ出力ユーティリティ
 */
export default class extends Controller {
  static targets = ["target", "template"]

  /**
   * 遅延時間定数: 再計算処理の遅延（ミリ秒）
   *
   * フィールド追加後、DOM更新の完了を待ってから
   * 合計再計算を実行するための遅延時間。
   */
  static RECALCULATION_DELAY_MS = 100

  /**
   * フィールド追加処理
   *
   * @param {Event} event - click イベント
   *
   * @description
   *   指定されたカテゴリタブに新しいフィールドを追加します。
   *   - テンプレートを複製
   *   - NEW_RECORDをユニークIDに置換
   *   - カテゴリタブとALLタブに追加
   *   - 合計再計算をディスパッチ（製造計画管理の場合）
   */
  add(event) {
    event.preventDefault()

    const button = event.currentTarget
    const categoryId = button.dataset.categoryId
    const templateId = button.dataset.templateId

    Logger.log(`Adding new field for category: ${categoryId}`)

    // ALLタブ (categoryId = 0) では追加不可
    if (categoryId === '0') {
      Logger.warn('Cannot add items in ALL tab')
      return
    }

    // テンプレートを取得
    const template = document.getElementById(templateId)
    if (!template) {
      Logger.error(`Template not found: ${templateId}`)
      return
    }

    // ターゲットコンテナを取得（同じカテゴリIDを持つtbody）
    const categoryContainer = this.findTargetContainer(categoryId)
    if (!categoryContainer) {
      Logger.error(`Target container not found for category: ${categoryId}`)
      return
    }

    // ユニークなIDを生成
    const uniqueId = `new_${Date.now()}_${Math.floor(Math.random() * 1000)}`

    // テンプレートを複製
    let content = template.innerHTML
    const newId = new Date().getTime()
    content = content.replace(/NEW_RECORD/g, newId)

    // ユニークIDを設定（両方の属性名に対応）
    // 製造計画管理用: data-row-unique-id
    content = content.replace(/data-row-unique-id="[^"]*"/g, `data-row-unique-id="${uniqueId}"`)
    // 商品管理用: data-unique-id
    content = content.replace(/data-unique-id="new_[^"]*"/g, `data-unique-id="${uniqueId}"`)

    // カテゴリタブに追加
    categoryContainer.insertAdjacentHTML('beforeend', content)
    Logger.log(`Added to category ${categoryId} tab`)

    // ALLタブにも同じ内容を追加
    const allContainer = this.findTargetContainer('0')
    if (allContainer) {
      allContainer.insertAdjacentHTML('beforeend', content)
      Logger.log('Also added to ALL tab')
    }

    // 合計を再計算（製造計画管理の場合のみ）
    const hasCalculation = document.querySelector('[data-resources--plan-product--totals-target]')
    if (hasCalculation) {
      setTimeout(() => {
        this.dispatch('recalculate', { prefix: 'resources--plan-product--totals', bubbles: true })
      }, this.constructor.RECALCULATION_DELAY_MS)
    }

    Logger.log(`New field added with unique ID: ${uniqueId}`)
  }

  /**
   * カテゴリIDに対応するターゲットコンテナを検索
   *
   * @param {string} categoryId - カテゴリID
   * @return {HTMLElement|null} ターゲットコンテナ（tbody）
   *
   * @description
   *   指定されたカテゴリIDのタブ内からターゲットコンテナを探します。
   *   両方のIDパターン（nav-X と category-pane-X）に対応。
   */
  findTargetContainer(categoryId) {
    // 両方のIDパターンに対応
    let tabPane = document.querySelector(`#nav-${categoryId}`)
    if (!tabPane) {
      tabPane = document.querySelector(`#category-pane-${categoryId}`)
    }

    if (!tabPane) {
      Logger.warn(`Tab pane not found for category: ${categoryId}`)
      return null
    }

    const container = tabPane.querySelector(
      `[data-form--nested-form-target="target"][data-category-id="${categoryId}"]`
    )
    if (!container) {
      Logger.warn(`Container not found in tab pane for category: ${categoryId}`)
    }
    return container
  }
}
