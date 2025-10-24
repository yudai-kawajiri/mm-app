import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["grandTotal", "categoryTotal"]

  connect() {
    console.log('🔌 Plan products controller connected!');
    this.updateTotals(); // 接続時に初期計算
  }

  // 子コントローラーからのイベントをキャッチして合計を更新
  recalculate(event) {
    // calculatedとrecalculateイベントの両方をこのメソッドで処理
    console.log(`🔄 Recalculate triggered by event: ${event.type}`);
    this.updateTotals();
  }

  // 新しい行追加時
  afterAdd(event) {
    console.log('New row added!');
    // 新しい行が完全に描画された後に計算を実行
    setTimeout(() => {
      this.updateTotals();
    }, 100);
  }

  // 統合された合計計算
  updateTotals() {
    console.log('Updating totals via Child Controllers');

    let grandTotal = 0;
    let categoryTotals = {};

    // フォーム内の全ての商品行をスキャン
    const productRows = this.element.querySelectorAll('[data-controller~="plan-product"]');
    const application = this.application; // Stimulusアプリケーションのインスタンスを取得

    productRows.forEach(row => {
      // テンプレート行（NEW_RECORD）を除外
      if (row.id && row.id.includes('NEW_RECORD')) return;

      // 削除フラグをチェック
      const destroyInput = row.querySelector('[data-nested-form-item-target="destroy"]');
      const isDestroyed = destroyInput ? destroyInput.value === '1' : false;
      if (isDestroyed) return;

      // 子コントローラーのインスタンスから直接値を取得
      const childController = application.getControllerForElementAndIdentifier(row, 'plan-product');

      if (childController && typeof childController.getCurrentValues === 'function') {
        const values = childController.getCurrentValues();

        const subtotal = values.subtotal;
        const categoryId = values.categoryId;

        console.log(`Row subtotal via controller: ${values.quantity} × ${values.price} = ${subtotal} (category: ${categoryId})`);

        // 総合計に加算
        grandTotal += subtotal;

        // カテゴリ合計に加算
        if (categoryId && subtotal > 0) {
          if (!categoryTotals.hasOwnProperty(categoryId)) {
            categoryTotals[categoryId] = 0;
          }
          categoryTotals[categoryId] += subtotal;
        }
      } else {
        console.warn('Child controller or getCurrentValues method not found on row:', row);
      }
    });

    console.log('Grand total:', grandTotal);
    console.log('Category totals:', categoryTotals);

    // 表示更新
    this.updateDisplay(grandTotal, categoryTotals);
  }

  //  表示更新ヘルパー
  updateDisplay(grandTotal, categoryTotals) {
    console.log('Updating display');

    // 総合計の更新
    // target名に合わせて grandTotalTarget を使用
    if (this.hasGrandTotalTarget) {
      this.grandTotalTarget.textContent = this.formatCurrency(grandTotal);
      console.log('Updated grand total display:', grandTotal);
    } else {
      console.warn('Grand total target not found! (Check HTML target name)');
    }

    // カテゴリ別合計の更新
    this.categoryTotalTargets.forEach(target => {
      const categoryId = target.dataset.categoryId;
      const total = categoryTotals[categoryId] || 0;
      target.textContent = this.formatCurrency(total);
      console.log(`Updated category ${categoryId} total:`, total);
    });
  }

  // 通貨フォーマット
  formatCurrency(amount) {
    return new Intl.NumberFormat('ja-JP', {
      style: 'currency',
      currency: 'JPY',
      minimumFractionDigits: 0
    }).format(amount);
  }
}