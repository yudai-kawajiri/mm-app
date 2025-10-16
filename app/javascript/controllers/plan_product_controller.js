// 個々の商品行の計算と API アクセス機能

import { Controller } from "@hotwired/stimulus";

// 個別項目の小計を計算し、親コントローラーに通知
export default class extends Controller {
  static targets = ["subtotal", "quantity", "destroy"];

  connect() {
    this.calculate(); // 初期計算を実行
  }

  // 1. 数量変更時の計算ロジック
  calculate() {
    const price = parseFloat(this.element.dataset.planProductPriceValue) || this.priceValue || 0;
    const quantity = parseFloat(this.quantityTarget.value) || 0;
    const subtotal = quantity * price;
    // 小計を整形して表示
    this.subtotalTarget.textContent = this.formatCurrency(subtotal);

   // 親コントローラーに通知し、総合計とカテゴリ合計を更新
    this.dispatch("calculated", { prefix: "plan-product" });
  }

  // 2. 商品選択時の処理 (API呼び出し)
  updateProduct(event) {
    // 選択された商品IDの取得と条件判定
    const productId = event.target.value;

    if (productId) {
       //  API呼び出しと状態の更新 (メインロジック)
      this.fetchProductDetails(productId).then(data => {
        this.priceValue = data.price;
        this.element.dataset.planProductPriceValue = data.price;
        // HTML要素にカテゴリIDをデータ属性として保存
        this.element.dataset.planProductCategoryId = data.category_id;

        // カテゴリIDもイベントに含めて親に渡す (カテゴリ別合計に利用)
        this.dispatch("plan-product:category-updated", { detail: { categoryId: data.category_id } });
        this.calculate();
      //   エラーハンドリング
      }).catch(error => {
        console.error("Failed to fetch product details:", error);
        this.priceValue = 0;
        this.calculate();
      });
    } else {
      // 解除した場合
      this.priceValue = 0;
      this.element.dataset.planProductPriceValue = 0;
      this.dispatch("plan-product:category-updated", { detail: { categoryId: null } });
      this.calculate();
    }
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