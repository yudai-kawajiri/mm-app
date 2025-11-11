/**
 * CurrencyFormatter - 通貨フォーマットユーティリティ
 *
 * 日本円の統一的なフォーマット処理を提供します。
 * Railsの number_to_currency(unit: "¥", precision: 0) と同等の出力を実現。
 */
(function() {
  'use strict';

  const CurrencyFormatter = {
    /**
     * 数値を日本円フォーマットに変換
     *
     * @param {number|string} amount - フォーマットする金額
     * @returns {string} フォーマット済み文字列（例: "¥1,000"）
     */
    format: function(amount) {
      const numAmount = typeof amount === 'string' ? parseInt(amount, 10) : amount;

      // NaNの場合は0として処理
      const validAmount = isNaN(numAmount) ? 0 : numAmount;

      // Intl.NumberFormatを使用して日本円フォーマット
      const formatter = new Intl.NumberFormat('ja-JP', {
        style: 'currency',
        currency: 'JPY',
        minimumFractionDigits: 0,
        maximumFractionDigits: 0
      });

      return formatter.format(validAmount);
    },

    /**
     * ¥記号なしの数値フォーマット（カンマ区切りのみ）
     *
     * @param {number|string} amount - フォーマットする金額
     * @returns {string} フォーマット済み文字列（例: "1,000"）
     */
    formatWithoutSymbol: function(amount) {
      const numAmount = typeof amount === 'string' ? parseInt(amount, 10) : amount;
      const validAmount = isNaN(numAmount) ? 0 : numAmount;

      return validAmount.toLocaleString('ja-JP');
    }
  };

  // グローバルスコープに公開
  window.CurrencyFormatter = CurrencyFormatter;

})();
