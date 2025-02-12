import "@hotwired/turbo-rails"
import "./controllers"
import * as bootstrap from "bootstrap"

document.addEventListener('turbo:load', () => {
  // Bootstrapのドロップダウンを初期化
  const dropdownTriggers = document.querySelectorAll('.dropdown-toggle')
  dropdownTriggers.forEach(trigger => {
    new bootstrap.Dropdown(trigger)
  })
  
  // Google Maps APIが読み込まれているか確認
  if (window.google && window.google.maps) {
    window.dispatchEvent(new Event('maps-loaded'));
  }
});

// グローバルにbootstrapを利用可能に
window.bootstrap = bootstrap

// Google Maps APIのグローバルエラーハンドリング
window.gm_authFailure = () => {
  console.error('Google Maps authentication failed');
  alert('Google Maps APIの認証に失敗しました。');
};
