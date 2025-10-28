import "@hotwired/turbo-rails"
import "controllers/index"

document.addEventListener('turbo:load', () => {
  const imageInput = document.getElementById('product-image-input');
  const imagePreview = document.getElementById('image-preview');
  const previewLabel = document.getElementById('preview-label');
  const cancelButton = document.getElementById('cancel-new-image-button');
  const deleteButton = document.getElementById('delete-button');

  if (!imageInput || !imagePreview || !previewLabel || !cancelButton) return;

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

  cancelButton.addEventListener('click', function(e) {
    e.preventDefault();
    imageInput.value = '';
    imagePreview.src = '';
    imagePreview.style.display = 'none';
    previewLabel.style.display = 'block';
    cancelButton.style.display = 'none';
  });

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