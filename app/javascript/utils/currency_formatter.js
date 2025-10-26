// app/javascript/utils/currency_formatter.js

class CurrencyFormatter {
  static format(amount) {
    return new Intl.NumberFormat('ja-JP', {
      style: 'currency',
      currency: 'JPY',
      minimumFractionDigits: 0
    }).format(amount || 0)
  }
}

export default CurrencyFormatter