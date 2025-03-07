import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["imageContainer", "fileInput"]
  static values = {
    travelId: String
  }

  connect() {
    console.log('Travel image controller connected');
    
    // コントローラーが接続されたらファイル選択フィールドを初期化
    if (!this.hasFileInputTarget) {
      const fileInput = document.createElement('input');
      fileInput.type = 'file';
      fileInput.accept = 'image/*';
      fileInput.style.display = 'none';
      fileInput.dataset.travelImageTarget = 'fileInput';
      fileInput.addEventListener('change', this.uploadImage.bind(this));
      this.element.appendChild(fileInput);
    }
    
    // 既存の画像があれば、サイズを調整
    this.adjustExistingImage();
  }
  
  // 既存の画像サイズを調整するメソッド
  adjustExistingImage() {
    const existingImage = this.imageContainerTarget.querySelector('img');
    if (existingImage) {
      // スタイルを変更して画像をコンテナに合わせる
      existingImage.style.width = '100%';
      existingImage.style.height = '100%';
      existingImage.style.objectFit = 'fill'; // containからfillに変更
      existingImage.style.maxWidth = 'none'; // maxWidthの制限を解除
      existingImage.style.maxHeight = 'none'; // maxHeightの制限を解除
      
      console.log('Adjusted image styles:', existingImage.style);
    }
  }

  // 画像コンテナクリック時にファイル選択ダイアログを表示
  openFileDialog(event) {
    if (this.element.querySelector('.overlay')) {
      return;
    }
    
    this.fileInputTarget.click();
  }

  // ファイル選択時に画像をアップロード
  async uploadImage(event) {
    const file = event.target.files[0];
    if (!file) return;
  
    try {
      const formData = new FormData();
      formData.append('travel[thumbnail]', file);
  
      const token = document.querySelector('meta[name="csrf-token"]').content;
      
      const response = await fetch(`/travels/${this.travelIdValue}`, {
        method: 'PATCH',
        headers: {
          'X-CSRF-Token': token
        },
        body: formData
      });
  
      if (!response.ok) {
        throw new Error('画像のアップロードに失敗しました');
      }
  
      // アップロード成功時、ページをリロードする代わりに画像を直接更新
      const reader = new FileReader();
      reader.onload = (e) => {
        // 既存の画像要素があれば更新、なければ新規作成
        const existingImage = this.imageContainerTarget.querySelector('img');
        if (existingImage) {
          existingImage.src = e.target.result;
          this.adjustExistingImage();
        } else {
          const newImage = document.createElement('img');
          newImage.src = e.target.result;
          newImage.alt = "表紙画像";
          newImage.className = "img-fluid";
          
          // 既存のテキスト要素があれば削除
          const textSpan = this.imageContainerTarget.querySelector('span');
          if (textSpan) {
            this.imageContainerTarget.removeChild(textSpan);
          }
          
          this.imageContainerTarget.appendChild(newImage);
          this.adjustExistingImage();
        }
        
        this.showFlashMessage('success', '画像をアップロードしました');
      };
      reader.readAsDataURL(file);
      
    } catch (error) {
      console.error('画像アップロードエラー:', error);
      this.showFlashMessage('danger', '画像のアップロードに失敗しました');
    }
  }

  // フラッシュメッセージを表示
  showFlashMessage(type, message) {
    // 既存の実装と同じ
    const flashContainer = document.createElement('div');
    flashContainer.innerHTML = `
      <div class="container mt-3">
        <div class="alert alert-${type} alert-dismissible fade show" role="alert">
          ${message}
          <button type="button" class="btn-close" data-bs-dismiss="alert" aria-label="Close"></button>
        </div>
      </div>
    `;
    
    const existingFlashContainer = document.querySelector('.container.mt-3');
    if (existingFlashContainer) {
      existingFlashContainer.parentNode.replaceChild(flashContainer.firstElementChild, existingFlashContainer);
    } else {
      const mainContent = document.querySelector('main');
      if (mainContent) {
        mainContent.insertBefore(flashContainer.firstElementChild, mainContent.firstChild);
      } else {
        document.body.insertBefore(flashContainer.firstElementChild, document.body.firstChild);
      }
    }
  }
}
