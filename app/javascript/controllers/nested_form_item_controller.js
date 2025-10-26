import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["destroy"]

  remove(event) {
    event.preventDefault();

    const button = event.currentTarget;
    const uniqueRowId = button.dataset.rowUniqueId;

    console.log(`🗑️ Removing row with unique ID: ${uniqueRowId}`);

    // 同じユニークIDを持つ全ての行を検索（ALLタブと各カテゴリタブ）
    const allMatchingRows = document.querySelectorAll(`[data-row-unique-id="${uniqueRowId}"]`);

    allMatchingRows.forEach(row => {
      // _destroyフィールドを設定
      const destroyInput = row.querySelector('[data-nested-form-item-target="destroy"]');
      if (destroyInput) {
        destroyInput.value = '1';
      }

      // 行を非表示
      row.style.display = 'none';
      console.log(`✅ Hidden row in tab:`, row.closest('.tab-pane')?.id);
    });

    // 合計を再計算
    setTimeout(() => {
      this.dispatch('recalculate', { prefix: 'plan-product', bubbles: true });
    }, 100);

    console.log(`✅ All matching rows removed (${allMatchingRows.length} rows)`);
  }
}
