// Number Input Controller
//
// 数値入力フィールドの全角→半角自動変換とカンマ挿入を行うStimulusコントローラー
//
// 使用例:
//   <!-- カンマあり（デフォルト） -->
//   <%= f.text_field :price,
//       data: {
//         controller: "number-input",
//         action: "input->number-input#handleInput paste->number-input#handlePaste focus->number-input#handleFocus blur->number-input#handleBlur"
//       }
//   %>
//
//   <!-- カンマなし -->
//   <%= f.text_field :quantity,
//       data: {
//         controller: "number-input",
//         number_input_no_comma: "true",
//         action: "input->number-input#handleInput paste->number-input#handlePaste focus->number-input#handleFocus blur->number-input#handleBlur"
//       }
//   %>
//
//   <!-- 整数のみ（小数点禁止） -->
//   <%= f.text_field :pieces,
//       data: {
//         controller: "number-input",
//         number_input_integer_only: "true",
//         action: "input->number-input#handleInput paste->number-input#handlePaste focus->number-input#handleFocus"
//       }
//   %>
//
//   <!-- 小数点フィールド（.0形式を維持） -->
//   <%= f.text_field :weight,
//       data: {
//         controller: "number-input",
//         number_input_decimal_field: "true",
//         action: "input->number-input#handleInput paste->number-input#handlePaste focus->number-input#handleFocus blur->number-input#handleBlur"
//       }
//   %>
//
// 注意事項:
// - type="text" を使用してください（type="number"はカンマを受け付けません）
// - フォーム送信前に自動的にカンマを削除し、数値型に変換します
//
// 機能:
// - 全角数字→半角数字の自動変換
// - 全角スペース・半角スペースの自動削除
// - 3桁ごとのカンマ挿入（オプション）
// - IME変換中の処理スキップ
// - カーソル位置の保持
// - フォーム送信前のカンマ自動削除 + 数値型変換
// - マイナス記号対応
// - フォーカス時の「0」「0.0」自動選択
// - 整数のみモード（小数点禁止）
// - 小数点フィールドモード（.0形式を維持）
// - disabledフィールドでは初期化をスキップ（リセット後の空欄状態を維持）

import { Controller } from "@hotwired/stimulus"
import Logger from "utils/logger"

// 定数定義
const DATA_ATTRIBUTES = {
  NO_COMMA: 'numberInputNoComma',
  INTEGER_ONLY: 'numberInputIntegerOnly',
  DECIMAL_FIELD: 'numberInputDecimalField'
}

const INPUT_TYPE = {
  NUMBER: 'number',
  TEXT: 'text'
}

const EVENT_TYPE = {
  COMPOSITION_START: 'compositionstart',
  COMPOSITION_END: 'compositionend',
  SUBMIT: 'submit'
}

const REGEX = {
  FULL_WIDTH_NUMBER: /[０-９]/g,
  FULL_WIDTH_MINUS: /[ー−]/g,
  HALF_WIDTH_SPACE: /\s/g,
  FULL_WIDTH_SPACE: /　/g,
  FULL_WIDTH_DOT: /[。．]/g,
  COMMA: /,/g,
  DIGIT: /\d/g,
  NON_DIGIT_NON_MINUS: /[^\d-]/g,
  NON_DIGIT_NON_MINUS_NON_DOT: /[^\d.-]/g,
  NUMERIC_FORMAT: /^-?\d+(\.\d+)?$/,
  MINUS: /-/g,
  THREE_DIGIT_GROUP: /\B(?=(\d{3})+(?!\d))/g
}

const CHAR_CODE = {
  FULL_WIDTH_OFFSET: 0xFEE0
}

const SPECIAL_VALUES = {
  ZERO: '0',
  ZERO_DECIMAL: '0.0',
  ZERO_TWO_DECIMAL: '0.00',
  MINUS: '-',
  DOT: '.',
  EMPTY: ''
}

const DECIMAL_PLACES = {
  ONE: 1
}

const LOG_MESSAGES = {
  CONVERSION_SUCCESS: '✅ Converted to numeric:',
  INVALID_VALUE: '⚠️ Invalid numeric value:'
}

const EVENT_OPTIONS = {
  CAPTURE: { capture: true }
}

const TIMEOUT_DELAY = {
  ZERO: 0
}

export default class extends Controller {
  // コントローラー接続時の処理
  // 初期設定とイベントリスナーの登録を行う
  // 既存の数値データがある場合は初期フォーマットを適用
  connect() {
    this.isUpdating = false
    this.isComposing = false
    this.noComma = this.element.dataset[DATA_ATTRIBUTES.NO_COMMA] === 'true'
    this.integerOnly = this.element.dataset[DATA_ATTRIBUTES.INTEGER_ONLY] === 'true'
    this.decimalField = this.element.dataset[DATA_ATTRIBUTES.DECIMAL_FIELD] === 'true'

    // type="number"の場合はsetSelectionRangeが使えない
    this.isNumberType = this.element.type === INPUT_TYPE.NUMBER

    // IME変換開始・終了イベントをリスン
    this.element.addEventListener(EVENT_TYPE.COMPOSITION_START, () => {
      this.isComposing = true
    })

    this.element.addEventListener(EVENT_TYPE.COMPOSITION_END, () => {
      this.isComposing = false
      // 変換確定後に処理を実行
      setTimeout(() => this.convertAndFormat(), TIMEOUT_DELAY.ZERO)
    })

    // フォーム送信前にカンマを削除して数値型に変換
    const form = this.element.closest('form')
    if (form) {
      // submitイベントをリスン（フォーム全体の送信時）
      form.addEventListener(EVENT_TYPE.SUBMIT, (e) => {
        this.removeCommasBeforeSubmit()
      }, EVENT_OPTIONS.CAPTURE)
    }

    // 初期値をフォーマット（既存データや編集時）
    // ただし、フィールドがdisabledの場合はスキップ（リセット後の空欄状態を維持）
    if (this.element.value && !this.element.disabled) {
      this.formatInitialValue()
    }
  }

  // 初期値をフォーマット
  // 既存データや編集時の初期値をフォーマットする
  formatInitialValue() {
    let value = this.element.value.replace(REGEX.COMMA, SPECIAL_VALUES.EMPTY)

    // 数値でない場合は何もしない
    if (!REGEX.NUMERIC_FORMAT.test(value)) {
      return
    }

    const numValue = parseFloat(value)

    // 整数のみモードの場合は小数点以下を切り捨て
    if (this.integerOnly) {
      this.element.value = Math.floor(numValue).toString()
      return
    }

    // 小数点フィールドモードの場合は.0形式を維持
    if (this.decimalField) {
      // 整数の場合は.0を追加
      if (Number.isInteger(numValue)) {
        this.element.value = numValue.toFixed(DECIMAL_PLACES.ONE)
      } else {
        this.element.value = value
      }
      return
    }

    // カンマありモードの場合はカンマを挿入
    if (!this.noComma && Number.isInteger(numValue)) {
      this.element.value = this.formatNumber(value)
    }
  }

  // focus イベント時の処理
  // 「0」または「0.0」の場合、フォーカス時に全選択する
  // 次に数字を入力すると自動的に上書きされる
  handleFocus(event) {
    const input = event.target
    const value = input.value.replace(REGEX.COMMA, SPECIAL_VALUES.EMPTY).trim()

    // 「0」または「0.0」の場合は全選択
    if (value === SPECIAL_VALUES.ZERO ||
        value === SPECIAL_VALUES.ZERO_DECIMAL ||
        value === SPECIAL_VALUES.ZERO_TWO_DECIMAL) {
      if (!this.isNumberType) {
        input.select()
      }
    }
  }

  // blur イベント時の処理
  // 小数点フィールドの場合、入力完了時に.0形式に変換する
  handleBlur(event) {
    const input = event.target

    // 小数点フィールドモードでない場合は何もしない
    if (!this.decimalField) {
      return
    }

    const value = input.value.replace(REGEX.COMMA, SPECIAL_VALUES.EMPTY).trim()

    // 空欄の場合は何もしない
    if (value === SPECIAL_VALUES.EMPTY || value === SPECIAL_VALUES.MINUS) {
      return
    }

    // 数値に変換
    const numValue = parseFloat(value)

    // NaNでない場合は.0形式に変換
    if (!isNaN(numValue)) {
      if (Number.isInteger(numValue)) {
        input.value = numValue.toFixed(DECIMAL_PLACES.ONE)
      }
    }
  }

  // input イベント時の処理
  // 全角→半角変換とカンマ挿入を実行
  // IME変換中または自分が起こしたinputイベントの場合はスキップ
  handleInput(event) {
    // IME変換中または自分が起こしたinputイベントの場合はスキップ
    if (this.isComposing || this.isUpdating) {
      return
    }
    this.convertAndFormat()
  }

  // paste イベント時の処理
  // ペースト後に変換処理を実行（次のイベントループで実行）
  handlePaste(event) {
    // ペースト後に変換（次のイベントループで実行）
    setTimeout(() => this.convertAndFormat(), TIMEOUT_DELAY.ZERO)
  }

  // 数値をカンマ区切りにフォーマット
  // 小数点がある場合は整数部分のみにカンマを挿入
  // 例: "1000" => "1,000", "1000000" => "1,000,000"
  formatNumber(digits) {
    // 小数点がある場合は整数部分のみにカンマを挿入
    if (digits.includes(SPECIAL_VALUES.DOT)) {
      const [integer, decimal] = digits.split(SPECIAL_VALUES.DOT)
      return integer.replace(REGEX.THREE_DIGIT_GROUP, ',') + SPECIAL_VALUES.DOT + decimal
    }
    return digits.replace(REGEX.THREE_DIGIT_GROUP, ',')
  }

  // フォーム送信前にカンマとスペースを削除して数値型に変換
  // サーバーに送信する前にカンマとスペースを削除して純粋な数値にする
  // 空欄の場合は空文字列のまま（サーバー側でバリデーションエラー）
  removeCommasBeforeSubmit() {
    if (!this.element.value) {
      // 空欄の場合は何もしない（サーバー側でpresenceバリデーション）
      return
    }

    // カンマとスペース（全角・半角）を削除
    let cleanValue = this.element.value
      .replace(REGEX.COMMA, SPECIAL_VALUES.EMPTY)
      .replace(REGEX.HALF_WIDTH_SPACE, SPECIAL_VALUES.EMPTY)
      .replace(REGEX.FULL_WIDTH_SPACE, SPECIAL_VALUES.EMPTY)

    // マイナス記号と小数点以外の非数値文字を削除（整数のみモードでは小数点も削除）
    if (this.integerOnly) {
      cleanValue = cleanValue.replace(REGEX.NON_DIGIT_NON_MINUS, SPECIAL_VALUES.EMPTY)
    } else {
      cleanValue = cleanValue.replace(REGEX.NON_DIGIT_NON_MINUS_NON_DOT, SPECIAL_VALUES.EMPTY)
    }

    // 空文字列でない場合は数値型に変換
    if (cleanValue !== SPECIAL_VALUES.EMPTY) {
      // 整数のみモードの場合はparseIntで変換
      const numericValue = this.integerOnly ? parseInt(cleanValue, 10) : parseFloat(cleanValue)

      // NaNでない場合のみ設定
      if (!isNaN(numericValue)) {
        this.element.value = numericValue
        Logger.log(LOG_MESSAGES.CONVERSION_SUCCESS, numericValue)
      } else {
        // NaNの場合は空文字列に設定（バリデーションエラーにする）
        this.element.value = SPECIAL_VALUES.EMPTY
        Logger.warn(LOG_MESSAGES.INVALID_VALUE, cleanValue)
      }
    }
  }

  // 全角文字を半角に変換 + スペース削除 + カンマ挿入
  // 入力値を以下の順で処理:
  // 1. 全角数字→半角数字
  // 2. 全角マイナス記号→半角マイナス記号
  // 3. 全角小数点→半角小数点（整数のみモードでは削除）
  // 4. 全角・半角スペースを削除
  // 5. カンマ削除
  // 6. 数値以外の文字削除
  // 7. カンマ挿入（noCommaモードでない場合）
  // 8. カーソル位置の調整
  convertAndFormat() {
    const input = this.element
    const originalValue = input.value

    // type="number"の場合はsetSelectionRangeが使えないのでカーソル位置を取得しない
    const cursorPosition = this.isNumberType ? null : input.selectionStart

    // 全角数字、マイナス記号を半角に変換
    let convertedValue = originalValue
      .replace(REGEX.FULL_WIDTH_NUMBER, (char) => String.fromCharCode(char.charCodeAt(0) - CHAR_CODE.FULL_WIDTH_OFFSET))
      .replace(REGEX.FULL_WIDTH_MINUS, SPECIAL_VALUES.MINUS)
      .replace(REGEX.HALF_WIDTH_SPACE, SPECIAL_VALUES.EMPTY)
      .replace(REGEX.FULL_WIDTH_SPACE, SPECIAL_VALUES.EMPTY)

    // 整数のみモードの場合は小数点を削除
    if (this.integerOnly) {
      convertedValue = convertedValue.replace(REGEX.FULL_WIDTH_DOT, SPECIAL_VALUES.EMPTY)
    } else {
      convertedValue = convertedValue.replace(REGEX.FULL_WIDTH_DOT, SPECIAL_VALUES.DOT)
    }

    // カンマを削除して数値のみを抽出
    const withoutCommas = convertedValue.replace(REGEX.COMMA, SPECIAL_VALUES.EMPTY)

    // 数値、マイナス記号、小数点のみ許可（整数のみモードでは小数点を除外）
    const allowedChars = this.integerOnly ? REGEX.NON_DIGIT_NON_MINUS : REGEX.NON_DIGIT_NON_MINUS_NON_DOT
    const cleanValue = withoutCommas.replace(allowedChars, SPECIAL_VALUES.EMPTY)

    // マイナス記号は先頭のみ許可
    const hasNegative = cleanValue.startsWith(SPECIAL_VALUES.MINUS)
    const withoutNegative = cleanValue.replace(REGEX.MINUS, SPECIAL_VALUES.EMPTY)

    // 小数点の処理（整数のみモードでない場合）
    const parts = this.integerOnly ? [withoutNegative] : withoutNegative.split(SPECIAL_VALUES.DOT)
    const integerPart = parts[0] || SPECIAL_VALUES.EMPTY
    const decimalPart = !this.integerOnly && parts.length > 1 ? SPECIAL_VALUES.DOT + parts[1] : SPECIAL_VALUES.EMPTY

    // 空の場合
    if (integerPart === SPECIAL_VALUES.EMPTY && decimalPart === SPECIAL_VALUES.EMPTY) {
      const newValue = hasNegative ? SPECIAL_VALUES.MINUS : SPECIAL_VALUES.EMPTY
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
    const finalValue = (hasNegative ? SPECIAL_VALUES.MINUS : SPECIAL_VALUES.EMPTY) + formatted + decimalPart

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
      const digitsBeforeCursor = (originalBeforeCursor.match(REGEX.DIGIT) || []).length

      // 新しい値で、同じ個数の数字の後ろにカーソルを配置
      let digitsSeen = 0
      let newCursorPos = hasNegative ? 1 : 0

      for (let i = hasNegative ? 1 : 0; i < finalValue.length; i++) {
        if (REGEX.DIGIT.test(finalValue[i])) {
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
