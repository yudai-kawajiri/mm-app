import { Controller } from "@hotwired/stimulus"

// 画像プレビューと削除UI制御
export default class extends Controller {
  static targets = [
    "input",           // file input
    "preview",         // img tag
    "previewLabel",    // "画像未選択"のラベル
    "deleteButton",    // 既存画像の削除ボタン（サーバー削除）
    "cancelButton",    // 新規選択画像のキャンセルボタン
    "currentImageContainer" // 削除ボタンのコンテナ
  ]

  connect() {
    console.log('Image preview controller connected')
    // 初期状態: 新規選択されていないのでキャンセルボタンは非表示
    if (this.hasCancelButtonTarget) {
      this.cancelButtonTarget.style.display = 'none'
    }
  }

  // ファイル選択時の処理
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

  // キャンセルボタン: 新規選択をキャンセル
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

  // 削除ボタン: 既存画像をサーバーから削除
  async deleteExistingImage(event) {
    event.preventDefault()

    const button = event.currentTarget
    const url = button.dataset.url
    const productId = button.dataset.productId

    if (!confirm('画像を削除してもよろしいですか？')) {
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

        // 成功メッセージ（オプション）
        alert('画像を削除しました')
      } else {
        console.error('Failed to delete image:', response.status)
        alert('画像の削除に失敗しました')
      }
    } catch (error) {
      console.error('削除エラー:', error)
      alert('画像の削除に失敗しました')
    }
  }
}