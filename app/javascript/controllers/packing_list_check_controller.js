import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  toggleCheck(event) {
    const itemId = event.target.dataset.itemId
    const checked = event.target.checked

    fetch(`/packing_lists/${this.getListId()}/packing_items/${itemId}`, {
      method: 'PATCH',
      headers: {
        'Content-Type': 'application/json',
        'X-CSRF-Token': this.getMetaValue('csrf-token')
      },
      body: JSON.stringify({ checked: checked })
    }).catch(error => {
      console.error('Error:', error)
      event.target.checked = !checked  // エラー時は元の状態に戻す
    })
  }

  clearAll() {
    if (!confirm('全てのチェックを外しますか？')) return

    fetch(`/packing_lists/${this.getListId()}/packing_items/clear_all`, {
      method: 'POST',
      headers: {
        'X-CSRF-Token': this.getMetaValue('csrf-token')
      }
    }).then(() => {
      location.reload()
    }).catch(error => {
      console.error('Error:', error)
    })
  }

  private

  getListId() {
    return window.location.pathname.split('/')[2]
  }

  getMetaValue(name) {
    const element = document.querySelector(`meta[name="${name}"]`)
    return element.getAttribute('content')
  }
}
