import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["checkbox", "selectAll"]

  connect() {
    console.log("Connected!")
  }

  toggleAll(event) {
    const checked = this.selectAllTarget.checked
    this.checkboxTargets.forEach(box => box.checked = checked)
  }

  toggleIndividual() {
    // event.preventDefault()を削除
    const allChecked = this.checkboxTargets.every(checkbox => checkbox.checked)
    this.selectAllTarget.checked = allChecked
  }
}
