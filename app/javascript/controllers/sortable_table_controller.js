// app/javascript/controllers/sortable_table_controller.js

import { Controller } from "@hotwired/stimulus"
import Sortable from "sortablejs"

export default class extends Controller {
  static targets = ["toggleBtn", "saveBtn", "cancelBtn"]
  static values = {
    reorderPath: String,
    paramName: String
  }

  connect() {
    this.sortable = null
  }

  // tbodyを自動検索
  get tbodyTarget() {
    return this.element.querySelector('tbody')
  }

  toggleReorderMode() {
    this.toggleBtnTarget.classList.add('d-none')
    this.saveBtnTarget.classList.remove('d-none')
    this.cancelBtnTarget.classList.remove('d-none')

    // ドラッグハンドルを表示
    document.querySelectorAll('.drag-handle').forEach(el => {
      el.classList.remove('d-none')
    })

    // アクションボタンを非表示
    document.querySelectorAll('td:last-child').forEach(el => {
      el.style.display = 'none'
    })

    // Sortable.js を有効化
    this.sortable = new Sortable(this.tbodyTarget, {
      handle: '.drag-handle',
      animation: 150,
      ghostClass: 'sortable-ghost'
    })
  }

  cancel() {
    location.reload()
  }

  save() {
    const rows = this.tbodyTarget.querySelectorAll('tr')
    const ids = Array.from(rows).map(row => row.dataset.id)

    console.log('保存する順序:', ids)  // デバッグ用
    console.log('パラメータ名:', this.paramNameValue)
    console.log('送信先URL:', this.reorderPathValue)

    // CSRF トークンを取得
    const csrfToken = document.querySelector('meta[name="csrf-token"]')?.content

    if (!csrfToken) {
      console.error('CSRF token not found!')
      alert('CSRF トークンが見つかりません')
      return
    }

    console.log('CSRF Token:', csrfToken)

    const payload = {}
    payload[this.paramNameValue] = ids

    console.log('送信するペイロード:', JSON.stringify(payload))

    // サーバーに送信
    fetch(this.reorderPathValue, {
      method: 'POST',
      headers: {
        'Content-Type': 'application/json',
        'X-CSRF-Token': csrfToken
      },
      body: JSON.stringify(payload)
    })
    .then(response => {
      console.log('Response status:', response.status)
      console.log('Response OK:', response.ok)

      if (response.ok) {
        alert('並び順を保存しました！')
        location.reload()
      } else {
        return response.text().then(text => {
          console.error('Error response:', text)
          alert('保存に失敗しました: ' + response.status)
        })
      }
    })
    .catch(error => {
      console.error('Fetch error:', error)
      alert('エラーが発生しました: ' + error.message)
    })
  }
}
