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
      console.warn('⚠️ Cannot add items in ALL tab');
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

    // ユニークなIDを生成
    const uniqueId = `new_${Date.now()}_${Math.floor(Math.random() * 1000)}`;

    // テンプレートを複製
    let content = template.innerHTML;
    const newId = new Date().getTime();
    content = content.replace(/NEW_RECORD/g, newId);

    // ユニークIDを設定（両方の属性名に対応）
    // 製造計画管理用: data-row-unique-id
    content = content.replace(/data-row-unique-id="[^"]*"/g, `data-row-unique-id="${uniqueId}"`);
    // 商品管理用: data-unique-id
    content = content.replace(/data-unique-id="new_[^"]*"/g, `data-unique-id="${uniqueId}"`);

    // カテゴリタブに追加
    categoryContainer.insertAdjacentHTML('beforeend', content);
    console.log(`✅ Added to category ${categoryId} tab`);

    // ALLタブにも同じ内容を追加
    const allContainer = this.findTargetContainer('0');
    if (allContainer) {
      allContainer.insertAdjacentHTML('beforeend', content);
      console.log('✅ Also added to ALL tab');
    }

    // 合計を再計算（製造計画管理の場合のみ）
    const hasCalculation = document.querySelector('[data-plan-product-target]');
    if (hasCalculation) {
      setTimeout(() => {
        this.dispatch('recalculate', { prefix: 'plan-product', bubbles: true });
      }, 100);
    }

    console.log(`✅ New field added with unique ID: ${uniqueId}`);
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