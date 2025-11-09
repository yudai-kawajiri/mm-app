/**
 * @file plan_assignment_controller.js
 * 計画割り当てモーダルの制御
 *
 * @module Controllers
 */

import { Controller } from "@hotwired/stimulus"

/**
 * Plan Assignment Controller
 *
 * @description
 *   計画割り当てモーダルのコントローラー。
 *   カテゴリ選択に応じて計画を動的に読み込み、
 *   選択された計画の予定売上を表示します。
 *
 * @example HTML での使用
 *   <div
 *     class="modal"
 *     data-controller="plan-assignment"
 *     data-bs-backdrop="static"
 *   >
 *     <!-- カテゴリ選択 -->
 *     <select
 *       data-plan-assignment-target="category"
 *       data-action="change->plan-assignment#updatePlans"
 *     >
 *       <option value="">カテゴリを選択</option>
 *     </select>
 *
 *     <!-- 計画選択 -->
 *     <select
 *       data-plan-assignment-target="plan"
 *       data-action="change->plan-assignment#updateRevenue"
 *     >
 *       <option value="">計画を選択</option>
 *     </select>
 *
 *     <!-- 予定売上表示 -->
 *     <input
 *       type="text"
 *       data-plan-assignment-target="plannedRevenue"
 *       readonly
 *     />
 *   </div>
 *
 * @targets
 *   category - カテゴリセレクトボックス
 *   plan - 計画セレクトボックス
 *   plannedRevenue - 予定売上表示フィールド
 *   categoryGroup - カテゴリ選択グループ
 *   planGroup - 計画選択グループ
 *
 * @features
 *   - カテゴリ選択に応じた計画の動的読み込み
 *   - 計画選択時の予定売上自動表示
 *   - モーダル開閉時の状態リセット
 *   - グローバル変数 window.plansByCategory からデータ取得
 *
 * @requires window.plansByCategory - サーバーから渡される計画データ
 */
export default class extends Controller {
  static targets = ["category", "plan", "plannedRevenue", "categoryGroup", "planGroup"]

  /**
   * コントローラー接続時の処理
   *
   * @description
   *   初期データを読み込み、モーダル開閉イベントをリスン
   */
  connect() {
    console.log("Plan assignment controller connected")
    this.loadPlansData()

    // モーダルが開かれるたびにデータを再読み込み
    this.element.addEventListener('show.bs.modal', () => {
      console.log("Modal opening (show.bs.modal)")
      this.loadPlansData()
      this.resetModal()
    })
  }

  /**
   * データ読み込みメソッド
   *
   * @description
   *   window.plansByCategory からカテゴリ別の計画データを読み込みます。
   *   connect と show.bs.modal で共通使用。
   */
  loadPlansData() {
    this.plansData = window.plansByCategory || {}
    console.log("Loaded plansData:", this.plansData)
    console.log("Available categories:", Object.keys(this.plansData))
  }

  /**
   * モーダルリセット処理
   *
   * @description
   *   モーダルを初期状態に戻します：
   *   - カテゴリと計画の選択をクリア
   *   - 予定売上をクリア
   *   - カテゴリグループを表示、計画グループを非表示
   */
  resetModal() {
    console.log("Reset modal")

    // カテゴリと計画の選択をリセット
    if (this.hasCategoryTarget) {
      this.categoryTarget.value = ""
    }
    if (this.hasPlanTarget) {
      this.planTarget.innerHTML = '<option value="">計画を選択してください</option>'
      this.planTarget.disabled = true
    }
    if (this.hasPlannedRevenueTarget) {
      this.plannedRevenueTarget.value = ""
    }

    // カテゴリグループを表示、計画グループを非表示
    if (this.hasCategoryGroupTarget) {
      this.categoryGroupTarget.style.display = "block"
    }
    if (this.hasPlanGroupTarget) {
      this.planGroupTarget.style.display = "none"
    }
  }

  /**
   * カテゴリ選択時の処理
   *
   * @param {Event} event - change イベント
   *
   * @description
   *   選択されたカテゴリに対応する計画を計画セレクトボックスに追加します。
   *   計画がある場合は計画グループを表示。
   */
  updatePlans(event) {
    const category = event.target.value
    console.log("Category selected:", category)

    if (!this.hasPlanTarget) {
      console.warn("Plan target not found")
      return
    }

    // 計画ドロップダウンをクリア
    this.planTarget.innerHTML = '<option value="">計画を選択してください</option>'

    if (!category) {
      this.planTarget.disabled = true
      if (this.hasPlanGroupTarget) {
        this.planGroupTarget.style.display = "none"
      }
      console.log("No category selected, hiding plan dropdown")
      return
    }

    // カテゴリに対応する計画を取得
    const plans = this.plansData[category]
    console.log(`Plans for category "${category}":`, plans)

    if (!plans || plans.length === 0) {
      console.warn(`No plans found for category: ${category}`)
      this.planTarget.disabled = true
      return
    }

    // 計画を追加
    plans.forEach(plan => {
      const option = document.createElement("option")
      option.value = plan.id
      option.textContent = plan.name
      option.dataset.revenue = plan.expected_revenue || 0
      this.planTarget.appendChild(option)
    })

    this.planTarget.disabled = false

    // 計画グループを表示
    if (this.hasPlanGroupTarget) {
      this.planGroupTarget.style.display = "block"
    }

    console.log(`Added ${plans.length} plans to dropdown`)
  }

  /**
   * 計画選択時の処理
   *
   * @param {Event} event - change イベント
   *
   * @description
   *   選択された計画の予定売上を予定売上フィールドに表示します。
   */
  updateRevenue(event) {
    const selectedOption = event.target.selectedOptions[0]
    console.log("Plan selected:", selectedOption)

    if (!selectedOption) {
      console.warn("No plan selected")
      return
    }

    const revenue = selectedOption.dataset.revenue || 0
    console.log("Expected revenue:", revenue)

    if (this.hasPlannedRevenueTarget) {
      this.plannedRevenueTarget.value = revenue
      console.log("Updated planned revenue field to:", revenue)
    }
  }
}
