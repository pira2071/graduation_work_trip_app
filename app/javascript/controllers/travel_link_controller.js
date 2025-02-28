import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static values = {
    isPlanner: Boolean,
    isShared: Boolean
  }
  
  connect() {
    console.log("Travel Link Controller connected");
    console.log("Is Planner:", this.isPlannerValue);
    console.log("Is Shared:", this.isSharedValue);
    
    // URLクエリパラメータをチェック
    const urlParams = new URLSearchParams(window.location.search);
    if (urlParams.has('from_notification')) {
      console.log("Access from notification detected");
      // from_notification パラメータがある場合は常に許可
      this.isSharedValue = true;
    }
  }

  click(event) {
    if (!this.isPlannerValue && !this.isSharedValue) {
      event.preventDefault();
      alert("旅のしおりは幹事が現在作成中です。");
    }
  }
}
