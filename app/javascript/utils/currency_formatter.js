/**
 * @file utils/currency_formatter.js
 * 通貨フォーマットユーティリティ
 *
 * @module Utils
 */

/**
 * CurrencyFormatter クラス
 *
 * 通貨フォーマット機能を提供するユーティリティ。
 * Intl.NumberFormat APIを使用して日本円形式にフォーマットする。
 *
 * 機能:
 * - 数値を日本円形式（¥記号付き）にフォーマット
 * - 小数点以下を表示しない整数表示
 * - カンマ区切り（3桁ごと）
 * - null/undefined を0円として扱う
 *
 * @example 使用例
 *   import CurrencyFormatter from "utils/currency_formatter"
 *
 *   CurrencyFormatter.format(1000)      // "¥1,000"
 *   CurrencyFormatter.format(1234567)   // "¥1,234,567"
 *   CurrencyFormatter.format(0)         // "¥0"
 *   CurrencyFormatter.format(null)      // "¥0"
 */
class CurrencyFormatter {
  /**
   * 数値を日本円形式にフォーマット
   *
   * @param {number|null|undefined} amount - フォーマットする金額
   * @return {string} フォーマット済み通貨文字列（例: "¥1,000"）
   */
  static format(amount) {
    return new Intl.NumberFormat('ja-JP', {
      style: 'currency',
      currency: 'JPY',
      minimumFractionDigits: 0
    }).format(amount || 0)
  }
}

export default CurrencyFormatter
