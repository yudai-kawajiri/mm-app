import { Controller } from "@hotwired/stimulus";

export default class extends Controller {
  // totalContainer は削除
  static targets = ["totalPrice", "categoryTotal"]

  connect() {
    this.updateTotals(); // 接続時に初期計算
  }

  // 子コントローラーからのイベントを捕捉するアクション
  recalculate(event) {
    // 常に全体の行をスキャンして合計を更新
    this.updateTotals();
  }

  // 総合計とカテゴリ合計を統合
  updateTotals() {
    let grandTotal = 0;
    let categoryTotals = {};

    // フォーム内の全ての商品行を一度だけスキャン
    const productRows = this.element.querySelectorAll('[data-controller~="plan-product"]');

    productRows.forEach(row => {
      // 1. テンプレート行（NEW_RECORD）を除外
      if (row.id && row.id.includes('NEW_RECORD')) return;

      // 2. 削除フラグと値の取
      const destroyInput = row.querySelector('[data-plan-product-target="destroy"]');
      const isDestroyed = destroyInput ? destroyInput.value === '1' : false;

      // 削除されていない行のみを対象とする
      if (!isDestroyed) {
        // 数量と価格の取得
        const price = parseFloat(row.dataset.planProductPriceValue || 0);
        const categoryId = row.dataset.planProductCategoryId;

        // 数量のフォーム入力値を取得
        const quantityInput = row.querySelector('[data-plan-product-target="quantity"]');
        const quantity = parseFloat(quantityInput ? quantityInput.value : 0);

        const subtotal = quantity * price;

        // 3. 総合計に加算
        grandTotal += subtotal;

        // 4. カテゴリ合計に加算
        if (categoryId) {
          if (!categoryTotals.hasOwnProperty(categoryId)) {
            categoryTotals[categoryId] = 0;
          }
          categoryTotals[categoryId] += subtotal;
        }
      }
    });

    // 5. 表示の更新
    this.updateDisplay(grandTotal, categoryTotals);
  }

  // 新しい行がフォームに追加されたときに、すぐに合計を再計算 (nested-formとの連携)
  afterAdd(event) {
    this.updateTotals(); // 統合されたメソッドを呼び出す
  }

  // 表示更新ヘルパー
  updateDisplay(grandTotal, categoryTotals) {
    // 総合計の更新
    if (this.totalPriceTarget) {
      this.totalPriceTarget.textContent = this.formatCurrency(grandTotal);
    }

    // カテゴリ別合計の更新
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