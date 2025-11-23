import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["forecastInput", "targetInput"]

  connect() {
    console.log("Discount rate controller connected")
  }

  // Ajax成功時の処理
  handleSuccess(event) {
    const [data, status, xhr] = event.detail

    if (data.success) {
      // 成功メッセージを表示
      this.showFlashMessage(data.message, "success")

      // 入力値を更新（サーバーから返された値で上書き）
      if (this.hasForecastInputTarget) {
        this.forecastInputTarget.value = data.forecast_discount_rate
      }
      if (this.hasTargetInputTarget) {
        this.targetInputTarget.value = data.target_discount_rate
      }

      // ページをリロードして予測値を再計算
      setTimeout(() => {
        window.location.reload()
      }, 1000)
    }
  }

  // Ajax失敗時の処理
  handleError(event) {
    const [data, status, xhr] = event.detail

    let errorMessage = "見切り率の更新に失敗しました"

    if (data && data.message) {
      errorMessage = data.message
    }

    if (data && data.errors && data.errors.length > 0) {
      errorMessage += "\n" + data.errors.join("\n")
    }

    this.showFlashMessage(errorMessage, "danger")
  }

  // フラッシュメッセージ表示
  showFlashMessage(message, type) {
    // 既存のフラッシュメッセージを削除
    const existingFlash = document.querySelector(".flash-message-container")
    if (existingFlash) {
      existingFlash.remove()
    }

    // 新しいフラッシュメッセージを作成
    const flashContainer = document.createElement("div")
    flashContainer.className = "flash-message-container position-fixed top-0 start-50 translate-middle-x mt-3"
    flashContainer.style.zIndex = "9999"

    const alertDiv = document.createElement("div")
    alertDiv.className = `alert alert-${type} alert-dismissible fade show`
    alertDiv.role = "alert"
    alertDiv.innerHTML = `
      ${message}
      <button type="button" class="btn-close" data-bs-dismiss="alert" aria-label="Close"></button>
    `
    flashContainer.appendChild(alertDiv)
    document.body.appendChild(flashContainer)

    // 5秒後に自動削除
    setTimeout(() => {
      flashContainer.remove()
    }, 5000)
  }
}
