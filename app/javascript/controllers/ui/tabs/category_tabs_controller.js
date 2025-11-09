/**
 * @file tabs/category_tabs_controller.js
 * カテゴリタブ管理コントローラー（統合版）
 *
 * @module Controllers/Tabs
 */

import { Controller } from "@hotwired/stimulus"
import Logger from "../../utils/logger"

/**
 * Category Tabs Controller
 *
 * カテゴリタブ管理コントローラー（統合版）。
 * タブの切り替え、動的追加、削除を統合的に管理する。
 * 商品管理・製造計画の両画面で使用される。
 *
 * 責務:
 * - タブの切り替え制御
 * - タブの動的追加（テンプレートベース）
 * - タブの削除（商品管理・製造計画の両方に対応）
 * - タブ削除時の全タブ同期（_destroy フラグ設定）
 * - 製造計画の合計再計算連携
 *
 * データフロー:
 * 1. ユーザーがタブをクリック → selectTab() → categoryIdValue更新 → updateTabs()
 * 2. カテゴリ選択 → showSelectedTab() → テンプレートから生成 → タブ追加
 * 3. タブ削除 → removeTab() → 全行の_destroyフラグ設定 → ALLタブに切り替え
 *
 * @extends Controller
 *
 * @example HTML での使用
 *   <div data-controller="tabs--category-tabs" data-tabs--category-tabs-category-id-value="0">
 *     <!-- タブナビゲーション -->
 *     <div data-tabs--category-tabs-target="tabNav">
 *       <button data-tabs--category-tabs-target="tab" data-category-id="0">ALL</button>
 *       <button data-tabs--category-tabs-target="tab" data-category-id="1">
 *         カテゴリ1
 *         <span data-action="click->tabs--category-tabs#removeTab">×</span>
 *       </button>
 *     </div>
 *
 *     <!-- タブコンテンツ -->
 *     <div data-tabs--category-tabs-target="contentContainer">
 *       <div data-tabs--category-tabs-target="category" data-category-id="0">ALL内容</div>
 *       <div data-tabs--category-tabs-target="category" data-category-id="1">カテゴリ1内容</div>
 *     </div>
 *
 *     <!-- カテゴリ追加セレクター -->
 *     <select data-tabs--category-tabs-target="categorySelector">
 *       <option value="">選択してください</option>
 *     </select>
 *     <button data-tabs--category-tabs-target="showButton">追加</button>
 *   </div>
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

  /**
   * 遅延時間定数: 合計再計算処理の遅延（ミリ秒）
   *
   * タブ削除後に製造計画の合計再計算を行う際の遅延時間。
   * DOM更新後に確実に計算が実行されるよう、わずかな待機時間を設ける。
   */
  static RECALCULATION_DELAY_MS = 100

  // ============================================================
  // 初期化
  // ============================================================

  /**
   * コントローラー接続時の処理
   */
  connect() {
    Logger.log("Category tabs controller connected")
  }

  // ============================================================
  // タブ切り替え
  // ============================================================

  /**
   * カテゴリIDが変更されたときの処理
   *
   * Stimulus Values API により、categoryIdValue が変更されると
   * 自動的にこのメソッドが呼ばれ、タブ表示を更新する。
   */
  categoryIdValueChanged() {
    this.updateTabs()
  }

  /**
   * タブ選択時の処理
   *
   * @param {Event} event - click イベント
   *
   * タブボタンクリック時に categoryIdValue を更新し、
   * categoryIdValueChanged を通じてタブを切り替える。
   */
  selectTab(event) {
    event.preventDefault()
    const selectedCategoryId = parseInt(event.currentTarget.dataset.categoryId, 10) || 0
    this.categoryIdValue = selectedCategoryId
    Logger.log(`Tab selected: ${selectedCategoryId}`)
  }

  /**
   * タブ表示を更新
   *
   * 全タブ・コンテンツの active クラスを削除し、
   * 選択されたカテゴリIDに対応するタブ・コンテンツに
   * active クラスを追加する。
   */
  updateTabs() {
    const selectedCategoryId = this.categoryIdValue
    Logger.log(`Updating tabs for category ID: ${selectedCategoryId}`)

    // 全タブの active を解除
    this.tabTargets.forEach(tab => {
      tab.classList.remove('active')
      tab.setAttribute('aria-selected', 'false')
    })

    // 全コンテンツの active を解除
    this.categoryTargets.forEach(content => {
      content.classList.remove('show', 'active')
    })

    // 選択されたタブを active に
    const activeTab = this.tabTargets.find(t => {
      const tabId = parseInt(t.dataset.categoryId, 10) || 0
      return tabId === selectedCategoryId
    })

    if (activeTab) {
      activeTab.classList.add('active')
      activeTab.setAttribute('aria-selected', 'true')
    }

    // 選択されたコンテンツを active に
    const activeContent = this.categoryTargets.find(c => {
      const contentId = parseInt(c.dataset.categoryId, 10) || 0
      return contentId === selectedCategoryId
    })

    if (activeContent) {
      activeContent.classList.add('show', 'active')
    } else {
      Logger.warn(`No content found for category ID: ${selectedCategoryId}`)
    }
  }

  // ============================================================
  // タブの動的追加
  // ============================================================

  /**
   * カテゴリ選択時の追加ボタン制御
   *
   * セレクトボックスで有効なカテゴリが選択されている場合のみ
   * 追加ボタンを有効化する。
   */
  toggleButton() {
    if (!this.hasCategorySelectorTarget || !this.hasShowButtonTarget) return
    const isSelected = this.categorySelectorTarget.value && this.categorySelectorTarget.value !== '0'
    this.showButtonTarget.disabled = !isSelected
  }

  /**
   * 既存カテゴリのオプションを無効化
   *
   * 既にタブとして追加されているカテゴリを
   * セレクトボックスで選択できないようにする。
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
   * 選択されたカテゴリのタブを追加
   *
   * セレクトボックスで選択されたカテゴリのタブを動的に追加。
   * 既に存在する場合はそのタブに切り替える。
   */
  showSelectedTab() {
    if (!this.hasCategorySelectorTarget) return
    const categoryId = String(this.categorySelectorTarget.value)
    if (!categoryId || categoryId === '0') return

    // 既存チェック
    const existingTab = this.tabNavTarget.querySelector(`[data-category-id="${categoryId}"]`)
    if (existingTab) {
      Logger.log(`Tab for category ID ${categoryId} already exists`)
      this.switchToTab(categoryId)
      this.categorySelectorTarget.value = ""
      this.toggleButton()
      return
    }

    const categoryName = this.categorySelectorTarget.options[this.categorySelectorTarget.selectedIndex].text
    Logger.log(`Adding tab for category ID ${categoryId}`)

    // タブボタンとコンテンツを追加
    const tabButton = this.addTabButton(categoryId, categoryName)
    const tabPane = this.addTabPane(categoryId, categoryName)

    if (tabButton && tabPane) {
      this.disableExistingCategoryOptions()
      this.switchToTab(categoryId)
      this.categorySelectorTarget.value = ""
      this.toggleButton()
      Logger.log(`Tab for category ID ${categoryId} added and displayed`)
    }
  }

  /**
   * タブボタンを追加
   *
   * @param {string} categoryId - カテゴリID
   * @param {string} categoryName - カテゴリ名
   * @return {HTMLElement|null} 追加されたタブボタン
   *
   * テンプレートからタブボタンを生成し、タブナビゲーションに追加する。
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
   *
   * @param {string} categoryId - カテゴリID
   * @param {string} categoryName - カテゴリ名
   * @return {HTMLElement|null} 追加されたタブコンテンツ
   *
   * テンプレートからタブコンテンツを生成し、コンテンツコンテナに追加する。
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
   * 指定されたタブに切り替え
   *
   * @param {string} categoryId - カテゴリID
   *
   * 全タブ・コンテンツの active クラスを削除し、
   * 指定されたカテゴリIDのタブ・コンテンツに active クラスを追加する。
   */
  switchToTab(categoryId) {
    if (!this.hasTabNavTarget || !this.hasContentContainerTarget) return

    // 全タブの active を解除
    this.tabNavTarget.querySelectorAll('[data-bs-toggle="tab"]').forEach(tab => {
      tab.classList.remove('active')
      tab.setAttribute('aria-selected', 'false')
    })

    // 全コンテンツの active を解除
    this.contentContainerTarget.querySelectorAll('.tab-pane').forEach(pane => {
      pane.classList.remove('show', 'active')
    })

    // 指定されたタブとコンテンツを active に
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

  /**
   * タブ削除処理
   *
   * @param {Event} event - click イベント
   *
   * 以下の処理を実行：
   * 1. ALLタブの削除を防止
   * 2. 確認ダイアログ
   * 3. タブ内の全行の unique_id を収集
   * 4. 各行の _destroy フラグを "1" に設定
   * 5. ALLタブから同じ unique_id の行を削除
   * 6. タブボタンとコンテンツを削除
   * 7. セレクトボックスのオプションを再有効化
   * 8. ALLタブに切り替え
   * 9. 合計再計算（製造計画の場合）
   */
  removeTab(event) {
    event.preventDefault()
    event.stopPropagation()

    const categoryId = event.currentTarget.dataset.categoryId

    // ALLタブは削除不可
    if (categoryId === '0') {
      alert('ALLタブは削除できません')
      return
    }

    // 確認ダイアログ
    if (!confirm(`このカテゴリタブを削除してもよろしいですか？\n※タブ内のデータも削除されます`)) {
      return
    }

    Logger.log(`Removing tab for category: ${categoryId}`)

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
            Logger.log(`Set _destroy=1 for row: ${uniqueId} (${destroyInput.name})`)
          } else {
            Logger.warn(`Destroy input not found for row: ${uniqueId}`)
          }

          // 行を非表示
          row.style.display = 'none'
        }
      })
    }

    // 2. ALLタブから同じ unique_id の行を削除
    const allTabPane = this.contentContainerTarget.querySelector('#nav-0')
    if (allTabPane && rowsToDelete.length > 0) {
      Logger.log(`Removing ${rowsToDelete.length} rows from ALL tab`)

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
              Logger.log(`Set _destroy=1 in ALL tab for row: ${uniqueId} (${destroyInput.name})`)
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

    Logger.log(`Tab for category ID ${categoryId} removed`)
  }

  /**
   * 合計を再計算（製造計画の場合のみ）
   *
   * resources--plan-product--totals コントローラーが存在する場合、
   * 合計再計算メソッドを呼び出す。
   */
  recalculateTotalsIfNeeded() {
    const parentElement = document.querySelector('[data-controller~="resources--plan-product--totals"]')
    if (parentElement) {
      const parentController = this.application.getControllerForElementAndIdentifier(
        parentElement,
        'resources--plan-product--totals'
      )
      if (parentController && typeof parentController.recalculate === 'function') {
        Logger.log('Recalculating totals after tab removal')
        setTimeout(() => {
          parentController.recalculate({ type: 'tab-removed' })
        }, this.constructor.RECALCULATION_DELAY_MS)
      }
    }
  }
}
