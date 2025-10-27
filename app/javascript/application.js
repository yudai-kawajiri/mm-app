import "@hotwired/turbo-rails"

import "controllers/index"

document.addEventListener('turbo:load', () => {
  // プレビュー/キャンセルに必要な要素をすべて取得
  const imageInput = document.getElementById('product-image-input');
  const imagePreview = document.getElementById('image-preview');
  const previewLabel = document.getElementById('preview-label');
  const cancelButton = document.getElementById('cancel-new-image-button');

  // 要素が存在しない場合は何もしない（重要！）

  // 画像選択時のプレビュー表示
  imageInput.addEventListener('change', function(e) {
    const file = e.target.files[0];
    if (file) {
      const reader = new FileReader();
      reader.onload = function(e) {
        imagePreview.src = e.target.result;
        imagePreview.style.display = 'block';
        previewLabel.style.display = 'none';
        cancelButton.style.display = 'inline-block';
      }
      reader.readAsDataURL(file);
    }
  });

  // キャンセルボタンのクリック処理
  cancelButton.addEventListener('click', function(e) {
    e.preventDefault();
    imageInput.value = '';
    imagePreview.src = '';
    imagePreview.style.display = 'none';
    previewLabel.style.display = 'block';
    cancelButton.style.display = 'none';
  });
});
