import { Controller } from "@hotwired/stimulus"
import Logger from "utils/logger"
import i18n from "controllers/i18n"

// 定数定義
const CSS_CLASSES = {
  TAB_WITH_CLOSE: 'category-tab-with-close',
  CLOSE_BUTTON: 'category-tab-close-button'
}

const DELAY_MS = {
  INITIAL_FORM_ROW: 100
}

const DEFAULT_CATEGORY_ID = '0'

const I18N_KEYS = {
  CONFIRM_DELETE: 'components.category_tabs.confirm_delete'
}

/**
 * カテゴリタブコントローラー
 * 製造計画の商品管理と商品原材料管理におけるカテゴリタブの動的な追加・削除を制御
 */
export default class extends Controller {
  static targets = [
    "tabNav",            // タブナビゲーション（旧tabList）
    "contentContainer",  // タブコンテンツコンテナ
    "allTab",           // ALLタブ
    "categoryPaneTemplate", // カテゴリペインテンプレート
    "addCategoryModal",   // カテゴリ追加モーダル
    "tab",
    "category",
    "categorySelector",
    "showButton",
    "categoryTemplate"
  ]

  static values = {
    categoriesData: Object,
    categoryId: { type: Number, default: 0 }
  }

  connect() {
    Logger.log('CategoryTabsController connected')
    this.initializeEventListeners()
    this.activateFirstTab()
  }

  initializeEventListeners() {
    this.element.addEventListener('click', (e) => {
      const tabButton = e.target.closest('[data-bs-toggle="tab"]')
      if (tabButton) {
        this.handleTabClick(e, tabButton)
      }

      const deleteButton = e.target.closest('[data-action*="deleteTab"]')
      if (deleteButton) {
        e.preventDefault()
        e.stopPropagation()
        // イベントオブジェクトを作成して渡す
        const customEvent = {
          currentTarget: deleteButton
        }
        this.deleteTab(customEvent)
      }
    })

    if (this.hasAddCategoryModalTarget) {
      this.addCategoryModalTarget.addEventListener('click', (e) => {
        const categoryItem = e.target.closest('[data-category-id]')
        if (categoryItem && !e.target.closest('.disabled')) {
          const categoryId = categoryItem.dataset.categoryId
          const categoryName = categoryItem.dataset.categoryName
          this.addCategoryTab(categoryId, categoryName)
        }
      })
    }
  }

  handleTabClick(event, tabButton) {
    event.preventDefault()
    const tab = new bootstrap.Tab(tabButton)
    tab.show()
    this.updateActiveTab(tabButton)
  }

  updateActiveTab(activeButton) {
    this.tabNavTarget.querySelectorAll('.nav-link').forEach(tab => {
      tab.classList.remove('active')
      tab.setAttribute('aria-selected', 'false')
    })

    activeButton.classList.add('active')
    activeButton.setAttribute('aria-selected', 'true')
  }

  activateFirstTab() {
    const firstTab = this.tabNavTarget.querySelector('.nav-link')
    if (firstTab) {
      const tab = new bootstrap.Tab(firstTab)
      tab.show()
    }
  }

  categoryIdValueChanged() {
    this.updateTabs()
  }

  updateTabs() {
    const selectedCategoryId = this.categoryIdValue
    Logger.log(`Updating tabs for category ID: ${selectedCategoryId}`)

    if (this.hasTabTarget) {
      this.tabTargets.forEach(tab => {
        tab.classList.remove('active')
        tab.setAttribute('aria-selected', 'false')
      })
    }

    if (this.hasCategoryTarget) {
      this.categoryTargets.forEach(content => {
        content.classList.remove('show', 'active')
      })
    }

    if (this.hasTabTarget) {
      const activeTab = this.tabTargets.find(t => {
        const tabId = parseInt(t.dataset.categoryId, 10) || 0
        return tabId === selectedCategoryId
      })

      if (activeTab) {
        activeTab.classList.add('active')
        activeTab.setAttribute('aria-selected', 'true')
      }
    }

    if (this.hasCategoryTarget) {
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
  }

  toggleButton() {
    if (!this.hasCategorySelectorTarget || !this.hasShowButtonTarget) return
    const isSelected = this.categorySelectorTarget.value && this.categorySelectorTarget.value !== DEFAULT_CATEGORY_ID
    this.showButtonTarget.disabled = !isSelected
  }

  // セレクター内の既存カテゴリオプションを無効化
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
    if (!categoryId || categoryId === DEFAULT_CATEGORY_ID) return

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

    const tabItem = this.createTabItem(categoryId, categoryName)
    const tabPane = this.addTabPane(categoryId, categoryName)

    if (tabItem && tabPane) {
      this.tabNavTarget.appendChild(tabItem)
      this.disableExistingCategoryOptions()
      this.switchToTab(categoryId)
      this.categorySelectorTarget.value = ""
      this.toggleButton()
      Logger.log(`Tab for category ID ${categoryId} added and displayed`)
    }
  }

  addCategoryTab(categoryId, categoryName) {
    if (!categoryId || !categoryName) {
      Logger.warn('Invalid category data')
      return
    }

    const existingTab = this.tabNavTarget.querySelector(`[data-category-id="${categoryId}"]`)
    if (existingTab) {
      Logger.warn(`Category tab already exists: ${categoryId}`)
      const tab = new bootstrap.Tab(existingTab)
      tab.show()
      this.closeModal()
      return
    }

    const tabItem = this.createTabItem(categoryId, categoryName)
    const tabPane = this.addTabPane(categoryId, categoryName)

    if (tabItem && tabPane) {
      const allTabButton = this.tabNavTarget.querySelector(`[data-category-id="${DEFAULT_CATEGORY_ID}"]`)
      const allTabLi = allTabButton ? allTabButton.closest('li') || allTabButton.parentElement : null

      if (allTabLi) {
        allTabLi.insertAdjacentElement('afterend', tabItem)
      } else {
        this.tabNavTarget.appendChild(tabItem)
      }

      const newTabButton = tabItem.querySelector('.nav-link')
      const tab = new bootstrap.Tab(newTabButton)
      tab.show()

      Logger.log(`Category tab added: ${categoryName} (${categoryId})`)
      this.closeModal()
      this.disableCategoryInModal(categoryId)
    }
  }

  createTabItem(categoryId, categoryName) {
    const li = document.createElement('li')
    li.className = 'nav-item'
    li.setAttribute('role', 'presentation')

    const tabId = `category-tab-${categoryId}`
    const paneId = `category-pane-${categoryId}`

    li.innerHTML = `
      <button class="nav-link position-relative ${CSS_CLASSES.TAB_WITH_CLOSE}"
              id="${tabId}"
              data-bs-toggle="tab"
              data-bs-target="#${paneId}"
              data-category-id="${categoryId}"
              type="button"
              role="tab"
              aria-controls="${paneId}"
              aria-selected="false">
        ${this.escapeHtml(categoryName)}
        <span class="position-absolute top-50 end-0 translate-middle-y pe-2"
              style="cursor: pointer; font-weight: bold; color: #dc3545; z-index: 10;"
              data-action="click->tabs--category-tabs#deleteTab"
              data-category-id="${categoryId}"
              onclick="event.stopPropagation()">
          ×
        </span>
      </button>
    `

    return li
  }

  addTabPane(categoryId, categoryName) {
    if (!categoryId || !categoryName) {
      Logger.warn('Invalid category ID or name')
      return null
    }

    const template = this.categoryPaneTemplateTarget
    const tabPane = this.createElementFromTemplate(template, categoryId, categoryName)

    if (tabPane) {
      this.contentContainerTarget.appendChild(tabPane)

      Logger.log(`Attempting to add initial form row for category ID: ${categoryId}`)
      setTimeout(() => {
        this.addInitialFormRow(categoryId)
      }, DELAY_MS.INITIAL_FORM_ROW)

      return tabPane
    }
    return null
  }

  /**
   * 新規追加されたカテゴリタブに初期フォーム行を1つ追加
   * 製造計画（product_fields）と商品原材料（material_fields）の両方に対応
   * @param {string} categoryId - カテゴリID
   */
  addInitialFormRow(categoryId) {
    Logger.log(`addInitialFormRow called for category ID: ${categoryId}`)

    // 1. 新しいカテゴリタブのtbodyに追加
    const categoryTbody = this.contentContainerTarget.querySelector(
      `tbody[data-category-id="${categoryId}"]`
    )

    if (!categoryTbody) {
      Logger.warn(`tbody not found for category ID: ${categoryId}`)
      return
    }

    Logger.log(`tbody found for category ID: ${categoryId}`)

    // 2. テンプレートを取得（製造計画と商品の両方に対応）
    let templateId = `product_fields_template_${categoryId}`
    let template = document.getElementById(templateId)

    // 製造計画のテンプレートが見つからない場合、商品原材料のテンプレートを試す
    if (!template) {
      templateId = `material_fields_template_${categoryId}`
      template = document.getElementById(templateId)
    }

    if (!template) {
      Logger.warn(`Template not found: product_fields_template_${categoryId} or material_fields_template_${categoryId}`)
      return
    }

    Logger.log(`Template found: ${templateId}`)

    // 3. 一意のIDを生成してテンプレートを展開
    const timestamp = new Date().getTime()
    const uniqueId = `${timestamp}_${Math.random().toString(36).substr(2, 9)}`
    let templateHtml = template.innerHTML.replace(/NEW_RECORD/g, uniqueId)

    // <tr>タグにdata-category-id属性とdata-initial-row属性を追加
    templateHtml = templateHtml.replace(
      /<tr([^>]*)>/,
      `<tr$1 data-category-id="${categoryId}" data-initial-row="true">`
    )

    // 4. カテゴリタブのtbodyに追加
    categoryTbody.insertAdjacentHTML('beforeend', templateHtml)
    Logger.log(`Initial form row added to category ID: ${categoryId}`)

    // 5. ALLタブ（category_id="0"）のtbodyにも同じ行を追加
    const allTbody = this.contentContainerTarget.querySelector(
      `tbody[data-category-id="${DEFAULT_CATEGORY_ID}"]`
    )

    if (allTbody) {
      // 新しいユニークIDを生成
      const allTabUniqueId = `${timestamp}_${Math.random().toString(36).substr(2, 9)}_all`
      let allTabTemplateHtml = template.innerHTML.replace(/NEW_RECORD/g, allTabUniqueId)

      allTabTemplateHtml = allTabTemplateHtml.replace(
        /<tr([^>]*)>/,
        `<tr$1 data-category-id="${categoryId}" data-initial-row="true" data-unique-id="${allTabUniqueId}">`
      )

      allTbody.insertAdjacentHTML('beforeend', allTabTemplateHtml)
    }
  }

  createElementFromTemplate(template, categoryId, categoryName) {
    if (!template || !template.content) {
      Logger.warn('Invalid template')
      return null
    }

    const clone = template.content.cloneNode(true)
    const element = clone.querySelector('.tab-pane')

    if (!element) {
      Logger.warn('Tab pane element not found in template')
      return null
    }

    const paneId = `category-pane-${categoryId}`
    element.id = paneId
    element.setAttribute('data-category-id', categoryId)
    element.setAttribute('aria-labelledby', `category-tab-${categoryId}`)

    const categoryNameElement = element.querySelector('[data-category-name]')
    if (categoryNameElement) {
      categoryNameElement.textContent = categoryName
    }

    // すべての CATEGORY_ID_PLACEHOLDER を実際のカテゴリIDに置換
    const elementsWithPlaceholder = element.querySelectorAll('[data-category-id="CATEGORY_ID_PLACEHOLDER"]')
    elementsWithPlaceholder.forEach(el => {
      el.setAttribute('data-category-id', categoryId)
    })

    // data-template-id の CATEGORY_ID_PLACEHOLDER も置換
    const elementsWithTemplateId = element.querySelectorAll('[data-template-id]')
    elementsWithTemplateId.forEach(el => {
      const templateId = el.getAttribute('data-template-id')
      if (templateId && templateId.includes('CATEGORY_ID_PLACEHOLDER')) {
        el.setAttribute('data-template-id', templateId.replace(/CATEGORY_ID_PLACEHOLDER/g, categoryId))
      }
    })

    const tbody = element.querySelector('tbody')
    if (tbody) {
      tbody.setAttribute('data-category-id', categoryId)
      Logger.log(`tbody data-category-id set to: ${categoryId}`)
    } else {
      Logger.warn('tbody not found in template')
    }

    const addButton = element.querySelector('[data-action*="add"]')
    if (addButton) {
      addButton.setAttribute('data-category-id', categoryId)
    }

    return element
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
    const selectedPane = this.contentContainerTarget.querySelector(`#category-pane-${categoryId}`)

    if (selectedTab && selectedPane) {
      selectedTab.classList.add('active')
      selectedTab.setAttribute('aria-selected', 'true')
      selectedPane.classList.add('show', 'active')
    }
  }

  /**
   * タブを削除
   * カテゴリタブとALLタブの両方からフォーム行を削除し、
   * セレクターとモーダルのカテゴリを再有効化
   * @param {Event} event - クリックイベント
   */
  deleteTab(event) {
    // イベントから削除ボタンの要素を取得
    const deleteButton = event.currentTarget
    const categoryId = deleteButton.dataset.categoryId

    if (!categoryId) {
      Logger.warn('Invalid category ID for deletion')
      return
    }

    // 確認ダイアログ（i18n対応）
    const confirmMessage = i18n.t(I18N_KEYS.CONFIRM_DELETE)
    if (!confirm(confirmMessage)) {
      return
    }

    // 1. 該当カテゴリのフォーム行をALLタブから削除
    const allTbody = this.contentContainerTarget.querySelector(
      `tbody[data-category-id="${DEFAULT_CATEGORY_ID}"]`
    )

    if (allTbody) {
      // data-category-id属性で該当カテゴリの行を検索して削除
      const categoryRows = allTbody.querySelectorAll(
        `tr[data-category-id="${categoryId}"]`
      )

      if (categoryRows.length > 0) {
        categoryRows.forEach(row => {
          Logger.log(`Removing product row from ALL tab: category ${categoryId}`)
          row.remove()
        })
      } else {
        Logger.warn(`No rows found with data-category-id="${categoryId}" in ALL tab`)
      }
    }

    // 2. タブボタンを削除
    const tabButton = this.tabNavTarget.querySelector(`[data-category-id="${categoryId}"]`)
    if (tabButton) {
      const parentLi = tabButton.closest('li') || tabButton.parentElement

      // 削除するタブがアクティブな場合、ALLタブをアクティブ化
      if (tabButton.classList.contains('active')) {
        const allTab = this.tabNavTarget.querySelector(`[data-category-id="${DEFAULT_CATEGORY_ID}"]`)
        if (allTab) {
          const tab = new bootstrap.Tab(allTab)
          tab.show()
        }
      }

      parentLi.remove()
    }

    // 3. タブペインを削除
    const tabPane = this.contentContainerTarget.querySelector(`#category-pane-${categoryId}`)
    if (tabPane) {
      tabPane.remove()
    }

    // 4. セレクター内のカテゴリオプションを再有効化
    this.enableCategoryInSelector(categoryId)

    // 5. モーダル内のカテゴリアイテムを有効化
    this.enableCategoryInModal(categoryId)

    Logger.log(`Category tab deleted: ${categoryId}`)
  }

  closeModal() {
    if (this.hasAddCategoryModalTarget) {
      const modal = bootstrap.Modal.getInstance(this.addCategoryModalTarget)
      if (modal) {
        modal.hide()
      }
    }
  }

  disableCategoryInModal(categoryId) {
    if (!this.hasAddCategoryModalTarget) return

    const categoryItem = this.addCategoryModalTarget.querySelector(
      `[data-category-id="${categoryId}"]`
    )
    if (categoryItem) {
      categoryItem.classList.add('disabled', 'text-muted')
      categoryItem.style.pointerEvents = 'none'
      categoryItem.style.opacity = '0.5'
    }
  }

  enableCategoryInModal(categoryId) {
    if (!this.hasAddCategoryModalTarget) return

    const categoryItem = this.addCategoryModalTarget.querySelector(
      `[data-category-id="${categoryId}"]`
    )
    if (categoryItem) {
      categoryItem.classList.remove('disabled', 'text-muted')
      categoryItem.style.pointerEvents = ''
      categoryItem.style.opacity = ''
    }
  }

  /**
   * セレクター内のカテゴリオプションを再有効化
   * タブ削除時に呼び出され、該当カテゴリを再選択可能にする
   * @param {string} categoryId - 再有効化するカテゴリID
   */
  enableCategoryInSelector(categoryId) {
    if (!this.hasCategorySelectorTarget) return

    const option = Array.from(this.categorySelectorTarget.options).find(
      opt => opt.value === categoryId
    )

    if (option) {
      option.disabled = false
      Logger.log(`Category option re-enabled in selector: ${categoryId}`)
    } else {
      Logger.warn(`Category option not found in selector: ${categoryId}`)
    }
  }

  escapeHtml(text) {
    const map = {
      '&': '&amp;',
      '<': '&lt;',
      '>': '&gt;',
      '"': '&quot;',
      "'": '&#039;'
    }
    return text.replace(/[&<>"']/g, m => map[m])
  }

  disconnect() {
    Logger.log('CategoryTabsController disconnected')
  }
}
