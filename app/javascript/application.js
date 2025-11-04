import "@hotwired/turbo-rails"
import "controllers/index"

document.addEventListener('turbo:load', () => {
  const imageInput = document.getElementById('product-image-input');
  const imagePreview = document.getElementById('image-preview');
  const previewLabel = document.getElementById('preview-label');
  const cancelButton = document.getElementById('cancel-new-image-button');
  const deleteButton = document.getElementById('delete-button');

  // 必須要素がない場合は早期リターン（previewLabelはオプショナル）
  if (!imageInput || !imagePreview || !cancelButton) return;

  // ページロード時の初期化：既に画像が表示されている場合の処理
  if (imagePreview.src && imagePreview.src !== window.location.href && imagePreview.style.display !== 'none') {
    if (previewLabel) previewLabel.style.display = 'none';
    cancelButton.style.display = 'inline-block';
  }

  // ファイル選択時の処理
  imageInput.addEventListener('change', function(e) {
    const file = e.target.files[0];
    if (file) {
      const reader = new FileReader();
      reader.onload = function(e) {
        imagePreview.src = e.target.result;
        imagePreview.style.display = 'block';
        if (previewLabel) previewLabel.style.display = 'none';
        cancelButton.style.display = 'inline-block';
      }
      reader.readAsDataURL(file);
    }
  });

  // キャンセルボタンの処理
  cancelButton.addEventListener('click', function(e) {
    e.preventDefault();
    imageInput.value = '';
    imagePreview.src = '';
    imagePreview.style.display = 'none';
    if (previewLabel) previewLabel.style.display = 'block';
    cancelButton.style.display = 'none';
  });

  // 画像削除ボタンの処理（既存の商品画像を削除）
  if (deleteButton) {
    deleteButton.addEventListener('click', function(e) {
      e.preventDefault();
      if (!confirm('本当に画像を削除しますか？')) return;

      const url = this.dataset.url;
      fetch(url, {
        method: 'DELETE',
        headers: {
          'X-CSRF-Token': document.querySelector('[name="csrf-token"]').content,
          'Accept': 'application/json'
        }
      })
      .then(response => {
        if (response.ok) {
          location.reload();
        } else {
          alert('画像の削除に失敗しました');
        }
      })
      .catch(error => {
        console.error('Error:', error);
        alert('画像の削除に失敗しました');
      });
    });
  }
});