// app/javascript/controllers/search_autocomplete_controller.js
import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static values = {
    url: String
  }

  connect() {
    this.element.addEventListener('input', this.handleInput.bind(this))
  }

  async handleInput(event) {
    if (event.target.value.length < 2) {
      this.removeExistingList()
      return
    }

    try {
      const response = await fetch(`${this.urlValue}?q[title_cont]=${encodeURIComponent(event.target.value)}`)
      const data = await response.json()
      
      this.removeExistingList()

      if (data.length > 0) {
        const list = document.createElement('ul')
        list.className = 'autocomplete-list list-group'
        
        data.forEach(item => {
          const li = document.createElement('li')
          li.className = 'list-group-item list-group-item-action'
          li.textContent = item.title
          li.addEventListener('click', () => {
            this.element.value = item.title
            this.removeExistingList()
            this.element.closest('form').submit()
          })
          list.appendChild(li)
        })

        // 検索フィールドの直下に配置し、幅を合わせる
        const searchField = this.element
        list.style.width = `${searchField.offsetWidth}px`
        searchField.parentNode.appendChild(list)
      }
    } catch (error) {
      console.error("Search error:", error)
    }
  }

  removeExistingList() {
    const existingList = this.element.parentNode.querySelector('.autocomplete-list')
    if (existingList) {
      existingList.remove()
    }
  }
}
