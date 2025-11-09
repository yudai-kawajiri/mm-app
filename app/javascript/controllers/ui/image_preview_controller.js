/**
 * @file image_preview_controller.js
 * 画像プレビューと削除UI制御
 *
 * @module Controllers
 */

import { Controller } from "@hotwired/stimulus"
import i18n from "../i18n"

/**
 * Image Preview Controller
 *
 * @description
 *   画像プレビューと削除UI制御を行うコントローラー。
 *   ファイル選択時のプレビュー表示、新規選択のキャンセル、
 *   既存画像の削除をサポートします。
 *
 * @example HTML での使用
 *   <div data-controller="image-preview">
 *     <input
 *       type="file"
 *       accept="image/*"
 *       data-image-preview-target="input"
 *       data-action="change->image-preview#handleFileSelect"
 *     />
 *     <img data-image-preview-target="preview" />
 *     <span data-image-preview-target="previewLabel">画像未選択</span>
 *     <button
 *       data-image-preview-target="deleteButton"
 *       data-action="click->image-preview#deleteExistingImage"
 *       data-url="/products/:id/delete_image"
 *     >削除</button>
 *     <button
 *       data-image-preview-target="cancelButton"
 *       data-action="click->image-preview#cancelNewImage"
 *     >キャンセル</button>
 *   </div>
 *
 * @targets
 *   input - file input 要素
 *   preview - img タグ（プレビュー表示）
 *   previewLabel - "画像未選択" のラベル
 *   deleteButton - 既存画像の削除ボタン（サーバー削除）
 *   cancelButton - 新規選択画像のキャンセルボタン
 *   currentImageContainer - 削除ボタンのコンテナ
 *
 * @features
 *   - ファイル選択時の即時プレビュー
 *   - 新規選択のキャンセル機能
 *   - 既存画像のサーバー削除
 *   - Base64 プレビュー表示
 *   - i18n対応のメッセージ表示
 *
 * @requires i18n.js - 翻訳機能
 */
export default class extends Controller {
  static targets = [
    "input",                    // file input
    "preview",                  // img tag
    "previewLabel",             // "画像未選択"のラベル
    "deleteButton",             // 既存画像の削除ボタン（サーバー削除）
    "cancelButton",             // 新規選択画像のキャンセルボタン
    "currentImageContainer"     // 削除ボタンのコンテナ
  ]

  /**
   * コントローラー接続時の処理
   *
   * @description
   *   初期状態では新規選択されていないため、キャンセルボタンを非表示
   */
  connect() {
    console.log('Image preview controller connected')
    // 初期状態: 新規選択されていないのでキャンセルボタンは非表示
    if (this.hasCancelButtonTarget) {
      this.cancelButtonTarget.style.display = 'none'
    }
  }

  /**
   * ファイル選択時の処理
   *
   * @param {Event} event - change イベント
   *
   * @description
   *   選択されたファイルを読み込み、Base64 形式でプレビュー表示。
   *   新規画像選択時は既存画像の削除ボタンを非表示にし、
   *   キャンセルボタンを表示します。
   */
  handleFileSelect(event) {
    const file = event.target.files[0]

    if (file) {
      console.log('File selected:', file.name)

      // 画像プレビュー表示
      const reader = new FileReader()
      reader.onload = (e) => {
        this.previewTarget.src = e.target.result
        this.previewTarget.style.display = 'block'

        // "画像未選択"ラベルを確実に非表示
        if (this.hasPreviewLabelTarget) {
          this.previewLabelTarget.style.display = 'none'
          console.log('Preview label hidden')
        }

        // 新規画像選択したので：
        // - 既存画像の削除ボタンを非表示（削除は新規画像で上書きされるため不要）
        // - キャンセルボタンを表示
        if (this.hasCurrentImageContainerTarget) {
          this.currentImageContainerTarget.style.display = 'none'
        }
        if (this.hasCancelButtonTarget) {
          this.cancelButtonTarget.style.display = 'inline-block'
        }
      }
      reader.readAsDataURL(file)
    }
  }

  /**
   * 新規選択のキャンセル処理
   *
   * @param {Event} event - click イベント
   *
   * @description
   *   ファイル選択をクリアし、既存画像の有無に応じて表示を切り替えます。
   *   - 既存画像がある場合: 既存画像を再表示
   *   - 既存画像がない場合: "画像未選択"表示
   */
  cancelNewImage(event) {
    event.preventDefault()

    console.log('Cancel new image clicked')

    // ファイル選択をクリア
    this.inputTarget.value = ''

    // 既存画像の有無で表示を切り替え
    const hasExistingImage = this.previewTarget.src &&
                             !this.previewTarget.src.startsWith('data:') &&
                             this.previewTarget.src !== ''

    console.log('Has existing image:', hasExistingImage)

    if (hasExistingImage) {
      // 既存画像がある場合: 既存画像を再表示
      this.previewTarget.style.display = 'block'
      if (this.hasPreviewLabelTarget) {
        this.previewLabelTarget.style.display = 'none'
      }

      // 削除ボタンを再表示、キャンセルボタンは非表示
      if (this.hasCurrentImageContainerTarget) {
        this.currentImageContainerTarget.style.display = 'block'
      }
      if (this.hasCancelButtonTarget) {
        this.cancelButtonTarget.style.display = 'none'
      }
    } else {
      // 既存画像がない場合: "画像未選択"表示
      this.previewTarget.style.display = 'none'
      this.previewTarget.src = ''

      if (this.hasPreviewLabelTarget) {
        this.previewLabelTarget.style.display = 'block'
      }

      // 両方のボタンを非表示
      if (this.hasCurrentImageContainerTarget) {
        this.currentImageContainerTarget.style.display = 'none'
      }
      if (this.hasCancelButtonTarget) {
        this.cancelButtonTarget.style.display = 'none'
      }
    }
  }

  /**
   * 既存画像のサーバー削除処理
   *
   * @param {Event} event - click イベント
   * @async
   *
   * @description
   *   確認ダイアログを表示後、サーバーにDELETEリクエストを送信して画像を削除。
   *   削除成功時はプレビューをクリアし、"画像未選択"表示に切り替えます。
   *
   * @i18n
   *   - products.confirm_delete_image: 削除確認メッセージ
   *   - products.image_deleted: 削除成功メッセージ
   *   - products.image_delete_failed: 削除失敗メッセージ
   */
  async deleteExistingImage(event) {
    event.preventDefault()

    const button = event.currentTarget
    const url = button.dataset.url
    const productId = button.dataset.productId

    // i18n対応の確認ダイアログ
    if (!confirm(i18n.t('products.confirm_delete_image'))) {
      return
    }

    console.log('Deleting image from server:', url)

    try {
      const response = await fetch(url, {
        method: 'DELETE',
        headers: {
          'X-CSRF-Token': document.querySelector('[name="csrf-token"]').content,
          'Accept': 'application/json'
        }
      })

      if (response.ok) {
        console.log('Image deleted successfully')

        // 削除成功: プレビューをクリア
        this.previewTarget.style.display = 'none'
        this.previewTarget.src = ''

        if (this.hasPreviewLabelTarget) {
          this.previewLabelTarget.style.display = 'block'
        }

        // 削除ボタンを非表示
        if (this.hasCurrentImageContainerTarget) {
          this.currentImageContainerTarget.style.display = 'none'
        }

        // i18n対応の成功メッセージ
        alert(i18n.t('products.image_deleted'))
      } else {
        console.error('Failed to delete image:', response.status)
        // i18n対応のエラーメッセージ
        alert(i18n.t('products.image_delete_failed'))
      }
    } catch (error) {
      console.error('削除エラー:', error)
      // i18n対応のエラーメッセージ
      alert(i18n.t('products.image_delete_failed'))
    }
  }
}
