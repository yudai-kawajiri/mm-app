import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["day", "dropZone"]

  connect() {
    console.log("Calendar controller connected")
    this.draggedPlanId = null
  }

  // 計画のドラッグ開始
  handleDragStart(event) {
    this.draggedPlanId = event.currentTarget.dataset.planId
    event.currentTarget.style.opacity = '0.5'
    event.dataTransfer.effectAllowed = 'move'
    event.dataTransfer.setData('text/html', event.currentTarget.innerHTML)
  }

  // ドラッグ終了
  handleDragEnd(event) {
    event.currentTarget.style.opacity = '1'
  }

  // ドロップエリアに入った時
  allowDrop(event) {
    event.preventDefault()
    event.currentTarget.classList.add('drag-over')
  }

  // ドロップ処理
  async handleDrop(event) {
    event.preventDefault()
    event.currentTarget.classList.remove('drag-over')

    if (!this.draggedPlanId) return

    const date = event.currentTarget.dataset.date

    try {
      const response = await fetch('/numerical_managements/assign_plan_to_date', {
        method: 'POST',
        headers: {
          'Content-Type': 'application/json',
          'X-CSRF-Token': document.querySelector('[name="csrf-token"]').content
        },
        body: JSON.stringify({
          plan_id: this.draggedPlanId,
          scheduled_date: date
        })
      })

      if (response.ok) {
        // ページをリロード（Turbo Streamsで部分更新することも可能）
        window.location.reload()
      } else {
        const data = await response.json()
        alert(data.error || '配置に失敗しました')
      }
    } catch (error) {
      console.error('Error:', error)
      alert('エラーが発生しました')
    }

    this.draggedPlanId = null
  }

  // 日付クリック（詳細表示など）
  selectDay(event) {
    const date = event.currentTarget.dataset.date
    console.log('Selected date:', date)
    // ここにモーダル表示などの処理を追加可能
  }
}