/**
 * @file form_validation_controller.js
 * HTML5バリデーションの強化とリアルタイムエラー表示
 *
 * @module Controllers
 */

import { Controller } from "@hotwired/stimulus"

/**
 * Form Validation Controller
 *
 * @description
 *   HTML5 バリデーションを強化し、リアルタイムでバリデーション結果を表示します。
 *   フォーム送信前に全フィールドをチェックし、エラーがある場合は
 *   最初のエラーフィールドにフォーカスします。
 *
 * @example HTML での使用
 *   <form data-controller="form-validation" data-action="submit->form-validation#validate">
 *     <input
 *       type="email"
 *       required
 *       data-form-validation-target="field"
 *     />
 *     <div class="invalid-feedback"></div>
 *   </form>
 *
 * @targets
 *   field - バリデーション対象のフィールド
 *
 * @features
 *   - リアルタイムバリデーション（blur時）
 *   - 入力中のエラー表示クリア
 *   - フォーム送信前の全フィールドチェック
 *   - エラーフィールドへの自動フォーカス
 *   - Bootstrap のバリデーションクラス対応（is-invalid, is-valid）
 */
export default class extends Controller {
  static targets = ["field"]

  /**
   * コントローラー接続時の処理
   *
   * @description
   *   すべてのフィールドにリアルタイムバリデーションを追加。
   *   - blur: フィールドを離れたときにバリデーション
   *   - input: 入力中はエラー表示をクリア
   */
  connect() {
    console.log('Form validation controller connected')

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

  /**
   * 個別フィールドのバリデーション
   *
   * @param {HTMLElement} field - バリデーション対象のフィールド
   *
   * @description
   *   HTML5 バリデーションをチェックし、エラーがあれば表示
   */
  validateField(field) {
    // HTML5 バリデーションをチェック
    if (!field.checkValidity()) {
      this.showFieldError(field, field.validationMessage)
    } else {
      this.clearFieldError(field)
    }
  }

  /**
   * フィールドエラーの表示
   *
   * @param {HTMLElement} field - エラー表示対象のフィールド
   * @param {String} message - エラーメッセージ
   *
   * @description
   *   is-invalid クラスを追加し、エラーメッセージを表示
   */
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

  /**
   * フィールドエラーのクリア
   *
   * @param {HTMLElement} field - エラークリア対象のフィールド
   *
   * @description
   *   is-invalid クラスを削除し、is-valid クラスを追加
   */
  clearFieldError(field) {
    field.classList.remove('is-invalid')
    field.classList.add('is-valid')

    const feedback = field.parentElement.querySelector('.invalid-feedback')
    if (feedback) {
      feedback.style.display = 'none'
    }
  }

  /**
   * フォーム送信前の全フィールドバリデーション
   *
   * @param {Event} event - submit イベント
   * @return {Boolean} バリデーション成功時 true、失敗時 false
   *
   * @description
   *   全フィールドをチェックし、エラーがある場合は送信を中止。
   *   最初のエラーフィールドにフォーカスしてスクロールします。
   */
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

  /**
   * validateForm のエイリアス
   *
   * @param {Event} event - submit イベント
   * @return {Boolean} バリデーション成功時 true、失敗時 false
   *
   * @description
   *   HTML から呼ばれる validate メソッド
   */
  validate(event) {
    return this.validateForm(event)
  }
}
