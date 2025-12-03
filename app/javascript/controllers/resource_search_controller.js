import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["input", "row", "clearButton"]

  connect() {
    console.log("Resource search controller connected")
    this.updateClearButton()
  }

  search(event) {
    // Enterキーでフォーム送信を防ぐ
    if (event.type === 'keydown' && event.key === 'Enter') {
      event.preventDefault()
      return
    }

    const keyword = this.inputTarget.value.toLowerCase().trim()
    console.log("Searching for:", keyword)
    this.filterRows(keyword)
    this.updateClearButton()
  }

  filterRows(keyword) {
    if (!this.hasRowTarget) {
      console.log("No row targets found")
      return
    }

    let visibleCount = 0

    this.rowTargets.forEach(row => {
      const name = row.dataset.searchName?.toLowerCase() || ""

      if (keyword === '' || name.includes(keyword)) {
        row.classList.remove('d-none')
        visibleCount++
      } else {
        row.classList.add('d-none')
      }
    })

    console.log(`Visible rows: ${visibleCount}`)
  }

  updateClearButton() {
    if (!this.hasClearButtonTarget) return

    const hasKeyword = this.inputTarget.value.trim() !== ''

    if (hasKeyword) {
      this.clearButtonTarget.classList.remove('d-none')
    } else {
      this.clearButtonTarget.classList.add('d-none')
    }
  }

  clear(event) {
    event.preventDefault()
    this.inputTarget.value = ''
    this.filterRows('')
    this.updateClearButton()
  }
}
