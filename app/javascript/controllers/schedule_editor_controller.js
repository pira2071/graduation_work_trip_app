import { Controller } from "@hotwired/stimulus"
import Sortable from "sortablejs"

export default class extends Controller {
  static targets = ["spotsList"]
  static values = {
    travelId: String
  }

  initialize() {
    this.deletedSpots = new Set(); // 削除予定のスポットを管理
    this.reorderedSchedules = new Map(); // 順序変更を一時的に保持
  }

  connect() {
    console.log("ScheduleEditor connected");
    if (this.hasSpotsListTarget) {
      this.initializeSortable();
      this.updateAllSpotNumbers(); // 初期表示時に番号を振る
    }
  }

  hasListTargets() {
    return this.hasSpotsListTarget && this.spotsListTargets.length > 0;
  }

  deleteSpot(event) {
    event.preventDefault();

    if (!confirm('このスポットを削除してもよろしいですか？\n※更新ボタンをクリックするまでは確定されません')) {
      return;
    }

    const targetButton = event.currentTarget;
    const scheduleCard = targetButton.closest('.spot-item');
    if (!scheduleCard) return;

    const spotId = targetButton.dataset.scheduleEditorSpotIdParam;
    const scheduleId = targetButton.dataset.scheduleEditorScheduleIdParam;
    
    // 削除予定リストに追加
    this.deletedSpots.add({
      spotId: spotId,
      scheduleId: scheduleId,
      element: scheduleCard
    });

    // 見た目上は非表示にする（完全な削除ではない）
    scheduleCard.style.display = 'none';
    
    this.showSuccessMessage('スポットを削除しました（更新ボタンをクリックで確定）');

    // 削除後に番号を振り直す
    this.updateAllSpotNumbers();
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

  showSuccessMessage(message = '') {
    const alert = document.createElement('div');
    alert.className = 'alert alert-success alert-dismissible fade show mt-3';
    alert.innerHTML = `
      ${message}
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

  updateAllSpotNumbers() {
    let spotNumber = 1;
    const days = new Set(this.spotsListTargets.map(list => list.dataset.day));
    const timeZones = ['morning', 'noon', 'night'];

    days.forEach(day => {
      timeZones.forEach(timeZone => {
        this.spotsListTargets.forEach(list => {
          if (list.dataset.day === day && list.dataset.timeZone === timeZone) {
            Array.from(list.children).forEach(spotItem => {
              if (spotItem.style.display !== 'none') { // 削除予定のものは除外
                const numberBadge = spotItem.querySelector('[data-spot-number]');
                if (numberBadge) {
                  numberBadge.textContent = spotNumber.toString();
                  spotNumber++;
                }
              }
            });
          }
        });
      });
    });
  }

  handleDragEnd(event) {
    const list = event.to;
    const day = list.dataset.day;
    const timeZone = list.dataset.timeZone;
    
    // 移動したカードの新しい位置情報を保持
    Array.from(list.children).forEach((item, index) => {
      const scheduleId = item.dataset.scheduleId;
      this.reorderedSchedules.set(scheduleId, {
        day_number: parseInt(day),
        time_zone: timeZone,
        order_number: index + 1
      });
    });

    // 番号を振り直す（見た目のみ）
    this.updateAllSpotNumbers();
  }
  
  updateSchedules() {
    const schedules = [];
    const deletions = Array.from(this.deletedSpots).map(item => ({
      spot_id: item.spotId,
      schedule_id: item.scheduleId
    }));
    
    this.spotsListTargets.forEach(list => {
      const day = list.dataset.day;
      const timeZone = list.dataset.timeZone;
      
      Array.from(list.children).forEach((spotItem, index) => {
        const scheduleId = spotItem.dataset.scheduleId;
        // 削除予定のものは除外
        if (scheduleId && !Array.from(this.deletedSpots).some(d => d.scheduleId === scheduleId)) {
          // reorderedSchedulesに保存された変更があればそれを使用
          const reorderedData = this.reorderedSchedules.get(scheduleId);
          schedules.push({
            schedule_id: scheduleId,
            day_number: reorderedData ? reorderedData.day_number : parseInt(day),
            time_zone: reorderedData ? reorderedData.time_zone : timeZone,
            order_number: reorderedData ? reorderedData.order_number : (index + 1)
          });
        }
      });
    });

    this.updateSchedulesWithServer(schedules, deletions);
  }

  updateSchedulesWithServer(schedules, deletions) {
    fetch(`/travels/${this.travelIdValue}/schedules/update_all`, {
      method: 'PATCH',
      headers: {
        'Content-Type': 'application/json',
        'X-CSRF-Token': document.querySelector('[name="csrf-token"]').content
      },
      body: JSON.stringify({ 
        schedules: schedules,
        deletions: deletions 
      })
    })
    .then(response => {
      if (!response.ok) {
        throw new Error('更新に失敗しました');
      }
      // プラン詳細画面へ遷移
      window.location.href = `/travels/${this.travelIdValue}`;
    })
    .catch(error => {
      console.error('Update error:', error);
      alert('更新に失敗しました: ' + error.message);
    });
  }
}
