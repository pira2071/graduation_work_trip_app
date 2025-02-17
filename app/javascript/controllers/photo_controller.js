import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["deleteButton"]
  static values = {
    travelId: String
  }

  upload(event) {
    const files = event.target.files
    const dayNumber = event.target.dataset.photoDayNumber
    
    if (!files.length) return

    const formData = new FormData()
    formData.append('photo[image]', files[0])
    formData.append('photo[day_number]', dayNumber)

    // CSRFトークンを取得
    const token = document.querySelector('meta[name="csrf-token"]').content

    fetch(`/travels/${this.travelIdValue}/photos`, {
      method: 'POST',
      body: formData,
      headers: {
        'X-CSRF-Token': token
      }
    })
    .then(response => {
      if (!response.ok) {
        throw new Error(`HTTP error! status: ${response.status}`)
      }
      return response.json()
    })
    .then(data => {
      if (data.photo) {
        this.addPhotoToGrid(data.photo, dayNumber)
      } else {
        throw new Error('Invalid response format')
      }
    })
    .catch(error => {
      console.error('Upload error:', error)
      alert('写真のアップロードに失敗しました。もう一度お試しください。')
    })

    // 入力をクリアしてreupload可能に
    event.target.value = ''
  }

  addPhotoToGrid(photo, dayNumber) {
    const grid = document.querySelector(`#day-${dayNumber}-photos`)
    if (!grid.style.cssText) {
      grid.style.cssText = 'display: grid; gap: 1.5rem; grid-template-columns: repeat(auto-fill, minmax(150px, 1fr)); justify-content: start;'
    }
    
    const container = document.createElement('div')
    container.className = 'photo-container'
    container.style.cssText = 'width: 150px; height: 200px; position: relative;'
    container.dataset.photoId = photo.id
    
    const img = document.createElement('img')
    img.src = photo.url
    img.className = 'rounded cursor-pointer'
    img.style.cssText = 'width: 150px; height: 150px; object-fit: cover;'
    img.dataset.bsToggle = 'modal'
    img.dataset.bsTarget = '#photoModal'
    img.dataset.action = "click->photo#showInModal"
    
    const deleteBtn = document.createElement('button')
    deleteBtn.className = 'delete-btn'
    deleteBtn.dataset.action = "click->photo#deletePhoto"
    deleteBtn.dataset.photoId = photo.id
    deleteBtn.innerHTML = '<i class="bi bi-trash"></i>'
    
    container.appendChild(img)
    container.appendChild(deleteBtn)
    grid.appendChild(container)
  }

  deletePhoto(event) {
    event.preventDefault()
    event.stopPropagation()
    
    const photoId = event.currentTarget.dataset.photoId
    const container = event.currentTarget.closest('.photo-container')

    if (confirm('この写真を削除してもよろしいですか？')) {
      fetch(`/travels/${this.travelIdValue}/photos/${photoId}`, {
        method: 'DELETE',
        headers: {
          'X-CSRF-Token': document.querySelector('[name="csrf-token"]').content
        },
        credentials: 'same-origin'
      })
      .then(response => {
        if (!response.ok) {
          throw new Error('Delete failed')
        }
        container.remove()
      })
      .catch(error => {
        console.error('Error:', error)
        alert('写真の削除に失敗しました')
      })
    }
  }

  showInModal(event) {
    event.preventDefault()
    const imageUrl = event.currentTarget.src
    document.querySelector('#modalImage').src = imageUrl
  }
}