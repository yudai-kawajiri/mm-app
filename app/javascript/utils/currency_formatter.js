// CurrencyFormatter - 通貨フォーマットユーティリティ
//
// 日本円の統一的なフォーマット処理を提供
// Railsの number_to_currency(unit: "¥", precision: 0) と同等の出力を実現
//
// 機能:
// - 数値を日本円フォーマットに変換（¥記号付き）
// - カンマ区切りのみの数値フォーマット（¥記号なし）
//
// 使用例:
//   import CurrencyFormatter from "utils/currency_formatter"
//   const formatted = CurrencyFormatter.format(1000)  // "¥1,000"
//   const withoutSymbol = CurrencyFormatter.formatWithoutSymbol(1000)  // "1,000"

// 型名（typeof チェック用）
const TYPE_NAME = {
  STRING: 'string',
  NUMBER: 'number'
}

// ロケール設定
const LOCALE = {
  JAPAN: 'ja-JP'
}

// 通貨設定
const CURRENCY = {
  JPY: 'JPY'
}

// Intl.NumberFormat スタイル
const NUMBER_FORMAT_STYLE = {
  CURRENCY: 'currency'
}

// 小数点桁数設定
const FRACTION_DIGITS = {
  ZERO: 0
}

// デフォルト値
const DEFAULT_VALUE = {
  AMOUNT: 0  // NaNの場合のデフォルト金額
}

// 基数（parseInt用）
const RADIX = {
  DECIMAL: 10
}

// CurrencyFormatter オブジェクト
const CurrencyFormatter = {
  // 数値を日本円フォーマットに変換
  // Intl.NumberFormatを使用して日本円フォーマット（例: "¥1,000"）
  format(amount) {
    const numAmount = typeof amount === TYPE_NAME.STRING
      ? parseInt(amount, RADIX.DECIMAL)
      : amount

    // NaNの場合は0として処理
    const validAmount = isNaN(numAmount) ? DEFAULT_VALUE.AMOUNT : numAmount

    // Intl.NumberFormatを使用して日本円フォーマット
    const formatter = new Intl.NumberFormat(LOCALE.JAPAN, {
      style: NUMBER_FORMAT_STYLE.CURRENCY,
      currency: CURRENCY.JPY,
      minimumFractionDigits: FRACTION_DIGITS.ZERO,
      maximumFractionDigits: FRACTION_DIGITS.ZERO
    })

    return formatter.format(validAmount)
  },

  // ¥記号なしの数値フォーマット（カンマ区切りのみ）
  // 例: 1000 → "1,000"
  formatWithoutSymbol(amount) {
    const numAmount = typeof amount === TYPE_NAME.STRING
      ? parseInt(amount, RADIX.DECIMAL)
      : amount
    const validAmount = isNaN(numAmount) ? DEFAULT_VALUE.AMOUNT : numAmount

    return validAmount.toLocaleString(LOCALE.JAPAN)
  }
}

// グローバルスコープにも公開（レガシー互換性のため）
window.CurrencyFormatter = CurrencyFormatter

export default CurrencyFormatter
