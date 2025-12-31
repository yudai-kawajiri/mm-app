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
    if (!this.eventListenersInitialized) {
      this.eventListenersInitialized = false
    }
    this.initializeEventListeners()
    this.activateFirstTab()
    this.disableExistingCategoryOptions()
  }

  disconnect() {
    Logger.log('CategoryTabsController disconnected')
    this.eventListenersInitialized = false
  }

  initializeEventListeners() {
    if (this.eventListenersInitialized) {
      Logger.log('Event listeners already initialized, skipping')
      return
    }

    this.element.addEventListener('click', (e) => {
      const tabButton = e.target.closest('[data-bs-toggle="tab"]')
      if (tabButton) {
        if (e.target.closest('[data-action*="deleteTab"]')) {
          return
        }
        this.handleTabClick(e, tabButton)
        return
      }

      const deleteButton = e.target.closest('[data-action*="deleteTab"]')
      if (deleteButton) {
        e.preventDefault()
        e.stopPropagation()
        this.deleteTab({ currentTarget: deleteButton })
        return
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

    this.eventListenersInitialized = true
    Logger.log('Event listeners initialized')
  }

  handleTabClick(event, tabButton) {
    event.preventDefault()

    const categoryId = tabButton.getAttribute('data-category-id')
    Logger.log(`Tab clicked: ${categoryId}`)

    const tabPane = this.contentContainerTarget.querySelector(`#category-pane-${categoryId}`)
    if (!tabPane) {
      Logger.warn(`Tab pane not found for category: ${categoryId}`)
      return
    }

    if (categoryId && categoryId !== '0') {
      this.copyExistingRowsToNewTab(categoryId)
    }

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

      if (allTabButton) {
        this.tabNavTarget.insertBefore(tabItem, allTabButton.nextSibling)
      } else {
        this.tabNavTarget.appendChild(tabItem)
      }

      const tab = new bootstrap.Tab(tabItem)
      tab.show()

      Logger.log(`Category tab added: ${categoryName} (${categoryId})`)

      this.disableExistingCategoryOptions()
      this.disableCategoryInModal(categoryId)

      this.closeModal()
    }
  }

  createTabItem(categoryId, categoryName) {
    const button = document.createElement('button')
    button.className = 'nav-link position-relative category-tab-with-close'
    button.id = `category-tab-${categoryId}`
    button.setAttribute('data-bs-toggle', 'tab')
    button.setAttribute('data-bs-target', `#category-pane-${categoryId}`)
    button.setAttribute('data-category-id', categoryId)
    button.setAttribute('type', 'button')
    button.setAttribute('role', 'tab')
    button.setAttribute('aria-controls', `category-pane-${categoryId}`)
    button.setAttribute('aria-selected', 'false')

    button.innerHTML = `
      ${this.escapeHtml(categoryName)}
      <span class="position-absolute top-50 end-0 translate-middle-y pe-2"
            style="cursor: pointer; font-weight: bold; color: #dc3545; z-index: 10;"
            data-action="click->tabs--category-tabs#deleteTab"
            data-category-id="${categoryId}">
        ×
      </span>
    `

    return button
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
      `<tr$1 data-category-id="${categoryId}" data-initial-row="true" data-unique-id="${uniqueId}">`
    )

    categoryTbody.insertAdjacentHTML('beforeend', templateHtml)
    Logger.log(`Initial form row added to category ID: ${categoryId}, uniqueId: ${uniqueId}`)

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
          `<tr$1 data-initial-row="true">`
        )

        allTbody.insertAdjacentHTML('beforeend', allTabTemplateHtml)

        Logger.log(`Inserted row to ALL tab, now setting attributes...`)

        const insertedRow = allTbody.querySelector(`tr:last-child`)
        if (insertedRow) {
          insertedRow.setAttribute('data-original-category-id', categoryId)
          insertedRow.setAttribute('data-unique-id', uniqueId)

          Logger.log(`Set attributes: data-original-category-id="${categoryId}", data-unique-id="${uniqueId}"`)
          Logger.log(`Verification: dataset.originalCategoryId="${insertedRow.dataset.originalCategoryId}"`)
        } else {
          Logger.error(`Failed to find inserted row`)
        }
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

    const allTabRows = Array.from(document.querySelectorAll(`tbody[data-category-id="0"] tr`)).filter(row => {
      const originalCategoryId = row.dataset.originalCategoryId?.replace(/['"]/g, '')
      const isHidden = row.classList.contains('d-none')
      const hasData = row.querySelector('select[name*="[material_id]"], select[name*="[product_id]"]')?.value

      Logger.log(`Checking ALL tab row: originalCategoryId=${originalCategoryId}, target=${categoryId}, isHidden=${isHidden}, hasData=${hasData}`)

      return originalCategoryId === String(categoryId) && !isHidden && hasData
    })

    if (allTabRows.length === 0) {
      Logger.log(`No existing data rows found in ALL tab for category: ${categoryId}`)
      return
    }

    Logger.log(`Found ${allTabRows.length} existing row(s) in ALL tab for category: ${categoryId}`)

    const existingUniqueIds = Array.from(categoryTbody.querySelectorAll('tr')).map(row => row.dataset.uniqueId).filter(Boolean)
    Logger.log(`Existing uniqueIds in category tab: ${existingUniqueIds.join(', ')}`)

    allTabRows.forEach(allTabRow => {
      const originalUniqueId = allTabRow.dataset.uniqueId

      if (existingUniqueIds.includes(originalUniqueId)) {
        Logger.log(`Row with uniqueId ${originalUniqueId} already exists in category tab, skipping`)
        return
      }

      Logger.log(`Copying row with uniqueId: ${originalUniqueId}`)

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

      const timestamp = new Date().getTime()
      const randomPart = Math.random().toString(36).substr(2, 9)
      const newUniqueId = `${timestamp}_${randomPart}`

      Logger.log(`Generated new uniqueId: ${newUniqueId} (original: ${originalUniqueId})`)

      let templateHtml = template.innerHTML.replace(/NEW_RECORD/g, newUniqueId)
      templateHtml = templateHtml.replace(/row_NEW_RECORD/g, `row_${newUniqueId}`)

      templateHtml = templateHtml.replace(
        /<tr([^>]*)>/,
        `<tr$1 data-category-id="${categoryId}" data-unique-id="${newUniqueId}">`
      )

      const tempDiv = document.createElement('div')
      tempDiv.innerHTML = templateHtml
      const newRow = tempDiv.querySelector('tr')

      if (!newRow) {
        Logger.warn(`Failed to create row from template for uniqueId: ${newUniqueId}`)
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

      const emptyInitialRow = categoryTbody.querySelector('tr[data-initial-row="true"]')
      if (emptyInitialRow) {
        const materialSelect = emptyInitialRow.querySelector('select[name*="[material_id]"], select[name*="[product_id]"]')
        if (!materialSelect || !materialSelect.value) {
          Logger.log('Removing empty initial row before adding copied row')
          emptyInitialRow.remove()
        }
      }

      categoryTbody.appendChild(newRow)
      Logger.log(`Added existing row to category tab: newUniqueId=${newUniqueId}`)

      existingUniqueIds.push(newUniqueId)
    })

    setTimeout(() => {
      const categoryRows = categoryTbody.querySelectorAll('tr[data-controller*="resources--product-material--material"]')
      categoryRows.forEach(row => {
        const controller = this.application.getControllerForElementAndIdentifier(
          row,
          'resources--product-material--material'
        )
        if (controller && controller.disableSelectedMaterialsInSameTab) {
          controller.disableSelectedMaterialsInSameTab()
          Logger.log(`Re-disabled materials for row in category ${categoryId}`)
        }
      })
    }, 100)
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

    Logger.log(`Delete button clicked for category: ${categoryId}`)

    const confirmMessage = i18n.t('tabs.category_tabs.confirm_delete', { category_id: categoryId })
    if (!confirm(confirmMessage)) {
      Logger.log('Deletion cancelled by user')
      return
    }

    Logger.log(`Starting deletion for category: ${categoryId}`)

    const tabButton = this.tabNavTarget.querySelector(`button[data-category-id="${categoryId}"]`)

    if (!tabButton) {
      Logger.warn(`Tab button not found for category: ${categoryId}`)
      return
    }

    const targetPaneId = tabButton.getAttribute("data-bs-target")
    Logger.log(`Target pane ID: ${targetPaneId}`)

    const allTabBody = this.contentContainerTarget.querySelector('tbody[data-category-id="0"]')

    if (allTabBody) {
      const rowsToRemove = Array.from(allTabBody.querySelectorAll("tr")).filter(
        (row) => {
          const originalCategoryId = row.dataset.originalCategoryId?.replace(/['"]/g, "")
          const targetCategoryId = String(categoryId)
          return originalCategoryId === targetCategoryId
        }
      )

      Logger.log(`Found ${rowsToRemove.length} row(s) to remove/mark in ALL tab`)

      rowsToRemove.forEach((row) => {
        const destroyInput = row.querySelector('input[name*="_destroy"]')
        if (destroyInput) {
          destroyInput.value = "1"
          row.classList.add("d-none")
          Logger.log(`Set _destroy=1 and hidden for row: ${row.dataset.uniqueId}`)
        } else {
          row.remove()
          Logger.log(`Removed new row (no _destroy field): ${row.dataset.uniqueId}`)
        }
      })

      Logger.log(`Removed/marked ${rowsToRemove.length} row(s) for category ${categoryId}`)
    }

    const tabPane = document.querySelector(targetPaneId)
    if (tabPane) {
      tabPane.remove()
      Logger.log(`Tab pane removed: ${targetPaneId}`)
    } else {
      Logger.warn(`Tab pane not found: ${targetPaneId}`)
    }

    tabButton.remove()
    Logger.log(`Tab button removed for category: ${categoryId}`)

    const allTabButton = this.tabNavTarget.querySelector('[data-bs-target="#nav-0"]')
    if (allTabButton) {
      const bsTab = new bootstrap.Tab(allTabButton)
      bsTab.show()
      Logger.log("Switched to ALL tab and displayed content")
    } else {
      Logger.warn('ALL tab button not found')
    }

    const categorySelectors = document.querySelectorAll(
      'select[data-tabs--category-tabs-target="categorySelector"]'
    )
    categorySelectors.forEach((selector) => {
      const option = selector.querySelector(`option[value="${categoryId}"]`)
      if (option) {
        option.disabled = false
        Logger.log(`Category option re-enabled in selector: ${categoryId}`)
      }
    })

    this.enableCategoryInModal(categoryId)

    Logger.log(`Category tab deletion completed: ${categoryId}`)
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
      Logger.log(`Category re-enabled in modal: ${categoryId}`)
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
