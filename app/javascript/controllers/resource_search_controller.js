import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["input", "row"]

  connect() {
    console.log("Resource search controller connected")
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
}
