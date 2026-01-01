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
    const embedUrl = `https://www.youtube.com/embed/${youtubeId}?autoplay=1&rel=0&enablejsapi=1`
    this.iframeTarget.src = embedUrl

    // Bootstrap Modalを表示
    const modal = new bootstrap.Modal(this.modalTarget)
    modal.show()
  }

  close() {
    this.iframeTarget.src = ""
  }

  enablePip(event) {
    event.preventDefault()

    const youtubeId = this.iframeTarget.src.match(/embed\/([^?]+)/)?.[1]
    if (!youtubeId) {
      alert(i18n.t('help.video_modal.pip_not_supported'))
      return
    }

    // 小さいウィンドウで開く
    const width = 480
    const height = 270
    const left = window.screen.width - width - 20
    const top = window.screen.height - height - 100

    window.open(
      `https://www.youtube.com/embed/${youtubeId}?autoplay=1&rel=0`,
      'PiP',
      `width=${width},height=${height},left=${left},top=${top},resizable=yes,scrollbars=no`
    )

    // モーダルを閉じる
    const modal = bootstrap.Modal.getInstance(this.modalTarget)
    if (modal) {
      modal.hide()
    }
  }

  openInYouTube(event) {
    event.preventDefault()

    const youtubeId = this.iframeTarget.src.match(/embed\/([^?]+)/)?.[1]
    if (youtubeId) {
      window.open(`https://www.youtube.com/watch?v=${youtubeId}`, '_blank')
    }
  }
}
