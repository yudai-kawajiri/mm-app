// Form Validation Controller
//
// HTML5バリデーションの強化とリアルタイムエラー表示
//
// 使用例:
//   <form data-controller="form-validation" data-action="submit->form-validation#validate">
//     <input
//       type="email"
//       required
//       data-form-validation-target="field"
//     />
//     <div class="invalid-feedback"></div>
//   </form>
//
// 機能:
// - リアルタイムバリデーション（blur時）
// - 入力中のエラー表示クリア
// - フォーム送信前の全フィールドチェック
// - エラーフィールドへの自動フォーカス
// - Bootstrap のバリデーションクラス対応（is-invalid, is-valid）

import { Controller } from "@hotwired/stimulus"
import Logger from "utils/logger"

export default class extends Controller {
  static targets = ["field"]
  static INVALID_CLASS = 'is-invalid'
  static VALID_CLASS = 'is-valid'
  static FEEDBACK_CLASS = 'invalid-feedback'
  static SCROLL_OPTIONS = { behavior: 'smooth', block: 'center' }

  // コントローラー接続時の処理
  //
  // すべてのフィールドにリアルタイムバリデーションを追加
  // - blur: フィールドを離れたときにバリデーション
  // - input: 入力中はエラー表示をクリア
  connect() {
    Logger.log('Form validation controller connected')

    // すべてのフィールドにリアルタイムバリデーションを追加
    this.fieldTargets.forEach(field => {
      field.addEventListener('blur', () => this.validateField(field))
      field.addEventListener('input', () => {
        // 入力中はエラー表示をクリア
        if (field.classList.contains(this.constructor.INVALID_CLASS)) {
          this.clearFieldError(field)
        }
      })
    })
  }

  // 個別フィールドのバリデーション
  //
  // @param {HTMLElement} field - バリデーション対象のフィールド
  validateField(field) {
    // HTML5 バリデーションをチェック
    if (!field.checkValidity()) {
      this.showFieldError(field, field.validationMessage)
    } else {
      this.clearFieldError(field)
    }
  }

  // フィールドエラーの表示
  //
  // @param {HTMLElement} field - エラー表示対象のフィールド
  // @param {String} message - エラーメッセージ
  showFieldError(field, message) {
    field.classList.add(this.constructor.INVALID_CLASS)
    field.classList.remove(this.constructor.VALID_CLASS)

    // エラーメッセージを表示
    let feedback = field.parentElement.querySelector(`.${this.constructor.FEEDBACK_CLASS}`)
    if (!feedback) {
      feedback = document.createElement('div')
      feedback.className = this.constructor.FEEDBACK_CLASS
      field.parentElement.appendChild(feedback)
    }
    feedback.textContent = message
    feedback.style.display = 'block'
  }

  // フィールドエラーのクリア
  //
  // @param {HTMLElement} field - エラークリア対象のフィールド
  clearFieldError(field) {
    field.classList.remove(this.constructor.INVALID_CLASS)
    field.classList.add(this.constructor.VALID_CLASS)

    const feedback = field.parentElement.querySelector(`.${this.constructor.FEEDBACK_CLASS}`)
    if (feedback) {
      feedback.style.display = 'none'
    }
  }

  // フォーム送信前の全フィールドバリデーション
  //
  // @param {Event} event - submit イベント
  // @return {Boolean} バリデーション成功時 true、失敗時 false
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
      const firstInvalid = this.element.querySelector(`.${this.constructor.INVALID_CLASS}`)
      if (firstInvalid) {
        firstInvalid.focus()
        firstInvalid.scrollIntoView(this.constructor.SCROLL_OPTIONS)
      }
    }

    return isValid
  }

  // validateForm のエイリアス
  //
  // @param {Event} event - submit イベント
  // @return {Boolean} バリデーション成功時 true、失敗時 false
  validate(event) {
    return this.validateForm(event)
  }
}
