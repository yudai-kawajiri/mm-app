/**
 * @file order_group_controller.js
 * 発注グループの選択・削除・解除制御
 *
 * @module Controllers
 */

import { Controller } from "@hotwired/stimulus"
import i18n from "../i18n"

/**
 * Order Group Controller
 *
 * @description
 *   発注グループの選択方法（既存/新規）の切り替えを制御するコントローラー。
 *   グループの削除・解除機能も提供します。
 *
 * @example HTML での使用
 *   <div data-controller="order-group">
 *     <!-- ラジオボタン -->
 *     <input
 *       type="radio"
 *       value="existing"
 *       data-order-group-target="existingRadio"
 *       data-action="change->order-group#toggleGroupType"
 *     /> 既存から選択
 *     <input
 *       type="radio"
 *       value="new"
 *       data-order-group-target="newRadio"
 *       data-action="change->order-group#toggleGroupType"
 *     /> 新規作成
 *
 *     <!-- 既存グループ選択 -->
 *     <div data-order-group-target="existingGroup">
 *       <select
 *         data-order-group-target="existingSelect"
 *         data-action="change->order-group#toggleClearButton"
 *       >
 *         <option value="">選択してください</option>
 *       </select>
 *       <button data-order-group-target="clearButton" data-action="click->order-group#clearGroup">解除</button>
 *       <button data-order-group-target="deleteButton" data-action="click->order-group#deleteGroup">削除</button>
 *     </div>
 *
 *     <!-- 新規グループ作成 -->
 *     <div data-order-group-target="newGroup">
 *       <input type="text" data-order-group-target="newInput" />
 *     </div>
 *   </div>
 *
 * @targets
 *   existingGroup - 既存グループ選択エリア
 *   newGroup - 新規グループ名入力エリア
 *   existingSelect - 既存グループセレクトボックス
 *   newInput - 新規グループ名入力
 *   existingRadio - 既存選択ラジオボタン
 *   newRadio - 新規選択ラジオボタン
 *   deleteButton - 削除ボタン
 *   clearButton - グループ解除ボタン
 *
 * @features
 *   - 既存/新規の切り替え表示
 *   - グループ選択時の削除・解除ボタン表示制御
 *   - グループ削除（Ajax）
 *   - グループ解除（セレクトボックスクリア）
 *
 * @requires i18n.js - 翻訳機能
 */
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

  /**
   * コントローラー接続時の処理
   *
   * @description
   *   初期表示時にボタンの表示状態を設定
   */
  connect() {
    // 初期表示時にボタンの表示状態を設定
    this.toggleClearButton()
  }

  /**
   * 選択方法が変更されたときの処理
   *
   * @param {Event} event - change イベント
   *
   * @description
   *   選択された方法（existing/new）に応じて：
   *   - 対応するエリアを表示
   *   - 非対応のエリアを非表示
   *   - 非対応のフィールドをクリア
   */
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

  /**
   * セレクトボックスの値変更時の処理
   *
   * @description
   *   セレクトボックスに値が選択されているかに応じて、
   *   削除・解除ボタンの表示を切り替えます。
   */
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

  /**
   * グループ解除処理
   *
   * @param {Event} event - click イベント
   *
   * @description
   *   セレクトボックスを空にしてグループ選択を解除
   */
  clearGroup(event) {
    event.preventDefault()

    if (this.hasExistingSelectTarget) {
      this.existingSelectTarget.value = ''
      this.toggleClearButton()
    }
  }

  /**
   * グループ削除処理
   *
   * @param {Event} event - click イベント
   * @async
   *
   * @description
   *   選択されたグループをサーバーから削除します。
   *   削除確認後、Ajaxでサーバーにリクエストを送信。
   *   成功時はセレクトボックスから削除します。
   *
   * @i18n
   *   - material_order_groups.select_group_to_delete: グループ選択促進メッセージ
   *   - material_order_groups.confirm_delete: 削除確認メッセージ
   *   - material_order_groups.deleted: 削除成功メッセージ
   *   - material_order_groups.delete_failed: 削除失敗メッセージ
   */
  async deleteGroup(event) {
    event.preventDefault()

    if (!this.hasExistingSelectTarget) return

    const groupId = this.existingSelectTarget.value

    if (!groupId) {
      alert(i18n.t('material_order_groups.select_group_to_delete'))
      return
    }

    const groupName = this.existingSelectTarget.options[this.existingSelectTarget.selectedIndex].text

    // i18n対応の確認ダイアログ
    const confirmMessage = i18n.t('material_order_groups.confirm_delete', { name: groupName })
    if (!confirm(confirmMessage)) {
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

        // i18n対応の成功メッセージ
        alert(data.message || i18n.t('material_order_groups.deleted'))
      } else {
        // 削除失敗：エラーメッセージ表示
        alert(data.error || i18n.t('material_order_groups.delete_failed'))
      }
    } catch (error) {
      console.error('削除エラー:', error)
      // i18n対応のエラーメッセージ
      alert(i18n.t('material_order_groups.delete_failed'))
    }
  }
}
