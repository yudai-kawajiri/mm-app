import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["input"]
  static values = { errorMessage: String }
  
  redirect(event) {
    const path = event.currentTarget.dataset.path
    const subdomain = this.inputTarget.value.trim()
    
    if (!subdomain) {
      alert(this.errorMessageValue)
      return
    }
    
    window.location.href = `http://${subdomain}.localhost:3000${path}`
  }
}
