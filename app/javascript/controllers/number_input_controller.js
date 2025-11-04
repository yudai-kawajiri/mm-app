// app/javascript/controllers/number_input_controller.js

import { Controller } from "@hotwired/stimulus"

/**
 * 数値入力フィールドの全角→半角自動変換コントローラー
 *
 * 使用方法:
 *   <%= f.number_field :price, data: { controller: "number-input" } %>
 */
export default class extends Controller {
  connect() {
    // 初期値も変換（既存データが全角の場合に対応）
    this.convertToHalfWidth()
  }

  /**
   * input イベント時に全角→半角変換
   * @param {Event} event - input イベント
   */
  handleInput(event) {
    this.convertToHalfWidth()
  }

  /**
   * paste イベント時に全角→半角変換
   * @param {Event} event - paste イベント
   */
  handlePaste(event) {
    // ペースト後に変換（次のイベントループで実行）
    setTimeout(() => this.convertToHalfWidth(), 0)
  }

  /**
   * 全角文字を半角に変換
   */
  convertToHalfWidth() {
    const input = this.element
    const originalValue = input.value
    const cursorPosition = input.selectionStart

    // 全角数字、マイナス記号、ピリオドを半角に変換
    const convertedValue = originalValue
      .replace(/[０-９]/g, (char) => String.fromCharCode(char.charCodeAt(0) - 0xFEE0))
      .replace(/[ー−]/g, '-')
      .replace(/．/g, '.')

    // 値が変更された場合のみ更新
    if (originalValue !== convertedValue) {
      input.value = convertedValue

      // カーソル位置を維持
      const diff = originalValue.length - convertedValue.length
      input.setSelectionRange(cursorPosition - diff, cursorPosition - diff)

      // 変更イベントを発火（他のコントローラーに通知）
      input.dispatchEvent(new Event('input', { bubbles: true }))
    }
  }
}
