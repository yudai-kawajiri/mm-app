import "@hotwired/turbo-rails"
import "./controllers"
// import "./controllers/index"

document.addEventListener('turbo:load', () => {
 // プレビュー/キャンセルに必要な要素をすべて取得
  const imageInput = document.getElementById('product-image-input');
  const imagePreview = document.getElementById('image-preview');
  const previewLabel = document.getElementById('preview-label'); // プレビューラベル (HTMLにこのIDが存在しない場合は undefined)
  const cancelButton = document.getElementById('cancel-new-image-button'); // キャンセルボタン
  // 既存の削除ボタンコンテナを取得
  const currentDeleteButtonContainer = document.querySelector('[id^="current-image-container-"]');

  if (imageInput && imagePreview) {

    // [機能1] ファイルが選択されたときのプレビュー表示イベント
    imageInput.addEventListener('change', (event) => {
      const file = event.target.files[0];

      if (file) {
        const reader = new FileReader();

        reader.onload = (e) => {
          // プレビューの更新
          imagePreview.src = e.target.result;
          imagePreview.style.display = 'block';

          // 既存削除ボタンコンテナを非表示
          if (currentDeleteButtonContainer) {
            currentDeleteButtonContainer.style.display = 'none';
          }

          // 新規画像のプレビューラベルとキャンセルボタンを表示 (キャンセルボタンはHTMLで #new-image-action に囲まれている前提)
          if (cancelButton) cancelButton.closest('#new-image-action').style.display = 'block'; // 親コンテナを操作
          if (previewLabel) previewLabel.style.display = 'block';
        };

        reader.readAsDataURL(file);
      } else {
        // ファイル選択がキャンセルされた場合
        // 既存画像がない場合のみプレビューを非表示
        if (imagePreview.dataset.existingImage !== 'true') {
          imagePreview.style.display = 'none';
        }

          // 既存削除ボタンコンテナを再表示
          if (currentDeleteButtonContainer && imagePreview.dataset.existingImage === 'true') {
            currentDeleteButtonContainer.style.display = 'block';
          }

        // キャンセルボタンとラベルも非表示
        if (cancelButton) cancelButton.closest('#new-image-action').style.display = 'none'; // 親コンテナを操作
        if (previewLabel) previewLabel.style.display = 'none';
      }
    });

    // [機能2] 新規選択のキャンセルボタンのクリックイベント
    if (cancelButton) {
      cancelButton.addEventListener('click', () => {
        // 1. ファイルフィールドの値をリセット
        imageInput.value = '';

        // 2. プレビューとボタン、ラベルを非表示
        // 既存画像がある場合、プレビューは非表示にしない
        if (imagePreview.dataset.existingImage !== 'true') {
          imagePreview.src = '';
          imagePreview.style.display = 'none';
        }

          // 既存画像があれば、削除ボタンを再表示
          if (currentDeleteButtonContainer && imagePreview.dataset.existingImage === 'true') {
            currentDeleteButtonContainer.style.display = 'block';
          }

        // キャンセルボタンを非表示
        cancelButton.closest('#new-image-action').style.display = 'none'; // 親コンテナを操作
        if (previewLabel) previewLabel.style.display = 'none';
      });
    }
  }


  // [機能3] 既存画像即時削除（Ajax）イベント
  document.querySelectorAll('[id^="delete-button-"]').forEach(button => {
  button.addEventListener('click', (event) => {
      // link_toによるページ遷移を止めて削除する
      event.preventDefault();
      // data-urlのURLを取得して、リクエスト先を特定
      const url = event.currentTarget.dataset.url;
      // 削除後のDOM操作のために要素の識別をする
      const productId = event.currentTarget.dataset.productId;

      // 先ほどのURLに送るリクエスト
      fetch(url, {
        method: 'DELETE',
        headers: {
          'X-CSRF-Token': document.querySelector('meta[name="csrf-token"]').content,
          'Accept': 'application/json'
        }
      })
      .then(response => {
        // 成功時 (ステータス 200番台) のみ処理を実行
        if (response.ok) {
          // 既存画像と削除ボタンの全体コンテナを削除
          const currentImageContainer = document.getElementById(`current-image-container-${productId}`);
          if (currentImageContainer) {
            currentImageContainer.remove();
          }

          // プレビューエリアを初期化/非表示
          const imagePreviewElement = document.getElementById('image-preview');
          if (imagePreviewElement) {
            imagePreviewElement.src = '';
            imagePreviewElement.style.display = 'none';
            imagePreviewElement.dataset.existingImage = 'false'; // 既存画像フラグをリセット
          }

          // 新規選択フィールドのヒントメッセージを「画像を選択してください」に戻す処理
          const smallElement = imageInput ? imageInput.closest('.mb-3').querySelector('small.text-muted') : null;
          if (smallElement) {
            smallElement.textContent = '画像を選択してください';
          }

          // 新規画像のプレビュー/ボタンも非表示にする (エラー回避）
          if (previewLabel) previewLabel.style.display = 'none';
          if (cancelButton) cancelButton.closest('#new-image-action').style.display = 'none'; //  親コンテナを操作

        } else {
          // 失敗ステータスの場合は、エラーを投げて次の .catch に処理を渡す
          throw new Error(`HTTP Error! Status: ${response.status}`);
        }
      })
      .catch(error => {
        console.error('Error deleting image:', error);
          alert('画像の削除中にエラーが発生しました。');
      });
    });
  });
});