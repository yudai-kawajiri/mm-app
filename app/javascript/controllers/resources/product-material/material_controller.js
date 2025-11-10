/**
 * @file resources/product-material/material_controller.js
 * 商品原材料フォームにおける原材料選択時の単位情報取得・表示コントローラー
 *
 * @module Controllers/Resources/ProductMaterial
 */

import { Controller } from "@hotwired/stimulus"
import Logger from "utils/logger"

/**
 * Product-Material Material Controller
 *
 * 商品原材料フォームにおける原材料選択時の単位情報取得・表示コントローラー。
 * 原材料のセレクトボックス変更時、サーバーAPIから単位情報を取得し、
 * 対応する表示フィールドを動的に更新する。
 *
 * 責務:
 * - 原材料選択時の単位情報API取得
 * - 単位表示フィールドの更新
 * - デフォルト単位重量の自動設定
 * - タブ間の原材料選択同期（複数タブで同じ原材料を編集時）
 * - エラーハンドリング（API失敗時のフォールバック）
 *
 * データフロー:
 * 1. ユーザーが原材料セレクトボックスを変更
 * 2. updateUnit() が発火
 * 3. GET /api/v1/materials/:id/fetch_product_unit_data でJSON取得
 * 4. 単位情報（unit_id, unit_name, default_unit_weight）を表示フィールドに反映
 * 5. 同期イベントを他タブの同じ原材料行に送信
 *
 * @extends Controller
 */
export default class extends Controller {
  static targets = ["materialSelect", "unitDisplay", "quantityInput", "unitWeightInput", "unitIdInput"]

  // ============================================================
  // 初期化
  // ============================================================

  /**
   * コントローラー接続時の初期化処理
   *
   * 既に原材料が選択されている場合（編集時）、単位情報を取得する。
   */
  connect() {
    console.log('Material controller connected')
    console.log('  Has materialSelect:', this.hasMaterialSelectTarget)
    console.log('  Has unitDisplay:', this.hasUnitDisplayTarget)
    console.log('  Has unitIdInput:', this.hasUnitIdInputTarget)
    console.log('  Has unitWeightInput:', this.hasUnitWeightInputTarget)

    // 既に原材料が選択されている場合（編集時）、単位情報を取得
    if (this.hasMaterialSelectTarget && this.materialSelectTarget.value) {
      const materialId = this.materialSelectTarget.value
      console.log('Existing material detected:', materialId)
      this.fetchUnitData(materialId)
    } else {
      console.log('No material selected yet')
    }
  }

  // ============================================================
  // 原材料選択時の処理
  // ============================================================

  /**
   * 原材料選択変更時の処理
   *
   * セレクトボックスで原材料が選択されたとき、APIから単位情報を取得し、
   * 関連するフィールドを更新する。空値の場合は表示をリセットする。
   *
   * @param {Event} event - changeイベントオブジェクト
   */
  updateUnit(event) {
    const materialId = event.target.value
    console.log('Material changed:', materialId)

    if (!materialId) {
      this.resetUnit()
      return
    }

    this.fetchUnitData(materialId)
  }

  /**
   * APIから原材料の単位情報を取得
   *
   * @param {string} materialId - 原材料ID
   * @private
   * @async
   */
  async fetchUnitData(materialId) {
    try {
      console.log('Fetching unit data for material:', materialId)

      const response = await fetch(`/api/v1/materials/${materialId}/fetch_product_unit_data`, {
        headers: {
          'Accept': 'application/json',
          'X-Requested-With': 'XMLHttpRequest'
        }
      })

      if (!response.ok) {
        throw new Error(`AJAX request failed with status: ${response.status}`)
      }

      const data = await response.json()

      this.updateUnitDisplay(data)
    } catch (error) {
      Logger.error("単位データの取得に失敗しました:", error)
      console.error('Fetch error:', error)
      this.resetUnit()
    }
  }

  /**
   * 単位情報を表示フィールドに反映
   *
   * @param {Object} data - APIレスポンスデータ
   * @param {string} data.unit_id - 単位ID
   * @param {string} data.unit_name - 単位名（例: "kg", "個"）
   * @param {number} data.default_unit_weight - デフォルト単位重量
   * @private
   */
  updateUnitDisplay(data) {
    console.log('Received unit data:', data)

    // unit_id を hidden field に設定
    if (this.hasUnitIdInputTarget) {
      const oldValue = this.unitIdInputTarget.value
      this.unitIdInputTarget.value = data.unit_id || ""
      console.log('Updated unit_id:', oldValue, '→', data.unit_id)
    }

    // unit_name を表示
    if (this.hasUnitDisplayTarget) {
      this.unitDisplayTarget.textContent = data.unit_name || "未設定"
      console.log('Set unit_name:', data.unit_name)
    }

    // default_unit_weight を入力フィールドに自動設定（編集時は上書きしない）
    if (this.hasUnitWeightInputTarget) {
      const currentValue = this.unitWeightInputTarget.value

      // 値が空欄または0の場合のみデフォルト値を設定
      if (!currentValue || parseFloat(currentValue) === 0) {
        this.unitWeightInputTarget.value = data.default_unit_weight || 0
        console.log('Set default_unit_weight:', data.default_unit_weight)
      } else {
        console.log('Keeping existing unit_weight:', currentValue)
      }
    }

    Logger.log(`Unit updated: ${data.unit_name}`)
  }

  /**
   * 単位情報をリセット
   *
   * 全ての単位関連フィールドを初期状態に戻す。
   *
   * @private
   */
  resetUnit() {
    if (this.hasUnitDisplayTarget) {
      this.unitDisplayTarget.textContent = "未設定"
    }

    if (this.hasUnitIdInputTarget) {
      this.unitIdInputTarget.value = ""
    }

    if (this.hasUnitWeightInputTarget) {
      this.unitWeightInputTarget.value = ""
    }

    console.log('Unit reset to default')
  }

  /**
   * エラー表示を設定
   *
   * API取得失敗時にエラー状態を表示する。
   *
   * @private
   */
  setError() {
    if (this.hasUnitDisplayTarget) {
      this.unitDisplayTarget.textContent = "エラー"
    }
  }

  // ============================================================
  // タブ間同期
  // ============================================================

  /**
   * 原材料選択を他のタブに同期
   *
   * 複数のカテゴリタブで同じ原材料行を使用している場合、
   * 一方のタブで選択された原材料を他方にも反映する。
   *
   * @param {Event} event - changeイベントオブジェクト
   */
  syncMaterialToOtherTabs(event) {
    const uniqueId = event.target.dataset.uniqueId
    const selectedMaterialId = event.target.value

    Logger.log(`Syncing material ${selectedMaterialId} for ${uniqueId}`)

    // 同じunique-idを持つ他のタブの原材料選択を更新
    document.querySelectorAll(`tr[data-unique-id="${uniqueId}"]`).forEach(row => {
      if (row === this.element) return // 自分自身はスキップ

      const select = row.querySelector('[data-resources--product-material--material-target="materialSelect"]')
      if (select && select.value !== selectedMaterialId) {
        select.value = selectedMaterialId
        // change イベントを発火して updateUnit を呼び出す
        select.dispatchEvent(new Event('change', { bubbles: true }))
      }
    })
  }

  /**
   * 数量を他のタブに同期
   *
   * 同じ原材料行の数量入力を全タブに同期する。
   *
   * @param {Event} event - inputイベントオブジェクト
   */
  syncQuantityToOtherTabs(event) {
    const uniqueId = event.target.dataset.uniqueId
    const quantity = event.target.value

    Logger.log(`Syncing quantity ${quantity} for ${uniqueId}`)

    document.querySelectorAll(`tr[data-unique-id="${uniqueId}"]`).forEach(row => {
      if (row === this.element) return

      const input = row.querySelector('[data-resources--product-material--material-target="quantityInput"]')
      if (input && input.value !== quantity) {
        input.value = quantity
      }
    })
  }

  /**
   * 単位重量を他のタブに同期
   *
   * 同じ原材料行の単位重量入力を全タブに同期する。
   *
   * @param {Event} event - inputイベントオブジェクト
   */
  syncUnitWeightToOtherTabs(event) {
    const uniqueId = event.target.dataset.uniqueId
    const unitWeight = event.target.value

    Logger.log(`Syncing unit_weight ${unitWeight} for ${uniqueId}`)

    document.querySelectorAll(`tr[data-unique-id="${uniqueId}"]`).forEach(row => {
      if (row === this.element) return

      const input = row.querySelector('[data-resources--product-material--material-target="unitWeightInput"]')
      if (input && input.value !== unitWeight) {
        input.value = unitWeight
      }
    })
  }
}
