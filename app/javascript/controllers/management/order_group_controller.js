// Order Group Controller
//
// 発注グループの選択方法（既存/新規）の切り替えを制御するStimulusコントローラー
//
// 使用例:
//   <div data-controller="order-group">
//     <!-- ラジオボタン -->
//     <input
//       type="radio"
//       value="existing"
//       data-order-group-target="existingRadio"
//       data-action="change->order-group#toggleGroupType"
//     /> 既存から選択
//     <input
//       type="radio"
//       value="new"
//       data-order-group-target="newRadio"
//       data-action="change->order-group#toggleGroupType"
//     /> 新規作成
//
//     <!-- 既存グループ選択 -->
//     <div data-order-group-target="existingGroup">
//       <select
//         data-order-group-target="existingSelect"
//         data-action="change->order-group#toggleClearButton"
//       >
//         <option value="">選択してください</option>
//       </select>
//       <button data-order-group-target="clearButton" data-action="click->order-group#clearGroup">解除</button>
//       <button data-order-group-target="deleteButton" data-action="click->order-group#deleteGroup">削除</button>
//     </div>
//
//     <!-- 新規グループ作成 -->
//     <div data-order-group-target="newGroup">
//       <input type="text" data-order-group-target="newInput" />
//     </div>
//   </div>
//
// 機能:
// - 既存/新規の切り替え表示
// - グループ選択時の削除・解除ボタン表示制御
// - グループ削除（Ajax）
// - グループ解除（セレクトボックスクリア）
//
// Targets:
// - existingGroup: 既存グループ選択エリア
// - newGroup: 新規グループ名入力エリア
// - existingSelect: 既存グループセレクトボックス
// - newInput: 新規グループ名入力
// - existingRadio: 既存選択ラジオボタン
// - newRadio: 新規選択ラジオボタン
// - deleteButton: 削除ボタン
// - clearButton: グループ解除ボタン
//
// 翻訳キー:
// - material_order_groups.select_group_to_delete: グループ選択促進メッセージ
// - material_order_groups.confirm_delete: 削除確認メッセージ
// - material_order_groups.deleted: 削除成功メッセージ
// - material_order_groups.delete_failed: 削除失敗メッセージ

import { Controller } from "@hotwired/stimulus"
import i18n from "controllers/i18n"
import Logger from "utils/logger"

// 定数定義
const GROUP_TYPE = {
  EXISTING: 'existing',
  NEW: 'new'
}

const DISPLAY_STYLE = {
  SHOW: '',
  HIDE: 'none'
}

const HTTP_METHOD = {
  DELETE: 'DELETE'
}

const CONTENT_TYPE = {
  JSON: 'application/json'
}

const HTTP_STATUS = {
  OK: 200
}

const SELECTOR = {
  CSRF_TOKEN: '[name="csrf-token"]',
  OPTION_BY_VALUE: (value) => `option[value="${value}"]`
}

const DATA_ATTRIBUTE = {
  GROUP_ID: 'groupId'
}

const I18N_KEYS = {
  SELECT_GROUP_TO_DELETE: 'material_order_groups.select_group_to_delete',
  CONFIRM_DELETE: 'material_order_groups.confirm_delete',
  DELETED: 'material_order_groups.deleted',
  DELETE_FAILED: 'material_order_groups.delete_failed'
}

const API_ENDPOINT = {
  MATERIAL_ORDER_GROUPS: '/material_order_groups'
}

const LOG_MESSAGES = {
  DELETE_ERROR: '削除エラー:'
}

const EMPTY_VALUE = ''

export default class extends Controller {
  static targets = [
    "existingGroup",
    "newGroup",
    "existingSelect",
    "newInput",
    "existingRadio",
    "newRadio",
    "deleteButton",
    "clearButton"
  ]

  // コントローラー接続時の処理
  // 初期表示時にボタンの表示状態を設定
  connect() {
    this.toggleClearButton()
  }

  // 選択方法が変更されたときの処理
  // 選択された方法（existing/new）に応じて：
  // - 対応するエリアを表示
  // - 非対応のエリアを非表示
  // - 非対応のフィールドをクリア
  toggleGroupType(event) {
    const selectedType = event.target.value

    if (selectedType === GROUP_TYPE.EXISTING) {
      // 既存から選択
      this.existingGroupTarget.style.display = DISPLAY_STYLE.SHOW
      this.newGroupTarget.style.display = DISPLAY_STYLE.HIDE

      // 新規入力フィールドのみクリア（既存選択は保持）
      if (this.hasNewInputTarget) {
        this.newInputTarget.value = EMPTY_VALUE
      }

      // セレクトボックスの値に応じてボタン表示を切り替え
      this.toggleClearButton()
    } else if (selectedType === GROUP_TYPE.NEW) {
      // 新規作成
      this.existingGroupTarget.style.display = DISPLAY_STYLE.HIDE
      this.newGroupTarget.style.display = DISPLAY_STYLE.SHOW

      // 既存セレクトボックスをクリア
      if (this.hasExistingSelectTarget) {
        this.existingSelectTarget.value = EMPTY_VALUE
      }

      // 削除ボタンと解除ボタンを非表示
      if (this.hasDeleteButtonTarget) {
        this.deleteButtonTarget.style.display = DISPLAY_STYLE.HIDE
      }
      if (this.hasClearButtonTarget) {
        this.clearButtonTarget.style.display = DISPLAY_STYLE.HIDE
      }
    }
  }

  // セレクトボックスの値変更時の処理
  // セレクトボックスに値が選択されているかに応じて、
  // 削除・解除ボタンの表示を切り替える
  toggleClearButton() {
    if (!this.hasExistingSelectTarget) return

    const hasValue = this.existingSelectTarget.value !== EMPTY_VALUE

    if (this.hasClearButtonTarget) {
      this.clearButtonTarget.style.display = hasValue ? DISPLAY_STYLE.SHOW : DISPLAY_STYLE.HIDE
    }

    if (this.hasDeleteButtonTarget) {
      this.deleteButtonTarget.style.display = hasValue ? DISPLAY_STYLE.SHOW : DISPLAY_STYLE.HIDE
      // data-group-id属性を更新
      this.deleteButtonTarget.dataset[DATA_ATTRIBUTE.GROUP_ID] = this.existingSelectTarget.value
    }
  }

  // グループ解除処理
  // セレクトボックスを空にしてグループ選択を解除
  clearGroup(event) {
    event.preventDefault()

    if (this.hasExistingSelectTarget) {
      this.existingSelectTarget.value = EMPTY_VALUE
      this.toggleClearButton()
    }
  }

  // グループ削除処理
  // 選択されたグループをサーバーから削除する
  // 削除確認後、Ajaxでサーバーにリクエストを送信
  // 成功時はセレクトボックスから削除する
  async deleteGroup(event) {
    event.preventDefault()

    if (!this.hasExistingSelectTarget) return

    const groupId = this.existingSelectTarget.value

    if (!groupId) {
      alert(i18n.t(I18N_KEYS.SELECT_GROUP_TO_DELETE))
      return
    }

    const groupName = this.existingSelectTarget.options[this.existingSelectTarget.selectedIndex].text

    // i18n対応の確認ダイアログ
    const confirmMessage = i18n.t(I18N_KEYS.CONFIRM_DELETE, { name: groupName })
    if (!confirm(confirmMessage)) {
      return
    }

    try {
      const response = await fetch(`${API_ENDPOINT.MATERIAL_ORDER_GROUPS}/${groupId}`, {
        method: HTTP_METHOD.DELETE,
        headers: {
          'Content-Type': CONTENT_TYPE.JSON,
          'X-CSRF-Token': document.querySelector(SELECTOR.CSRF_TOKEN).content
        }
      })

      const data = await response.json()

      if (response.ok) {
        // 削除成功：セレクトボックスから削除
        this.existingSelectTarget.querySelector(SELECTOR.OPTION_BY_VALUE(groupId)).remove()
        this.existingSelectTarget.value = EMPTY_VALUE
        this.toggleClearButton()

        // i18n対応の成功メッセージ
        alert(data.message || i18n.t(I18N_KEYS.DELETED))
      } else {
        // 削除失敗：エラーメッセージ表示
        alert(data.error || i18n.t(I18N_KEYS.DELETE_FAILED))
      }
    } catch (error) {
      Logger.error(LOG_MESSAGES.DELETE_ERROR, error)
      // i18n対応のエラーメッセージ
      alert(i18n.t(I18N_KEYS.DELETE_FAILED))
    }
  }
}
