import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["roleSelect", "storeField", "storeSelect"]

  connect() {
    this.toggleStoreField()
  }

  toggleStoreField() {
    const role = this.roleSelectTarget.value

    if (role === 'company_admin' || role === 'super_admin') {
      // 会社管理者・システム管理者: 店舗不要
      this.storeFieldTarget.style.display = 'none'
      this.storeSelectTarget.required = false
      this.storeSelectTarget.value = ''
    } else if (role === 'store_admin') {
      // 店舗管理者: 店舗必須
      this.storeFieldTarget.style.display = 'block'
      this.storeSelectTarget.required = true
    } else {
      // 一般: 店舗任意
      this.storeFieldTarget.style.display = 'block'
      this.storeSelectTarget.required = false
    }
  }
}
