import { Controller } from "@hotwired/stimulus"
import Sortable from 'sortablejs'

export default class extends Controller {
  static targets = ["map", "sightseeingList", "restaurantList", "hotelList", "scheduleList"]
  static values = {
    travelId: String,
    totalDays: Number,
    existingSpots: Array
  }

  initialize() {
    this.markers = [];
    this.temporarySpots = {
      sightseeing: [],
      restaurant: [],
      hotel: []
    };
  }

  connect() {
    window.addEventListener('maps-loaded', () => {
      this.initializeMap();
    }, { once: true });

    this.initializeDragAndDrop();
  }

  disconnect() {
    if (this.map) {
      google.maps.event.clearInstanceListeners(this.map);
      this.map = null;
    }
    this.cleanupMarkers();
  }

  initializeMap() {
    const mapOptions = {
      center: { lat: 35.6812362, lng: 139.7671248 },
      zoom: 14,
      mapTypeControl: true,
      mapTypeControlOptions: {
        position: google.maps.ControlPosition.TOP_RIGHT
      },
      fullscreenControl: true,
      fullscreenControlOptions: {
        position: google.maps.ControlPosition.RIGHT_TOP
      }
    };

    this.map = new google.maps.Map(this.mapTarget, mapOptions);
    this.setupSearchBox();

    if (this.existingSpotsValue) {
      this.loadExistingSpots();
    }
  }

  setupSearchBox() {
    const input = document.getElementById('pac-input');
    const searchBox = new google.maps.places.SearchBox(input);

    this.map.addListener('bounds_changed', () => {
      searchBox.setBounds(this.map.getBounds());
    });

    searchBox.addListener('places_changed', () => {
      const places = searchBox.getPlaces();
      if (places.length === 0) return;

      const place = places[0];
      this.selectedPlace = place;

      if (!place.geometry) {
        alert("選択された場所の詳細が取得できませんでした");
        return;
      }

      if (place.geometry.viewport) {
        this.map.fitBounds(place.geometry.viewport);
      } else {
        this.map.setCenter(place.geometry.location);
        this.map.setZoom(17);
      }

      // 既存のマーカーをクリア
      if (this.temporaryMarker) {
        this.temporaryMarker.setMap(null);
      }

      // 新しいマーカーを設置
      this.temporaryMarker = new google.maps.Marker({
        map: this.map,
        position: place.geometry.location,
        title: place.name
      });
    });
  }

  loadExistingSpots() {
    if (this.hasExistingSpotsValue) {
      this.existingSpotsValue.forEach(spot => {
        if (parseInt(spot.travel_id) === parseInt(this.travelIdValue)) {
          const category = spot.category;
          this.temporarySpots[category].push(spot);
          this.addMarker(spot, category, spot.order_number);
        }
      });

      Object.keys(this.temporarySpots).forEach(category => {
        this.updateSpotsList(category);
      });
    }
  }

  initializeDragAndDrop() {
    // スポットリストのドラッグ設定
    const listTargets = [
      this.sightseeingListTarget,
      this.restaurantListTarget,
      this.hotelListTarget
    ];
  
    listTargets.forEach(list => {
      new Sortable(list, {
        group: {
          name: 'spots',
          pull: 'clone',
          put: false
        },
        sort: false,
        animation: 150,
        ghostClass: 'sortable-ghost',
        removeCloneOnHide: true,  // 追加：クローンを非表示時に削除
        onClone: (evt) => {
          const item = evt.item;
          const clone = evt.clone;
          clone.dataset.spotId = item.dataset.spotId;
          clone.dataset.category = item.closest('.spot-section').dataset.category;
        }
      });
    });
  
    // スケジュールリストのドラッグ設定
    this.scheduleListTargets.forEach(list => {
      new Sortable(list, {
        group: {
          name: 'spots',
          pull: true,
          put: true
        },
        animation: 150,
        ghostClass: 'sortable-ghost',
        onAdd: (evt) => {
          const item = evt.item;
          const list = evt.to;
          item.classList.add('schedule-spot-item');
          item.dataset.day = list.dataset.day;
          item.dataset.timeZone = list.dataset.timeZone;
          
          // 番号を更新
          this.updateAllSpotNumbers();
        },
        onSort: (evt) => {
          // ドラッグ&ドロップでの並び替え時に番号を更新
          this.updateAllSpotNumbers();
        }
      });
    });
  }

  // 全てのスポットの番号を更新するメソッド
  updateAllSpotNumbers() {
    let spotNumber = 1;
    const days = Array.from({ length: this.totalDaysValue }, (_, i) => i + 1);
    const timeZones = ['morning', 'noon', 'night'];

    days.forEach(day => {
      timeZones.forEach(timeZone => {
        this.scheduleListTargets.forEach(list => {
          if (parseInt(list.dataset.day) === day && list.dataset.timeZone === timeZone) {
            // カードが存在する場合のみ処理
            Array.from(list.children).forEach(spotItem => {
              const numberBadge = spotItem.querySelector('.badge');
              if (numberBadge) {
                numberBadge.textContent = spotNumber.toString();
                spotNumber++;
              }
            });
          }
        });
      });
    });
  }

  deleteFromList(event) {
    const item = event.target.closest('.spot-item');
    if (!item || !confirm('このスポットを削除してもよろしいですか？')) {
      return;
    }
  
    const spotId = item.dataset.spotId;
    const category = item.dataset.category;
    const parentList = item.closest('.spots-list, .schedule-list');
  
    // 同じspotIdを持つ全てのカードを取得して削除
    document.querySelectorAll(`.spot-item[data-spot-id="${spotId}"]`).forEach(card => {
      const cardList = card.closest('.spots-list, .schedule-list');
      card.remove();
      
      // リストが空になった場合の処理
      if (cardList && cardList.children.length === 0) {
        cardList.style.padding = '0';
        cardList.style.minHeight = '0';
        cardList.style.border = 'none';
      }
    });
  
    // temporarySpotsからも削除
    if (category && this.temporarySpots[category]) {
      this.temporarySpots[category] = this.temporarySpots[category].filter(
        spot => spot.id.toString() !== spotId.toString()
      );
    }
  
    // 番号を振り直す
    this.updateAllSpotNumbers();
  
    // サーバーサイドでの削除処理
    fetch(`/travels/${this.travelIdValue}/spots/${spotId}`, {
      method: 'DELETE',
      headers: {
        'Content-Type': 'application/json',
        'X-CSRF-Token': document.querySelector('[name="csrf-token"]').content
      }
    })
    .then(response => {
      if (!response.ok) {
        throw new Error('削除に失敗しました');
      }
      // マーカーの削除
      this.removeMarker(spotId);
    })
    .catch(error => {
      console.error('Delete error:', error);
      alert('削除に失敗しました');
    });
  }

  registerSpot(event) {
    const category = event.currentTarget.dataset.category;
    
    if (!this.selectedPlace) {
      alert('場所を選択してください');
      return;
    }

    const orderNumber = this.temporarySpots[category].length + 1;
    const spotData = {
      spot: {
        name: this.selectedPlace.name,
        category: category,
        lat: this.selectedPlace.geometry.location.lat(),
        lng: this.selectedPlace.geometry.location.lng(),
        order_number: orderNumber
      }
    };

    this.registerSpotWithServer(spotData, category);
  }

  registerSpotWithServer(spotData, category) {
    if (!this.travelIdValue) {
      alert('旅行IDが見つかりません');
      return;
    }
  
    fetch(`/travels/${this.travelIdValue}/spots/register`, {
      method: 'POST',
      headers: {
        'Content-Type': 'application/json',
        'X-CSRF-Token': document.querySelector('[name="csrf-token"]').content
      },
      body: JSON.stringify(spotData)
    })
    .then(response => {
      if (!response.ok) throw new Error('登録に失敗しました');
      return response.json();
    })
    .then(data => {
      if (data.success) {
        this.handleSuccessfulRegistration(data.spot, category);
      } else {
        alert(data.message || '登録に失敗しました');
      }
    })
    .catch(error => {
      alert(error.message);
    });
  }

  handleSuccessfulRegistration(spot, category) {
    this.temporarySpots[category].push(spot);
    this.updateSpotsList(category);
    this.addMarker(spot, category, spot.order_number);
    
    document.getElementById("pac-input").value = '';
    this.selectedPlace = null;
    if (this.temporaryMarker) {
      this.temporaryMarker.setMap(null);
    }
    
    this.updateSpotsOrder(category);
  }

  addMarker(spot, category, orderNumber) {
    const categoryColors = {
      sightseeing: '#28a745',
      restaurant: '#ffc107',
      hotel: '#17a2b8'
    };
  
    const newMarker = new google.maps.Marker({
      position: { lat: parseFloat(spot.lat), lng: parseFloat(spot.lng) },
      map: this.map,
      label: {
        text: orderNumber.toString(),
        color: 'white'
      },
      icon: {
        path: google.maps.SymbolPath.CIRCLE,
        fillColor: categoryColors[category],
        fillOpacity: 0.8,
        strokeColor: 'white',
        strokeWeight: 2,
        scale: 15
      }
    });
  
    newMarker.spotId = spot.id; // マーカーにspotIdを追加
    this.markers.push(newMarker);
    return newMarker;
  }

  removeMarker(spotId) {
    const markerIndex = this.markers.findIndex(marker => 
      marker.spotId && marker.spotId.toString() === spotId.toString()
    );
    
    if (markerIndex !== -1) {
      this.markers[markerIndex].setMap(null);
      this.markers.splice(markerIndex, 1);
    }
  }

  cleanupMarkers() {
    if (this.markers.length > 0) {
      this.markers.forEach(marker => {
        if (marker) marker.setMap(null);
      });
      this.markers = [];
    }
    if (this.temporaryMarker) {
      this.temporaryMarker.setMap(null);
      this.temporaryMarker = null;
    }
  }

  updateSpotsList(category) {
    const targetMap = {
      sightseeing: 'sightseeingList',
      restaurant: 'restaurantList',
      hotel: 'hotelList'
    };

    const listElement = this[`${targetMap[category]}Target`];
    if (!listElement) return;

    listElement.innerHTML = '';

    this.temporarySpots[category]
      .filter(spot => parseInt(spot.travel_id) === parseInt(this.travelIdValue))
      .forEach((spot, index) => {
        const spotItem = document.createElement('div');
        spotItem.className = 'card mb-2';
        spotItem.dataset.spotId = spot.id;
        
        const dayOptions = Array.from({length: this.totalDaysValue}, (_, i) => {
          const day = i + 1;
          return `<option value="${day}" ${spot.day_number === day ? 'selected' : ''}>${day}日目</option>`;
        }).join('');

        spotItem.innerHTML = this.generateSpotItemHtml(spot, index, category, dayOptions);
        listElement.appendChild(spotItem);
      });
  }

  generateSpotItemHtml(spot, index, category) {
    return `
      <div class="spot-item" data-spot-id="${spot.id}" data-category="${category}">
        <div class="d-flex justify-content-between align-items-center">
          <div class="d-flex align-items-center">
            <span class="badge bg-${this.getColorClass(category)} me-2"></span>
            <span class="flex-grow-1">${spot.name}</span>
          </div>
          <button type="button" 
                  class="btn btn-outline-danger btn-sm"
                  data-action="spots-registration#deleteFromList">
            <i class="bi bi-trash"></i> 削除
          </button>
        </div>
      </div>
    `;
  }

  saveSchedules() {
    const schedules = [];
    let hasEmptySchedule = false;

    document.querySelectorAll('.card.mb-2').forEach(spotItem => {
      const spotId = spotItem.dataset.spotId;
      const daySelect = spotItem.querySelector('.day-select');
      const timeSelect = spotItem.querySelector('.time-select');

      if (!daySelect?.value || !timeSelect?.value) {
        hasEmptySchedule = true;
        return;
      }

      schedules.push({
        spot_id: spotId,
        day_number: daySelect.value,
        time_zone: timeSelect.value
      });
    });

    if (hasEmptySchedule) {
      alert('全てのスポットの日程と時間帯を選択してください');
      return;
    }

    this.saveSchedulesWithServer(schedules);
  }

  saveSchedulesWithServer(schedules) {
    fetch(`/travels/${this.travelIdValue}/spots/save_schedules`, {
      method: 'POST',
      headers: {
        'Content-Type': 'application/json',
        'X-CSRF-Token': document.querySelector('[name="csrf-token"]').content
      },
      body: JSON.stringify({ schedules: schedules })
    })
    .then(response => {
      if (!response.ok) {
        return response.json().then(data => {
          throw new Error(data.message || 'スケジュールの保存に失敗しました');
        });
      }
      window.location.href = `/travels/${this.travelIdValue}`;
    })
    .catch(error => {
      alert(error.message);
    });
  }

  updateSpotsOrder(category) {
    const spots = this.temporarySpots[category];
    spots.forEach((spot, index) => {
      if (spot.order_number !== index + 1) {
        this.updateSpotOrderWithServer(spot.id, index + 1);
      }
    });
  }

  updateSpotOrderWithServer(spotId, newOrder) {
    fetch(`/travels/${this.travelIdValue}/spots/${spotId}/update_order`, {
      method: 'PATCH',
      headers: {
        'Content-Type': 'application/json',
        'X-CSRF-Token': document.querySelector('[name="csrf-token"]').content
      },
      body: JSON.stringify({ order_number: newOrder })
    });
  }

  getColorClass(category) {
    switch (category) {
      case 'sightseeing': return 'success';
      case 'restaurant': return 'warning';
      case 'hotel': return 'info';
      default: return 'secondary';
    }
  }
}
