// app/javascript/controllers/tabs/category_tabs_controller.js
import { Controller } from "@hotwired/stimulus"
import Logger from "utils/logger"

/**
 * カテゴリタブ管理コントローラー（統合版）
 * - タブの切り替え
 * - タブの動的追加
 * - タブの削除
 */
export default class extends Controller {
  static targets = [
    "tab",
    "category",
    "categorySelector",
    "showButton",
    "tabNav",
    "categoryTemplate",
    "categoryPaneTemplate",
    "contentContainer"
  ]

  static values = {
    categoryId: { type: Number, default: 0 }
  }

  // ============================================================
  // 初期化
  // ============================================================

 connect() {
   Logger.log("✅ Category tabs controller connected")
 }

  // ============================================================
  // タブ切り替え
  // ============================================================

  /**
   * categoryIdValue が変更されたときに自動で実行
   */
  categoryIdValueChanged() {
    this.updateTabs()
  }

  /**
   * タブのクリック時に呼ばれる
   * @param {Event} event - クリックイベント
   */
  selectTab(event) {
    event.preventDefault()

    // クリックされたタブからカテゴリーIDを取得（ALLタブはID=0）
    const selectedCategoryId = parseInt(event.currentTarget.dataset.categoryId, 10) || 0

    // categoryIdValue を直接更新することで、categoryIdValueChanged() が実行される
    this.categoryIdValue = selectedCategoryId

    Logger.log(`🔄 Tab selected: ${selectedCategoryId}`)
  }

  /**
   * タブとコンテンツの表示・非表示を切り替える
   */
  updateTabs() {
    const selectedCategoryId = this.categoryIdValue
    Logger.log(`🔄 Updating tabs for category ID: ${selectedCategoryId}`)

    // 全てのタブとカテゴリーコンテンツをリセット
    this.tabTargets.forEach(tab => {
      tab.classList.remove('active')
      tab.setAttribute('aria-selected', 'false')
    })

    this.categoryTargets.forEach(content => {
      content.classList.remove('show', 'active')
    })

    // 1. タブの状態更新
    const activeTab = this.tabTargets.find(t => {
      const tabId = parseInt(t.dataset.categoryId, 10) || 0
      return tabId === selectedCategoryId
    })

    if (activeTab) {
      activeTab.classList.add('active')
      activeTab.setAttribute('aria-selected', 'true')
    }

    // 2. コンテンツの状態更新
    const activeContent = this.categoryTargets.find(c => {
      const contentId = parseInt(c.dataset.categoryId, 10) || 0
      return contentId === selectedCategoryId
    })

    if (activeContent) {
      activeContent.classList.add('show', 'active')
    } else {
      Logger.warn(`⚠️ No content found for category ID: ${selectedCategoryId}`)
    }
  }

  // ============================================================
  // タブの動的追加
  // ============================================================

  /**
   * セレクトボックスの変更時にボタンを有効/無効化
   */
  toggleButton() {
    if (!this.hasCategorySelectorTarget || !this.hasShowButtonTarget) return

    const isSelected = this.categorySelectorTarget.value && this.categorySelectorTarget.value !== '0'
    this.showButtonTarget.disabled = !isSelected
  }

  /**
   * 既存タブのカテゴリをセレクトボックスから無効化
   */
  disableExistingCategoryOptions() {
    if (!this.hasTabNavTarget || !this.hasCategorySelectorTarget) return

    const existingTabs = this.tabNavTarget.querySelectorAll('[data-category-id]')
    const existingCategoryIds = Array.from(existingTabs).map(tab => tab.dataset.categoryId)

    Array.from(this.categorySelectorTarget.options).forEach(option => {
      if (option.value && existingCategoryIds.includes(option.value)) {
        option.disabled = true
      }
    })
  }

  /**
   * カテゴリタブの追加
   */
  showSelectedTab() {
    if (!this.hasCategorySelectorTarget) return

    const categoryId = String(this.categorySelectorTarget.value)

    if (!categoryId || categoryId === '0') return

    // 既にタブが存在するかチェック
    const existingTab = this.tabNavTarget.querySelector(`[data-category-id="${categoryId}"]`)

    if (existingTab) {
      Logger.log(`⚠️ カテゴリ ID ${categoryId} のタブは既に存在します`)
      this.switchToTab(categoryId)
      this.categorySelectorTarget.value = ""
      this.toggleButton()
      return
    }

    const categoryName = this.categorySelectorTarget.options[this.categorySelectorTarget.selectedIndex].text

    Logger.log(`🔄 カテゴリ ID ${categoryId} のタブを動的に追加します`)

    // タブボタンとコンテンツを追加
    const tabButton = this.addTabButton(categoryId, categoryName)
    const tabPane = this.addTabPane(categoryId, categoryName)

    if (tabButton && tabPane) {
      this.disableExistingCategoryOptions()
      this.switchToTab(categoryId)
      this.categorySelectorTarget.value = ""
      this.toggleButton()
      Logger.log(`✅ カテゴリ ID ${categoryId} のタブを追加・表示しました`)
    }
  }

  /**
   * タブボタンを追加
   * @param {string} categoryId - カテゴリID
   * @param {string} categoryName - カテゴリ名
   * @returns {HTMLElement|null} - 追加されたタブボタン
   */
  addTabButton(categoryId, categoryName) {
    if (!this.hasCategoryTemplateTarget) return null

    const templateHtml = this.categoryTemplateTarget.innerHTML
    const replacedHtml = templateHtml
      .replace(/CATEGORY_ID_PLACEHOLDER/g, categoryId)
      .replace(/CATEGORY_NAME_PLACEHOLDER/g, categoryName)

    const tempDiv = document.createElement('div')
    tempDiv.innerHTML = replacedHtml.trim()
    const tabButton = tempDiv.firstElementChild

    if (tabButton) {
      this.tabNavTarget.appendChild(tabButton)
      return tabButton
    }
    return null
  }

  /**
   * タブコンテンツを追加
   * @param {string} categoryId - カテゴリID
   * @param {string} categoryName - カテゴリ名
   * @returns {HTMLElement|null} - 追加されたタブコンテンツ
   */
  addTabPane(categoryId, categoryName) {
    if (!this.hasCategoryPaneTemplateTarget) return null

    const templateHtml = this.categoryPaneTemplateTarget.innerHTML
    const replacedHtml = templateHtml
      .replace(/CATEGORY_ID_PLACEHOLDER/g, categoryId)
      .replace(/CATEGORY_NAME_PLACEHOLDER/g, categoryName)

    const tempDiv = document.createElement('div')
    tempDiv.innerHTML = replacedHtml.trim()
    const tabPane = tempDiv.firstElementChild

    if (tabPane) {
      this.contentContainerTarget.appendChild(tabPane)
      return tabPane
    }
    return null
  }

  /**
   * タブを切り替え
   * @param {string} categoryId - カテゴリID
   */
  switchToTab(categoryId) {
    if (!this.hasTabNavTarget || !this.hasContentContainerTarget) return

    // 全タブとペインを非アクティブ化
    this.tabNavTarget.querySelectorAll('[data-bs-toggle="tab"]').forEach(tab => {
      tab.classList.remove('active')
      tab.setAttribute('aria-selected', 'false')
    })

    this.contentContainerTarget.querySelectorAll('.tab-pane').forEach(pane => {
      pane.classList.remove('show', 'active')
    })

    // 選択されたタブをアクティブ化
    const selectedTab = this.tabNavTarget.querySelector(`[data-category-id="${categoryId}"]`)
    const selectedPane = this.contentContainerTarget.querySelector(`#nav-${categoryId}`)

    if (selectedTab && selectedPane) {
      selectedTab.classList.add('active')
      selectedTab.setAttribute('aria-selected', 'true')
      selectedPane.classList.add('show', 'active')
    }
  }

  // ============================================================
  // タブの削除
  // ============================================================

  /**
   * タブを削除
   * @param {Event} event - クリックイベント
   */
  removeTab(event) {
    event.preventDefault()
    event.stopPropagation() // タブの切り替えを防ぐ

    const categoryId = event.currentTarget.dataset.categoryId

    if (categoryId === '0') {
      alert('ALLタブは削除できません')
      return
    }

    if (!confirm(`このカテゴリタブを削除してもよろしいですか？\n※タブ内の商品データも削除されます`)) {
      return
    }

    Logger.log(`🗑️ Removing tab for category: ${categoryId}`)

    // タブボタンを削除
    const tabButton = this.tabNavTarget.querySelector(`button[data-category-id="${categoryId}"]`)
    if (tabButton) {
      tabButton.remove()
    }

    // タブコンテンツを削除
    const tabPane = this.contentContainerTarget.querySelector(`#nav-${categoryId}`)
    if (tabPane) {
      // コンテンツ内の全フィールドに_destroyフラグを設定
      const destroyInputs = tabPane.querySelectorAll('[data-form--nested-form-item-target="destroy"]')
      destroyInputs.forEach(input => {
        input.value = '1'
      })

      // ALLタブからも該当カテゴリの行を削除
      const allTabPane = this.contentContainerTarget.querySelector('#nav-0')
      if (allTabPane) {
        const rowsToRemove = allTabPane.querySelectorAll(`tr[data-category-id="${categoryId}"]`)
        rowsToRemove.forEach(row => {
          const destroyInput = row.querySelector('[data-form--nested-form-item-target="destroy"]')
          if (destroyInput) {
            destroyInput.value = '1'
          }
          row.style.display = 'none'
        })
      }

      tabPane.remove()
    }

    // セレクトボックスのオプションを再有効化
    if (this.hasCategorySelectorTarget) {
      Array.from(this.categorySelectorTarget.options).forEach(option => {
        if (option.value === categoryId) {
          option.disabled = false
        }
      })
    }

    // ALLタブに切り替え
    this.switchToTab('0')

    // 合計を再計算
    setTimeout(() => {
      this.dispatch('recalculate', { prefix: 'resources--plan-product--totals', bubbles: true })
    }, 100)

    Logger.log(`✅ カテゴリ ID ${categoryId} のタブを削除しました`)
  }
}