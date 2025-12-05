import { Controller } from "@hotwired/stimulus"
import i18n from "controllers/i18n"
import Logger from "utils/logger"

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

  disconnect() {
    Logger.log('CategoryTabsController disconnected')
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
        this.deleteTab({ currentTarget: deleteButton })
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
      Logger.log(`Tab for category ID ${categoryId} already exists`)
      this.switchToTab(categoryId)
      this.categorySelectorTarget.value = ''
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
      this.categorySelectorTarget.value = ''
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
      const allTabButton = this.tabNavTarget.querySelector('[data-category-id="0"]')
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
      <button class="nav-link position-relative category-tab-with-close"
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

      Logger.log(`addInitialFormRow called for category ID: ${categoryId}`)
      setTimeout(() => {
        this.addInitialFormRow(categoryId)
        this.copyExistingRowsToNewTab(categoryId)
      }, 100)

      return tabPane
    }
    return null
  }

  addInitialFormRow(categoryId) {
    Logger.log(`Adding initial form row for category ID: ${categoryId}`)

    const categoryTbody = this.contentContainerTarget.querySelector(`tbody[data-category-id="${categoryId}"]`)

    if (!categoryTbody) {
      Logger.warn(`tbody not found for category ID: ${categoryId}`)
      return
    }

    Logger.log(`tbody found for category ID: ${categoryId}`)

    let templateId = `product_fields_template_${categoryId}`
    let template = document.getElementById(templateId)

    if (!template) {
      templateId = `material_fields_template_${categoryId}`
      template = document.getElementById(templateId)
    }

    if (!template) {
      Logger.warn(`Template not found: product_fields_template_${categoryId} or material_fields_template_${categoryId}`)
      return
    }

    Logger.log(`Template found: ${templateId}`)

    const timestamp = new Date().getTime()
    const uniqueId = `${timestamp}_${Math.random().toString(36).substr(2, 9)}`
    const rowUniqueId = `row_${uniqueId}`
    let templateHtml = template.innerHTML.replace(/NEW_RECORD/g, uniqueId)
    templateHtml = templateHtml.replace(/row_NEW_RECORD/g, rowUniqueId)

    templateHtml = templateHtml.replace(
      /<tr([^>]*)>/,
      `<tr$1 data-category-id="${categoryId}" data-initial-row="true">`
    )

    categoryTbody.insertAdjacentHTML('beforeend', templateHtml)
    Logger.log(`Initial form row added to category ID: ${categoryId}`)

    const allTbody = this.contentContainerTarget.querySelector('tbody[data-category-id="0"]')

    if (allTbody) {
      const allTabTemplate = document.getElementById('product_fields_template_0') ||
                              document.getElementById('material_fields_template_0')

      if (allTabTemplate) {
        let allTabTemplateHtml = allTabTemplate.innerHTML.replace(/NEW_RECORD/g, uniqueId)
        allTabTemplateHtml = allTabTemplateHtml.replace(/row_NEW_RECORD/g, rowUniqueId)

        allTabTemplateHtml = allTabTemplateHtml.replace(
          /data-category-id="[^"]*"/g,
          'data-category-id="0"'
        )

        allTabTemplateHtml = allTabTemplateHtml.replace(
          /<tr([^>]*)>/,
          `<tr$1 data-initial-row="true" data-original-category-id="${categoryId}" data-plan-product-category-id-value="${categoryId}">`
        )

        Logger.log(`Added row to ALL tab with same uniqueId: ${uniqueId}, original category: ${categoryId}`)

        allTbody.insertAdjacentHTML('beforeend', allTabTemplateHtml)
      }
    }
  }

  copyExistingRowsToNewTab(categoryId) {
    Logger.log(`Copying existing rows to category tab: ${categoryId}`)

    const categoryTbody = this.contentContainerTarget.querySelector(`tbody[data-category-id="${categoryId}"]`)

    if (!categoryTbody) {
      Logger.warn(`Category tbody not found for category: ${categoryId}`)
      return
    }

    const allTabRows = document.querySelectorAll(`#nav-0 tr[data-original-category-id="${categoryId}"]`)

    if (allTabRows.length === 0) {
      Logger.log(`No existing rows found for category: ${categoryId}`)
      return
    }

    Logger.log(`Found ${allTabRows.length} existing row(s) for category: ${categoryId}`)

    allTabRows.forEach(allTabRow => {
      const uniqueId = allTabRow.dataset.uniqueId
      Logger.log(`Copying row with uniqueId: ${uniqueId}`)

      let templateId = `product_fields_template_${categoryId}`
      let template = document.getElementById(templateId)

      if (!template) {
        templateId = `material_fields_template_${categoryId}`
        template = document.getElementById(templateId)
      }

      if (!template) {
        Logger.warn(`Template not found for category: ${categoryId}`)
        return
      }

      let templateHtml = template.innerHTML.replace(/NEW_RECORD/g, uniqueId)
      templateHtml = templateHtml.replace(/row_NEW_RECORD/g, `row_${uniqueId}`)

      templateHtml = templateHtml.replace(
        /<tr([^>]*)>/,
        `<tr$1 data-category-id="${categoryId}">`
      )

      const tempDiv = document.createElement('div')
      tempDiv.innerHTML = templateHtml
      const newRow = tempDiv.querySelector('tr')

      if (!newRow) {
        Logger.warn(`Failed to create row from template for uniqueId: ${uniqueId}`)
        return
      }

      const allTabSelect = allTabRow.querySelector('select[name*="[product_id]"], select[name*="[material_id]"]')
      const allTabHiddenId = allTabRow.querySelector('input[type="hidden"][name*="[product_id]"], input[type="hidden"][name*="[material_id]"]')

      if (allTabHiddenId && allTabHiddenId.value) {
        const newRowSelect = newRow.querySelector('select[name*="[product_id]"], select[name*="[material_id]"]')
        if (newRowSelect) {
          newRowSelect.value = allTabHiddenId.value
          Logger.log(`Set product/material_id: ${allTabHiddenId.value}`)
          newRowSelect.dispatchEvent(new Event('change', { bubbles: true }))
        }
      } else if (allTabSelect && allTabSelect.value) {
        const newRowSelect = newRow.querySelector('select[name*="[product_id]"], select[name*="[material_id]"]')
        if (newRowSelect) {
          newRowSelect.value = allTabSelect.value
          newRowSelect.dispatchEvent(new Event('change', { bubbles: true }))
        }
      }

      const allTabQuantity = allTabRow.querySelector('input[name*="[production_count]"], input[name*="[quantity]"]')
      if (allTabQuantity && allTabQuantity.value) {
        const newRowQuantity = newRow.querySelector('input[name*="[production_count]"], input[name*="[quantity]"]')
        if (newRowQuantity) {
          newRowQuantity.value = allTabQuantity.value
          Logger.log(`Set quantity: ${allTabQuantity.value}`)
        }
      }

      const allTabUnitWeight = allTabRow.querySelector('input[name*="[unit_weight]"]')
      if (allTabUnitWeight && allTabUnitWeight.value) {
        const newRowUnitWeight = newRow.querySelector('input[name*="[unit_weight]"]')
        if (newRowUnitWeight) {
          newRowUnitWeight.value = allTabUnitWeight.value
          Logger.log(`Set unit_weight: ${allTabUnitWeight.value}`)
        }
      }

      categoryTbody.appendChild(newRow)
      Logger.log(`Added existing row to category tab: uniqueId=${uniqueId}`)
    })
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

    const elementsWithPlaceholder = element.querySelectorAll('[data-category-id="CATEGORY_ID_PLACEHOLDER"]')
    elementsWithPlaceholder.forEach(el => {
      el.setAttribute('data-category-id', categoryId)
    })

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

  deleteTab(event) {
    const deleteButton = event.currentTarget
    const categoryId = deleteButton.dataset.categoryId

    if (!categoryId) {
      Logger.warn('Invalid category ID for deletion')
      return
    }

    const confirmMessage = i18n.t('components.category_tabs.confirm_delete')
    if (!confirm(confirmMessage)) {
      return
    }

    const allTbody = this.contentContainerTarget.querySelector('tbody[data-category-id="0"]')

    if (allTbody) {
      const categoryRows = allTbody.querySelectorAll(`tr[data-original-category-id="${categoryId}"]`)

      if (categoryRows.length > 0) {
        categoryRows.forEach(row => {
          Logger.log(`Removing product row from ALL tab: category ${categoryId}`)
          row.remove()
        })
      } else {
        Logger.warn(`No rows found with data-category-id="${categoryId}" in ALL tab`)
      }
    }

    const tabButton = this.tabNavTarget.querySelector(`[data-category-id="${categoryId}"]`)
    if (tabButton) {
      if (tabButton.classList.contains('active')) {
        const allTab = this.tabNavTarget.querySelector('[data-category-id="0"]')
        if (allTab) {
          this.tabNavTarget.querySelectorAll('.nav-link').forEach(tab => {
            tab.classList.remove('active')
            tab.setAttribute('aria-selected', 'false')
          })
          allTab.classList.add('active')
          allTab.setAttribute('aria-selected', 'true')

          const allPane = this.contentContainerTarget.querySelector('#nav-0')
          if (allPane) {
            this.contentContainerTarget.querySelectorAll('.tab-pane').forEach(pane => {
              pane.classList.remove('show', 'active')
            })
            allPane.classList.add('show', 'active')
          }
        }
      }

      tabButton.remove()
    }

    const tabPane = this.contentContainerTarget.querySelector(`#category-pane-${categoryId}`)
    if (tabPane) {
      tabPane.remove()
    }

    this.enableCategoryInSelector(categoryId)
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

    const categoryItem = this.addCategoryModalTarget.querySelector(`[data-category-id="${categoryId}"]`)
    if (categoryItem) {
      categoryItem.classList.add('disabled', 'text-muted')
      categoryItem.style.pointerEvents = 'none'
      categoryItem.style.opacity = '0.5'
    }
  }

  enableCategoryInModal(categoryId) {
    if (!this.hasAddCategoryModalTarget) return

    const categoryItem = this.addCategoryModalTarget.querySelector(`[data-category-id="${categoryId}"]`)
    if (categoryItem) {
      categoryItem.classList.remove('disabled', 'text-muted')
      categoryItem.style.pointerEvents = ''
      categoryItem.style.opacity = ''
    }
  }

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
}
