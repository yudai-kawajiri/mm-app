import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["productSelect", "productionCount", "priceDisplay", "subtotal", "grandTotal", "categoryTotal"]

  static values = {
    price: Number,
    categoryId: Number
  }

  // ============================================================
  // 初期化
  // ============================================================

  connect() {
    console.log('🔌 Plan product controller connected');

    // 計算中フラグの初期化
    this.isCalculating = false;
    this.isUpdatingTotals = false;

    if (this.hasGrandTotalTarget) {
      console.log('👨 Parent controller mode');
      this.updateTotals();
    }

    if (this.hasSubtotalTarget && !this.hasGrandTotalTarget) {
      console.log('👶 Child controller mode');
      setTimeout(() => this.calculate(), 100);
    }
  }

  // ============================================================
  // 親コントローラー：総合計・カテゴリ合計の管理
  // ============================================================

  recalculate(event) {
    if (!this.hasGrandTotalTarget) return;

    // 既に更新中なら無視
    if (this.isUpdatingTotals) {
      console.log('⏭️ Already updating totals, skipping');
      return;
    }

    console.log(`🔄 Recalculate triggered: ${event?.type}`);

    // 短い遅延で実行（連続呼び出しを防ぐ）
    clearTimeout(this.updateTimeout);
    this.updateTimeout = setTimeout(() => this.updateTotals(), 50);
  }

  updateTotals() {
    if (!this.hasGrandTotalTarget) return;

    // 更新中フラグを立てる
    if (this.isUpdatingTotals) return;
    this.isUpdatingTotals = true;

    console.log('📊 Updating totals');

    const allTabPane = document.querySelector('#nav-0');
    if (!allTabPane) {
      console.warn('⚠️ ALL tab not found');
      this.isUpdatingTotals = false;
      return;
    }

    let grandTotal = 0;
    let categoryTotals = {};

    const productRows = allTabPane.querySelectorAll('tr[data-controller~="plan-product"]');
    console.log(`📊 Scanning ${productRows.length} rows`);

    productRows.forEach((row, index) => {
      if (row.outerHTML.includes('NEW_RECORD')) return;

      const destroyInput = row.querySelector('[data-nested-form-item-target="destroy"]');
      if (destroyInput?.value === '1') return;

      if (row.style.display === 'none') return;

      const childController = this.application.getControllerForElementAndIdentifier(row, 'plan-product');

      if (childController?.getCurrentValues) {
        const values = childController.getCurrentValues();
        console.log(`  Row ${index}: ${values.quantity} × ${values.price} = ${values.subtotal} (cat: ${values.categoryId})`);

        grandTotal += values.subtotal;

        if (values.categoryId && values.categoryId !== 0 && values.subtotal > 0) {
          categoryTotals[values.categoryId] = (categoryTotals[values.categoryId] || 0) + values.subtotal;
        }
      }
    });

    console.log(`💰 Grand total: ${grandTotal}`);
    console.log(`📊 Category totals:`, categoryTotals);

    this.updateDisplay(grandTotal, categoryTotals);

    // フラグを解除
    this.isUpdatingTotals = false;
  }

  updateDisplay(grandTotal, categoryTotals) {
    if (this.hasGrandTotalTarget) {
      this.grandTotalTarget.textContent = this.formatCurrency(grandTotal);
      console.log(`✅ Grand total updated: ${this.formatCurrency(grandTotal)}`);
    }

    if (this.hasCategoryTotalTarget) {
      this.categoryTotalTargets.forEach(target => {
        const categoryId = target.dataset.categoryId;
        const total = categoryTotals[categoryId] || 0;
        target.textContent = this.formatCurrency(total);
        console.log(`✅ Category ${categoryId} updated: ${this.formatCurrency(total)}`);
      });
    }
  }

  // ============================================================
  // 子コントローラー：商品行の計算
  // ============================================================

  async updateProduct(event) {
    const productId = event.target.value;
    console.log(`📦 Product selected: ${productId}`);

    if (!productId) {
      this.resetProduct();
      return;
    }

    await this.fetchProductInfo(productId);
  }

  async fetchProductInfo(productId) {
    try {
      const response = await fetch(`/api/v1/products/${productId}/details_for_plan`);
      if (!response.ok) throw new Error(`HTTP error! status: ${response.status}`);

      const product = await response.json();

      this.priceValue = product.price || 0;
      this.categoryIdValue = product.category_id || 0;

      this.updatePriceDisplay();
      this.calculate();
    } catch (error) {
      console.error('❌ Product fetch error:', error);
      this.resetProduct();
    }
  }

  updatePriceDisplay() {
    if (this.hasPriceDisplayTarget) {
      this.priceDisplayTarget.textContent = this.formatCurrency(this.priceValue);
      console.log(`💰 Price: ${this.formatCurrency(this.priceValue)}`);
    }
  }

  resetProduct() {
    this.priceValue = 0;
    this.categoryIdValue = 0;
    this.updatePriceDisplay();
    this.calculate();
  }

  calculate() {
    // 計算中なら無視
    if (this.isCalculating) return;

    this.isCalculating = true;
    console.log('🧮 Calculate');

    const quantity = this.getQuantity();
    const price = this.priceValue || 0;
    const subtotal = quantity * price;

    console.log(`  ${quantity} × ${price} = ${subtotal}`);

    this.updateSubtotal(subtotal);

    // 親への通知は遅延させて1回だけ
    clearTimeout(this.notifyTimeout);
    this.notifyTimeout = setTimeout(() => {
      this.notifyParent();
      this.isCalculating = false;
    }, 100);
  }

  getQuantity() {
    if (!this.hasProductionCountTarget) return 0;
    return parseFloat(this.productionCountTarget.value) || 0;
  }

  updateSubtotal(subtotal) {
    if (this.hasSubtotalTarget) {
      this.subtotalTarget.textContent = this.formatCurrency(subtotal);
    }
  }

  notifyParent() {
  console.log('📢 Notify parent');

  // イベントを dispatch
  this.dispatch('calculated', {
    prefix: 'plan-product',
    bubbles: true
  });

  // 直接親コントローラーを探して呼び出す（より確実）
  const parentElement = document.querySelector('[data-plan-product-target="totalContainer"]');
  if (parentElement) {
    const parentController = this.application.getControllerForElementAndIdentifier(parentElement, 'plan-product');
    if (parentController && parentController !== this && typeof parentController.recalculate === 'function') {
      console.log('📢 Directly calling parent recalculate');
      parentController.recalculate({ type: 'direct-call' });
    } else {
      console.warn('⚠️ Parent controller not found or is same as this');
    }
  } else {
    console.warn('⚠️ Parent element not found');
  }
}

  getCurrentValues() {
    const quantity = this.getQuantity();
    return {
      quantity: quantity,
      price: this.priceValue || 0,
      subtotal: quantity * (this.priceValue || 0),
      categoryId: this.categoryIdValue || 0
    };
  }

  // ============================================================
  // タブ間の同期
  // ============================================================

  syncProductToOtherTabs(event) {
    const selectElement = event.currentTarget;
    const selectedProductId = selectElement.value;
    const uniqueRowId = selectElement.dataset.rowUniqueId;

    console.log(`🔄 Sync product: ${selectedProductId} for row: ${uniqueRowId}`);

    const allMatchingSelects = document.querySelectorAll(`select[data-row-unique-id="${uniqueRowId}"]`);

    allMatchingSelects.forEach(select => {
      if (select !== selectElement && select.value !== selectedProductId) {
        select.value = selectedProductId;

        // イベントを発火（ただし同期は防ぐ）
        const changeEvent = new Event('change', { bubbles: true });
        select.dispatchEvent(changeEvent);
      }
    });
  }

  syncQuantityToOtherTabs(event) {
    const inputElement = event.currentTarget;
    const quantity = inputElement.value;
    const uniqueRowId = inputElement.dataset.rowUniqueId;

    console.log(`🔄 Sync quantity: ${quantity} for row: ${uniqueRowId}`);

    const allMatchingInputs = document.querySelectorAll(`input[data-plan-product-target="productionCount"][data-row-unique-id="${uniqueRowId}"]`);

    allMatchingInputs.forEach(input => {
      if (input !== inputElement && input.value !== quantity) {
        input.value = quantity;

        // イベントを発火（ただし同期は防ぐ）
        const inputEvent = new Event('input', { bubbles: true });
        input.dispatchEvent(inputEvent);
      }
    });
  }

  // ============================================================
  // ヘルパー
  // ============================================================

  formatCurrency(amount) {
    return new Intl.NumberFormat('ja-JP', {
      style: 'currency',
      currency: 'JPY',
      minimumFractionDigits: 0
    }).format(amount);
  }
}
