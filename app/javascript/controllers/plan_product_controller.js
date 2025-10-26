import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["productSelect", "quantity", "priceDisplay", "subtotal"]
  static values = {
    price: Number,
    categoryId: Number
  }

  connect() {
    console.log('🔌 Plan product controller connected!');
    this.calculate(); // 初期計算
  }

  // 商品変更時の処理
  updateProduct(event) {
    const productId = event.target.value;
    console.log('📦 Product selected:', productId);

    if (!productId) {
      this.resetProduct();
      return;
    }

    // 商品情報を取得
    this.fetchProductInfo(productId);
  }

  // 商品情報取得
  async fetchProductInfo(productId) {
  try {
    const response = await fetch(`/api/v1/products/${productId}/details_for_plan`);

    // HTTPステータスコードが成功でない場合のエラー処理を追加
    if (!response.ok) {
        throw new Error(`HTTP error! status: ${response.status}`);
    }

    const product = await response.json();

    console.log('Product info:', product);

    // 価格とカテゴリーIDを更新
    this.priceValue = product.price || 0;
    this.categoryIdValue = product.category_id || 0;

    // 価格表示を更新
    this.updatePriceDisplay();

    // 計算実行
    this.calculate();

  } catch (error) {
    console.error('❌ Product fetch error:', error);
    this.resetProduct();
  }
}

  // 🔧 価格表示更新
  updatePriceDisplay() {
    if (this.hasPriceDisplayTarget) {
      const formattedPrice = new Intl.NumberFormat('ja-JP', {
        style: 'currency',
        currency: 'JPY',
        minimumFractionDigits: 0
      }).format(this.priceValue);

      this.priceDisplayTarget.textContent = formattedPrice;
      console.log('💰 Price updated:', formattedPrice);
    }
  }

  // 🔧 商品リセット
  resetProduct() {
    this.priceValue = 0;
    this.categoryIdValue = 0;
    this.updatePriceDisplay();
    this.calculate();
  }

  // 🔧 計算処理
  calculate() {
    console.log('🧮 Calculate triggered!');

    const quantity = this.getQuantity();
    const price = this.priceValue || 0;
    const subtotal = quantity * price;

    console.log(`💵 Calculation: ${quantity} × ${price} = ${subtotal}`);

    // 小計表示更新
    this.updateSubtotal(subtotal);

    // 親に通知
    this.notifyParent();
  }

  // 🔧 数量取得
  getQuantity() {
    if (!this.hasQuantityTarget) {
      console.warn('⚠️ Quantity target not found!');
      return 0;
    }
    const value = this.quantityTarget.value;
    console.log('📊 Quantity value:', value);
    return value ? parseFloat(value) || 0 : 0;
  }

  // 🔧 小計表示更新
  updateSubtotal(subtotal) {
    if (this.hasSubtotalTarget) {
      const formattedSubtotal = new Intl.NumberFormat('ja-JP', {
        style: 'currency',
        currency: 'JPY',
        minimumFractionDigits: 0
      }).format(subtotal);

      this.subtotalTarget.textContent = formattedSubtotal;
      console.log('📊 Subtotal updated:', formattedSubtotal);
    }
  }

  // 🔧 親への通知（計算時）
  notifyParent() {
    console.log('📊 Notifying parent of calculation!');
    this.dispatch('calculated', {
      prefix: 'plan-product',
      bubbles: true
    });
  }

  // 🔧 削除通知
  notifyDeletion(event) {
    console.log('🗑️ Deletion triggered!');
    this.dispatch('recalculate', {
      prefix: 'plan-product',
      bubbles: true
    });
  }

  // 🔧 現在の値を取得（親コントローラー用）
  getCurrentValues() {
    return {
      quantity: this.getQuantity(),
      price: this.priceValue || 0,
      subtotal: this.getQuantity() * (this.priceValue || 0),
      categoryId: this.categoryIdValue || 0
    };
  }
}