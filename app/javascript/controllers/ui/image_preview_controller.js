// Image Preview Controller
//
// 画像プレビューと削除UI制御を行うコントローラー
// ファイル選択時のプレビュー表示、新規選択のキャンセル、既存画像の削除をサポート
//
// 使用例:
//   <div data-controller="image-preview">
//     <input
//       type="file"
//       accept="image/*"
//       data-image-preview-target="input"
//       data-action="change->image-preview#handleFileSelect"
//     />
//     <img data-image-preview-target="preview" />
//     <span data-image-preview-target="previewLabel">画像未選択</span>
//     <button
//       data-image-preview-target="deleteButton"
//       data-action="click->image-preview#deleteExistingImage"
//       data-url="/products/:id/delete_image"
//     >削除</button>
//     <button
//       data-image-preview-target="cancelButton"
//       data-action="click->image-preview#cancelNewImage"
//     >キャンセル</button>
//   </div>
//
// Targets:
// - input: file input 要素
// - preview: img タグ（プレビュー表示）
// - previewLabel: "画像未選択" のラベル
// - deleteButton: 既存画像の削除ボタン（サーバー削除）
// - cancelButton: 新規選択画像のキャンセルボタン
// - currentImageContainer: 削除ボタンのコンテナ
//
// 機能:
// - ファイル選択時の即時プレビュー
// - 新規選択のキャンセル機能
// - 既存画像のサーバー削除
// - Base64 プレビュー表示
// - i18n対応のメッセージ表示

import { Controller } from "@hotwired/stimulus"
import i18n from "controllers/i18n"
import Logger from "utils/logger"

// Stimulusターゲット名
const TARGETS = {
  INPUT: 'input',
  PREVIEW: 'preview',
  PREVIEW_LABEL: 'previewLabel',
  DELETE_BUTTON: 'deleteButton',
  CANCEL_BUTTON: 'cancelButton',
  CURRENT_IMAGE_CONTAINER: 'currentImageContainer'
}

// データ属性
const DATA_ATTRIBUTES = {
  URL: 'url',
  PRODUCT_ID: 'productId'
}

// CSSスタイル値
const DISPLAY_STYLE = {
  NONE: 'none',
  BLOCK: 'block',
  INLINE_BLOCK: 'inline-block'
}

// URL関連
const URL_PREFIX = {
  DATA_URL: 'data:'
}

// HTTP関連
const HTTP_METHOD = {
  DELETE: 'DELETE'
}

const HTTP_HEADERS = {
  CSRF_TOKEN: 'X-CSRF-Token',
  ACCEPT: 'Accept',
  APPLICATION_JSON: 'application/json'
}

// HTMLセレクタ
const SELECTOR = {
  CSRF_TOKEN: '[name="csrf-token"]'
}

// 翻訳キー
const I18N_KEYS = {
  CONFIRM_DELETE_IMAGE: 'products.confirm_delete_image',
  IMAGE_DELETED: 'products.image_deleted',
  IMAGE_DELETE_FAILED: 'products.image_delete_failed'
}

// ログメッセージ
const LOG_MESSAGES = {
  CONNECTED: 'Image preview controller connected',
  fileSelected: (fileName) => `File selected: ${fileName}`,
  PREVIEW_LABEL_HIDDEN: 'Preview label hidden',
  CANCEL_CLICKED: 'Cancel new image clicked',
  hasExistingImage: (hasImage) => `Has existing image: ${hasImage}`,
  deletingImage: (url) => `Deleting image from server: ${url}`,
  DELETE_SUCCESS: 'Image deleted successfully',
  deleteFailed: (status) => `Failed to delete image: ${status}`,
  deleteError: (error) => `削除エラー: ${error}`
}

// Image Preview Controller
export default class extends Controller {
  static targets = [
    TARGETS.INPUT,
    TARGETS.PREVIEW,
    TARGETS.PREVIEW_LABEL,
    TARGETS.DELETE_BUTTON,
    TARGETS.CANCEL_BUTTON,
    TARGETS.CURRENT_IMAGE_CONTAINER
  ]

  // コントローラー接続時の処理
  // 初期状態では新規選択されていないため、キャンセルボタンを非表示
  connect() {
    Logger.log(LOG_MESSAGES.CONNECTED)

    // 初期状態: 新規選択されていないのでキャンセルボタンは非表示
    if (this.hasCancelButtonTarget) {
      this.cancelButtonTarget.style.display = DISPLAY_STYLE.NONE
    }
  }

  // ファイル選択時の処理
  // 選択されたファイルを読み込み、Base64 形式でプレビュー表示
  // 新規画像選択時は既存画像の削除ボタンを非表示にし、キャンセルボタンを表示
  handleFileSelect(event) {
    const file = event.target.files[0]

    if (file) {
      Logger.log(LOG_MESSAGES.fileSelected(file.name))

      // 画像プレビュー表示
      const reader = new FileReader()
      reader.onload = (e) => {
        this.previewTarget.src = e.target.result
        this.previewTarget.style.display = DISPLAY_STYLE.BLOCK

        // "画像未選択"ラベルを確実に非表示
        if (this.hasPreviewLabelTarget) {
          this.previewLabelTarget.style.display = DISPLAY_STYLE.NONE
          Logger.log(LOG_MESSAGES.PREVIEW_LABEL_HIDDEN)
        }

        // 新規画像選択したので：
        // - 既存画像の削除ボタンを非表示（削除は新規画像で上書きされるため不要）
        // - キャンセルボタンを表示
        if (this.hasCurrentImageContainerTarget) {
          this.currentImageContainerTarget.style.display = DISPLAY_STYLE.NONE
        }
        if (this.hasCancelButtonTarget) {
          this.cancelButtonTarget.style.display = DISPLAY_STYLE.BLOCK
        }
      }
      reader.readAsDataURL(file)
    }
  }

  // 新規選択のキャンセル処理
  // ファイル選択をクリアし、既存画像の有無に応じて表示を切り替え
  // - 既存画像がある場合: 既存画像を再表示
  // - 既存画像がない場合: "画像未選択"表示
  cancelNewImage(event) {
    event.preventDefault()

    Logger.log(LOG_MESSAGES.CANCEL_CLICKED)

    // ファイル選択をクリア
    this.inputTarget.value = ''

    // 既存画像の有無で表示を切り替え
    const hasExistingImage = this.previewTarget.src &&
                             !this.previewTarget.src.startsWith(URL_PREFIX.DATA_URL) &&
                             this.previewTarget.src !== ''

    Logger.log(LOG_MESSAGES.hasExistingImage(hasExistingImage))

    if (hasExistingImage) {
      // 既存画像がある場合: 既存画像を再表示
      this.previewTarget.style.display = DISPLAY_STYLE.BLOCK
      if (this.hasPreviewLabelTarget) {
        this.previewLabelTarget.style.display = DISPLAY_STYLE.NONE
      }

      // 削除ボタンを再表示、キャンセルボタンは非表示
      if (this.hasCurrentImageContainerTarget) {
        this.currentImageContainerTarget.style.display = DISPLAY_STYLE.BLOCK
      }
      if (this.hasCancelButtonTarget) {
        this.cancelButtonTarget.style.display = DISPLAY_STYLE.NONE
      }
    } else {
      // 既存画像がない場合: "画像未選択"表示
      this.previewTarget.style.display = DISPLAY_STYLE.NONE
      this.previewTarget.src = ''

      if (this.hasPreviewLabelTarget) {
        this.previewLabelTarget.style.display = DISPLAY_STYLE.BLOCK
      }

      // 両方のボタンを非表示
      if (this.hasCurrentImageContainerTarget) {
        this.currentImageContainerTarget.style.display = DISPLAY_STYLE.NONE
      }
      if (this.hasCancelButtonTarget) {
        this.cancelButtonTarget.style.display = DISPLAY_STYLE.NONE
      }
    }
  }

  // 既存画像のサーバー削除処理
  // 確認ダイアログを表示後、サーバーにDELETEリクエストを送信して画像を削除
  // 削除成功時はプレビューをクリアし、"画像未選択"表示に切り替え
  //
  // 翻訳キー:
  // - products.confirm_delete_image: 削除確認メッセージ
  // - products.image_deleted: 削除成功メッセージ
  // - products.image_delete_failed: 削除失敗メッセージ
  async deleteExistingImage(event) {
    event.preventDefault()

    const button = event.currentTarget
    const url = button.dataset[DATA_ATTRIBUTES.URL]
    const productId = button.dataset[DATA_ATTRIBUTES.PRODUCT_ID]

    // i18n対応の確認ダイアログ
    if (!confirm(i18n.t(I18N_KEYS.CONFIRM_DELETE_IMAGE))) {
      return
    }

    Logger.log(LOG_MESSAGES.deletingImage(url))

    try {
      const response = await fetch(url, {
        method: HTTP_METHOD.DELETE,
        headers: {
          [HTTP_HEADERS.CSRF_TOKEN]: document.querySelector(SELECTOR.CSRF_TOKEN).content,
          [HTTP_HEADERS.ACCEPT]: HTTP_HEADERS.APPLICATION_JSON
        }
      })

      if (response.ok) {
        Logger.log(LOG_MESSAGES.DELETE_SUCCESS)

        // 削除成功: プレビューをクリア
        this.previewTarget.style.display = DISPLAY_STYLE.NONE
        this.previewTarget.src = ''

        if (this.hasPreviewLabelTarget) {
          this.previewLabelTarget.style.display = DISPLAY_STYLE.BLOCK
        }

        // 削除ボタンを非表示
        if (this.hasCurrentImageContainerTarget) {
          this.currentImageContainerTarget.style.display = DISPLAY_STYLE.NONE
        }

        // i18n対応の成功メッセージ
        alert(i18n.t(I18N_KEYS.IMAGE_DELETED))
      } else {
        Logger.error(LOG_MESSAGES.deleteFailed(response.status))
        // i18n対応のエラーメッセージ
        alert(i18n.t(I18N_KEYS.IMAGE_DELETE_FAILED))
      }
    } catch (error) {
      Logger.error(LOG_MESSAGES.deleteError(error))
      // i18n対応のエラーメッセージ
      alert(i18n.t(I18N_KEYS.IMAGE_DELETE_FAILED))
    }
  }
}
