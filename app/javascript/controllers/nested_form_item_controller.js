import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["destroy"]

  remove(event) {
    event.preventDefault();

    const button = event.currentTarget;

    // 両方の属性名に対応（製造計画管理: data-row-unique-id, 商品管理: data-unique-id）
    const uniqueId = button.dataset.rowUniqueId || button.dataset.uniqueId;

    if (!uniqueId) {
      console.error(' No unique ID found on button');
      return;
    }

    console.log(` Removing row with unique ID: ${uniqueId}`);

    // 同じユニークIDを持つ全ての行を検索（ALLタブと各カテゴリタブ）
    // 両方の属性名で検索
    const allMatchingRows = document.querySelectorAll(
      `[data-row-unique-id="${uniqueId}"], tr[data-unique-id="${uniqueId}"]`
    );

    if (allMatchingRows.length === 0) {
      console.warn(` No rows found with unique ID: ${uniqueId}`);
      return;
    }

    allMatchingRows.forEach(row => {
      // _destroyフィールドを設定
      const destroyInput = row.querySelector('[data-nested-form-item-target="destroy"]');
      if (destroyInput) {
        destroyInput.value = '1';
        console.log(`Set _destroy=1 for row in tab:`, row.closest('.tab-pane')?.id);
      }

      // 行を非表示
      row.style.display = 'none';
      console.log(` Hidden row in tab:`, row.closest('.tab-pane')?.id);
    });

    // 合計を再計算（製造計画管理の場合のみ）
    const hasCalculation = document.querySelector('[data-plan-product-target]');
    if (hasCalculation) {
      setTimeout(() => {
        this.dispatch('recalculate', { prefix: 'plan-product', bubbles: true });
      }, 100);
    }

    console.log(`All matching rows removed (${allMatchingRows.length} rows)`);
  }
}