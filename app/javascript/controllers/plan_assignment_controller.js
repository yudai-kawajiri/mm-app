import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["category", "plan", "plannedRevenue", "categoryGroup", "planGroup"]

  connect() {
    console.log("=== Stimulus Connect ===")
    this.loadPlansData()

    // モーダルが開かれるたびにデータを再読み込み
    this.element.addEventListener('show.bs.modal', () => {
      console.log("=== Modal Opening (show.bs.modal) ===")
      this.loadPlansData()
      this.resetModal()
    })
  }

  // データ読み込みメソッド（connect と show.bs.modal で共通使用）
  loadPlansData() {
    this.plansData = window.plansByCategory || {}
    console.log("Loaded plansData:", this.plansData)
    console.log("Available categories:", Object.keys(this.plansData))
  }

  // モーダルリセット
  resetModal() {
    console.log("=== Reset Modal ===")

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

  // カテゴリ選択時
  updatePlans(event) {
    const category = event.target.value
    console.log("=== Category Selected ===")
    console.log("Selected category:", category)

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

  // 計画選択時
  updateRevenue(event) {
    const selectedOption = event.target.selectedOptions[0]
    console.log("=== Plan Selected ===")
    console.log("Selected plan option:", selectedOption)

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
