import { Controller } from "@hotwired/stimulus"

// 計画割当モーダルのinfoアラート制御コントローラー
export default class extends Controller {
  static targets = ["infoAlert", "planSelect"]

  connect() {
    // 初期表示: infoアラートを表示
    this.showInfo()
  }

  // 計画選択時に呼ばれる
  handlePlanChange(event) {
    const selectedValue = event.target.value

    if (selectedValue && selectedValue !== '') {
      // 計画が選択されたらinfoアラートを非表示
      this.hideInfo()
    } else {
      // 計画選択がクリアされたらinfoアラートを表示
      this.showInfo()
    }
  }

  // カテゴリ―変更時に呼ばれる（計画選択がリセットされるので、infoを表示）
  handleCategoryChange() {
    this.showInfo()
  }

  // モーダルが開かれた時に呼ばれる
  showModal() {
    this.showInfo()
  }

  showInfo() {
    if (this.hasInfoAlertTarget) {
      this.infoAlertTarget.style.display = 'block'
    }
  }

  hideInfo() {
    if (this.hasInfoAlertTarget) {
      this.infoAlertTarget.style.display = 'none'
    }
  }
}
