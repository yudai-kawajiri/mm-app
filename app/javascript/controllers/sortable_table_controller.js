/**
 * @file sortable_table_controller.js
 * テーブル行のドラッグ&ドロップ並び替え制御
 *
 * @module Controllers
 */

import { Controller } from "@hotwired/stimulus"
import Sortable from "sortablejs"
import i18n from "../i18n"

/**
 * Sortable Table Controller
 *
 * @description
 *   テーブル行のドラッグ&ドロップ並び替えを制御するコントローラー。
 *   Sortable.js を使用して並び替え機能を提供し、
 *   変更をサーバーに保存します。
 *
 * @example HTML での使用
 *   <div
 *     data-controller="sortable-table"
 *     data-sortable-table-reorder-path-value="/materials/reorder"
 *     data-sortable-table-param-name-value="material_ids"
 *   >
 *     <!-- 並び替えモード切り替えボタン -->
 *     <button data-sortable-table-target="toggleBtn" data-action="click->sortable-table#toggleReorderMode">
 *       並び替えモード
 *     </button>
 *     <button data-sortable-table-target="saveBtn" data-action="click->sortable-table#save" class="d-none">
 *       保存
 *     </button>
 *     <button data-sortable-table-target="cancelBtn" data-action="click->sortable-table#cancel" class="d-none">
 *       キャンセル
 *     </button>
 *
 *     <!-- テーブル -->
 *     <table>
 *       <tbody>
 *         <tr data-id="1">
 *           <td><span class="drag-handle d-none">☰</span></td>
 *           <td>アイテム1</td>
 *         </tr>
 *       </tbody>
 *     </table>
 *   </div>
 *
 * @targets
 *   toggleBtn - 並び替えモード切り替えボタン
 *   saveBtn - 保存ボタン
 *   cancelBtn - キャンセルボタン
 *
 * @values
 *   reorderPath {String} - 並び替え保存用のAPI URL
 *   paramName {String} - サーバーに送信するパラメータ名
 *
 * @features
 *   - Sortable.js によるドラッグ&ドロップ
 *   - 並び替えモード切り替え
 *   - サーバーへの並び替え保存（Ajax）
 *   - キャンセル機能（ページリロード）
 *
 * @requires sortablejs - ドラッグ&ドロップライブラリ
 * @requires i18n.js - 翻訳機能
 */
export default class extends Controller {
  static targets = ["toggleBtn", "saveBtn", "cancelBtn"]
  static values = {
    reorderPath: String,
    paramName: String
  }

  /**
   * コントローラー接続時の処理
   */
  connect() {
    this.sortable = null
  }

  /**
   * tbody 要素を自動検索
   *
   * @return {HTMLElement} tbody 要素
   */
  get tbodyTarget() {
    return this.element.querySelector('tbody')
  }

  /**
   * 並び替えモードの切り替え
   *
   * @description
   *   以下の処理を実行：
   *   - 通常ボタンを非表示、保存・キャンセルボタンを表示
   *   - ドラッグハンドルを表示
   *   - アクションボタンを非表示
   *   - Sortable.js を有効化
   */
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

  /**
   * キャンセル処理
   *
   * @description
   *   ページをリロードして並び替えをキャンセル
   */
  cancel() {
    location.reload()
  }

  /**
   * 並び替えの保存処理
   *
   * @async
   *
   * @description
   *   現在の行の順序をサーバーに送信して保存します。
   *   成功時はページをリロード。
   *
   * @i18n
   *   - sortable_table.csrf_token_not_found: CSRFトークンエラー
   *   - sortable_table.saved: 保存成功メッセージ
   *   - sortable_table.save_failed: 保存失敗メッセージ
   *   - sortable_table.error: エラーメッセージ
   */
  save() {
    const rows = this.tbodyTarget.querySelectorAll('tr')
    const ids = Array.from(rows).map(row => row.dataset.id)

    console.log('保存する順序:', ids)
    console.log('パラメータ名:', this.paramNameValue)
    console.log('送信先URL:', this.reorderPathValue)

    // CSRF トークンを取得
    const csrfToken = document.querySelector('meta[name="csrf-token"]')?.content

    if (!csrfToken) {
      console.error('CSRF token not found')
      alert(i18n.t('sortable_table.csrf_token_not_found'))
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
        alert(i18n.t('sortable_table.saved'))
        location.reload()
      } else {
        return response.text().then(text => {
          console.error('Error response:', text)
          alert(i18n.t('sortable_table.save_failed', { status: response.status }))
        })
      }
    })
    .catch(error => {
      console.error('Fetch error:', error)
      alert(i18n.t('sortable_table.error', { message: error.message }))
    })
  }
}
