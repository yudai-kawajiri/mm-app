// app/javascript/controllers/product_material_controller.js

import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = [ "materialSelect", "unitDisplay", "quantityInput", "unitWeightDisplay", "unitIdInput" ]

  // ドロップダウンが変更されたときに実行されるアクション
  updateUnit(event) {
    const materialId = event.target.value;

    if (!materialId) {
      this.unitDisplayTarget.textContent = "未設定";
      this.unitWeightDisplayTarget.textContent = "未設定"; // 追加

      this.unitIdInputTarget.value = "";
      return;
    }

    // 単位名、数量、重量を取得するための AJAX リクエストを実行
    fetch(`/api/v1/materials/${materialId}/product_unit_data`)
      .then(response => {
        if (!response.ok) {
          // 404/500エラーはここでキャッチ
          throw new Error(`AJAX request failed with status: ${response.status}`);
        }
        return response.json();
      })
      .then(data => {

        this.unitIdInputTarget.value = data.unit_id || "";
        // data.unit_name を単位表示ターゲットに設定
        this.unitDisplayTarget.textContent = data.unit_name || "未設定";

        // data.unit_weight を商品単位重量表示ターゲットに設定 (textContentプロパティを使う)
        this.unitWeightDisplayTarget.textContent = data.unit_weight || "未設定"; // 追加
      })
      .catch(error => {
        console.error("単位データの取得に失敗しました:", error);
        this.unitDisplayTarget.textContent = "エラー";
        this.unitWeightDisplayTarget.textContent = "エラー"; // 追加
      });
  }
}