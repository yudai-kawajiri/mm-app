import { Controller } from "@hotwired/stimulus"
import i18n from "controllers/i18n"
import Logger from "utils/logger"

const API_ENDPOINT = {
  MATERIAL_UNIT_DATA: (materialId) => `/api/v1/materials/${materialId}/fetch_product_unit_data`
}

const HTTP_HEADERS = {
  ACCEPT: 'application/json',
  X_REQUESTED_WITH: 'XMLHttpRequest'
}

const DATA_ATTRIBUTE = {
  UNIQUE_ID: 'uniqueId'
}

const SELECTOR = {
  ROW_BY_UNIQUE_ID: (uniqueId) => `tr[data-unique-id="${uniqueId}"]`,
  MATERIAL_SELECT: '[data-resources--product-material--material-target="materialSelect"]',
  QUANTITY_INPUT: '[data-resources--product-material--material-target="quantityInput"]',
  UNIT_WEIGHT_INPUT: '[data-resources--product-material--material-target="unitWeightInput"]'
}

const EVENT_TYPE = {
  CHANGE: 'change',
  INPUT: 'input'
}

const EVENT_OPTIONS = {
  BUBBLES: { bubbles: true }
}

const DEFAULT_VALUE = {
  ZERO: 0,
  EMPTY_STRING: ''
}

const DISPLAY_TEXT = {
  UNIT_NOT_SET: '未設定',
  UNIT_ERROR: 'エラー',
  PLEASE_SELECT: '選択してください'
}

const I18N_KEYS = {
  UNIT_FETCH_FAILED: 'product_material.errors.unit_fetch_failed',
  UNIT_NOT_SET: 'product_material.unit_not_set',
  UNIT_ERROR: 'product_material.unit_error'
}

const LOG_MESSAGES = {
  CONTROLLER_CONNECTED: 'Material controller connected',
  HAS_MATERIAL_SELECT: '  Has materialSelect:',
  HAS_UNIT_DISPLAY: '  Has unitDisplay:',
  HAS_UNIT_ID_INPUT: '  Has unitIdInput:',
  HAS_UNIT_WEIGHT_INPUT: '  Has unitWeightInput:',
  EXISTING_MATERIAL_DETECTED: 'Existing material detected:',
  NO_MATERIAL_SELECTED: 'No material selected yet',
  MATERIAL_CHANGED: 'Material changed:',
  FETCHING_UNIT_DATA: 'Fetching unit data for material:',
  FETCH_ERROR: 'Fetch error:',
  RECEIVED_UNIT_DATA: 'Received unit data:',
  UPDATED_UNIT_ID: (oldValue, newValue) => `Updated unit_id: ${oldValue} → ${newValue}`,
  SET_UNIT_NAME: 'Set unit_name:',
  SET_DEFAULT_UNIT_WEIGHT: 'Set default_unit_weight:',
  KEEPING_EXISTING_UNIT_WEIGHT: 'Keeping existing unit_weight:',
  UNIT_UPDATED: (unitName) => `Unit updated: ${unitName}`,
  UNIT_RESET: 'Unit reset to default',
  SYNCING_MATERIAL: (materialId, uniqueId) => `Syncing material ${materialId} for ${uniqueId}`,
  SYNCING_QUANTITY: (quantity, uniqueId) => `Syncing quantity ${quantity} for ${uniqueId}`,
  SYNCING_UNIT_WEIGHT: (unitWeight, uniqueId) => `Syncing unit_weight ${unitWeight} for ${uniqueId}`,
  SKIPPING_MATERIAL_DISABLE: 'Skipping material disabling: All tab or no category ID',
  TBODY_NOT_FOUND: 'tbody[data-category-id] not found',
  SELECTED_MATERIAL_IDS: (categoryId, ids) => `Selected material IDs in category ${categoryId}:`,
  MATERIAL_DISABLED: (materialId) => `Disabled material ID ${materialId}`,
  MATERIAL_DISABLE_COMPLETED: 'Disabled selected materials in same tab'
}

export default class extends Controller {
  static targets = ["materialSelect", "materialNameDisplay", "materialIdHidden", "unitDisplay", "quantityInput", "unitWeightInput", "unitIdInput"]

  connect() {
    Logger.log(LOG_MESSAGES.CONTROLLER_CONNECTED)
    Logger.log(LOG_MESSAGES.HAS_MATERIAL_SELECT, this.hasMaterialSelectTarget)
    Logger.log('  Has materialNameDisplay:', this.hasMaterialNameDisplayTarget)
    Logger.log('  Has materialIdHidden:', this.hasMaterialIdHiddenTarget)
    Logger.log(LOG_MESSAGES.HAS_UNIT_DISPLAY, this.hasUnitDisplayTarget)
    Logger.log(LOG_MESSAGES.HAS_UNIT_ID_INPUT, this.hasUnitIdInputTarget)
    Logger.log(LOG_MESSAGES.HAS_UNIT_WEIGHT_INPUT, this.hasUnitWeightInputTarget)

    let materialId = null

    if (this.hasMaterialSelectTarget && this.materialSelectTarget.value) {
      materialId = this.materialSelectTarget.value
    } else if (this.hasMaterialIdHiddenTarget && this.materialIdHiddenTarget.value) {
      materialId = this.materialIdHiddenTarget.value
    }

    if (materialId) {
      Logger.log(LOG_MESSAGES.EXISTING_MATERIAL_DETECTED, materialId)
      setTimeout(() => {
        this.enableInputFields()
        Logger.log('Input fields enabled after delay')
      }, 100)
      this.fetchUnitData(materialId)
    } else {
      Logger.log(LOG_MESSAGES.NO_MATERIAL_SELECTED)
      this.disableInputFields()
    }

    setTimeout(() => {
      this.disableSelectedMaterialsInSameTab()
    }, 200)
  }

  updateUnit(event) {
    const materialId = event.target.value
    Logger.log(LOG_MESSAGES.MATERIAL_CHANGED, materialId)

    if (!materialId) {
      this.resetUnit()
      this.resetAllTabMaterial()
      this.disableInputFields()
      return
    }

    this.enableInputFields()
    this.fetchUnitData(materialId)
    this.disableSelectedMaterialsInSameTab()
  }

  async fetchUnitData(materialId) {
    try {
      Logger.log(LOG_MESSAGES.FETCHING_UNIT_DATA, materialId)

      const response = await fetch(API_ENDPOINT.MATERIAL_UNIT_DATA(materialId), {
        headers: {
          'Accept': HTTP_HEADERS.ACCEPT,
          'X-Requested-With': HTTP_HEADERS.X_REQUESTED_WITH
        }
      })

      if (!response.ok) {
        throw new Error(`AJAX request failed with status: ${response.status}`)
      }

      const data = await response.json()

      this.updateUnitDisplay(data)
      this.syncMaterialNameToAllTab()
      this.syncUnitToAllTab()
    } catch (error) {
      Logger.error(i18n.t(I18N_KEYS.UNIT_FETCH_FAILED), error)
      Logger.log(LOG_MESSAGES.FETCH_ERROR, error)
      this.resetUnit()
    }
  }

  updateUnitDisplay(data) {
    Logger.log(LOG_MESSAGES.RECEIVED_UNIT_DATA, data)

    if (this.hasUnitIdInputTarget) {
      const oldValue = this.unitIdInputTarget.value
      this.unitIdInputTarget.value = data.unit_id || DEFAULT_VALUE.EMPTY_STRING
      Logger.log(LOG_MESSAGES.UPDATED_UNIT_ID(oldValue, data.unit_id))
    }

    if (this.hasUnitDisplayTarget) {
      this.unitDisplayTarget.textContent = data.unit_name || DISPLAY_TEXT.UNIT_NOT_SET
      Logger.log(LOG_MESSAGES.SET_UNIT_NAME, data.unit_name)
    }

    if (this.hasUnitWeightInputTarget) {
      const currentValue = this.unitWeightInputTarget.value

      if (!currentValue || parseFloat(currentValue) === DEFAULT_VALUE.ZERO) {
        this.unitWeightInputTarget.value = data.default_unit_weight || DEFAULT_VALUE.ZERO
        Logger.log(LOG_MESSAGES.SET_DEFAULT_UNIT_WEIGHT, data.default_unit_weight)
      } else {
        Logger.log(LOG_MESSAGES.KEEPING_EXISTING_UNIT_WEIGHT, currentValue)
      }
    }

    Logger.log(LOG_MESSAGES.UNIT_UPDATED(data.unit_name))
  }

  resetUnit() {
    if (this.hasUnitDisplayTarget) {
      this.unitDisplayTarget.textContent = DISPLAY_TEXT.UNIT_NOT_SET
    }

    if (this.hasUnitIdInputTarget) {
      this.unitIdInputTarget.value = DEFAULT_VALUE.EMPTY_STRING
    }

    if (this.hasUnitWeightInputTarget) {
      this.unitWeightInputTarget.value = DEFAULT_VALUE.EMPTY_STRING
    }

    if (this.hasQuantityInputTarget) {
      this.quantityInputTarget.value = DEFAULT_VALUE.EMPTY_STRING
    }

    Logger.log(LOG_MESSAGES.UNIT_RESET)
  }

  setError() {
    if (this.hasUnitDisplayTarget) {
      this.unitDisplayTarget.textContent = DISPLAY_TEXT.UNIT_ERROR
    }
  }

  enableInputFields() {
    if (this.hasQuantityInputTarget) {
      this.quantityInputTarget.disabled = false
      Logger.log('Quantity input enabled')
    }

    if (this.hasUnitWeightInputTarget) {
      this.unitWeightInputTarget.disabled = false
      Logger.log('Unit weight input enabled')
    }
  }

  disableInputFields() {
    if (this.hasQuantityInputTarget) {
      this.quantityInputTarget.disabled = true
      Logger.log('Quantity input disabled')
    }

    if (this.hasUnitWeightInputTarget) {
      this.unitWeightInputTarget.disabled = true
      Logger.log('Unit weight input disabled')
    }
  }

  syncMaterialNameToAllTab() {
    const rowUniqueId = this.element.dataset.uniqueId
    if (!rowUniqueId) {
      Logger.warn('Row unique ID not found, cannot sync material name to ALL tab')
      return
    }

    let allTabRow = document.querySelector(`#nav-0 tr[data-unique-id="${rowUniqueId}"]`)

    if (!allTabRow) {
      Logger.warn(`ALL tab row not found for unique ID: ${rowUniqueId}, creating new row`)
      allTabRow = this.createAllTabRow(rowUniqueId)
      if (!allTabRow) {
        Logger.error('Failed to create ALL tab row')
        return
      }
    }

    let materialId = null
    let materialName = null

    if (this.hasMaterialSelectTarget && this.materialSelectTarget.value) {
      materialId = this.materialSelectTarget.value
      const selectedOption = this.materialSelectTarget.options[this.materialSelectTarget.selectedIndex]
      materialName = selectedOption ? selectedOption.text : ''
    }

    if (!materialId || !materialName) {
      Logger.warn('Material ID or name not found, skipping sync')
      return
    }

    Logger.log(`Syncing material name to ALL tab: ${materialName} (ID: ${materialId})`)

    const allTabRowController = this.application.getControllerForElementAndIdentifier(
      allTabRow,
      'resources--product-material--material'
    )

    if (allTabRowController && allTabRowController !== this) {
      if (allTabRowController.hasMaterialNameDisplayTarget) {
        allTabRowController.materialNameDisplayTarget.textContent = materialName
        Logger.log(`Updated materialNameDisplay in ALL tab: ${materialName}`)
      }

      if (allTabRowController.hasMaterialIdHiddenTarget) {
        allTabRowController.materialIdHiddenTarget.value = materialId
        Logger.log(`Updated materialIdHidden in ALL tab: ${materialId}`)
      }

      if (allTabRowController.hasQuantityInputTarget) {
        allTabRowController.quantityInputTarget.disabled = false
        Logger.log('ALL tab quantity input force enabled')
      }

      if (allTabRowController.hasUnitWeightInputTarget) {
        allTabRowController.unitWeightInputTarget.disabled = false
        Logger.log('ALL tab unit weight input force enabled')
      }

      Logger.log('ALL tab material name updated')
    } else {
      Logger.warn('ALL tab row controller not found or is same instance')
    }
  }

  createAllTabRow(uniqueId) {
    Logger.log(`Creating new ALL tab row with uniqueId: ${uniqueId}`)

    const categoryId = this.element.dataset.categoryId || this.element.dataset.originalCategoryId

    const allTbody = document.querySelector('#nav-0 tbody[data-category-id="0"]')
    if (!allTbody) {
      Logger.error('ALL tab tbody not found')
      return null
    }

    const template = document.getElementById('material_fields_template_0')
    if (!template) {
      Logger.error('material_fields_template_0 not found')
      return null
    }

    let templateHtml = template.innerHTML.replace(/NEW_RECORD/g, uniqueId)
    templateHtml = templateHtml.replace(/row_NEW_RECORD/g, `row_${uniqueId}`)

    templateHtml = templateHtml.replace(
      /data-category-id="[^"]*"/g,
      'data-category-id="0"'
    )

    templateHtml = templateHtml.replace(
      /<tr([^>]*)>/,
      `<tr$1 data-original-category-id="${categoryId}">`
    )

    allTbody.insertAdjacentHTML('beforeend', templateHtml)

    const newRow = allTbody.querySelector(`tr[data-unique-id="${uniqueId}"]`)
    Logger.log(`Created new ALL tab row: ${uniqueId}`)

    return newRow
  }

  syncUnitToAllTab() {
    const rowUniqueId = this.element.dataset.uniqueId
    if (!rowUniqueId) {
      Logger.warn('Row unique ID not found, cannot sync to ALL tab')
      return
    }

    const allTabRow = document.querySelector(`#nav-0 tr[data-unique-id="${rowUniqueId}"]`)
    if (!allTabRow) {
      Logger.warn(`ALL tab row not found for unique ID: ${rowUniqueId}`)
      return
    }

    if (this.hasUnitIdInputTarget) {
      allTabRow.dataset.unitId = this.unitIdInputTarget.value || ''
    }

    Logger.log(`ALL tab row updated: unit_id=${this.unitIdInputTarget.value}`)

    const allTabRowController = this.application.getControllerForElementAndIdentifier(
      allTabRow,
      'resources--product-material--material'
    )

    if (allTabRowController && allTabRowController !== this) {
      if (allTabRowController.hasUnitIdInputTarget && this.hasUnitIdInputTarget) {
        allTabRowController.unitIdInputTarget.value = this.unitIdInputTarget.value
      }

      if (allTabRowController.hasUnitDisplayTarget && this.hasUnitDisplayTarget) {
        allTabRowController.unitDisplayTarget.textContent = this.unitDisplayTarget.textContent
      }

      if (allTabRowController.hasUnitWeightInputTarget && this.hasUnitWeightInputTarget) {
        const currentValue = allTabRowController.unitWeightInputTarget.value
        if (!currentValue || parseFloat(currentValue) === DEFAULT_VALUE.ZERO) {
          allTabRowController.unitWeightInputTarget.value = this.unitWeightInputTarget.value
        }
      }

      Logger.log('ALL tab row controller updated')
    } else {
      Logger.warn('ALL tab row controller not found or is same instance')
    }
  }

  resetAllTabMaterial() {
    const rowUniqueId = this.element.dataset.uniqueId
    if (!rowUniqueId) {
      Logger.warn('Row unique ID not found, cannot reset ALL tab material')
      return
    }

    const allTabRow = document.querySelector(`#nav-0 tr[data-unique-id="${rowUniqueId}"]`)
    if (!allTabRow) {
      Logger.log(`ALL tab row not found for unique ID: ${rowUniqueId}, no reset needed`)
      return
    }

    const allTabRowController = this.application.getControllerForElementAndIdentifier(
      allTabRow,
      'resources--product-material--material'
    )

    if (allTabRowController && allTabRowController !== this) {
      if (allTabRowController.hasMaterialNameDisplayTarget) {
        allTabRowController.materialNameDisplayTarget.textContent = DISPLAY_TEXT.PLEASE_SELECT
      }

      if (allTabRowController.hasMaterialIdHiddenTarget) {
        allTabRowController.materialIdHiddenTarget.value = ''
      }

      allTabRowController.resetUnit()
      allTabRowController.disableInputFields()

      Logger.log('ALL tab material reset completed')
    } else {
      Logger.warn('ALL tab row controller not found or is same instance')
    }
  }

  syncMaterialToOtherTabs(event) {
    const uniqueId = event.target.dataset[DATA_ATTRIBUTE.UNIQUE_ID]
    const selectedMaterialId = event.target.value

    Logger.log(LOG_MESSAGES.SYNCING_MATERIAL(selectedMaterialId, uniqueId))

    document.querySelectorAll(SELECTOR.ROW_BY_UNIQUE_ID(uniqueId)).forEach(row => {
      if (row === this.element) return

      const select = row.querySelector(SELECTOR.MATERIAL_SELECT)
      if (select && select.value !== selectedMaterialId) {
        select.value = selectedMaterialId
        select.dispatchEvent(new Event(EVENT_TYPE.CHANGE, EVENT_OPTIONS.BUBBLES))
      }
    })
  }

  syncQuantityToOtherTabs(event) {
    const uniqueId = event.target.dataset[DATA_ATTRIBUTE.UNIQUE_ID]
    const quantity = event.target.value

    Logger.log(LOG_MESSAGES.SYNCING_QUANTITY(quantity, uniqueId))

    document.querySelectorAll(SELECTOR.ROW_BY_UNIQUE_ID(uniqueId)).forEach(row => {
      if (row === this.element) return

      const input = row.querySelector(SELECTOR.QUANTITY_INPUT)
      if (input && input.value !== quantity) {
        input.value = quantity
      }
    })
  }

  syncUnitWeightToOtherTabs(event) {
    const uniqueId = event.target.dataset[DATA_ATTRIBUTE.UNIQUE_ID]
    const unitWeight = event.target.value

    Logger.log(LOG_MESSAGES.SYNCING_UNIT_WEIGHT(unitWeight, uniqueId))

    document.querySelectorAll(SELECTOR.ROW_BY_UNIQUE_ID(uniqueId)).forEach(row => {
      if (row === this.element) return

      const input = row.querySelector(SELECTOR.UNIT_WEIGHT_INPUT)
      if (input && input.value !== unitWeight) {
        input.value = unitWeight
      }
    })
  }

  disableSelectedMaterialsInSameTab() {
    const currentCategoryId = this.element.dataset.categoryId
    if (!currentCategoryId || currentCategoryId === '0') {
      Logger.log(LOG_MESSAGES.SKIPPING_MATERIAL_DISABLE)
      return
    }

    const tbody = this.element.closest('tbody[data-category-id]')
    if (!tbody) {
      Logger.warn(LOG_MESSAGES.TBODY_NOT_FOUND)
      return
    }

    const rows = tbody.querySelectorAll('tr[data-controller*="resources--product-material--material"]')

    const selectedMaterialIds = []
    rows.forEach(row => {
      const select = row.querySelector('select[data-resources--product-material--material-target="materialSelect"]')
      if (select && select.value) {
        selectedMaterialIds.push(select.value)
      }
    })

    Logger.log(LOG_MESSAGES.SELECTED_MATERIAL_IDS(currentCategoryId, selectedMaterialIds))

    rows.forEach(row => {
      const select = row.querySelector('select[data-resources--product-material--material-target="materialSelect"]')
      if (!select) return

      const currentValue = select.value

      Array.from(select.options).forEach(option => {
        if (option.value && option.value !== currentValue && selectedMaterialIds.includes(option.value)) {
          option.disabled = true
          Logger.log(LOG_MESSAGES.MATERIAL_DISABLED(option.value))
        } else if (option.value && !selectedMaterialIds.includes(option.value)) {
          option.disabled = false
        }
      })
    })

    Logger.log(LOG_MESSAGES.MATERIAL_DISABLE_COMPLETED)
  }
}
