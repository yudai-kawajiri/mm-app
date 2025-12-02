import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["modal", "iframe", "title"]

  connect() {
    console.log("Video modal controller connected")
  }

  // 動画カードがクリックされたときに呼ばれる
  open(event) {
    event.preventDefault()

    const youtubeId = event.currentTarget.dataset.youtubeId
    const title = event.currentTarget.dataset.videoTitle

    // YouTube IDが空の場合は準備中メッセージを表示
    if (!youtubeId || youtubeId === "") {
      alert(`${title} の動画を準備中です`)
      return
    }

    // モーダルのタイトルを設定
    this.titleTarget.textContent = title

    // YouTube埋め込みURLを生成
    const embedUrl = `https://www.youtube.com/embed/${youtubeId}?autoplay=1&rel=0`
    this.iframeTarget.src = embedUrl

    // Bootstrap Modalを表示
    const modal = new bootstrap.Modal(this.modalTarget)
    modal.show()
  }

  // モーダルが閉じられたときに動画を停止
  close() {
    this.iframeTarget.src = ""
  }
}
