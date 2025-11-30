import { Controller } from "@hotwired/stimulus"

// Connects to data-controller="help-search"
export default class extends Controller {
  static targets = [
    "input",
    "videoItem",
    "videoCategory",
    "faqItem",
    "noVideosFound",
    "noFaqFound",
    "noResultsFound",
    "searchKeyword"
  ]

  connect() {
    console.log("Help search controller connected")
  }

  search() {
    const keyword = this.inputTarget.value.toLowerCase().trim()

    if (keyword === '') {
      // 検索キーワードが空の場合、全て表示
      this.showAll()
      return
    }

    let videoCount = 0
    let faqCount = 0

    // 動画の検索
    this.videoItemTargets.forEach(item => {
      const keywords = item.dataset.keywords.toLowerCase()
      const title = item.textContent.toLowerCase()

      if (keywords.includes(keyword) || title.includes(keyword)) {
        item.classList.remove('d-none')
        videoCount++
      } else {
        item.classList.add('d-none')
      }
    })

    // カテゴリーの表示制御(該当動画があるカテゴリーのみ表示)
    this.videoCategoryTargets.forEach(category => {
      const visibleVideos = category.querySelectorAll('[data-video-item]:not(.d-none)')
      if (visibleVideos.length > 0) {
        category.classList.remove('d-none')
        // 該当するカテゴリーを自動展開
        const collapseElement = category.querySelector('.collapse')
        if (collapseElement && !collapseElement.classList.contains('show')) {
          collapseElement.classList.add('show')
        }
      } else {
        category.classList.add('d-none')
      }
    })

    // FAQの検索
    this.faqItemTargets.forEach(item => {
      const keywords = item.dataset.keywords.toLowerCase()
      const title = item.querySelector('.accordion-button').textContent.toLowerCase()
      const content = item.textContent.toLowerCase()

      if (keywords.includes(keyword) || title.includes(keyword) || content.includes(keyword)) {
        item.classList.remove('d-none')
        faqCount++
      } else {
        item.classList.add('d-none')
      }
    })

    // 結果表示の制御
    this.toggleVisibility(this.noVideosFoundTarget, videoCount === 0)
    this.toggleVisibility(this.noFaqFoundTarget, faqCount === 0)

    if (videoCount === 0 && faqCount === 0) {
      this.searchKeywordTarget.textContent = keyword
      this.noResultsFoundTarget.classList.remove('d-none')
    } else {
      this.noResultsFoundTarget.classList.add('d-none')
    }
  }

  showAll() {
    this.videoItemTargets.forEach(item => item.classList.remove('d-none'))
    this.videoCategoryTargets.forEach(category => category.classList.remove('d-none'))
    this.faqItemTargets.forEach(item => item.classList.remove('d-none'))
    this.noVideosFoundTarget.classList.add('d-none')
    this.noFaqFoundTarget.classList.add('d-none')
    this.noResultsFoundTarget.classList.add('d-none')
  }

  toggleVisibility(element, shouldHide) {
    if (shouldHide) {
      element.classList.remove('d-none')
    } else {
      element.classList.add('d-none')
    }
  }
}
