import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = [ "materialSelect", "unitDisplay", "quantityInput", "unitWeightDisplay", "unitIdInput" ]

  updateUnit(event) {
    const materialId = event.target.value;

    if (!materialId) {
      this.unitDisplayTarget.textContent = "未設定";
      this.unitWeightDisplayTarget.textContent = "未設定";
      this.unitIdInputTarget.value = "";
      return;
    }

    fetch(`/api/v1/materials/${materialId}/product_unit_data`)
      .then(response => {
        if (!response.ok) {
          throw new Error(`AJAX request failed with status: ${response.status}`);
        }
        return response.json();
      })
      .then(data => {
        this.unitIdInputTarget.value = data.unit_id || "";
        this.unitDisplayTarget.textContent = data.unit_name || "未設定";
        this.unitWeightDisplayTarget.textContent = data.unit_weight || "未設定";
      })
      .catch(error => {
        console.error("単位データの取得に失敗しました:", error);
        this.unitDisplayTarget.textContent = "エラー";
        this.unitWeightDisplayTarget.textContent = "エラー";
      });
  }

  // 原材料選択を他のタブに同期
  syncMaterialToOtherTabs(event) {
    const uniqueId = event.target.dataset.uniqueId;
    const selectedMaterialId = event.target.value;

    console.log(`🔄 Syncing material ${selectedMaterialId} for ${uniqueId}`);

    // 同じunique-idを持つ他のタブの原材料選択を更新
    document.querySelectorAll(`tr[data-unique-id="${uniqueId}"]`).forEach(row => {
      if (row === this.element) return; // 自分自身はスキップ

      const select = row.querySelector('[data-product-material-target="materialSelect"]');
      if (select && select.value !== selectedMaterialId) {
        select.value = selectedMaterialId;
        // change イベントを発火して updateUnit を呼び出す
        select.dispatchEvent(new Event('change', { bubbles: true }));
      }
    });
  }

  // 数量を他のタブに同期
  syncQuantityToOtherTabs(event) {
    const uniqueId = event.target.dataset.uniqueId;
    const quantity = event.target.value;

    console.log(`🔄 Syncing quantity ${quantity} for ${uniqueId}`);

    document.querySelectorAll(`tr[data-unique-id="${uniqueId}"]`).forEach(row => {
      if (row === this.element) return;

      const input = row.querySelector('[data-product-material-target="quantityInput"]');
      if (input && input.value !== quantity) {
        input.value = quantity;
      }
    });
  }
}
