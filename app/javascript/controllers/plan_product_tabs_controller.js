// 商品カテゴリのタブ切り替えと表示制御
import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = [ "tab", "category" ]

  connect() {
    this.updateTabs()
  }

  // タブのクリック時に呼ばれる
  selectTab(event) {
    // 遷移を禁止
    event.preventDefault()

    // クリックされたタブからカテゴリーIDを取得
    const selectedCategoryId = event.currentTarget.dataset.categoryId

    // データ属性を更新し、updateTabsをトリガー
    this.element.dataset.planProductTabsCategoryIdValue = selectedCategoryId

    // 画面の更新を実行
    this.updateTabs()
  }

  // タブとコンテンツの表示・非表示を切り替えるメインロジック
  updateTabs() {
    // 現在選択されているカテゴリーIDを取得 (タブクリックから取得)
    const selectedCategoryId = this.element.dataset.planProductTabsCategoryIdValue

    // 全てのタブとカテゴリーコンテンツをリセット
    this.tabTargets.forEach(tab => {
      tab.classList.remove('active')
      tab.setAttribute('aria-selected', 'false')
    })

    this.categoryTargets.forEach(category => {
      // カテゴリーコンテンツをデフォルトで全て非表示にする
      category.classList.add('d-none')
    })

    if (selectedCategoryId) {
      // 選択されたカテゴリーに対応するタブとコンテンツを見つけて表示する
      const activeTab = this.tabTargets.find(t => t.dataset.categoryId === selectedCategoryId)
      const activeContent = this.categoryTargets.find(c => c.dataset.categoryId === selectedCategoryId)

      if (activeTab) {
        activeTab.classList.add('active')
        activeTab.setAttribute('aria-selected', 'true')
      }

      if (activeContent) {
        // 選択されたカテゴリーコンテンツのみ表示
        activeContent.classList.remove('d-none')
      }
    }
  }
}