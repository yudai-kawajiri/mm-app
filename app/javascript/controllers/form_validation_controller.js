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

// Stimulusターゲット名
const TARGETS = {
  FIELD: 'field'
}

// CSSクラス名
const CSS_CLASSES = {
  INVALID: 'is-invalid',
  VALID: 'is-valid',
  FEEDBACK: 'invalid-feedback'
}

// イベント名
const EVENT_TYPE = {
  BLUR: 'blur',
  INPUT: 'input'
}

// HTML要素名
const HTML_ELEMENT = {
  DIV: 'div'
}

// CSSスタイルプロパティ
const STYLE_PROPERTY = {
  DISPLAY: 'display'
}

// CSSスタイル値
const DISPLAY_STYLE = {
  BLOCK: 'block',
  NONE: 'none'
}

// セレクタ関連
const SELECTOR_PREFIX = {
  CLASS: '.'
}

// スクロール設定
const SCROLL_OPTIONS = {
  behavior: 'smooth',
  block: 'center'
}

// ログメッセージ
const LOG_MESSAGES = {
  CONNECTED: 'Form validation controller connected'
}

// Form Validation Controller
export default class extends Controller {
  static targets = [TARGETS.FIELD]

  // コントローラー接続時の処理
  // すべてのフィールドにリアルタイムバリデーションを追加
  // - blur: フィールドを離れたときにバリデーション
  // - input: 入力中はエラー表示をクリア
  connect() {
    Logger.log(LOG_MESSAGES.CONNECTED)

    // すべてのフィールドにリアルタイムバリデーションを追加
    this.fieldTargets.forEach(field => {
      field.addEventListener(EVENT_TYPE.BLUR, () => this.validateField(field))
      field.addEventListener(EVENT_TYPE.INPUT, () => {
        // 入力中はエラー表示をクリア
        if (field.classList.contains(CSS_CLASSES.INVALID)) {
          this.clearFieldError(field)
        }
      })
    })
  }

  // 個別フィールドのバリデーション
  // HTML5 バリデーションをチェック
  validateField(field) {
    if (!field.checkValidity()) {
      this.showFieldError(field, field.validationMessage)
    } else {
      this.clearFieldError(field)
    }
  }

  // フィールドエラーの表示
  // エラーメッセージを表示し、is-invalidクラスを追加
  showFieldError(field, message) {
    field.classList.add(CSS_CLASSES.INVALID)
    field.classList.remove(CSS_CLASSES.VALID)

    // エラーメッセージを表示
    let feedback = field.parentElement.querySelector(SELECTOR_PREFIX.CLASS + CSS_CLASSES.FEEDBACK)
    if (!feedback) {
      feedback = document.createElement(HTML_ELEMENT.DIV)
      feedback.className = CSS_CLASSES.FEEDBACK
      field.parentElement.appendChild(feedback)
    }
    feedback.textContent = message
    feedback.style[STYLE_PROPERTY.DISPLAY] = DISPLAY_STYLE.BLOCK
  }

  // フィールドエラーのクリア
  // is-invalidクラスを削除し、is-validクラスを追加
  clearFieldError(field) {
    field.classList.remove(CSS_CLASSES.INVALID)
    field.classList.add(CSS_CLASSES.VALID)

    const feedback = field.parentElement.querySelector(SELECTOR_PREFIX.CLASS + CSS_CLASSES.FEEDBACK)
    if (feedback) {
      feedback.style[STYLE_PROPERTY.DISPLAY] = DISPLAY_STYLE.NONE
    }
  }

  // フォーム送信前の全フィールドバリデーション
  // すべてのフィールドをチェックし、エラーがあれば送信を中止
  // 最初のエラーフィールドにフォーカスとスクロール
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
      const firstInvalid = this.element.querySelector(SELECTOR_PREFIX.CLASS + CSS_CLASSES.INVALID)
      if (firstInvalid) {
        firstInvalid.focus()
        firstInvalid.scrollIntoView(SCROLL_OPTIONS)
      }
    }

    return isValid
  }

  // validateForm のエイリアス
  // submit イベントから呼び出される
  validate(event) {
    return this.validateForm(event)
  }
}
