import { Controller } from "@hotwired/stimulus"
export default class extends Controller {
  static targets = ["totalPrice", "totalContainer", "categoryTotal"]

  connect() {
    this.updateTotalPrice();
    this.updateCategoryTotals();
  }

  // 子コントローラーからのイベントを捕捉するアクション
  recalculate(event) {
    this.updateTotalPrice();
    this.updateCategoryTotals();
  }

  // 1. 総合計の計算ロジック
  updateTotalPrice() {
    let total = 0;
    const productRows = this.element.querySelectorAll('[data-controller~="plan-product"]');

    productRows.forEach(row => {
        // 1. テンプレート行（'NEW_RECORD'）を除外
        if (row.id && row.id.includes('NEW_RECORD')) return;

        // 2. 削除フィールドの要素を安全に取得（エラー回避）
        const destroyInput = row.querySelector('[data-plan-product-target="destroy"]');
        if (!destroyInput) return; // destroyInput が null の場合はスキップ

        const isDestroyed = destroyInput.value === '1';

        if (!isDestroyed) {

            // 数量入力フィールドの存在を確認（エラー回避）
            const quantityInput = row.querySelector('[data-plan-product-target="quantity"]');
            if (!quantityInput) return;

            // 値の取得と計算
            const price = parseFloat(row.dataset.planProductPriceValue) || 0;
            const quantity = parseFloat(quantityInput.value) || 0;

            total += quantity * price;
        }
    });

    this.totalPriceTarget.textContent = this.formatCurrency(total);
}

  // 2. カテゴリ合計の計算ロジック
  updateCategoryTotals() {
    let categoryTotals = {};

    const productRows = this.element.querySelectorAll('[data-controller~="plan-product"]');

    productRows.forEach(row => {
       // テンプレート行（NEW_RECORD）を除外
      if (row.id && row.id.includes('NEW_RECORD')) return;

        // 削除フィールドの要素を安全に取得（エラー回避）
        const destroyInput = row.querySelector('[data-plan-product-target="destroy"]');
        if (!destroyInput) return;

        const isDestroyed = destroyInput.value === '1';

        const categoryId = row.dataset.planProductCategoryId;

        if (!isDestroyed && categoryId) {

            const quantityInput = row.querySelector('[data-plan-product-target="quantity"]');
            if (!quantityInput) return;

            const price = parseFloat(row.dataset.planProductPriceValue) || 0;
            const quantity = parseFloat(quantityInput.value) || 0;
            const subtotal = quantity * price;

            if (!categoryTotals.hasOwnProperty(categoryId)) {
              categoryTotals[categoryId] = 0;
            }
            categoryTotals[categoryId] += subtotal;
        }
    });

    this.categoryTotalTargets.forEach(target => {
      const categoryId = target.dataset.categoryId;
      const total = categoryTotals[categoryId] || 0;
      target.textContent = this.formatCurrency(total);
    });
  }

  // 通貨整形ヘルパー
  formatCurrency(amount) {
    return new Intl.NumberFormat('ja-JP', { style: 'currency', currency: 'JPY', minimumFractionDigits: 0 }).format(amount);
}
}