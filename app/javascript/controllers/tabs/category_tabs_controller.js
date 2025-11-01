// app/javascript/controllers/tabs/category_tabs_controller.js
import { Controller } from "@hotwired/stimulus"
import Logger from "utils/logger"

/**
 * カテゴリタブ管理コントローラー（統合版）
 * - タブの切り替え
 * - タブの動的追加
 * - タブの削除（商品管理・製造計画の両方に対応）
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

  categoryIdValueChanged() {
    this.updateTabs()
  }

  selectTab(event) {
    event.preventDefault()
    const selectedCategoryId = parseInt(event.currentTarget.dataset.categoryId, 10) || 0
    this.categoryIdValue = selectedCategoryId
    Logger.log(`🔄 Tab selected: ${selectedCategoryId}`)
  }

  updateTabs() {
    const selectedCategoryId = this.categoryIdValue
    Logger.log(`🔄 Updating tabs for category ID: ${selectedCategoryId}`)

    this.tabTargets.forEach(tab => {
      tab.classList.remove('active')
      tab.setAttribute('aria-selected', 'false')
    })

    this.categoryTargets.forEach(content => {
      content.classList.remove('show', 'active')
    })

    const activeTab = this.tabTargets.find(t => {
      const tabId = parseInt(t.dataset.categoryId, 10) || 0
      return tabId === selectedCategoryId
    })

    if (activeTab) {
      activeTab.classList.add('active')
      activeTab.setAttribute('aria-selected', 'true')
    }

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

  toggleButton() {
    if (!this.hasCategorySelectorTarget || !this.hasShowButtonTarget) return
    const isSelected = this.categorySelectorTarget.value && this.categorySelectorTarget.value !== '0'
    this.showButtonTarget.disabled = !isSelected
  }

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

  showSelectedTab() {
    if (!this.hasCategorySelectorTarget) return
    const categoryId = String(this.categorySelectorTarget.value)
    if (!categoryId || categoryId === '0') return

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

  switchToTab(categoryId) {
    if (!this.hasTabNavTarget || !this.hasContentContainerTarget) return

    this.tabNavTarget.querySelectorAll('[data-bs-toggle="tab"]').forEach(tab => {
      tab.classList.remove('active')
      tab.setAttribute('aria-selected', 'false')
    })

    this.contentContainerTarget.querySelectorAll('.tab-pane').forEach(pane => {
      pane.classList.remove('show', 'active')
    })

    const selectedTab = this.tabNavTarget.querySelector(`[data-category-id="${categoryId}"]`)
    const selectedPane = this.contentContainerTarget.querySelector(`#nav-${categoryId}`)

    if (selectedTab && selectedPane) {
      selectedTab.classList.add('active')
      selectedTab.setAttribute('aria-selected', 'true')
      selectedPane.classList.add('show', 'active')
    }
  }

  // ============================================================
  // タブの削除（商品管理・製造計画の両方に対応）
  // ============================================================

  removeTab(event) {
    event.preventDefault()
    event.stopPropagation()

    const categoryId = event.currentTarget.dataset.categoryId

    if (categoryId === '0') {
      alert('ALLタブは削除できません')
      return
    }

    if (!confirm(`このカテゴリタブを削除してもよろしいですか？\n※タブ内のデータも削除されます`)) {
      return
    }

    Logger.log(`🗑️ Removing tab for category: ${categoryId}`)

    // 1. カテゴリタブ内の全行の unique_id を収集
    const tabPane = this.contentContainerTarget.querySelector(`#nav-${categoryId}`)
    const rowsToDelete = []

    if (tabPane) {
      // data-row-unique-id または data-unique-id を持つ行を検索
      const rows = tabPane.querySelectorAll('tr[data-row-unique-id], tr[data-unique-id]')
      Logger.log(`Found ${rows.length} rows in category tab ${categoryId}`)

      rows.forEach(row => {
        const uniqueId = row.dataset.rowUniqueId || row.dataset.uniqueId
        if (uniqueId) {
          rowsToDelete.push(uniqueId)

          // _destroy フラグを設定
          const destroyInput = row.querySelector('[data-form--nested-form-item-target="destroy"]')
          if (destroyInput) {
            destroyInput.value = '1'
            Logger.log(`✅ Set _destroy=1 for row: ${uniqueId} (${destroyInput.name})`)
          } else {
            Logger.warn(`⚠️ Destroy input not found for row: ${uniqueId}`)
          }

          // 行を非表示
          row.style.display = 'none'
        }
      })
    }

    // 2. ALLタブから同じ unique_id の行を削除
    const allTabPane = this.contentContainerTarget.querySelector('#nav-0')
    if (allTabPane && rowsToDelete.length > 0) {
      Logger.log(`🔍 Removing ${rowsToDelete.length} rows from ALL tab`)

      rowsToDelete.forEach(uniqueId => {
        // data-row-unique-id と data-unique-id の両方を検索
        const selectors = [
          `tr[data-row-unique-id="${uniqueId}"]`,
          `tr[data-unique-id="${uniqueId}"]`
        ]

        selectors.forEach(selector => {
          const allTabRows = allTabPane.querySelectorAll(selector)

          allTabRows.forEach(row => {
            const destroyInput = row.querySelector('[data-form--nested-form-item-target="destroy"]')
            if (destroyInput) {
              destroyInput.value = '1'
              Logger.log(`✅ Set _destroy=1 in ALL tab for row: ${uniqueId} (${destroyInput.name})`)
            }
            row.style.display = 'none'
          })
        })
      })
    }

    // 3. タブボタンを削除
    const tabButton = this.tabNavTarget.querySelector(`button[data-category-id="${categoryId}"]`)
    if (tabButton) {
      tabButton.remove()
    }

    // 4. タブコンテンツを削除
    if (tabPane) {
      tabPane.remove()
    }

    // 5. セレクトボックスのオプションを再有効化
    if (this.hasCategorySelectorTarget) {
      Array.from(this.categorySelectorTarget.options).forEach(option => {
        if (option.value === categoryId) {
          option.disabled = false
        }
      })
    }

    // 6. ALLタブに切り替え
    this.switchToTab('0')

    // 7. 合計を再計算（製造計画の場合のみ）
    this.recalculateTotalsIfNeeded()

    Logger.log(`✅ カテゴリ ID ${categoryId} のタブを削除しました`)
  }

  /**
   * 合計を再計算（製造計画の場合のみ）
   */
  recalculateTotalsIfNeeded() {
    const parentElement = document.querySelector('[data-controller~="resources--plan-product--totals"]')
    if (parentElement) {
      const parentController = this.application.getControllerForElementAndIdentifier(
        parentElement,
        'resources--plan-product--totals'
      )
      if (parentController && typeof parentController.recalculate === 'function') {
        Logger.log('📊 Recalculating totals after tab removal')
        setTimeout(() => {
          parentController.recalculate({ type: 'tab-removed' })
        }, 100)
      }
    }
  }
}