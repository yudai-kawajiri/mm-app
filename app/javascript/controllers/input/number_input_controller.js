/**
 * @file number_input_controller.js
 * 数値入力フィールドの全角→半角自動変換とカンマ挿入
 *
 * @module Controllers
 */

import { Controller } from "@hotwired/stimulus"

/**
 * Number Input Controller
 *
 * @description
 *   数値入力フィールドの全角→半角自動変換とカンマ挿入を行うコントローラー。
 *   IME変換中の挙動を考慮し、カーソル位置を保持しながらフォーマットします。
 *
 * @example HTML での使用
 *   <!-- カンマあり（デフォルト） -->
 *   <%= f.text_field :price,
 *       data: {
 *         controller: "number-input",
 *         action: "input->number-input#handleInput paste->number-input#handlePaste"
 *       }
 *   %>
 *
 *   <!-- カンマなし -->
 *   <%= f.text_field :quantity,
 *       data: {
 *         controller: "number-input",
 *         number_input_no_comma: "true",
 *         action: "input->number-input#handleInput paste->number-input#handlePaste"
 *       }
 *   %>
 *
 * @note
 *   - type="text" を使用してください（type="number"はカンマを受け付けません）
 *   - フォーム送信前に自動的にカンマを削除し、数値型に変換します
 *
 * @features
 *   - 全角数字→半角数字の自動変換
 *   - 全角スペース・半角スペースの自動削除
 *   - 3桁ごとのカンマ挿入（オプション）
 *   - IME変換中の処理スキップ
 *   - カーソル位置の保持
 *   - フォーム送信前のカンマ自動削除 + 数値型変換
 *   - マイナス記号対応
 */
export default class extends Controller {
  /**
   * コントローラー接続時の処理
   *
   * @description
   *   初期設定とイベントリスナーの登録を行います。
   *   既存の数値データがある場合は初期フォーマットを適用。
   */
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

    // フォーム送信前にカンマを削除して数値型に変換
    const form = this.element.closest('form')
    if (form) {
      // submitイベントをリスン（フォーム全体の送信時）
      form.addEventListener('submit', (e) => {
        this.removeCommasBeforeSubmit()
      }, { capture: true })
    }

    // 初期値をフォーマット（既存データや編集時）
    if (this.element.value && !this.noComma) {
      // 既に数値が入っている場合はカンマ付きに変換
      const initialValue = this.element.value.replace(/,/g, '') // カンマを削除
      if (initialValue && /^-?\d+(\.\d+)?$/.test(initialValue)) {
        // 純粋な数値の場合のみフォーマット
        this.element.value = this.formatNumber(initialValue)
      }
    }
  }

  /**
   * input イベント時の処理
   *
   * @param {Event} event - input イベント
   *
   * @description
   *   全角→半角変換とカンマ挿入を実行。
   *   IME変換中または自分が起こしたinputイベントの場合はスキップ。
   */
  handleInput(event) {
    // IME変換中または自分が起こしたinputイベントの場合はスキップ
    if (this.isComposing || this.isUpdating) {
      return
    }
    this.convertAndFormat()
  }

  /**
   * paste イベント時の処理
   *
   * @param {Event} event - paste イベント
   *
   * @description
   *   ペースト後に変換処理を実行（次のイベントループで実行）
   */
  handlePaste(event) {
    // ペースト後に変換（次のイベントループで実行）
    setTimeout(() => this.convertAndFormat(), 0)
  }

  /**
   * 数値をカンマ区切りにフォーマット
   *
   * @param {string} digits - 数字のみの文字列
   * @return {string} カンマ区切りの文字列
   *
   * @example
   *   formatNumber("1000")    // => "1,000"
   *   formatNumber("1000000") // => "1,000,000"
   */
  formatNumber(digits) {
    // 小数点がある場合は整数部分のみにカンマを挿入
    if (digits.includes('.')) {
      const [integer, decimal] = digits.split('.')
      return integer.replace(/\B(?=(\d{3})+(?!\d))/g, ',') + '.' + decimal
    }
    return digits.replace(/\B(?=(\d{3})+(?!\d))/g, ',')
  }

  /**
   * フォーム送信前にカンマとスペースを削除して数値型に変換
   *
   * @description
   *   サーバーに送信する前にカンマとスペースを削除して純粋な数値にします。
   *   空欄の場合は空文字列のまま（サーバー側でバリデーションエラー）。
   */
  removeCommasBeforeSubmit() {
    if (!this.element.value) {
      // 空欄の場合は何もしない（サーバー側でpresenceバリデーション）
      return
    }

    // カンマとスペース（全角・半角）を削除
    let cleanValue = this.element.value
      .replace(/,/g, '')           // カンマ削除
      .replace(/\s/g, '')          // 半角スペース削除
      .replace(/　/g, '')          // 全角スペース削除

    // マイナス記号と小数点以外の非数値文字を削除
    cleanValue = cleanValue.replace(/[^\d.-]/g, '')

    // 空文字列でない場合は数値型に変換
    if (cleanValue !== '') {
      // parseFloatで数値に変換（小数点対応）
      const numericValue = parseFloat(cleanValue)

      // NaNでない場合のみ設定
      if (!isNaN(numericValue)) {
        this.element.value = numericValue
        console.log('✅ Converted to numeric:', numericValue)
      } else {
        // NaNの場合は空文字列に設定（バリデーションエラーにする）
        this.element.value = ''
        console.warn('⚠️ Invalid numeric value:', cleanValue)
      }
    }
  }

  /**
   * 全角文字を半角に変換 + スペース削除 + カンマ挿入
   *
   * @description
   *   入力値を以下の順で処理：
   *   1. 全角数字→半角数字
   *   2. 全角マイナス記号→半角マイナス記号
   *   3. 全角小数点→半角小数点
   *   4. **全角・半角スペースを削除**
   *   5. カンマ削除
   *   6. 数値以外の文字削除
   *   7. カンマ挿入（noCommaモードでない場合）
   *   8. カーソル位置の調整
   */
  convertAndFormat() {
    const input = this.element
    const originalValue = input.value

    // type="number"の場合はsetSelectionRangeが使えないのでカーソル位置を取得しない
    const cursorPosition = this.isNumberType ? null : input.selectionStart

    // 全角数字、マイナス記号、小数点を半角に変換
    let convertedValue = originalValue
      .replace(/[０-９]/g, (char) => String.fromCharCode(char.charCodeAt(0) - 0xFEE0))
      .replace(/[ー−]/g, '-')
      .replace(/[。．]/g, '.')
      .replace(/\s/g, '')          // ★ 半角スペース削除
      .replace(/　/g, '')          // ★ 全角スペース削除

    // カンマを削除して数値のみを抽出
    const withoutCommas = convertedValue.replace(/,/g, '')

    // 数値、マイナス記号、小数点のみ許可
    const cleanValue = withoutCommas.replace(/[^\d.-]/g, '')

    // マイナス記号は先頭のみ許可
    const hasNegative = cleanValue.startsWith('-')
    const withoutNegative = cleanValue.replace(/-/g, '')

    // 小数点の処理
    const parts = withoutNegative.split('.')
    const integerPart = parts[0] || ''
    const decimalPart = parts.length > 1 ? '.' + parts[1] : ''

    // 空の場合
    if (integerPart === '' && decimalPart === '') {
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
    const formatted = this.noComma ? integerPart : this.formatNumber(integerPart)
    const finalValue = (hasNegative ? '-' : '') + formatted + decimalPart

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
