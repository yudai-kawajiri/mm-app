import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["input"]
  static values = { errorMessage: String }
  
  redirect(event) {
    const path = event.currentTarget.dataset.path
    const slug = this.inputTarget.value.trim()
    
    if (!slug) {
      alert(this.errorMessageValue)
      return
    }
    
    window.location.href = `/c/${slug}${path}`
  }
}
