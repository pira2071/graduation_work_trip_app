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

  // Google Maps APIが読み込まれているか確認
  if (window.google && window.google.maps) {
    window.dispatchEvent(new Event('maps-loaded'));
  }
});

// ページキャッシュ前の処理
document.addEventListener('turbo:before-cache', () => {
  if (window.google && window.google.maps) {
    delete window.google.maps;
  }
});

// グローバルにbootstrapを利用可能に
window.bootstrap = bootstrap

// Google Maps APIのグローバルエラーハンドリング
window.gm_authFailure = () => {
  console.error('Google Maps authentication failed');
  alert('Google Maps APIの認証に失敗しました。');
};
