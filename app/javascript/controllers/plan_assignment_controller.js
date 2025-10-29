import { Controller } from "@hotwired/stimulus"

// 計画割り当てモーダルを制御するStimulusコントローラー
export default class extends Controller {
  // data-plan-assignment-target で参照する要素を定義
  static targets = ["planSelect", "revenueField"]

  // 接続時の初期化
  connect() {
    console.log("Plan assignment controller connected")
  }

  // 計画選択時に呼ばれるメソッド
  async updateRevenue() {
    const planId = this.planSelectTarget.value

    // 計画が選択されていない場合はクリア
    if (!planId) {
      this.revenueFieldTarget.value = ""
      return
    }

    try {
      // APIから計画の売上を取得
      const response = await fetch(`/api/v1/plans/${planId}/revenue`)

      if (!response.ok) {
        throw new Error(`HTTP error! status: ${response.status}`)
      }

      const data = await response.json()

      // 取得した売上を金額フィールドに設定
      this.revenueFieldTarget.value = data.revenue

      console.log(`Plan ${planId} revenue: ${data.formatted_revenue}`)

    } catch (error) {
      console.error("Failed to fetch plan revenue:", error)
      alert("計画の売上を取得できませんでした")
      this.revenueFieldTarget.value = ""
    }
  }
}
