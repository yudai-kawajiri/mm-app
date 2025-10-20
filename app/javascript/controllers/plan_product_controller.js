// 商品行の計算と API アクセス機能

import { Controller } from "@hotwired/stimulus";

export default class extends Controller {
  static targets = ["subtotal", "quantity", "destroy", "priceDisplay"];

  // 内部プロパティで価格を管理
  priceValue = 0;

  connect() {
    this.priceValue = parseFloat(this.element.dataset.planProductPriceValue) || 0;
    this.calculate();
  }

  // 1. 数量変更時の計算ロジック
  calculate() {
    const price = this.priceValue;
    const quantity = parseFloat(this.quantityTarget.value) || 0;
    const subtotal = quantity * price;

    this.subtotalTarget.textContent = this.formatCurrency(subtotal);
    this.updatePriceDisplay(price);

    this.dispatch('calculated', { prefix: 'plan-product' });
  }

  // 2. 商品選択時の処理 (API呼び出し)
  updateProduct(event) {
    const productId = event.target.value;

    if (productId) {
      this.fetchProductDetails(productId).then(data => {
        this.priceValue = data.price || 0;

        this.element.dataset.planProductPriceValue = this.priceValue;

        this.element.dataset.planProductCategoryId = data.category_id;

        this.updatePriceDisplay(this.priceValue);

        if (data.unit_weight && (this.quantityTarget.value === "" || parseFloat(this.quantityTarget.value) === 0)) {
            this.quantityTarget.value = data.unit_weight;
        }

        this.dispatch("plan-product:category-updated", { detail: { categoryId: data.category_id } });
        this.calculate();
      }).catch(error => {
        console.error("Failed to fetch product details:", error);
        this.priceValue = 0;
        this.updatePriceDisplay(0);
        this.calculate();
      });
    } else {
      this.priceValue = 0;
      this.updatePriceDisplay(0);
      this.dispatch("plan-product:category-updated", { detail: { categoryId: null } });
      this.calculate();
    }
  }

  // 3. 論理削除（_destroy）に対応した削除アクション
  remove(event) {
    // 1. _destroy 隠しフィールドの値を '1' に設定（Railsに削除を伝える）
    this.destroyTarget.value = '1';

    // 2. 行全体を非表示
    this.element.style.display = 'none';

    // 3. 親コントローラーに再計算を要求
    this.dispatch('calculated', { prefix: 'plan-product', bubbles: true });
  }

  // 売価表示を更新するヘルパーメソッド
  updatePriceDisplay(price) {
    this.priceDisplayTarget.textContent = this.formatCurrency(price);
  }

  // APIを介して商品詳細を取得する非同期関数
  async fetchProductDetails(productId) {
    const response = await fetch(`/products/${productId}/details_for_plan`);
    if (!response.ok) {
      throw new Error('Network response was not ok');
    }
    return response.json();
  }

  // 通貨整形ヘルパー
  formatCurrency(amount) {
    return new Intl.NumberFormat('ja-JP', { style: 'currency', currency: 'JPY', minimumFractionDigits: 0 }).format(amount);
  }
}