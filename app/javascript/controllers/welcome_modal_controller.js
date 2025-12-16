import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["urlInput"]

  copy(event) {
    const input = this.urlInputTarget
    input.select()
    document.execCommand('copy')

    const btn = event.currentTarget
    const originalHtml = btn.innerHTML
    const copiedText = btn.dataset.copiedText || 'コピーしました'

    btn.innerHTML = `<i class="bi bi-check"></i> ${copiedText}`

    setTimeout(() => {
      btn.innerHTML = originalHtml
    }, 2000)
  }

  close() {
    this.element.remove()
  }
}
