import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = [ "itemsContainer" ]

  addItem(event) {
    event.preventDefault();
    const itemCount = this.itemsContainerTarget.children.length;
    const newItem = document.createElement('div');
    newItem.className = 'mb-2';
    newItem.innerHTML = `<input type="text" name="packing_list[items[${itemCount}]]" class="form-control">`;
    this.itemsContainerTarget.appendChild(newItem);
  }
}
