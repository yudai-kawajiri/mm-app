import { Controller } from "@hotwired/stimulus"

// HTML5 バリデーションを強化
export default class extends Controller {
  static targets = ["field"]

  connect() {
    console.log("Form validation controller connected")

    // すべてのフィールドにリアルタイムバリデーションを追加
    this.fieldTargets.forEach(field => {
      field.addEventListener('blur', () => this.validateField(field))
      field.addEventListener('input', () => {
        // 入力中はエラー表示をクリア
        if (field.classList.contains('is-invalid')) {
          this.clearFieldError(field)
        }
      })
    })
  }

  validateField(field) {
    // HTML5 バリデーションをチェック
    if (!field.checkValidity()) {
      this.showFieldError(field, field.validationMessage)
    } else {
      this.clearFieldError(field)
    }
  }

  showFieldError(field, message) {
    field.classList.add('is-invalid')
    field.classList.remove('is-valid')

    // エラーメッセージを表示
    let feedback = field.parentElement.querySelector('.invalid-feedback')
    if (!feedback) {
      feedback = document.createElement('div')
      feedback.className = 'invalid-feedback'
      field.parentElement.appendChild(feedback)
    }
    feedback.textContent = message
    feedback.style.display = 'block'
  }

  clearFieldError(field) {
    field.classList.remove('is-invalid')
    field.classList.add('is-valid')

    const feedback = field.parentElement.querySelector('.invalid-feedback')
    if (feedback) {
      feedback.style.display = 'none'
    }
  }

  // フォーム送信前に全フィールドをバリデーション
  validateForm(event) {
    let isValid = true

    this.fieldTargets.forEach(field => {
      if (!field.checkValidity()) {
        this.showFieldError(field, field.validationMessage)
        isValid = false
      }
    })

    if (!isValid) {
      event.preventDefault()
      // 最初のエラーフィールドにフォーカス
      const firstInvalid = this.element.querySelector('.is-invalid')
      if (firstInvalid) {
        firstInvalid.focus()
        firstInvalid.scrollIntoView({ behavior: 'smooth', block: 'center' })
      }
    }

    return isValid
  }

  //  追加: HTMLから呼ばれる validate メソッド（エイリアス）
  validate(event) {
    return this.validateForm(event)
  }
}
