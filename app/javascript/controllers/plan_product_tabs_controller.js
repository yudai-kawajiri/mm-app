// 商品カテゴリのタブ切り替えと表示制御
import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = [ "tab", "category" ]
  static values = { categoryId: Number }

  // 値の変更を監視し、変更されたら updateTabs を自動で実行する
  static values = { categoryId: { type: Number, default: 0 } }

  // 接続時の初期化
  connect() {
    console.log("[DEBUG] plan-product-tabs connected. Initial Category ID:", this.categoryIdValue)
  }

  // categoryIdValue が変更されたときに自動で実行されるメソッド
  categoryIdValueChanged() {
    this.updateTabs()
  }

  // タブのクリック時に呼ばれる
  selectTab(event) {
    event.preventDefault()

    // クリックされたタブからカテゴリーIDを取得（ALLタブはID=0）
    const selectedCategoryId = parseInt(event.currentTarget.dataset.categoryId, 10) || 0

    // categoryIdValue を直接更新することで、categoryIdValueChanged() と updateTabs() が実行される
    this.categoryIdValue = selectedCategoryId

    console.log(`🔄 [DEBUG] Tab selected: ${selectedCategoryId}`)
  }

  // タブとコンテンツの表示・非表示を切り替えるメインロジック
  updateTabs() {
    const selectedCategoryId = this.categoryIdValue
    console.log(`🔄 [DEBUG] Updating tabs for category ID: ${selectedCategoryId}`)

    // 全てのタブとカテゴリーコンテンツをリセット
    this.tabTargets.forEach(tab => {
      tab.classList.remove('active')
      tab.setAttribute('aria-selected', 'false')
    })

    this.categoryTargets.forEach(content => {
      // Bootstrapのタブコンテンツクラス fade と show active を操作
      content.classList.remove('show', 'active')
    })

    // 1. タブの状態更新
    const activeTab = this.tabTargets.find(t => {
      const tabId = parseInt(t.dataset.categoryId, 10) || 0
      return tabId === selectedCategoryId
    })

    if (activeTab) {
      activeTab.classList.add('active')
      activeTab.setAttribute('aria-selected', 'true')
    }

    // 2. コンテンツの状態更新
    const activeContent = this.categoryTargets.find(c => {
      const contentId = parseInt(c.dataset.categoryId, 10) || 0
      return contentId === selectedCategoryId
    })

    if (activeContent) {
      activeContent.classList.add('show', 'active')
    } else {
        console.warn(` [WARNING] No content found for category ID: ${selectedCategoryId}`)
    }
  }
}