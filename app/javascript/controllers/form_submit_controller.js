import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  connect() {
    console.log("Form submit controller connected");

    // フォーム要素を取得
    const form = this.element;

    // submit イベントをリッスン
    form.addEventListener('submit', this.handleSubmit.bind(this));
  }

  handleSubmit(event) {
    console.log("Form submitting, removing duplicates...");

    // すべてのネストフォームフィールドを取得
    const allRows = this.element.querySelectorAll('tr[data-unique-id], tr[data-row-unique-id]');

    if (allRows.length === 0) {
      console.log("No nested fields found, proceeding with submit");
      return;
    }

    // unique_id ごとにグループ化
    const rowsByUniqueId = new Map();

    allRows.forEach(row => {
      const uniqueId = row.dataset.uniqueId || row.dataset.rowUniqueId;

      if (!uniqueId) return;

      // _destroy=1 の行はスキップ
      const destroyInput = row.querySelector('[data-nested-form-item-target="destroy"]');
      if (destroyInput && destroyInput.value === '1') {
        return;
      }

      if (!rowsByUniqueId.has(uniqueId)) {
        rowsByUniqueId.set(uniqueId, []);
      }

      rowsByUniqueId.get(uniqueId).push(row);
    });

    // 重複がある場合、2つ目以降の行のフィールドを無効化
    let duplicatesFound = 0;

    rowsByUniqueId.forEach((rows, uniqueId) => {
      if (rows.length > 1) {
        console.log(`Found ${rows.length} duplicates for ${uniqueId}`);

        // 最初の1つを残し、残りを無効化
        for (let i = 1; i < rows.length; i++) {
          const row = rows[i];

          // この行の全てのinput/select/textareaを無効化（hidden以外）
          const inputs = row.querySelectorAll('input:not([type="hidden"]), select, textarea');
          inputs.forEach(input => {
            input.disabled = true;
            console.log(`  Disabled field: ${input.name}`);
          });

          duplicatesFound++;
        }
      }
    });

    if (duplicatesFound > 0) {
      console.log(`Disabled ${duplicatesFound} duplicate rows`);
    } else {
      console.log("No duplicates found");
    }

    // フォーム送信を続行
    return true;
  }
}
Response
