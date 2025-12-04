import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["input", "row", "clearButton"]

  connect() {
    console.log("Resource search controller connected")
    this.updateClearButton()

    // セレクトボックスの変更も監視
    this.setupSelectListeners()
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

    const form = this.element.querySelector('form')
    if (!form) {
      // フォームが見つからない場合は元のロジックを使用
      const hasKeyword = this.hasInputTarget && this.inputTarget.value.trim() !== ''

      if (hasKeyword) {
        this.clearButtonTarget.classList.remove('d-none')
      } else {
        this.clearButtonTarget.classList.add('d-none')
      }
      return
    }

    // テキスト入力とセレクトボックスの値をチェック
    const textInputs = form.querySelectorAll('input[type="text"]')
    const selects = form.querySelectorAll('select')

    let hasValue = false

    // テキスト入力をチェック
    textInputs.forEach(input => {
      if (input.value && input.value.trim() !== '') {
        hasValue = true
      }
    })

    // セレクトボックスをチェック
    selects.forEach(select => {
      if (select.value && select.value !== '') {
        hasValue = true
      }
    })

    if (hasValue) {
      this.clearButtonTarget.classList.remove('d-none')
      console.log('Clear button shown')
    } else {
      this.clearButtonTarget.classList.add('d-none')
      console.log('Clear button hidden')
    }
  }

  setupSelectListeners() {
    const form = this.element.querySelector('form')
    if (!form) return

    const selects = form.querySelectorAll('select')
    selects.forEach(select => {
      select.addEventListener('change', () => {
        // フォーム送信前にクリアボタンを更新
        setTimeout(() => this.updateClearButton(), 50)
      })
    })
  }

  clear(event) {
    event.preventDefault()

    // テキスト入力をクリア
    if (this.hasInputTarget) {
      this.inputTarget.value = ''
    }

    // セレクトボックスをクリア
    const form = this.element.querySelector('form')
    if (form) {
      const selects = form.querySelectorAll('select')
      selects.forEach(select => {
        select.value = ''
      })
    }

    this.filterRows('')
    this.updateClearButton()
  }
}
