// app/javascript/controllers/resources/product-material/material_controller.js
import { Controller } from "@hotwired/stimulus"
import Logger from "utils/logger"

/**
 * 商品-原材料管理コントローラー
 * 原材料選択時に単位情報を取得・表示
 */
export default class extends Controller {
  static targets = ["materialSelect", "unitDisplay", "quantityInput", "unitWeightInput", "unitIdInput"]

  // ============================================================
  // 初期化
  // ============================================================

  /**
   * コントローラー接続時に実行
   */
  connect() {
    console.log('✅ Material controller connected')
    console.log('  Has materialSelect:', this.hasMaterialSelectTarget)
    console.log('  Has unitDisplay:', this.hasUnitDisplayTarget)
    console.log('  Has unitIdInput:', this.hasUnitIdInputTarget)
    console.log('  Has unitWeightInput:', this.hasUnitWeightInputTarget)

    // 既に原材料が選択されている場合（編集時）、単位情報を取得
    if (this.hasMaterialSelectTarget && this.materialSelectTarget.value) {
      const materialId = this.materialSelectTarget.value
      console.log('🔄 Existing material detected:', materialId)
      this.fetchUnitData(materialId)
    } else {
      console.log('ℹ️ No material selected yet')
    }
  }

  // ============================================================
  // 原材料選択時の処理
  // ============================================================

  /**
   * 原材料選択時に単位情報を取得
   * @param {Event} event - change イベント
   */
  updateUnit(event) {
    const materialId = event.target.value
    console.log('🔄 Material changed:', materialId)

    if (!materialId) {
      this.resetUnit()
      return
    }

    this.fetchUnitData(materialId)
  }

  /**
   * 単位情報をAPIから取得
   * @param {string} materialId - 原材料ID
   */
  async fetchUnitData(materialId) {
    try {
      console.log(' Fetching unit data for material:', materialId)

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
      console.error('❌ Fetch error:', error)
      this.resetUnit()
    }
  }

  /**
   * 単位情報を表示
   * @param {Object} data - { unit_id, unit_name, default_unit_weight }
   */
  updateUnitDisplay(data) {
    console.log('📥 Received unit data:', data)

    // unit_id を hidden field に設定
    if (this.hasUnitIdInputTarget) {
      const oldValue = this.unitIdInputTarget.value
      this.unitIdInputTarget.value = data.unit_id || ""
      console.log('✏️ Updated unit_id:', oldValue, '→', data.unit_id)
    }

    // unit_name を表示
    if (this.hasUnitDisplayTarget) {
      this.unitDisplayTarget.textContent = data.unit_name || "未設定"
      console.log('✅ Set unit_name:', data.unit_name)
    }

    // default_unit_weight を入力フィールドに自動設定（編集時は上書きしない）
    if (this.hasUnitWeightInputTarget) {
      const currentValue = this.unitWeightInputTarget.value

      // 値が空欄または0の場合のみデフォルト値を設定
      if (!currentValue || parseFloat(currentValue) === 0) {
        this.unitWeightInputTarget.value = data.default_unit_weight || 0
        console.log('✅ Set default_unit_weight:', data.default_unit_weight)
      } else {
        console.log('ℹ️ Keeping existing unit_weight:', currentValue)
      }
    }

    Logger.log(`✅ Unit updated: ${data.unit_name}`)
  }

  /**
   * 単位情報をリセット
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

    console.log('🔄 Unit reset to default')
  }

  /**
   * エラー表示を設定
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
   * @param {Event} event - change イベント
   */
  syncMaterialToOtherTabs(event) {
    const uniqueId = event.target.dataset.uniqueId
    const selectedMaterialId = event.target.value

    Logger.log(`🔄 Syncing material ${selectedMaterialId} for ${uniqueId}`)

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
   * @param {Event} event - input イベント
   */
  syncQuantityToOtherTabs(event) {
    const uniqueId = event.target.dataset.uniqueId
    const quantity = event.target.value

    Logger.log(`🔄 Syncing quantity ${quantity} for ${uniqueId}`)

    document.querySelectorAll(`tr[data-unique-id="${uniqueId}"]`).forEach(row => {
      if (row === this.element) return

      const input = row.querySelector('[data-resources--product-material--material-target="quantityInput"]')
      if (input && input.value !== quantity) {
        input.value = quantity
      }
    })
  }

  /**
   * 重量を他のタブに同期
   * @param {Event} event - input イベント
   */
  syncUnitWeightToOtherTabs(event) {
    const uniqueId = event.target.dataset.uniqueId
    const unitWeight = event.target.value

    Logger.log(`🔄 Syncing unit_weight ${unitWeight} for ${uniqueId}`)

    document.querySelectorAll(`tr[data-unique-id="${uniqueId}"]`).forEach(row => {
      if (row === this.element) return

      const input = row.querySelector('[data-resources--product-material--material-target="unitWeightInput"]')
      if (input && input.value !== unitWeight) {
        input.value = unitWeight
      }
    })
  }
}
