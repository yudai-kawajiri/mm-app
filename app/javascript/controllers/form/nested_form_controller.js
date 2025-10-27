// app/javascript/controllers/form/nested_form_controller.js
import { Controller } from "@hotwired/stimulus"
// 💡 修正後 (Importmapのピン名):
import Logger from "utils/logger"

/**
 * ネストフォームの親コントローラー
 * 「原材料を追加」「商品を追加」ボタンを制御
 */
export default class extends Controller {
  static targets = ["target", "template"]

  add(event) {
    event.preventDefault()

    const button = event.currentTarget
    const categoryId = button.dataset.categoryId
    const templateId = button.dataset.templateId

    Logger.log(`📝 Adding new field for category: ${categoryId}`)

    // ALLタブ (categoryId = 0) では追加不可
    if (categoryId === '0') {
      Logger.warn('⚠️ Cannot add items in ALL tab')
      return
    }

    // テンプレートを取得
    const template = document.getElementById(templateId)
    if (!template) {
      Logger.error(`❌ Template not found: ${templateId}`)
      return
    }

    // ターゲットコンテナを取得（同じカテゴリIDを持つtbody）
    const categoryContainer = this.findTargetContainer(categoryId)
    if (!categoryContainer) {
      Logger.error(`❌ Target container not found for category: ${categoryId}`)
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
    Logger.log(`✅ Added to category ${categoryId} tab`)

    // ALLタブにも同じ内容を追加
    const allContainer = this.findTargetContainer('0')
    if (allContainer) {
      allContainer.insertAdjacentHTML('beforeend', content)
      Logger.log('✅ Also added to ALL tab')
    }

    // 合計を再計算（製造計画管理の場合のみ）
    const hasCalculation = document.querySelector('[data-resources--plan-product--totals-target]')
    if (hasCalculation) {
      setTimeout(() => {
        this.dispatch('recalculate', { prefix: 'resources--plan-product--totals', bubbles: true })
      }, 100)
    }

    Logger.log(`✅ New field added with unique ID: ${uniqueId}`)
  }

  /**
   * カテゴリIDに対応するターゲットコンテナを検索
   * @param {string} categoryId - カテゴリID
   * @returns {HTMLElement|null} - ターゲットコンテナ
   */
  findTargetContainer(categoryId) {
    const tabPane = document.querySelector(`#nav-${categoryId}`)
    if (!tabPane) {
      Logger.warn(`⚠️ Tab pane not found for category: ${categoryId}`)
      return null
    }

    const container = tabPane.querySelector(
      `[data-form--nested-form-target="target"][data-category-id="${categoryId}"]`
    )
    if (!container) {
      Logger.warn(`⚠️ Container not found in tab pane for category: ${categoryId}`)
    }
    return container
  }
}
