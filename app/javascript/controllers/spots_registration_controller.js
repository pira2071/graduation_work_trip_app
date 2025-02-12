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
          // マーカーを追加（番号なしで）
          this.addMarker(spot, category);
        }
      });
  
      // スポットリストを更新
      Object.keys(this.temporarySpots).forEach(category => {
        this.updateSpotsList(category);
      });
  
      // 番号を振り直す（これにより旅程表のスポットのみに番号が付与される）
      this.updateAllSpotNumbers();
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
        removeCloneOnHide: true,
        onClone: (evt) => {
          const item = evt.item;
          const clone = evt.clone;
          // 全ての必要なデータ属性とクラスを複製
          clone.className = item.className;
          clone.dataset.spotId = item.dataset.spotId;
          clone.dataset.category = item.closest('.spot-section').dataset.category;
  
          // 内部の要素の構造も正しく複製されるようにする
          const originalButton = item.querySelector('button');
          if (originalButton) {
            const clonedButton = clone.querySelector('button');
            if (clonedButton) {
              clonedButton.setAttribute('data-action', originalButton.getAttribute('data-action'));
            }
          }
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
          
          // データ属性を追加
          item.dataset.day = list.dataset.day;
          item.dataset.timeZone = list.dataset.timeZone;
          
          console.log('Item added to schedule:', item);
          
          // 番号を更新
          this.updateAllSpotNumbers();
        },
        onSort: (evt) => {
          console.log('Items sorted');
          this.updateAllSpotNumbers();
        }
      });
    });
  }

  updateSpotsList(category) {
    // カテゴリーごとのリストのマッピング
    const targetMap = {
      sightseeing: 'sightseeingList',
      restaurant: 'restaurantList',
      hotel: 'hotelList'
    };
  
    // 対象のリスト要素を取得
    const listTarget = this[`${targetMap[category]}Target`];
    if (!listTarget) {
      console.error(`Target list for category ${category} not found`);
      return;
    }
  
    // リストをクリア
    listTarget.innerHTML = '';
  
    // 該当カテゴリーのスポットを追加
    this.temporarySpots[category]
      .filter(spot => parseInt(spot.travel_id) === parseInt(this.travelIdValue))
      .forEach((spot, index) => {
        const spotItem = document.createElement('div');
        spotItem.className = 'card mb-2';
        spotItem.dataset.spotId = spot.id;
        spotItem.dataset.category = category;
  
        spotItem.innerHTML = this.generateSpotItemHtml(spot, index, category);
        listTarget.appendChild(spotItem);
      });
  }

  // 全てのスポットの番号を更新するメソッド
  updateAllSpotNumbers() {
    let spotNumber = 1;
    const days = Array.from({ length: this.totalDaysValue }, (_, i) => i + 1);
    const timeZones = ['morning', 'noon', 'night'];
    const spotOrder = new Map(); // スポットIDと番号のマッピング
  
    console.log('Starting updateAllSpotNumbers...'); // デバッグ用
  
    // 旅程表中のスポットに番号を振る
    days.forEach(day => {
      timeZones.forEach(timeZone => {
        this.scheduleListTargets.forEach(list => {
          if (parseInt(list.dataset.day) === day && list.dataset.timeZone === timeZone) {
            Array.from(list.children).forEach(spotItem => {
              const numberBadge = spotItem.querySelector('[data-spot-number]');
              const spotId = spotItem.dataset.spotId;
              if (numberBadge) {
                console.log(`Updating number for spot ${spotId} to ${spotNumber}`); // デバッグ用
                numberBadge.textContent = spotNumber.toString();
                spotOrder.set(spotId, spotNumber);
                spotNumber++;
              }
            });
          }
        });
      });
    });
  
    console.log('Spot order map:', spotOrder); // デバッグ用
    this.updateMarkerNumbers(spotOrder);
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
    // マーカーを追加する際に番号を指定しない
    this.addMarker(spot, category);  // order_numberパラメータを削除
    
    document.getElementById("pac-input").value = '';
    this.selectedPlace = null;
    if (this.temporaryMarker) {
      this.temporaryMarker.setMap(null);
    }
    
    this.updateSpotsOrder(category);
  }

  addMarker(spot, category) {
    const categoryColors = {
      sightseeing: '#198754',
      restaurant: '#ffc107',
      hotel: '#0dcaf0'
    };
  
    this.removeMarker(spot.id);
  
    const markerOptions = {
      position: { lat: parseFloat(spot.lat), lng: parseFloat(spot.lng) },
      map: this.map,
      label: {
        text: '',  // 初期値は必ず空文字列
        color: 'white',
        fontSize: '14px',
        fontWeight: 'bold'
      },
      icon: {
        path: google.maps.SymbolPath.MARKER,
        fillColor: categoryColors[category],
        fillOpacity: 1.0,
        strokeColor: 'white',
        strokeWeight: 2,
        scale: 30,
        labelOrigin: new google.maps.Point(0, -3)
      }
    };
  
    const newMarker = new google.maps.Marker(markerOptions);
    newMarker.spotId = spot.id;
    this.markers.push(newMarker);
  
    return newMarker;
  }

  removeMarker(spotId) {
    if (!spotId) return;
  
    // 既存のマーカーを検索
    const markerIndex = this.markers.findIndex(marker => 
      marker && marker.spotId && marker.spotId.toString() === spotId.toString()
    );
    
    // マーカーが見つかった場合、削除
    if (markerIndex !== -1) {
      const marker = this.markers[markerIndex];
      if (marker) {
        marker.setMap(null);  // マップから削除
      }
      this.markers.splice(markerIndex, 1);  // 配列から削除
    }
  }

  updateMarkerNumbers(spotOrder) {
    console.log('Updating marker numbers with order:', spotOrder);
  
    if (!this.markers || !Array.isArray(this.markers)) {
      console.error('Markers array is not properly initialized');
      return;
    }
  
    this.markers.forEach(marker => {
      if (marker && marker.spotId) {
        const number = spotOrder.get(marker.spotId.toString());
        try {
          marker.setLabel({
            text: number ? number.toString() : '',
            color: 'white',
            fontSize: '14px',
            fontWeight: 'bold'
          });
        } catch (error) {
          console.error('Error updating marker label:', error, marker);
        }
      }
    });
  }

  generateSpotItemHtml(spot, index, category) {
    return `
      <div class="spot-item" data-spot-id="${spot.id}" data-category="${category}">
        <div class="d-flex justify-content-between align-items-center">
          <div class="d-flex align-items-center">
            <span class="badge bg-${this.getColorClass(category)} me-2" data-spot-number></span>
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
    const scheduledSpots = new Set(); // スケジュール表に配置されたスポットのIDを管理
  
    // スケジュール表のスポットを収集
    this.scheduleListTargets.forEach(list => {
      const day = parseInt(list.dataset.day);
      const timeZone = list.dataset.timeZone;
  
      Array.from(list.children).forEach((spotItem, index) => {
        const spotId = spotItem.dataset.spotId;
        scheduledSpots.add(spotId);
        schedules.push({
          spot_id: spotId,
          day_number: day,
          time_zone: timeZone,
          order_number: index + 1
        });
      });
    });
  
    // スケジュールデータをサーバーに送信
    this.saveSchedulesWithServer(schedules);
  }

  saveSchedulesWithServer(schedules) {
    fetch(`/travels/${this.travelIdValue}/spots/save_schedules`, {
      method: 'POST',
      headers: {
        'Content-Type': 'application/json',
        'X-CSRF-Token': document.querySelector('[name="csrf-token"]').content
      },
      // スケジュールデータをラップして送信
      body: JSON.stringify({ schedules: schedules })  // 変更点：schedules キーでラップ
    })
    .then(response => {
      if (!response.ok) {
        return response.json().then(data => {
          throw new Error(data.message || 'スケジュールの保存に失敗しました');
        });
      }
      this.showSuccessMessage('旅程表を保存しました');
    })
    .catch(error => {
      console.error('Save error:', error);
      alert('保存に失敗しました: ' + error.message);
    });
  }

  showSuccessMessage(message = '') {
    if (message) {
      alert(message);  // とりあえずalertで表示
    }
    // プラン詳細画面へ遷移
    window.location.href = `/travels/${this.travelIdValue}`;
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
