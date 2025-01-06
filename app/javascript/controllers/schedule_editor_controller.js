// app/javascript/controllers/schedule_editor_controller.js
import { Controller } from "@hotwired/stimulus"
import Sortable from "sortablejs"

export default class extends Controller {
  static targets = ["spotsList"]
  static values = {
    travelId: String
  }

  connect() {
    console.log("ScheduleEditor connected");
    // spotsListTargetsが存在する場合のみSortableを初期化
    if (this.hasSpotsListTarget) {
      this.initializeSortable();
    }
  }

  hasListTargets() {
    return this.hasSpotsListTarget && this.spotsListTargets.length > 0;
  }

  deleteSpot(event) {
    console.log("Delete button clicked", event.currentTarget);
    event.preventDefault();

    if (!confirm('このスポットを削除してもよろしいですか？')) {
      return;
    }

    const targetButton = event.currentTarget;
    if (!targetButton) {
      console.error('Button element not found');
      return;
    }

    // まず親の.card要素を探す
    const scheduleCard = targetButton.closest('.card');
    if (!scheduleCard) {
      console.error('Schedule card not found');
      return;
    }

    const spotId = targetButton.dataset.scheduleEditorSpotIdParam;
    const scheduleId = targetButton.dataset.scheduleEditorScheduleIdParam;
    
    console.log('Deleting:', { spotId, scheduleId, element: scheduleCard });

    fetch(`/travels/${this.travelIdValue}/schedules/delete_spot`, {
      method: 'DELETE',
      headers: {
        'Content-Type': 'application/json',
        'X-CSRF-Token': document.querySelector('[name="csrf-token"]').content
      },
      body: JSON.stringify({
        spot_id: spotId,
        schedule_id: scheduleId
      })
    })
    .then(response => {
      if (!response.ok) {
        throw new Error('削除に失敗しました');
      }
      // 要素を画面から削除
      scheduleCard.remove();
      
      // 成功メッセージを表示
      this.showSuccessMessage();
    })
    .catch(error => {
      console.error('Delete error:', error);
      alert(`削除に失敗しました: ${error.message}`);
    });
  }

  initializeSortable() {
    if (!this.spotsListTargets || this.spotsListTargets.length === 0) {
      console.log("No spotsList targets found");
      return;
    }

    console.log("Initializing sortable with targets:", this.spotsListTargets);
    this.spotsListTargets.forEach(list => {
      new Sortable(list, {
        group: 'schedules',
        animation: 150,
        ghostClass: 'schedule-item-ghost',
        onEnd: this.handleDragEnd.bind(this)
      });
    });
  }

  showSuccessMessage() {
    const alert = document.createElement('div');
    alert.className = 'alert alert-success alert-dismissible fade show mt-3';
    alert.innerHTML = `
      スポットを削除しました
      <button type="button" class="btn-close" data-bs-dismiss="alert" aria-label="Close"></button>
    `;
    
    const container = document.querySelector('.container');
    if (container) {
      container.insertBefore(alert, container.firstChild);
      setTimeout(() => {
        alert.remove();
      }, 3000);
    }
  }

  handleDragEnd(event) {
    const scheduleIds = Array.from(event.to.children).map(item => 
      item.dataset.scheduleId
    );
  
    // ドラッグ＆ドロップ後の順序を更新
    this.updateScheduleOrder(scheduleIds);
  }
  
  updateScheduleOrder(scheduleIds) {
    fetch(`/travels/${this.travelIdValue}/schedules/reorder`, {
      method: 'POST',
      headers: {
        'Content-Type': 'application/json',
        'X-CSRF-Token': document.querySelector('[name="csrf-token"]').content
      },
      body: JSON.stringify({ schedule_ids: scheduleIds })
    })
    .catch(error => {
      console.error('Reorder error:', error);
      alert('並び順の更新に失敗しました');
    });
  }
}
