// app/javascript/controllers/number_input_controller.js

import { Controller } from "@hotwired/stimulus"

/**
 * 数値入力フィールドの全角→半角自動変換 + カンマ挿入コントローラー
 *
 * 使用方法:
 *   <%= f.text_field :price, data: { controller: "number-input", action: "input->number-input#handleInput paste->number-input#handlePaste" } %>
 *   カンマなし: data: { controller: "number-input", number_input_no_comma: "true", ... }
 *
 * 注意: type="text" を使用してください（type="number"はカンマを受け付けません）
 */
export default class extends Controller {
  connect() {
    this.isUpdating = false
    this.isComposing = false  // IME変換中フラグ
    this.noComma = this.element.dataset.numberInputNoComma === 'true'  // カンマなしモード

    // type="number"の場合はsetSelectionRangeが使えない
    this.isNumberType = this.element.type === 'number'

    // IME変換開始・終了イベントをリスン
    this.element.addEventListener('compositionstart', () => {
      this.isComposing = true
    })

    this.element.addEventListener('compositionend', () => {
      this.isComposing = false
      // 変換確定後に処理を実行
      setTimeout(() => this.convertAndFormat(), 0)
    })

    // フォーム送信前にカンマを削除
    const form = this.element.closest('form')
    if (form) {
      form.addEventListener('submit', () => {
        this.removeCommasBeforeSubmit()
      })
    }

    // 初期値をフォーマット（既存データや編集時）
    if (this.element.value && !this.noComma) {
      // 既に数値が入っている場合はカンマ付きに変換
      const initialValue = this.element.value.replace(/,/g, '') // カンマを削除
      if (initialValue && /^\d+$/.test(initialValue)) {
        // 純粋な数値の場合のみフォーマット
        this.element.value = this.formatNumber(initialValue)
      }
    }
  }

  /**
   * input イベント時に全角→半角変換 + カンマ挿入
   * @param {Event} event - input イベント
   */
  handleInput(event) {
    // IME変換中または自分が起こしたinputイベントの場合はスキップ
    if (this.isComposing || this.isUpdating) {
      return
    }
    this.convertAndFormat()
  }

  /**
   * paste イベント時に全角→半角変換 + カンマ挿入
   * @param {Event} event - paste イベント
   */
  handlePaste(event) {
    // ペースト後に変換（次のイベントループで実行）
    setTimeout(() => this.convertAndFormat(), 0)
  }

  /**
   * 数値をカンマ区切りにフォーマット
   * @param {string} digits - 数字のみの文字列
   * @returns {string} カンマ区切りの文字列
   */
  formatNumber(digits) {
    return digits.replace(/\B(?=(\d{3})+(?!\d))/g, ',')
  }

  /**
   * フォーム送信前にカンマを削除
   */
  removeCommasBeforeSubmit() {
    if (this.element.value) {
      // カンマを削除して数値のみにする
      this.element.value = this.element.value.replace(/,/g, '')
    }
  }

  /**
   * 全角文字を半角に変換 + カンマ挿入
   */
  convertAndFormat() {
    const input = this.element
    const originalValue = input.value

    // type="number"の場合はsetSelectionRangeが使えないのでカーソル位置を取得しない
    const cursorPosition = this.isNumberType ? null : input.selectionStart

    // 全角数字、マイナス記号を半角に変換
    let convertedValue = originalValue
      .replace(/[０-９]/g, (char) => String.fromCharCode(char.charCodeAt(0) - 0xFEE0))
      .replace(/[ー−]/g, '-')

    // カンマを削除して数値のみを抽出
    const withoutCommas = convertedValue.replace(/,/g, '')

    // 数値とマイナス記号のみ許可
    const cleanValue = withoutCommas.replace(/[^\d-]/g, '')

    // マイナス記号は先頭のみ許可
    const hasNegative = cleanValue.startsWith('-')
    const digitsOnly = cleanValue.replace(/-/g, '')

    // 空の場合
    if (digitsOnly === '') {
      const newValue = hasNegative ? '-' : ''
      if (originalValue !== newValue) {
        this.isUpdating = true
        input.value = newValue
        // type="number"の場合はsetSelectionRangeをスキップ
        if (!this.isNumberType) {
          input.setSelectionRange(newValue.length, newValue.length)
        }
        // 同期的にフラグを戻す
        this.isUpdating = false
      }
      return
    }

    // カンマを挿入（3桁区切り）※カンマなしモードの場合はスキップ
    const formatted = this.noComma ? digitsOnly : this.formatNumber(digitsOnly)
    const finalValue = hasNegative ? '-' + formatted : formatted

    // 値が変わっていない場合は何もしない
    if (originalValue === finalValue) {
      return
    }

    // 値を更新（isUpdatingフラグを立てる）
    this.isUpdating = true
    input.value = finalValue

    // type="number"の場合はカーソル位置の調整をスキップ
    if (!this.isNumberType && cursorPosition !== null) {
      // カーソル位置を調整
      // 元の値でカーソルより前にある数字の個数を数える
      const originalBeforeCursor = originalValue.slice(0, cursorPosition)
      const digitsBeforeCursor = (originalBeforeCursor.match(/\d/g) || []).length

      // 新しい値で、同じ個数の数字の後ろにカーソルを配置
      let digitsSeen = 0
      let newCursorPos = hasNegative ? 1 : 0

      for (let i = hasNegative ? 1 : 0; i < finalValue.length; i++) {
        if (/\d/.test(finalValue[i])) {
          digitsSeen++
          if (digitsSeen >= digitsBeforeCursor) {
            newCursorPos = i + 1
            break
          }
        }
      }

      // カーソルが先頭でマイナスがある場合
      if (cursorPosition === 0 && hasNegative) {
        newCursorPos = 0
      }

      input.setSelectionRange(newCursorPos, newCursorPos)
    }

    // 同期的にフラグを戻す
    this.isUpdating = false
  }
}