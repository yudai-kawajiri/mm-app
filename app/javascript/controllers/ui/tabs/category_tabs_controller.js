import { Controller } from "@hotwired/stimulus"
import i18n from "controllers/i18n"
import Logger from "utils/logger"

const CSS_CLASSES = {
  TAB_WITH_CLOSE: 'category-tab-with-close',
  CLOSE_BUTTON: 'category-tab-close-button',
  NAV_ITEM: 'nav-item',
  NAV_LINK: 'nav-link',
  ACTIVE: 'active',
  SHOW: 'show',
  TAB_PANE: 'tab-pane',
  POSITION_RELATIVE: 'position-relative',
  POSITION_ABSOLUTE: 'position-absolute',
  TOP_50: 'top-50',
  END_0: 'end-0',
  TRANSLATE_MIDDLE_Y: 'translate-middle-y',
  PE_2: 'pe-2',
  DISABLED: 'disabled',
  TEXT_MUTED: 'text-muted'
}

const HTML_ELEMENT = {
  LI: 'li',
  BUTTON: 'button',
  SPAN: 'span',
  TBODY: 'tbody',
  TR: 'tr'
}

const HTML_ATTRIBUTE = {
  ROLE: 'role',
  TYPE: 'type',
  ARIA_SELECTED: 'aria-selected',
  ARIA_CONTROLS: 'aria-controls',
  ARIA_LABELLEDBY: 'aria-labelledby',
  ID: 'id',
  DISABLED: 'disabled'
}

const ARIA_VALUE = {
  TRUE: 'true',
  FALSE: 'false'
}

const ROLE_VALUE = {
  PRESENTATION: 'presentation',
  TAB: 'tab'
}

const BUTTON_TYPE = {
  BUTTON: 'button'
}

const DATA_ATTRIBUTE = {
  BS_TOGGLE: 'data-bs-toggle',
  BS_TARGET: 'data-bs-target',
  CATEGORY_ID: 'data-category-id',
  ACTION: 'data-action',
  CATEGORY_NAME: 'data-category-name',
  TEMPLATE_ID: 'data-template-id',
  UNIQUE_ID: 'data-unique-id',
  ROW_UNIQUE_ID: 'data-row-unique-id',
  INITIAL_ROW: 'data-initial-row',
  PRODUCT_ID: 'data-product-id'
}

const DATA_VALUE = {
  TAB: 'tab'
}

const SELECTOR = {
  BS_TAB_TOGGLE: '[data-bs-toggle="tab"]',
  DELETE_BUTTON: '[data-action*="deleteTab"]',
  CATEGORY_ITEM: '[data-category-id]',
  NAV_LINK: '.nav-link',
  TAB_PANE: '.tab-pane',
  CATEGORY_NAME: '[data-category-name]',
  TEMPLATE_ID: '[data-template-id]',
  ADD_BUTTON: '[data-action*="add"]',
  CATEGORY_BY_ID: (categoryId) => `[data-category-id="${categoryId}"]`,
  TBODY_BY_CATEGORY_ID: (categoryId) => `tbody[data-category-id="${categoryId}"]`,
  TR_BY_CATEGORY_ID: (categoryId) => `tr[data-category-id="${categoryId}"]`,
  PANE_BY_ID: (categoryId) => `#category-pane-${categoryId}`,
  CLOSEST_LI: 'li',
  CLOSEST_DISABLED: '.disabled'
}

const TEMPLATE_ID = {
  PRODUCT_FIELDS: (categoryId) => `product_fields_template_${categoryId}`,
  MATERIAL_FIELDS: (categoryId) => `material_fields_template_${categoryId}`
}

const ELEMENT_ID = {
  CATEGORY_TAB: (categoryId) => `category-tab-${categoryId}`,
  CATEGORY_PANE: (categoryId) => `category-pane-${categoryId}`
}

const DELAY_MS = {
  INITIAL_FORM_ROW: 100
}

const DEFAULT_CATEGORY_ID = '0'

const TEMPLATE_PLACEHOLDER = {
  NEW_RECORD: 'NEW_RECORD',
  CATEGORY_ID: 'CATEGORY_ID_PLACEHOLDER'
}

const INSERT_POSITION = {
  BEFORE_END: 'beforeend',
  AFTER_END: 'afterend'
}

const STYLE_PROPERTY = {
  CURSOR: 'cursor',
  FONT_WEIGHT: 'font-weight',
  COLOR: 'color',
  Z_INDEX: 'z-index',
  POINTER_EVENTS: 'pointer-events',
  OPACITY: 'opacity',
  DISPLAY: 'display'
}

const STYLE_VALUE = {
  CURSOR_POINTER: 'pointer',
  FONT_WEIGHT_BOLD: 'bold',
  COLOR_DANGER: '#dc3545',
  Z_INDEX_10: '10',
  POINTER_EVENTS_NONE: 'none',
  OPACITY_HALF: '0.5',
  EMPTY: ''
}

const CLOSE_SYMBOL = '×'

const STOP_PROPAGATION_ATTRIBUTE = 'onclick'
const STOP_PROPAGATION_VALUE = 'event.stopPropagation()'

const I18N_KEYS = {
  CONFIRM_DELETE: 'components.category_tabs.confirm_delete'
}

const LOG_MESSAGES = {
  CONTROLLER_CONNECTED: 'CategoryTabsController connected',
  CONTROLLER_DISCONNECTED: 'CategoryTabsController disconnected',
  UPDATING_TABS: (categoryId) => `Updating tabs for category ID: ${categoryId}`,
  NO_CONTENT_FOUND: (categoryId) => `No content found for category ID: ${categoryId}`,
  TAB_ALREADY_EXISTS: (categoryId) => `Tab for category ID ${categoryId} already exists`,
  ADDING_TAB: (categoryId) => `Adding tab for category ID ${categoryId}`,
  TAB_ADDED: (categoryId, categoryName) => `Tab for category ID ${categoryId} added and displayed`,
  INVALID_CATEGORY_DATA: 'Invalid category data',
  CATEGORY_TAB_ALREADY_EXISTS: (categoryId) => `Category tab already exists: ${categoryId}`,
  CATEGORY_TAB_ADDED: (categoryName, categoryId) => `Category tab added: ${categoryName} (${categoryId})`,
  ADDING_INITIAL_FORM_ROW: (categoryId) => `addInitialFormRow called for category ID: ${categoryId}`,
  TBODY_NOT_FOUND: (categoryId) => `tbody not found for category ID: ${categoryId}`,
  TBODY_FOUND: (categoryId) => `tbody found for category ID: ${categoryId}`,
  TEMPLATE_NOT_FOUND: (categoryId) => `Template not found: product_fields_template_${categoryId} or material_fields_template_${categoryId}`,
  TEMPLATE_FOUND: (templateId) => `Template found: ${templateId}`,
  INITIAL_FORM_ROW_ADDED: (categoryId) => `Initial form row added to category ID: ${categoryId}`,
  INVALID_TEMPLATE: 'Invalid template',
  TAB_PANE_NOT_FOUND: 'Tab pane element not found in template',
  TBODY_CATEGORY_ID_SET: (categoryId) => `tbody data-category-id set to: ${categoryId}`,
  TBODY_NOT_FOUND_IN_TEMPLATE: 'tbody not found in template',
  INVALID_CATEGORY_ID: 'Invalid category ID or name',
  INVALID_CATEGORY_ID_FOR_DELETION: 'Invalid category ID for deletion',
  REMOVING_PRODUCT_ROW: (categoryId) => `Removing product row from ALL tab: category ${categoryId}`,
  NO_ROWS_FOUND_IN_ALL_TAB: (categoryId) => `No rows found with data-category-id="${categoryId}" in ALL tab`,
  CATEGORY_TAB_DELETED: (categoryId) => `Category tab deleted: ${categoryId}`,
  CATEGORY_OPTION_RE_ENABLED: (categoryId) => `Category option re-enabled in selector: ${categoryId}`,
  CATEGORY_OPTION_NOT_FOUND: (categoryId) => `Category option not found in selector: ${categoryId}`
}

const HTML_ESCAPE_MAP = {
  '&': '&amp;',
  '<': '&lt;',
  '>': '&gt;',
  '"': '&quot;',
  "'": '&#039;'
}

const REGEX = {
  HTML_ESCAPE: /[&<>"']/g,
  TR_TAG: /<tr([^>]*)>/
}

const SUBSTRING_START = {
  RANDOM_ID: 2,
  RANDOM_LENGTH: 9
}

export default class extends Controller {
  static targets = [
    "tabNav",
    "contentContainer",
    "allTab",
    "categoryPaneTemplate",
    "addCategoryModal",
    "tab",
    "category",
    "categorySelector",
    "showButton",
    "categoryTemplate",
    "categoryButtons"
  ]

  static values = {
    categoriesData: Object,
    categoryId: { type: Number, default: 0 }
  }

  connect() {
    Logger.log(LOG_MESSAGES.CONTROLLER_CONNECTED)
    this.initializeEventListeners()
    this.activateFirstTab()
    this.disableExistingCategoryOptions()
  }

  initializeEventListeners() {
    this.element.addEventListener('click', (e) => {
      const tabButton = e.target.closest(SELECTOR.BS_TAB_TOGGLE)
      if (tabButton) {
        this.handleTabClick(e, tabButton)
      }

      const deleteButton = e.target.closest(SELECTOR.DELETE_BUTTON)
      if (deleteButton) {
        e.preventDefault()
        e.stopPropagation()
        const customEvent = {
          currentTarget: deleteButton
        }
        this.deleteTab(customEvent)
      }
    })

    if (this.hasAddCategoryModalTarget) {
      this.addCategoryModalTarget.addEventListener('click', (e) => {
        const categoryItem = e.target.closest(SELECTOR.CATEGORY_ITEM)
        if (categoryItem && !e.target.closest(SELECTOR.CLOSEST_DISABLED)) {
          const categoryId = categoryItem.dataset.categoryId
          const categoryName = categoryItem.dataset.categoryName
          this.addCategoryTab(categoryId, categoryName)
        }
      })
    }
  }

  handleTabClick(event, tabButton) {
    event.preventDefault()

    this.tabNavTarget.querySelectorAll(SELECTOR.NAV_LINK).forEach(tab => {
      tab.classList.remove(CSS_CLASSES.ACTIVE)
      tab.setAttribute(HTML_ATTRIBUTE.ARIA_SELECTED, ARIA_VALUE.FALSE)
    })

    this.contentContainerTarget.querySelectorAll(SELECTOR.TAB_PANE).forEach(pane => {
      pane.classList.remove(CSS_CLASSES.SHOW, CSS_CLASSES.ACTIVE)
    })

    tabButton.classList.add(CSS_CLASSES.ACTIVE)
    tabButton.setAttribute(HTML_ATTRIBUTE.ARIA_SELECTED, ARIA_VALUE.TRUE)

    const targetPaneId = tabButton.getAttribute('aria-controls')
    if (targetPaneId) {
      const targetPane = document.getElementById(targetPaneId)
      if (targetPane) {
        targetPane.classList.add(CSS_CLASSES.SHOW, CSS_CLASSES.ACTIVE)
      }
    }
  }

  updateActiveTab(activeButton) {
    // Handled in handleTabClick
  }

  activateFirstTab() {
    const firstTab = this.tabNavTarget.querySelector(SELECTOR.NAV_LINK)
    if (firstTab) {
      firstTab.click()
    }
  }

  categoryIdValueChanged() {
    this.updateTabs()
  }

  updateTabs() {
    const selectedCategoryId = this.categoryIdValue
    Logger.log(LOG_MESSAGES.UPDATING_TABS(selectedCategoryId))

    if (this.hasTabTarget) {
      this.tabTargets.forEach(tab => {
        tab.classList.remove(CSS_CLASSES.ACTIVE)
        tab.setAttribute(HTML_ATTRIBUTE.ARIA_SELECTED, ARIA_VALUE.FALSE)
      })
    }

    if (this.hasCategoryTarget) {
      this.categoryTargets.forEach(content => {
        content.classList.remove(CSS_CLASSES.SHOW, CSS_CLASSES.ACTIVE)
      })
    }

    if (this.hasTabTarget) {
      const activeTab = this.tabTargets.find(t => {
        const tabId = parseInt(t.dataset.categoryId, 10) || 0
        return tabId === selectedCategoryId
      })

      if (activeTab) {
        activeTab.classList.add(CSS_CLASSES.ACTIVE)
        activeTab.setAttribute(HTML_ATTRIBUTE.ARIA_SELECTED, ARIA_VALUE.TRUE)
      }
    }

    if (this.hasCategoryTarget) {
      const activeContent = this.categoryTargets.find(c => {
        const contentId = parseInt(c.dataset.categoryId, 10) || 0
        return contentId === selectedCategoryId
      })

      if (activeContent) {
        activeContent.classList.add(CSS_CLASSES.SHOW, CSS_CLASSES.ACTIVE)
      } else {
        Logger.warn(LOG_MESSAGES.NO_CONTENT_FOUND(selectedCategoryId))
      }
    }
  }

  toggleButton() {
    if (!this.hasCategorySelectorTarget || !this.hasShowButtonTarget) return
    const isSelected = this.categorySelectorTarget.value && this.categorySelectorTarget.value !== DEFAULT_CATEGORY_ID
    this.showButtonTarget[HTML_ATTRIBUTE.DISABLED] = !isSelected
  }

  disableExistingCategoryOptions() {
    if (!this.hasTabNavTarget || !this.hasCategorySelectorTarget) return
    const existingTabs = this.tabNavTarget.querySelectorAll(SELECTOR.CATEGORY_ITEM)
    const existingCategoryIds = Array.from(existingTabs).map(tab => tab.dataset.categoryId)
    Array.from(this.categorySelectorTarget.options).forEach(option => {
      if (option.value && existingCategoryIds.includes(option.value)) {
        option[HTML_ATTRIBUTE.DISABLED] = true
      }
    })
  }

  showSelectedTab() {
    if (!this.hasCategorySelectorTarget) return
    const categoryId = String(this.categorySelectorTarget.value)
    if (!categoryId || categoryId === DEFAULT_CATEGORY_ID) return

    const existingTab = this.tabNavTarget.querySelector(SELECTOR.CATEGORY_BY_ID(categoryId))
    if (existingTab) {
      Logger.log(LOG_MESSAGES.TAB_ALREADY_EXISTS(categoryId))
      this.switchToTab(categoryId)
      this.categorySelectorTarget.value = STYLE_VALUE.EMPTY
      this.toggleButton()
      return
    }

    const categoryName = this.categorySelectorTarget.options[this.categorySelectorTarget.selectedIndex].text
    Logger.log(LOG_MESSAGES.ADDING_TAB(categoryId))

    const tabItem = this.createTabItem(categoryId, categoryName)
    const tabPane = this.addTabPane(categoryId, categoryName)

    if (tabItem && tabPane) {
      this.tabNavTarget.appendChild(tabItem)
      this.disableExistingCategoryOptions()
      this.switchToTab(categoryId)
      this.categorySelectorTarget.value = STYLE_VALUE.EMPTY
      this.toggleButton()
      Logger.log(LOG_MESSAGES.TAB_ADDED(categoryId, categoryName))
    }
  }

  addCategoryTab(categoryId, categoryName) {
    if (!categoryId || !categoryName) {
      Logger.warn(LOG_MESSAGES.INVALID_CATEGORY_DATA)
      return
    }

    const existingTab = this.tabNavTarget.querySelector(SELECTOR.CATEGORY_BY_ID(categoryId))
    if (existingTab) {
      Logger.warn(LOG_MESSAGES.CATEGORY_TAB_ALREADY_EXISTS(categoryId))
      existingTab.click()
      this.closeModal()
      return
    }

    const tabItem = this.createTabItem(categoryId, categoryName)
    const tabPane = this.addTabPane(categoryId, categoryName)

    if (tabItem && tabPane) {
      const allTabButton = this.tabNavTarget.querySelector(SELECTOR.CATEGORY_BY_ID(DEFAULT_CATEGORY_ID))
      const allTabLi = allTabButton ? allTabButton.closest(SELECTOR.CLOSEST_LI) || allTabButton.parentElement : null

      if (allTabLi) {
        allTabLi.insertAdjacentElement(INSERT_POSITION.AFTER_END, tabItem)
      } else {
        this.tabNavTarget.appendChild(tabItem)
      }

      const newTabButton = tabItem.querySelector(SELECTOR.NAV_LINK)
      newTabButton.click()

      Logger.log(LOG_MESSAGES.CATEGORY_TAB_ADDED(categoryName, categoryId))
      this.closeModal()
      this.disableCategoryInModal(categoryId)
    }
  }

  createTabItem(categoryId, categoryName) {
    const li = document.createElement(HTML_ELEMENT.LI)
    li.className = CSS_CLASSES.NAV_ITEM
    li.setAttribute(HTML_ATTRIBUTE.ROLE, ROLE_VALUE.PRESENTATION)

    const tabId = ELEMENT_ID.CATEGORY_TAB(categoryId)
    const paneId = ELEMENT_ID.CATEGORY_PANE(categoryId)

    li.innerHTML = `
      <button class="${CSS_CLASSES.NAV_LINK} ${CSS_CLASSES.POSITION_RELATIVE} ${CSS_CLASSES.TAB_WITH_CLOSE}"
              ${HTML_ATTRIBUTE.ID}="${tabId}"
              ${DATA_ATTRIBUTE.BS_TOGGLE}="${DATA_VALUE.TAB}"
              ${DATA_ATTRIBUTE.BS_TARGET}="#${paneId}"
              ${DATA_ATTRIBUTE.CATEGORY_ID}="${categoryId}"
              ${HTML_ATTRIBUTE.TYPE}="${BUTTON_TYPE.BUTTON}"
              ${HTML_ATTRIBUTE.ROLE}="${ROLE_VALUE.TAB}"
              ${HTML_ATTRIBUTE.ARIA_CONTROLS}="${paneId}"
              ${HTML_ATTRIBUTE.ARIA_SELECTED}="${ARIA_VALUE.FALSE}"
              style="padding-right: 2.5rem;">
        ${this.escapeHtml(categoryName)}
        <span class="${CSS_CLASSES.POSITION_ABSOLUTE} ${CSS_CLASSES.TOP_50} ${CSS_CLASSES.END_0} ${CSS_CLASSES.TRANSLATE_MIDDLE_Y} ${CSS_CLASSES.PE_2}"
              style="${STYLE_PROPERTY.CURSOR}: ${STYLE_VALUE.CURSOR_POINTER}; ${STYLE_PROPERTY.FONT_WEIGHT}: ${STYLE_VALUE.FONT_WEIGHT_BOLD}; ${STYLE_PROPERTY.COLOR}: ${STYLE_VALUE.COLOR_DANGER}; ${STYLE_PROPERTY.Z_INDEX}: ${STYLE_VALUE.Z_INDEX_10};"
              ${DATA_ATTRIBUTE.ACTION}="click->tabs--category-tabs#deleteTab"
              ${DATA_ATTRIBUTE.CATEGORY_ID}="${categoryId}"
              ${STOP_PROPAGATION_ATTRIBUTE}="${STOP_PROPAGATION_VALUE}">
          ${CLOSE_SYMBOL}
        </span>
      </button>
    `

    return li
  }

  addTabPane(categoryId, categoryName) {
    if (!categoryId || !categoryName) {
      Logger.warn(LOG_MESSAGES.INVALID_CATEGORY_ID)
      return null
    }

    const template = this.categoryPaneTemplateTarget
    const tabPane = this.createElementFromTemplate(template, categoryId, categoryName)

    if (tabPane) {
      this.contentContainerTarget.appendChild(tabPane)

      Logger.log(LOG_MESSAGES.ADDING_INITIAL_FORM_ROW(categoryId))
      setTimeout(() => {
        this.addInitialFormRow(categoryId)
      }, DELAY_MS.INITIAL_FORM_ROW)

      return tabPane
    }
    return null
  }

  addInitialFormRow(categoryId) {
    Logger.log(LOG_MESSAGES.ADDING_INITIAL_FORM_ROW(categoryId))

    const categoryTbody = this.contentContainerTarget.querySelector(
      SELECTOR.TBODY_BY_CATEGORY_ID(categoryId)
    )

    if (!categoryTbody) {
      Logger.warn(LOG_MESSAGES.TBODY_NOT_FOUND(categoryId))
      return
    }

    Logger.log(LOG_MESSAGES.TBODY_FOUND(categoryId))

    let templateId = TEMPLATE_ID.PRODUCT_FIELDS(categoryId)
    let template = document.getElementById(templateId)

    if (!template) {
      templateId = TEMPLATE_ID.MATERIAL_FIELDS(categoryId)
      template = document.getElementById(templateId)
    }

    if (!template) {
      Logger.warn(LOG_MESSAGES.TEMPLATE_NOT_FOUND(categoryId))
      return
    }

    Logger.log(LOG_MESSAGES.TEMPLATE_FOUND(templateId))

    const timestamp = new Date().getTime()
    const uniqueId = `new_${timestamp}`
    let templateHtml = template.innerHTML.replace(new RegExp(TEMPLATE_PLACEHOLDER.NEW_RECORD, 'g'), uniqueId)

    templateHtml = templateHtml.replace(
      REGEX.TR_TAG,
      `<tr$1 ${DATA_ATTRIBUTE.CATEGORY_ID}="${categoryId}" ${DATA_ATTRIBUTE.INITIAL_ROW}="${ARIA_VALUE.TRUE}">`
    )

    categoryTbody.insertAdjacentHTML(INSERT_POSITION.BEFORE_END, templateHtml)
    Logger.log(LOG_MESSAGES.INITIAL_FORM_ROW_ADDED(categoryId))

    const allTbody = document.querySelector(
      SELECTOR.TBODY_BY_CATEGORY_ID(DEFAULT_CATEGORY_ID)
    )

    if (allTbody) {
      const allTabUniqueId = `new_${timestamp}_all`
      let allTabTemplateHtml = template.innerHTML.replace(new RegExp(TEMPLATE_PLACEHOLDER.NEW_RECORD, 'g'), allTabUniqueId)

      allTabTemplateHtml = allTabTemplateHtml.replace(/data-category-id="[^"]*"/g, '')

      allTabTemplateHtml = allTabTemplateHtml.replace(
        REGEX.TR_TAG,
        `<tr$1 ${DATA_ATTRIBUTE.CATEGORY_ID}="${categoryId}" ${DATA_ATTRIBUTE.INITIAL_ROW}="${ARIA_VALUE.TRUE}" ${DATA_ATTRIBUTE.UNIQUE_ID}="${allTabUniqueId}">`
      )

      allTbody.insertAdjacentHTML(INSERT_POSITION.BEFORE_END, allTabTemplateHtml)

      const addedRow = allTbody.querySelector(`tr[${DATA_ATTRIBUTE.UNIQUE_ID}="${allTabUniqueId}"]`)
      if (addedRow) {
        Logger.log(`Added row to ALL tab with category-id: ${addedRow.getAttribute('data-category-id')}`)
      }
    }
  }

  createElementFromTemplate(template, categoryId, categoryName) {
    if (!template || !template.content) {
      Logger.warn(LOG_MESSAGES.INVALID_TEMPLATE)
      return null
    }

    const clone = template.content.cloneNode(true)
    const element = clone.querySelector(SELECTOR.TAB_PANE)

    if (!element) {
      Logger.warn(LOG_MESSAGES.TAB_PANE_NOT_FOUND)
      return null
    }

    const paneId = ELEMENT_ID.CATEGORY_PANE(categoryId)
    element[HTML_ATTRIBUTE.ID] = paneId
    element.setAttribute(DATA_ATTRIBUTE.CATEGORY_ID, categoryId)
    element.setAttribute(HTML_ATTRIBUTE.ARIA_LABELLEDBY, ELEMENT_ID.CATEGORY_TAB(categoryId))

    const categoryNameElement = element.querySelector(SELECTOR.CATEGORY_NAME)
    if (categoryNameElement) {
      categoryNameElement.textContent = categoryName
    }

    const elementsWithPlaceholder = element.querySelectorAll(SELECTOR.CATEGORY_BY_ID(TEMPLATE_PLACEHOLDER.CATEGORY_ID))
    elementsWithPlaceholder.forEach(el => {
      el.setAttribute(DATA_ATTRIBUTE.CATEGORY_ID, categoryId)
    })

    const elementsWithTemplateId = element.querySelectorAll(SELECTOR.TEMPLATE_ID)
    elementsWithTemplateId.forEach(el => {
      const templateId = el.getAttribute(DATA_ATTRIBUTE.TEMPLATE_ID)
      if (templateId && templateId.includes(TEMPLATE_PLACEHOLDER.CATEGORY_ID)) {
        el.setAttribute(DATA_ATTRIBUTE.TEMPLATE_ID, templateId.replace(new RegExp(TEMPLATE_PLACEHOLDER.CATEGORY_ID, 'g'), categoryId))
      }
    })

    const tbody = element.querySelector(HTML_ELEMENT.TBODY)
    if (tbody) {
      tbody.setAttribute(DATA_ATTRIBUTE.CATEGORY_ID, categoryId)
      Logger.log(LOG_MESSAGES.TBODY_CATEGORY_ID_SET(categoryId))
    } else {
      Logger.warn(LOG_MESSAGES.TBODY_NOT_FOUND_IN_TEMPLATE)
    }

    const addButton = element.querySelector(SELECTOR.ADD_BUTTON)
    if (addButton) {
      addButton.setAttribute(DATA_ATTRIBUTE.CATEGORY_ID, categoryId)
    }

    return element
  }

  switchToTab(categoryId) {
    if (!this.hasTabNavTarget || !this.hasContentContainerTarget) return

    this.tabNavTarget.querySelectorAll(SELECTOR.BS_TAB_TOGGLE).forEach(tab => {
      tab.classList.remove(CSS_CLASSES.ACTIVE)
      tab.setAttribute(HTML_ATTRIBUTE.ARIA_SELECTED, ARIA_VALUE.FALSE)
    })

    this.contentContainerTarget.querySelectorAll(SELECTOR.TAB_PANE).forEach(pane => {
      pane.classList.remove(CSS_CLASSES.SHOW, CSS_CLASSES.ACTIVE)
    })

    const selectedTab = this.tabNavTarget.querySelector(SELECTOR.CATEGORY_BY_ID(categoryId))
    const selectedPane = this.contentContainerTarget.querySelector(SELECTOR.PANE_BY_ID(categoryId))

    if (selectedTab && selectedPane) {
      selectedTab.classList.add(CSS_CLASSES.ACTIVE)
      selectedTab.setAttribute(HTML_ATTRIBUTE.ARIA_SELECTED, ARIA_VALUE.TRUE)
      selectedPane.classList.add(CSS_CLASSES.SHOW, CSS_CLASSES.ACTIVE)
    }
  }

  deleteTab(event) {
    event.preventDefault()
    event.stopPropagation()
    event.stopImmediatePropagation()

    const button = event.currentTarget
    const categoryId = String(button.dataset.categoryId)

    if (!categoryId) {
      Logger.warn(LOG_MESSAGES.INVALID_CATEGORY_ID_FOR_DELETION)
      return
    }

    const confirmMessage = i18n.t(I18N_KEYS.CONFIRM_DELETE)
    if (!confirm(confirmMessage)) {
      return
    }

    window._deletingCategory = true

    try {
      Logger.log(`=== Deleting category ${categoryId} ===`)

      // カテゴリタブのペインを探す
      let tabPane = document.getElementById(`nav-${categoryId}`)
      if (!tabPane) {
        tabPane = document.getElementById(`category-pane-${categoryId}`)
      }
      if (!tabPane) {
        const tabButton = this.tabNavTarget.querySelector(SELECTOR.CATEGORY_BY_ID(categoryId))
        if (tabButton) {
          const paneId = tabButton.getAttribute(HTML_ATTRIBUTE.ARIA_CONTROLS)
          if (paneId) {
            tabPane = document.getElementById(paneId)
          }
        }
      }

      // カテゴリタブ内の行を処理（新規追加データ用）
      if (tabPane) {
        const categoryTbody = tabPane.querySelector(HTML_ELEMENT.TBODY)
        if (categoryTbody) {
          const allRows = Array.from(categoryTbody.querySelectorAll(HTML_ELEMENT.TR))
          Logger.log(`Deleting ${allRows.length} rows from category ${categoryId}`)

          allRows.forEach((row) => {
            let destroyInput = row.querySelector('input[name*="[_destroy]"]')
            if (!destroyInput) {
              // _destroyフィールドがない場合は作成
              const idInput = row.querySelector('input[name*="[id]"]')
              if (idInput && idInput.name) {
                const destroyName = idInput.name.replace('[id]', '[_destroy]')
                destroyInput = document.createElement('input')
                destroyInput.type = 'hidden'
                destroyInput.name = destroyName
                destroyInput.value = '1'
                row.appendChild(destroyInput)
                Logger.log(`Created _destroy field: ${destroyName}`)
              }
            } else {
              destroyInput.value = '1'
            }
            row.classList.add('d-none')
            // idと_destroy以外をdisabledにする（idはフォーム送信に必要）
            row.querySelectorAll('input:not([name*="[_destroy]"]):not([name*="[id]"]), select, textarea').forEach(field => {
              field.disabled = true
            })
          })
        }
      }

      // ALLタブ内の行を処理（既存データ + 新規追加データ）
      const allTbody = document.querySelector('tbody[data-category-id="0"]')

      if (allTbody) {
        // data-category-id で検索（新規追加データ）
        const allRows = Array.from(allTbody.querySelectorAll('tr[data-category-id]'))
        const foundRows = allRows.filter(row => {
          const rowCategoryId = String(row.getAttribute('data-category-id'))
          return rowCategoryId === categoryId
        })

        Logger.log(`Found ${foundRows.length} rows in ALL tab with data-category-id="${categoryId}"`)

        foundRows.forEach((row) => {
          const destroyInput = row.querySelector('input[name*="[_destroy]"]')
          if (destroyInput) {
            destroyInput.value = '1'
          }
          row.classList.add('d-none')
          row.querySelectorAll('input:not([name*="[_destroy]"]):not([name*="[id]"]), select, textarea').forEach(field => {
            field.disabled = true
          })
        })

        // 既存データの処理：現在表示されているカテゴリタブと同じIDを持つ行を検索
        if (tabPane) {
          const categoryTbody = tabPane.querySelector(HTML_ELEMENT.TBODY)
          if (categoryTbody) {
            // カテゴリタブ内に表示されていた行のIDを収集（material_idまたはproduct_id）
            const displayedRows = Array.from(categoryTbody.querySelectorAll(HTML_ELEMENT.TR))
            displayedRows.forEach(catRow => {
              // 商品原材料の場合：material_id
              let itemSelect = catRow.querySelector('select[name*="[material_id]"]')
              let itemIdName = 'material_id'

              // 製造計画の場合：product_id
              if (!itemSelect) {
                itemSelect = catRow.querySelector('select[name*="[product_id]"]')
                itemIdName = 'product_id'
              }

              if (itemSelect && itemSelect.value) {
                const itemId = itemSelect.value
                // ALLタブから同じIDを持つ行を検索
                const allRowsToDelete = Array.from(allTbody.querySelectorAll('tr')).filter(allRow => {
                  const allItemSelect = allRow.querySelector(`select[name*="[${itemIdName}]"]`)
                  return allItemSelect && allItemSelect.value === itemId
                })

                Logger.log(`Found ${allRowsToDelete.length} existing data rows in ALL tab with ${itemIdName}="${itemId}"`)

                allRowsToDelete.forEach((row) => {
                  let destroyInput = row.querySelector('input[name*="[_destroy]"]')
                  if (!destroyInput) {
                    // _destroyフィールドがない場合は作成
                    const idInput = row.querySelector('input[name*="[id]"]')
                    if (idInput && idInput.name) {
                      const destroyName = idInput.name.replace('[id]', '[_destroy]')
                      destroyInput = document.createElement('input')
                      destroyInput.type = 'hidden'
                      destroyInput.name = destroyName
                      destroyInput.value = '1'
                      row.appendChild(destroyInput)
                      Logger.log(`Created _destroy field for existing data: ${destroyName}`)
                    }
                  } else {
                    destroyInput.value = '1'
                  }
                  row.classList.add('d-none')
                  // idと_destroy以外をdisabledにする（idはフォーム送信に必要）
                  row.querySelectorAll('input:not([name*="[_destroy]"]):not([name*="[id]"]), select, textarea').forEach(field => {
                    field.disabled = true
                  })
                })
              }
            })
          }
        }
      }

      // 合計再計算
      const totalsController = this.application.getControllerForElementAndIdentifier(
        document.querySelector('[data-controller*="form--totals"]'),
        'form--totals'
      )
      if (totalsController) {
        totalsController.recalculateTotals()
      }

      // アクティブタブの切り替え
      const tabButton = this.tabNavTarget.querySelector(SELECTOR.CATEGORY_BY_ID(categoryId))
      const isActiveTab = tabButton && tabButton.classList.contains(CSS_CLASSES.ACTIVE)

      if (isActiveTab) {
        const allTab = this.tabNavTarget.querySelector(SELECTOR.CATEGORY_BY_ID(DEFAULT_CATEGORY_ID))
        const allPane = document.getElementById('nav-0')

        if (allTab && allPane) {
          this.tabNavTarget.querySelectorAll(SELECTOR.NAV_LINK).forEach(tab => {
            tab.classList.remove(CSS_CLASSES.ACTIVE)
            tab.setAttribute(HTML_ATTRIBUTE.ARIA_SELECTED, ARIA_VALUE.FALSE)
          })

          this.contentContainerTarget.querySelectorAll(SELECTOR.TAB_PANE).forEach(pane => {
            pane.classList.remove(CSS_CLASSES.SHOW, CSS_CLASSES.ACTIVE)
          })

          allTab.classList.add(CSS_CLASSES.ACTIVE)
          allTab.setAttribute(HTML_ATTRIBUTE.ARIA_SELECTED, ARIA_VALUE.TRUE)
          allPane.classList.add(CSS_CLASSES.SHOW, CSS_CLASSES.ACTIVE)
        }
      }

      // タブボタンとペインを削除
      if (tabButton) {
        const tabButtonLi = tabButton.closest('li')

        if (tabButtonLi) {
          tabButtonLi.remove()
        } else {
          tabButton.remove()
          const closeButton = this.tabNavTarget.querySelector(`span[data-category-id="${categoryId}"]`)
          if (closeButton) {
            closeButton.remove()
          }
        }
      }

      if (tabPane) {
        tabPane.remove()
      }

      this.enableCategoryInSelector(categoryId)
      this.enableCategoryInModal(categoryId)

      Logger.log(LOG_MESSAGES.CATEGORY_TAB_DELETED(categoryId))

    } finally {
      delete window._deletingCategory
    }
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
      SELECTOR.CATEGORY_BY_ID(categoryId)
    )
    if (categoryItem) {
      categoryItem.classList.add(CSS_CLASSES.DISABLED, CSS_CLASSES.TEXT_MUTED)
      categoryItem.style[STYLE_PROPERTY.POINTER_EVENTS] = STYLE_VALUE.POINTER_EVENTS_NONE
      categoryItem.style[STYLE_PROPERTY.OPACITY] = STYLE_VALUE.OPACITY_HALF
    }
  }

  enableCategoryInModal(categoryId) {
    if (!this.hasAddCategoryModalTarget) return

    const categoryItem = this.addCategoryModalTarget.querySelector(
      SELECTOR.CATEGORY_BY_ID(categoryId)
    )
    if (categoryItem) {
      categoryItem.classList.remove(CSS_CLASSES.DISABLED, CSS_CLASSES.TEXT_MUTED)
      categoryItem.style[STYLE_PROPERTY.POINTER_EVENTS] = STYLE_VALUE.EMPTY
      categoryItem.style[STYLE_PROPERTY.OPACITY] = STYLE_VALUE.EMPTY
    }
  }

  enableCategoryInSelector(categoryId) {
    if (!this.hasCategorySelectorTarget) return

    const option = Array.from(this.categorySelectorTarget.options).find(
      opt => opt.value === categoryId
    )

    if (option) {
      option[HTML_ATTRIBUTE.DISABLED] = false
      Logger.log(LOG_MESSAGES.CATEGORY_OPTION_RE_ENABLED(categoryId))
    } else {
      Logger.warn(LOG_MESSAGES.CATEGORY_OPTION_NOT_FOUND(categoryId))
    }
  }

  escapeHtml(text) {
    return text.replace(REGEX.HTML_ESCAPE, m => HTML_ESCAPE_MAP[m])
  }

  disconnect() {
    Logger.log(LOG_MESSAGES.CONTROLLER_DISCONNECTED)
  }
}