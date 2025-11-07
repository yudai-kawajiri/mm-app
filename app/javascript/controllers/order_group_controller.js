import { Controller } from "@hotwired/stimulus"

// 発注グループの選択方法（既存/新規）の切り替えを制御
export default class extends Controller {
  static targets = [
    "existingGroup",  // 既存グループ選択エリア
    "newGroup",       // 新規グループ名入力エリア
    "existingSelect", // 既存グループセレクトボックス
    "newInput",       // 新規グループ名入力
    "existingRadio",  // 既存選択ラジオボタン
    "newRadio",       // 新規選択ラジオボタン
    "deleteButton",   // 削除ボタン
    "clearButton"     // グループ解除ボタン
  ]

  connect() {
    // 初期表示時にボタンの表示状態を設定
    this.toggleClearButton()
  }

  // 選択方法が変更されたときに呼ばれる
  toggleGroupType(event) {
    const selectedType = event.target.value

    if (selectedType === 'existing') {
      // 既存から選択
      this.existingGroupTarget.style.display = ''
      this.newGroupTarget.style.display = 'none'

      // 新規入力フィールドのみクリア（既存選択は保持）
      if (this.hasNewInputTarget) {
        this.newInputTarget.value = ''
      }

      // セレクトボックスの値に応じてボタン表示を切り替え
      this.toggleClearButton()
    } else if (selectedType === 'new') {
      // 新規作成
      this.existingGroupTarget.style.display = 'none'
      this.newGroupTarget.style.display = ''

      // 既存セレクトボックスをクリア
      if (this.hasExistingSelectTarget) {
        this.existingSelectTarget.value = ''
      }

      // 削除ボタンと解除ボタンを非表示
      if (this.hasDeleteButtonTarget) this.deleteButtonTarget.style.display = 'none'
      if (this.hasClearButtonTarget) this.clearButtonTarget.style.display = 'none'
    }
  }

  // セレクトボックスの値が変更された時に解除・削除ボタンの表示を切り替え
  toggleClearButton() {
    if (!this.hasExistingSelectTarget) return

    const hasValue = this.existingSelectTarget.value !== ''

    if (this.hasClearButtonTarget) {
      this.clearButtonTarget.style.display = hasValue ? '' : 'none'
    }

    if (this.hasDeleteButtonTarget) {
      this.deleteButtonTarget.style.display = hasValue ? '' : 'none'
      // data-group-id属性を更新
      this.deleteButtonTarget.dataset.groupId = this.existingSelectTarget.value
    }
  }

  // グループ解除（セレクトボックスを空にする）
  clearGroup(event) {
    event.preventDefault()

    if (this.hasExistingSelectTarget) {
      this.existingSelectTarget.value = ''
      this.toggleClearButton()
    }
  }

  // グループ削除
  async deleteGroup(event) {
    event.preventDefault()

    if (!this.hasExistingSelectTarget) return

    const groupId = this.existingSelectTarget.value

    if (!groupId) {
      alert('削除するグループを選択してください')
      return
    }

    const groupName = this.existingSelectTarget.options[this.existingSelectTarget.selectedIndex].text

    if (!confirm(`「${groupName}」を削除しますか？\n\nこのグループを使用している原材料がある場合は削除できません。`)) {
      return
    }

    try {
      const response = await fetch(`/material_order_groups/${groupId}`, {
        method: 'DELETE',
        headers: {
          'Content-Type': 'application/json',
          'X-CSRF-Token': document.querySelector('[name="csrf-token"]').content
        }
      })

      const data = await response.json()

      if (response.ok) {
        // 削除成功：セレクトボックスから削除
        this.existingSelectTarget.querySelector(`option[value="${groupId}"]`).remove()
        this.existingSelectTarget.value = ''
        this.toggleClearButton()
        alert(data.message || '削除しました')
      } else {
        // 削除失敗：エラーメッセージ表示
        alert(data.error || '削除できませんでした')
      }
    } catch (error) {
      console.error('削除エラー:', error)
      alert('削除に失敗しました')
    }
  }
}
