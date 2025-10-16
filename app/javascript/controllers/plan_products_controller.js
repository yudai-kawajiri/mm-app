// 総合計とカテゴリ合計の集計

import { Controller } from "@hotwired/stimulus"
export default class extends Controller {
  static targets = ["totalPrice", "totalContainer", "categoryTotal"]

  connect() {
    this.updateTotalPrice();
    this.updateCategoryTotals(); // カテゴリ合計も初期計算
  }

  // 子コントローラーからのイベントを捕捉するアクション
  recalculate(event) {
    this.updateTotalPrice();
    this.updateCategoryTotals(); // 総合計とカテゴリ合計を更新
  }

  // 1. 総合計の計算ロジック
  updateTotalPrice() {
    let total = 0;

    // 全ての plan-product コントローラーの要素（商品行）を取得
    const productRows = this.element.querySelectorAll('[data-controller~="plan-product"]');

    productRows.forEach(row => {
      // 削除対象でないことを確認
      const isDestroyed = row.querySelector('[data-plan-product-target="destroy"]').value === '1';

      if (!isDestroyed) {
        // 子コントローラーの Stimulus Value（データ属性）から price を取得
        const price = parseFloat(row.dataset.planProductPriceValue) || 0;
        // 数量入力フィールドから quantity を取得
        const quantity = parseFloat(row.querySelector('[data-plan-product-target="quantity"]').value) || 0;

        total += quantity * price;
      }
    });

    // 総合計を表示
    this.totalPriceTarget.textContent = this.formatCurrency(total);
  }

  // 2. カテゴリ合計の計算ロジック
  updateCategoryTotals() {
    let categoryTotals = {};

    //  全ての製品行をループして集計
    const productRows = this.element.querySelectorAll('[data-controller~="plan-product"]');

    productRows.forEach(row => {
      const isDestroyed = row.querySelector('[data-plan-product-target="destroy"]').value === '1';
      //  修正後の子ERBから data-plan-product-category-id を取得
      const categoryId = row.dataset.planProductCategoryId;
      // 読み取った文字列を数値（例: 5）に変換し、quantity 変数に代入する。
      if (!isDestroyed && categoryId) {
        const price = parseFloat(row.dataset.planProductPriceValue) || 0;
        const quantity = parseFloat(row.querySelector('[data-plan-product-target="quantity"]').value) || 0;
        const subtotal = quantity * price;

        if (!categoryTotals.hasOwnProperty(categoryId)) {
          categoryTotals[categoryId] = 0;
        }
        categoryTotals[categoryId] += subtotal;
      }
    });

    //  結果を全ての categoryTotal ターゲットに書き込む
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
