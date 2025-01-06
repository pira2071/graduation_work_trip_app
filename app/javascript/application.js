import "@hotwired/turbo-rails"
import "./controllers"
import * as bootstrap from "bootstrap"

document.addEventListener('turbo:load', () => {
  // Bootstrapのドロップダウンを初期化
  const dropdownTriggers = document.querySelectorAll('.dropdown-toggle')
  dropdownTriggers.forEach(trigger => {
    new bootstrap.Dropdown(trigger)
  })
  // CSRFトークン対策
  const token = document.querySelector('meta[name="csrf-token"]')?.content
  if (token) {
    window.csrfToken = token
  }
})

// グローバルにbootstrapを利用可能に
window.bootstrap = bootstrap

// Google Maps APIのコールバック関数をグローバルスコープで定義
window.initializeMap = function() {
  const event = new Event('google-maps-loaded');
  window.dispatchEvent(event);
}
