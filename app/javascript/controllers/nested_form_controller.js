import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["target", "template"]

  add(event) {
    event.preventDefault();

    const button = event.currentTarget;
    const categoryId = button.dataset.categoryId;
    const templateId = button.dataset.templateId;

    console.log(`📝 Adding new field for category: ${categoryId}`);

    // ALLタブ (categoryId = 0) では追加不可
    if (categoryId === '0') {
      console.warn('⚠️ Cannot add products in ALL tab');
      return;
    }

    // テンプレートを取得
    const template = document.getElementById(templateId);
    if (!template) {
      console.error(`❌ Template not found: ${templateId}`);
      return;
    }

    // ターゲットコンテナを取得（同じカテゴリIDを持つtbody）
    const categoryContainer = this.findTargetContainer(categoryId);
    if (!categoryContainer) {
      console.error(`❌ Target container not found for category: ${categoryId}`);
      return;
    }

    // ユニークなrow_idを生成
    const uniqueRowId = `row_${Date.now()}_${Math.floor(Math.random() * 1000)}`;

    // テンプレートを複製
    let content = template.innerHTML;
    const newId = new Date().getTime();
    content = content.replace(/NEW_RECORD/g, newId);

    // ユニークIDを設定（既存のrow_XXXを置換）
    content = content.replace(/data-row-unique-id="row_[^"]*"/g, `data-row-unique-id="${uniqueRowId}"`);

    // カテゴリタブに追加
    categoryContainer.insertAdjacentHTML('beforeend', content);

    // ALLタブにも同じ内容を追加
    const allContainer = this.findTargetContainer('0');
    if (allContainer) {
      allContainer.insertAdjacentHTML('beforeend', content);
      console.log('✅ Also added to ALL tab');
    }

    // 合計を再計算
    setTimeout(() => {
      this.dispatch('recalculate', { prefix: 'plan-product', bubbles: true });
    }, 100);

    console.log(`✅ New field added with unique ID: ${uniqueRowId}`);
  }

  // カテゴリIDに対応するターゲットコンテナを検索
  findTargetContainer(categoryId) {
    const tabPane = document.querySelector(`#nav-${categoryId}`);
    if (!tabPane) {
      console.warn(`⚠️ Tab pane not found for category: ${categoryId}`);
      return null;
    }

    const container = tabPane.querySelector(`[data-nested-form-target="target"][data-category-id="${categoryId}"]`);
    if (!container) {
      console.warn(`⚠️ Container not found in tab pane for category: ${categoryId}`);
    }
    return container;
  }
}
