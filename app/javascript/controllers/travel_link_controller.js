import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static values = {
    isPlanner: Boolean,
    isShared: Boolean
  }

  click(event) {
    if (!this.isPlannerValue && !this.isSharedValue) {
      event.preventDefault()
      alert("旅のしおりは幹事が現在作成中です。")
    }
  }
}
