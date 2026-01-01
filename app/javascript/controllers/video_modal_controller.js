import { Controller } from "@hotwired/stimulus"
import i18n from "controllers/i18n"

export default class extends Controller {
  static targets = ["modal", "iframe", "title"]

  connect() {
  }

  open(event) {
    event.preventDefault()

    const youtubeId = event.currentTarget.dataset.youtubeId
    const title = event.currentTarget.dataset.videoTitle

    // YouTube IDが空の場合は準備中メッセージを表示
    if (!youtubeId || youtubeId === "") {
      alert(i18n.t('help.video_modal.preparing', { title: title }))
      return
    }

    // モーダルのタイトルを設定
    this.titleTarget.textContent = title

    // YouTube埋め込みURLを生成（enablejsapi=1 を追加）
    const embedUrl = `https://www.youtube-nocookie.com/embed/${youtubeId}?autoplay=1&rel=0&enablejsapi=1`
    this.iframeTarget.src = embedUrl

    // Bootstrap Modalを表示
    const modal = new bootstrap.Modal(this.modalTarget)
    modal.show()
  }

  close() {
    this.iframeTarget.src = ""
  }

  // ピクチャーインピクチャー機能を有効化
  enablePip() {
    const iframe = this.iframeTarget

    // iframeの動画要素を取得してPiPを要求
    try {
      // YouTube iframe APIにPiPリクエストを送信
      iframe.contentWindow.postMessage(
        '{"event":"command","func":"requestPictureInPicture","args":""}',
        '*'
      )

      // モーダルを閉じる
      const modal = bootstrap.Modal.getInstance(this.modalTarget)
      if (modal) {
        modal.hide()
      }
    } catch (error) {
      console.error('Picture-in-Picture failed:', error)
      alert(i18n.t('help.video_modal.pip_not_supported'))
    }
  }

  // 新しいタブでYouTubeを開く
  openInYouTube() {
    const iframe = this.iframeTarget
    const src = iframe.src

    // YouTube IDを抽出
    const match = src.match(/embed\/([^?]+)/)
    if (match && match[1]) {
      const youtubeId = match[1]
      const youtubeUrl = `https://www.youtube.com/watch?v=${youtubeId}`
      window.open(youtubeUrl, '_blank')
    }
  }
}
