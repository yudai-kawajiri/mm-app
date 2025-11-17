// Sortable Table Controller
//
// テーブル行のドラッグ&ドロップ並び替えを制御するコントローラー
// Sortable.js を使用して並び替え機能を提供し、変更をサーバーに保存
//
// 使用例:
//   <div
//     data-controller="sortable-table"
//     data-sortable-table-reorder-path-value="/materials/reorder"
//     data-sortable-table-param-name-value="material_ids"
//   >
//     <!-- 並び替えモード切り替えボタン -->
//     <button data-sortable-table-target="toggleBtn" data-action="click->sortable-table#toggleReorderMode">
//       並び替えモード
//     </button>
//     <button data-sortable-table-target="saveBtn" data-action="click->sortable-table#save" class="d-none">
//       保存
//     </button>
//     <button data-sortable-table-target="cancelBtn" data-action="click->sortable-table#cancel" class="d-none">
//       キャンセル
//     </button>
//
//     <!-- ソート選択フォーム -->
//     <div data-sortable-table-target="sortForm">...</div>
//
//     <!-- テーブル -->
//     <table>
//       <tbody>
//         <tr data-id="1" data-display-order="1">
//           <td><span class="drag-handle d-none">☰</span></td>
//           <td>アイテム1</td>
//         </tr>
//       </tbody>
//     </table>
//   </div>
//
// Targets:
// - toggleBtn: 並び替えモード切り替えボタン
// - saveBtn: 保存ボタン
// - cancelBtn: キャンセルボタン
// - sortForm: ソート選択フォーム（並び替えモード中は無効化）
//
// Values:
// - reorderPath: 並び替え保存用のAPI URL
// - paramName: サーバーに送信するパラメータ名
//
// 機能:
// - Sortable.js によるドラッグ&ドロップ
// - 並び替えモード切り替え
// - サーバーへの並び替え保存（Ajax）
// - キャンセル機能（ページリロード）
// - 並び替えモード中はソートプルダウンを無効化

import { Controller } from "@hotwired/stimulus"
import Sortable from "sortablejs"
import i18n from "controllers/i18n"
import Logger from "utils/logger"

// Stimulusターゲット名
const TARGETS = {
  TOGGLE_BTN: 'toggleBtn',
  SAVE_BTN: 'saveBtn',
  CANCEL_BTN: 'cancelBtn',
  SORT_FORM: 'sortForm'
}

// Stimulus値名
const VALUES = {
  REORDER_PATH: 'reorderPath',
  PARAM_NAME: 'paramName'
}

// CSSクラス名
const CSS_CLASSES = {
  D_NONE: 'd-none',
  DRAG_HANDLE: 'drag-handle',
  SORTABLE_GHOST: 'sortable-ghost'
}

// CSSスタイルプロパティ
const STYLE_PROPERTY = {
  OPACITY: 'opacity',
  POINTER_EVENTS: 'pointerEvents',
  DISPLAY: 'display'
}

// CSSスタイル値
const STYLE_VALUE = {
  OPACITY_HALF: '0.5',
  POINTER_EVENTS_NONE: 'none',
  DISPLAY_NONE: 'none'
}

// データ属性名
const DATA_ATTRIBUTES = {
  ID: 'id',
  DISPLAY_ORDER: 'displayOrder'
}

// HTMLセレクタ
const SELECTOR = {
  TBODY: 'tbody',
  DRAG_HANDLE: '.drag-handle',
  TD_LAST_CHILD: 'td:last-child',
  SELECT: 'select',
  TR: 'tr',
  CSRF_TOKEN: 'meta[name="csrf-token"]'
}

// HTTP関連
const HTTP_METHOD = {
  POST: 'POST'
}

const HTTP_HEADERS = {
  CONTENT_TYPE: 'Content-Type',
  CSRF_TOKEN: 'X-CSRF-Token',
  APPLICATION_JSON: 'application/json'
}

// Sortable.js設定
const SORTABLE_CONFIG = {
  ANIMATION_DURATION: 150
}

// デフォルト値
const DEFAULT_VALUE = {
  DISPLAY_ORDER: 999999  // display_orderが未設定の場合のデフォルト値（最後尾に配置）
}

// 翻訳キー
const I18N_KEYS = {
  CSRF_TOKEN_NOT_FOUND: 'sortable_table.csrf_token_not_found',
  SAVED: 'sortable_table.saved',
  SAVE_FAILED: 'sortable_table.save_failed',
  ERROR: 'sortable_table.error'
}

// ログメッセージ
const LOG_MESSAGES = {
  saveOrder: (ids) => `保存する順序: ${ids}`,
  paramName: (name) => `パラメータ名: ${name}`,
  url: (url) => `送信先URL: ${url}`,
  CSRF_TOKEN_NOT_FOUND: 'CSRF token not found',
  csrfToken: (token) => `CSRF Token: ${token}`,
  payload: (payload) => `送信するペイロード: ${JSON.stringify(payload)}`,
  responseStatus: (status) => `Response status: ${status}`,
  responseOk: (ok) => `Response OK: ${ok}`,
  errorResponse: (text) => `Error response: ${text}`,
  fetchError: (error) => `Fetch error: ${error}`
}

// Sortable Table Controller
export default class extends Controller {
  static targets = [
    TARGETS.TOGGLE_BTN,
    TARGETS.SAVE_BTN,
    TARGETS.CANCEL_BTN,
    TARGETS.SORT_FORM
  ]

  static values = {
    [VALUES.REORDER_PATH]: String,
    [VALUES.PARAM_NAME]: String
  }

  // コントローラー接続時の処理
  connect() {
    this.sortable = null
  }

  // tbody 要素を自動検索
  get tbodyTarget() {
    return this.element.querySelector(SELECTOR.TBODY)
  }

  // 並び替えモードの切り替え
  // 以下の処理を実行:
  // - 通常ボタンを非表示、保存・キャンセルボタンを表示
  // - ドラッグハンドルを表示
  // - アクションボタンを非表示
  // - ソートプルダウンを無効化
  // - Sortable.js を有効化
  toggleReorderMode() {
    this.sortTableByDisplayOrder()
    this.toggleBtnTarget.classList.add(CSS_CLASSES.D_NONE)
    this.saveBtnTarget.classList.remove(CSS_CLASSES.D_NONE)
    this.cancelBtnTarget.classList.remove(CSS_CLASSES.D_NONE)

    // ソートフォームを無効化（存在する場合のみ）
    if (this.hasSortFormTarget) {
      this.sortFormTarget.style[STYLE_PROPERTY.OPACITY] = STYLE_VALUE.OPACITY_HALF
      this.sortFormTarget.style[STYLE_PROPERTY.POINTER_EVENTS] = STYLE_VALUE.POINTER_EVENTS_NONE
      const select = this.sortFormTarget.querySelector(SELECTOR.SELECT)
      if (select) {
        select.disabled = true
      }
    }

    // ドラッグハンドルを表示
    this.element.querySelectorAll(SELECTOR.DRAG_HANDLE).forEach(el => {
      el.classList.remove(CSS_CLASSES.D_NONE)
    })

    // アクションボタンを非表示
    this.tbodyTarget.querySelectorAll(SELECTOR.TD_LAST_CHILD).forEach(el => {
      el.style[STYLE_PROPERTY.DISPLAY] = STYLE_VALUE.DISPLAY_NONE
    })

    // Sortable.js を有効化
    this.sortable = new Sortable(this.tbodyTarget, {
      handle: SELECTOR.DRAG_HANDLE,
      animation: SORTABLE_CONFIG.ANIMATION_DURATION,
      ghostClass: CSS_CLASSES.SORTABLE_GHOST
    })
  }

  // キャンセル処理
  // ページをリロードして並び替えをキャンセル
  cancel() {
    location.reload()
  }

  // 並び替えの保存処理
  // 現在の行の順序をサーバーに送信して保存
  // 成功時はページをリロード
  //
  // 翻訳キー:
  // - sortable_table.csrf_token_not_found: CSRFトークンエラー
  // - sortable_table.saved: 保存成功メッセージ
  // - sortable_table.save_failed: 保存失敗メッセージ
  // - sortable_table.error: エラーメッセージ
  save() {
    const rows = this.tbodyTarget.querySelectorAll(SELECTOR.TR)
    const ids = Array.from(rows).map(row => row.dataset[DATA_ATTRIBUTES.ID])

    Logger.log(LOG_MESSAGES.saveOrder(ids))
    Logger.log(LOG_MESSAGES.paramName(this.paramNameValue))
    Logger.log(LOG_MESSAGES.url(this.reorderPathValue))

    // CSRF トークンを取得
    const csrfToken = document.querySelector(SELECTOR.CSRF_TOKEN)?.content

    if (!csrfToken) {
      Logger.error(LOG_MESSAGES.CSRF_TOKEN_NOT_FOUND)
      alert(i18n.t(I18N_KEYS.CSRF_TOKEN_NOT_FOUND))
      return
    }

    Logger.log(LOG_MESSAGES.csrfToken(csrfToken))

    const payload = {}
    payload[this.paramNameValue] = ids

    Logger.log(LOG_MESSAGES.payload(payload))

    // サーバーに送信
    fetch(this.reorderPathValue, {
      method: HTTP_METHOD.POST,
      headers: {
        [HTTP_HEADERS.CONTENT_TYPE]: HTTP_HEADERS.APPLICATION_JSON,
        [HTTP_HEADERS.CSRF_TOKEN]: csrfToken
      },
      body: JSON.stringify(payload)
    })
    .then(response => {
      Logger.log(LOG_MESSAGES.responseStatus(response.status))
      Logger.log(LOG_MESSAGES.responseOk(response.ok))

      if (response.ok) {
        alert(i18n.t(I18N_KEYS.SAVED))
        location.reload()
      } else {
        return response.text().then(text => {
          Logger.error(LOG_MESSAGES.errorResponse(text))
          alert(i18n.t(I18N_KEYS.SAVE_FAILED, { status: response.status }))
        })
      }
    })
    .catch(error => {
      Logger.error(LOG_MESSAGES.fetchError(error))
      alert(i18n.t(I18N_KEYS.ERROR, { message: error.message }))
    })
  }

  // display_order順にテーブルを並び替え
  // display_orderが未設定の行は最後尾に配置される
  sortTableByDisplayOrder() {
    const rows = Array.from(this.tbodyTarget.querySelectorAll(SELECTOR.TR))

    rows.sort((a, b) => {
      const orderA = parseInt(a.dataset[DATA_ATTRIBUTES.DISPLAY_ORDER]) || DEFAULT_VALUE.DISPLAY_ORDER
      const orderB = parseInt(b.dataset[DATA_ATTRIBUTES.DISPLAY_ORDER]) || DEFAULT_VALUE.DISPLAY_ORDER
      return orderA - orderB
    })

    rows.forEach(row => this.tbodyTarget.appendChild(row))
  }
}
