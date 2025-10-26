// app/javascript/controllers/plan_product_tabs_controller.js
import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = [ "tab", "category" ]

  // 修正: 重複を削除
  static values = {
    categoryId: { type: Number, default: 0 }
  }

  connect() {
    console.log("[DEBUG] plan-product-tabs connected. Initial Category ID:", this.categoryIdValue)
  }

  categoryIdValueChanged() {
    this.updateTabs()
  }

  selectTab(event) {
    event.preventDefault()
    const selectedCategoryId = parseInt(event.currentTarget.dataset.categoryId, 10) || 0
    this.categoryIdValue = selectedCategoryId
    console.log(`🔄 [DEBUG] Tab selected: ${selectedCategoryId}`)
  }

  updateTabs() {
    const selectedCategoryId = this.categoryIdValue
    console.log(`🔄 [DEBUG] Updating tabs for category ID: ${selectedCategoryId}`)

    this.tabTargets.forEach(tab => {
      tab.classList.remove('active')
      tab.setAttribute('aria-selected', 'false')
    })

    this.categoryTargets.forEach(content => {
      content.classList.remove('show', 'active')
    })

    const activeTab = this.tabTargets.find(t => {
      const tabId = parseInt(t.dataset.categoryId, 10) || 0
      return tabId === selectedCategoryId
    })

    if (activeTab) {
      activeTab.classList.add('active')
      activeTab.setAttribute('aria-selected', 'true')
    }

    const activeContent = this.categoryTargets.find(c => {
      const contentId = parseInt(c.dataset.categoryId, 10) || 0
      return contentId === selectedCategoryId
    })

    if (activeContent) {
      activeContent.classList.add('show', 'active')
    } else {
      console.warn(`[WARNING] No content found for category ID: ${selectedCategoryId}`)
    }
  }
}