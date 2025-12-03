// Product Material Material Controller
//
// 商品原材料フォームにおける原材料選択時の単位情報取得・表示コントローラー
//
// 責務:
// - 原材料選択時の単位情報API取得
// - 単位表示フィールドの更新
// - デフォルト単位重量の自動設定
// - タブ間の原材料選択同期（複数タブで同じ原材料を編集時）
// - エラーハンドリング（API失敗時のフォールバック）
//
// データフロー:
// 1. ユーザーが原材料セレクトボックスを変更
// 2. updateUnit() が発火
// 3. GET /api/v1/materials/:id/fetch_product_unit_data でJSON取得
// 4. 単位情報（unit_id, unit_name, default_unit_weight）を表示フィールドに反映
// 5. 同期イベントを他タブの同じ原材料行に送信
//
// Targets:
// - materialSelect: 原材料セレクトボックス
// - unitDisplay: 単位表示要素
// - quantityInput: 数量入力フィールド
// - unitWeightInput: 単位重量入力フィールド
// - unitIdInput: 単位ID hidden フィールド
//
// 翻訳キー:
// - product_material.errors.unit_fetch_failed: 単位データ取得失敗メッセージ
// - product_material.unit_not_set: 単位未設定表示
// - product_material.unit_error: 単位取得エラー表示

import { Controller } from "@hotwired/stimulus"
import i18n from "controllers/i18n"
import Logger from "utils/logger"

// 定数定義
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
  SYNCING_UNIT_WEIGHT: (unitWeight, uniqueId) => `Syncing unit_weight ${unitWeight} for ${uniqueId}`
}

export default class extends Controller {
  static targets = ["materialSelect", "unitDisplay", "quantityInput", "unitWeightInput", "unitIdInput"]

  // ============================================================
  // 初期化
  // ============================================================

  // コントローラー接続時の初期化処理
  // 既に原材料が選択されている場合（編集時）、単位情報を取得する
  connect() {
    Logger.log(LOG_MESSAGES.CONTROLLER_CONNECTED)
    Logger.log(LOG_MESSAGES.HAS_MATERIAL_SELECT, this.hasMaterialSelectTarget)
    Logger.log(LOG_MESSAGES.HAS_UNIT_DISPLAY, this.hasUnitDisplayTarget)
    Logger.log(LOG_MESSAGES.HAS_UNIT_ID_INPUT, this.hasUnitIdInputTarget)
    Logger.log(LOG_MESSAGES.HAS_UNIT_WEIGHT_INPUT, this.hasUnitWeightInputTarget)

    // 既に原材料が選択されている場合（編集時）、単位情報を取得
    if (this.hasMaterialSelectTarget && this.materialSelectTarget.value) {
      const materialId = this.materialSelectTarget.value
      Logger.log(LOG_MESSAGES.EXISTING_MATERIAL_DETECTED, materialId)
      this.fetchUnitData(materialId)
    } else {
      Logger.log(LOG_MESSAGES.NO_MATERIAL_SELECTED)
    }
  }

  // ============================================================
  // 原材料選択時の処理
  // ============================================================

  // 原材料選択変更時の処理
  // セレクトボックスで原材料が選択されたとき、APIから単位情報を取得し、
  // 関連するフィールドを更新する。空値の場合は表示をリセットする
  updateUnit(event) {
    const materialId = event.target.value
    Logger.log(LOG_MESSAGES.MATERIAL_CHANGED, materialId)

    if (!materialId) {
      this.resetUnit()
      return
    }

    this.fetchUnitData(materialId)
  }

  // APIから原材料の単位情報を取得
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
    } catch (error) {
      Logger.error(i18n.t(I18N_KEYS.UNIT_FETCH_FAILED), error)
      Logger.log(LOG_MESSAGES.FETCH_ERROR, error)
      this.resetUnit()
    }
  }

  // 単位情報を表示フィールドに反映
  updateUnitDisplay(data) {
    Logger.log(LOG_MESSAGES.RECEIVED_UNIT_DATA, data)

    // unit_id を hidden field に設定
    if (this.hasUnitIdInputTarget) {
      const oldValue = this.unitIdInputTarget.value
      this.unitIdInputTarget.value = data.unit_id || DEFAULT_VALUE.EMPTY_STRING
      Logger.log(LOG_MESSAGES.UPDATED_UNIT_ID(oldValue, data.unit_id))
    }

    // unit_name を表示
    if (this.hasUnitDisplayTarget) {
      this.unitDisplayTarget.textContent = data.unit_name || i18n.t(I18N_KEYS.UNIT_NOT_SET)
      Logger.log(LOG_MESSAGES.SET_UNIT_NAME, data.unit_name)
    }

    // default_unit_weight を入力フィールドに自動設定（編集時は上書きしない）
    if (this.hasUnitWeightInputTarget) {
      const currentValue = this.unitWeightInputTarget.value

      // 値が空欄または0の場合のみデフォルト値を設定
      if (!currentValue || parseFloat(currentValue) === DEFAULT_VALUE.ZERO) {
        this.unitWeightInputTarget.value = data.default_unit_weight || DEFAULT_VALUE.ZERO
        Logger.log(LOG_MESSAGES.SET_DEFAULT_UNIT_WEIGHT, data.default_unit_weight)
      } else {
        Logger.log(LOG_MESSAGES.KEEPING_EXISTING_UNIT_WEIGHT, currentValue)
      }
    }

    Logger.log(LOG_MESSAGES.UNIT_UPDATED(data.unit_name))
  }

  // 単位情報をリセット
  // 全ての単位関連フィールドを初期状態に戻す
  resetUnit() {
    if (this.hasUnitDisplayTarget) {
      this.unitDisplayTarget.textContent = i18n.t(I18N_KEYS.UNIT_NOT_SET)
    }

    if (this.hasUnitIdInputTarget) {
      this.unitIdInputTarget.value = DEFAULT_VALUE.EMPTY_STRING
    }

    if (this.hasUnitWeightInputTarget) {
      this.unitWeightInputTarget.value = DEFAULT_VALUE.EMPTY_STRING
    }

    Logger.log(LOG_MESSAGES.UNIT_RESET)
  }

  // エラー表示を設定
  // API取得失敗時にエラー状態を表示する
  setError() {
    if (this.hasUnitDisplayTarget) {
      this.unitDisplayTarget.textContent = i18n.t(I18N_KEYS.UNIT_ERROR)
    }
  }

  // ============================================================
  // タブ間同期
  // ============================================================

  // 原材料選択を他のタブに同期
  // 複数のカテゴリ―タブで同じ原材料行を使用している場合、
  // 一方のタブで選択された原材料を他方にも反映する
  syncMaterialTotherTabs(event) {
    const uniqueId = event.target.dataset[DATA_ATTRIBUTE.UNIQUE_ID]
    const selectedMaterialId = event.target.value

    Logger.log(LOG_MESSAGES.SYNCING_MATERIAL(selectedMaterialId, uniqueId))

    // 同じunique-idを持つ他のタブの原材料選択を更新
    document.querySelectorAll(SELECTOR.ROW_BY_UNIQUE_ID(uniqueId)).forEach(row => {
      if (row === this.element) return // 自分自身はスキップ

      const select = row.querySelector(SELECTOR.MATERIAL_SELECT)
      if (select && select.value !== selectedMaterialId) {
        select.value = selectedMaterialId
        // change イベントを発火して updateUnit を呼び出す
        select.dispatchEvent(new Event(EVENT_TYPE.CHANGE, EVENT_OPTIONS.BUBBLES))
      }
    })
  }

  // 数量を他のタブに同期
  // 同じ原材料行の数量入力を全タブに同期する
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

  // 単位重量を他のタブに同期
  // 同じ原材料行の単位重量入力を全タブに同期する
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
}
