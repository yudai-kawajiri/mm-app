import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
    static targets = ["categorySelector", "showButton", "tabNav", "categoryTemplate", "categoryPaneTemplate", "contentContainer"]

    connect() {
        console.log("✅ Category Tab Manager connected");
        this.disableExistingCategoryOptions();
    }

    // セレクトボックスの変更時にボタンを有効/無効化
    toggleButton() {
        const isSelected = this.categorySelectorTarget.value && this.categorySelectorTarget.value !== '0';
        this.showButtonTarget.disabled = !isSelected;
    }

    // 既存タブのカテゴリをセレクトボックスから無効化
    disableExistingCategoryOptions() {
        const existingTabs = this.tabNavTarget.querySelectorAll('[data-category-id]');
        const existingCategoryIds = Array.from(existingTabs).map(tab => tab.dataset.categoryId);

        Array.from(this.categorySelectorTarget.options).forEach(option => {
            if (option.value && existingCategoryIds.includes(option.value)) {
                option.disabled = true;
            }
        });
    }

    // カテゴリタブの追加
    showSelectedTab() {
        const categoryId = String(this.categorySelectorTarget.value);

        if (!categoryId || categoryId === '0') return;

        // 既にタブが存在するかチェック
        let existingTab = this.tabNavTarget.querySelector(`[data-category-id="${categoryId}"]`);

        if (existingTab) {
            console.log(`⚠️ カテゴリ ID ${categoryId} のタブは既に存在します`);
            this.switchToTab(categoryId);
            this.categorySelectorTarget.value = "";
            this.toggleButton();
            return;
        }

        const categoryName = this.categorySelectorTarget.options[this.categorySelectorTarget.selectedIndex].text;

        console.log(`🔄 カテゴリ ID ${categoryId} のタブを動的に追加します`);

        // タブボタンとコンテンツを追加
        const tabButton = this.addTabButton(categoryId, categoryName);
        const tabPane = this.addTabPane(categoryId, categoryName);

        if (tabButton && tabPane) {
            this.disableExistingCategoryOptions();
            this.switchToTab(categoryId);
            this.categorySelectorTarget.value = "";
            this.toggleButton();
            console.log(`✅ カテゴリ ID ${categoryId} のタブを追加・表示しました`);
        }
    }

    // タブボタンを追加
    addTabButton(categoryId, categoryName) {
        const templateHtml = this.categoryTemplateTarget.innerHTML;
        const replacedHtml = templateHtml
            .replace(/CATEGORY_ID_PLACEHOLDER/g, categoryId)
            .replace(/CATEGORY_NAME_PLACEHOLDER/g, categoryName);

        const tempDiv = document.createElement('div');
        tempDiv.innerHTML = replacedHtml.trim();
        const tabButton = tempDiv.firstElementChild;

        if (tabButton) {
            this.tabNavTarget.appendChild(tabButton);
            return tabButton;
        }
        return null;
    }

    // タブコンテンツを追加
    addTabPane(categoryId, categoryName) {
        const templateHtml = this.categoryPaneTemplateTarget.innerHTML;
        const replacedHtml = templateHtml
            .replace(/CATEGORY_ID_PLACEHOLDER/g, categoryId)
            .replace(/CATEGORY_NAME_PLACEHOLDER/g, categoryName);

        const tempDiv = document.createElement('div');
        tempDiv.innerHTML = replacedHtml.trim();
        const tabPane = tempDiv.firstElementChild;

        if (tabPane) {
            this.contentContainerTarget.appendChild(tabPane);
            return tabPane;
        }
        return null;
    }

    // タブを切り替え
    switchToTab(categoryId) {
        // 全タブとペインを非アクティブ化
        this.tabNavTarget.querySelectorAll('[data-bs-toggle="tab"]').forEach(tab => {
            tab.classList.remove('active');
            tab.setAttribute('aria-selected', 'false');
        });

        this.contentContainerTarget.querySelectorAll('.tab-pane').forEach(pane => {
            pane.classList.remove('show', 'active');
        });

        // 選択されたタブをアクティブ化
        const selectedTab = this.tabNavTarget.querySelector(`[data-category-id="${categoryId}"]`);
        const selectedPane = this.contentContainerTarget.querySelector(`#nav-${categoryId}`);

        if (selectedTab && selectedPane) {
            selectedTab.classList.add('active');
            selectedTab.setAttribute('aria-selected', 'true');
            selectedPane.classList.add('show', 'active');
        }
    }

    // タブを削除
    removeTab(event) {
        event.preventDefault();
        event.stopPropagation(); // タブの切り替えを防ぐ

        const categoryId = event.currentTarget.dataset.categoryId;

        if (categoryId === '0') {
            alert('ALLタブは削除できません');
            return;
        }

        if (!confirm(`このカテゴリタブを削除してもよろしいですか？\n※タブ内の商品データも削除されます`)) {
            return;
        }

        console.log(`🗑️ Removing tab for category: ${categoryId}`);

        // タブボタンを削除
        const tabButton = this.tabNavTarget.querySelector(`button[data-category-id="${categoryId}"]`);
        if (tabButton) {
            tabButton.remove();
        }

        // タブコンテンツを削除
        const tabPane = this.contentContainerTarget.querySelector(`#nav-${categoryId}`);
        if (tabPane) {
            // コンテンツ内の全フィールドに_destroyフラグを設定
            const destroyInputs = tabPane.querySelectorAll('[data-nested-form-item-target="destroy"]');
            destroyInputs.forEach(input => {
                input.value = '1';
            });

            // ALLタブからも該当カテゴリの行を削除
            const allTabPane = this.contentContainerTarget.querySelector('#nav-0');
            if (allTabPane) {
                const rowsToRemove = allTabPane.querySelectorAll(`tr[data-category-id="${categoryId}"]`);
                rowsToRemove.forEach(row => {
                    const destroyInput = row.querySelector('[data-nested-form-item-target="destroy"]');
                    if (destroyInput) {
                        destroyInput.value = '1';
                    }
                    row.style.display = 'none';
                });
            }

            tabPane.remove();
        }

        // セレクトボックスのオプションを再有効化
        Array.from(this.categorySelectorTarget.options).forEach(option => {
            if (option.value === categoryId) {
                option.disabled = false;
            }
        });

        // ALLタブに切り替え
        this.switchToTab('0');

        // 合計を再計算
        setTimeout(() => {
            this.dispatch('recalculate', { prefix: 'plan-product', bubbles: true });
        }, 100);

        console.log(`✅ カテゴリ ID ${categoryId} のタブを削除しました`);
    }
}
