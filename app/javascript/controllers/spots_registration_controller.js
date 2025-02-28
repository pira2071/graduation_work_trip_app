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
    this.currentInfoWindow = null; // 現在開いている情報ウィンドウを追跡
    this.deletedSpotIds = new Set(); // 削除されたスポットのID
  }

  connect() {
    console.log('Controller connected');
    // データ属性の生の値を出力
    console.log('Raw data attribute:', this.element.dataset.spotsRegistrationExistingSpotsValue);
    // 型も確認
    console.log('Type of data:', typeof this.element.dataset.spotsRegistrationExistingSpotsValue);
    
    if (document.readyState === 'loading') {
      document.addEventListener('DOMContentLoaded', () => {
        this.initializeController();
      });
    } else {
      this.initializeController();
    }
  }
  
  initializeController() {
    console.log('initializeController started');
    console.log('existingSpotsValue:', this.existingSpotsValue);  // 追加
    
    window.addEventListener('maps-loaded', () => {
      console.log('maps-loaded event fired');  // 追加
      this.initializeMap();
    }, { once: true });
  
    setTimeout(() => {
      console.log('Timeout callback started');  // 追加
      this.initializeDragAndDrop();
      this.updateAllSpotNumbers();
      console.log('Initial setup completed');
    }, 100);
  }

  disconnect() {
    if (this.map) {
      google.maps.event.clearInstanceListeners(this.map);
      this.map = null;
    }
    this.cleanupMarkers();
  }

  initializeMap() {
    console.log('initializeMap started');

    if (!window.google || !window.google.maps) {
      console.error('Google Maps API not loaded');
      return;
    }
  
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
  
    try {
      this.map = new google.maps.Map(this.mapTarget, mapOptions);
      console.log('Map instance created:', this.map);
      
      // Google Maps APIのロード完了を待ってから実行
      google.maps.event.addListenerOnce(this.map, 'idle', () => {
        console.log('Map idle event fired');
        this.setupSearchBox();
        console.log('About to load existing spots:', this.existingSpotsValue);
        if (this.existingSpotsValue && this.existingSpotsValue.length > 0) {
          this.loadExistingSpots();
        }
      });
  
    } catch (error) {
      console.error('Error initializing map:', error);
    }
  }

  setupSearchBox() {
    if (!google.maps.places) {
      console.error('Places library not loaded');
      return;
    }
  
    const input = document.getElementById('pac-input');
    if (!input) {
      console.error('Search input not found');
      return;
    }
  
    const searchBox = new google.maps.places.SearchBox(input);
  
    // マップの表示領域が変更されたときの処理
    this.map.addListener('bounds_changed', () => {
      searchBox.setBounds(this.map.getBounds());
    });
  
    searchBox.addListener('places_changed', () => {
      const places = searchBox.getPlaces();
      if (places.length === 0) return;
  
      const place = places[0];
      this.selectedPlace = place;
  
      if (!place.geometry || !place.geometry.location) {
        alert("選択された場所の詳細が取得できませんでした");
        return;
      }
  
      // 既存の一時マーカーをクリア
      if (this.temporaryMarker) {
        this.temporaryMarker.setMap(null);
      }
  
      // 新しい一時マーカーを作成
      this.temporaryMarker = new google.maps.Marker({
        map: this.map,
        position: place.geometry.location,
        title: place.name
      });
  
      // マップの表示位置を調整
      if (place.geometry.viewport) {
        this.map.fitBounds(place.geometry.viewport);
      } else {
        this.map.setCenter(place.geometry.location);
        this.map.setZoom(17);
      }
    });
  }

  loadExistingSpots() {
    if (this.hasExistingSpotsValue) {
      console.log('Loading existing spots:', this.existingSpotsValue);
      
      // スケジュールのあるスポットとないスポットを分類
      const scheduledSpots = this.existingSpotsValue.filter(spot => spot.schedule);
      const unscheduledSpots = this.existingSpotsValue.filter(spot => !spot.schedule);
      
      // スケジュール済みのスポットを日程順にソート
      const sortedScheduledSpots = scheduledSpots.sort((a, b) => {
        if (a.schedule.day_number !== b.schedule.day_number) {
          return a.schedule.day_number - b.schedule.day_number;
        }
        if (a.schedule.time_zone !== b.schedule.time_zone) {
          const timeZoneOrder = { morning: 0, noon: 1, night: 2 };
          return timeZoneOrder[a.schedule.time_zone] - timeZoneOrder[b.schedule.time_zone];
        }
        return a.schedule.order_number - b.schedule.order_number;
      });
  
      // 番号付きマーカーを追加（スケジュール済みのスポット）
      sortedScheduledSpots.forEach((spot, index) => {
        const category = spot.category;
        this.temporarySpots[category].push(spot);
        this.addMarker(spot, category, index + 1);  // インデックス+1を番号として渡す
      });
  
      // 番号なしマーカーを追加（未スケジュールのスポット）
      unscheduledSpots.forEach(spot => {
        const category = spot.category;
        this.temporarySpots[category].push(spot);
        this.addMarker(spot, category);  // 番号なしで追加
      });
  
      // マップの表示位置を調整
      if (sortedScheduledSpots.length > 0) {
        const firstSpot = sortedScheduledSpots[0];
        const center = {
          lat: parseFloat(firstSpot.lat),
          lng: parseFloat(firstSpot.lng)
        };
        this.map.setCenter(center);
        this.map.setZoom(14);
      }
  
      Object.keys(this.temporarySpots).forEach(category => {
        this.updateSpotsList(category);
      });
    }
  }

  initializeDragAndDrop() {
    console.log('Initializing drag and drop');
  
    // カテゴリー別リストの設定
    [this.sightseeingListTarget, this.restaurantListTarget, this.hotelListTarget].forEach(list => {
      if (!list) return;
      
      console.log('Setting up Sortable for category list:', list);
      
      new Sortable(list, {
        group: {
          name: 'shared',
          pull: 'clone',
          put: false
        },
        sort: false,
        animation: 150,
        ghostClass: 'sortable-ghost',
        onClone: (evt) => {
          const item = evt.item;
          const clone = evt.clone;
          clone.className = item.className;
          clone.dataset.spotId = item.dataset.spotId;
          clone.dataset.category = item.dataset.category;
        }
      });
    });
  
    // スケジュールリストの設定
    this.scheduleListTargets.forEach(scheduleList => {
      new Sortable(scheduleList, {
        group: 'shared',
        animation: 150,
        ghostClass: 'sortable-ghost',
        onSort: (evt) => {
          // ドラッグ&ドロップ完了時に番号を更新
          this.updateAllSpotNumbers();
        }
      });
    });
  }

  updateSpotsList(category) {
    const targetMap = {
      sightseeing: 'sightseeingList',
      restaurant: 'restaurantList',
      hotel: 'hotelList'
    };
  
    const listTarget = this[`${targetMap[category]}Target`];
    if (!listTarget) return;
  
    listTarget.innerHTML = '';
  
    const spots = this.temporarySpots[category]
      .filter(spot => parseInt(spot.travel_id) === parseInt(this.travelIdValue));
  
    spots.forEach((spot, index) => {
      const spotItem = document.createElement('div');
      spotItem.className = 'spot-item card mb-2';  // cardクラスをここで追加
      spotItem.dataset.spotId = spot.id;
      spotItem.dataset.category = category;
  
      // スケジュール情報がある場合はそれも含める
      if (spot.schedule) {
        spotItem.dataset.day = spot.schedule.day_number;
        spotItem.dataset.timeZone = spot.schedule.time_zone;
      }
  
      spotItem.innerHTML = this.generateSpotItemHtml(spot, index, category);
      listTarget.appendChild(spotItem);
    });
  }

  // 全てのスポットの番号を更新するメソッド
  updateAllSpotNumbers() {
    if (!this.scheduleListTargets || this.scheduleListTargets.length === 0) {
      console.warn('Schedule list targets not found');
      return;
    }
  
    console.log('Updating all spot numbers...');
    let spotNumber = 1;
    const processedSpotIds = new Set();
    const days = Array.from({ length: this.totalDaysValue }, (_, i) => i + 1);
    const timeZones = ['morning', 'noon', 'night'];
    const spotOrder = new Map(); // スポットIDと番号のマッピング
  
    // 全てのスケジュールされたスポットを順番に処理
    days.forEach(day => {
      timeZones.forEach(timeZone => {
        this.scheduleListTargets.forEach(list => {
          if (!list) return;
          
          if (parseInt(list.dataset.day) === day && list.dataset.timeZone === timeZone) {
            const items = Array.from(list.querySelectorAll('.spot-item'));
            items.forEach(spotItem => {
              const spotId = spotItem.dataset.spotId;
              if (!processedSpotIds.has(spotId)) {
                const badge = spotItem.querySelector('[data-spot-number]');
                if (badge) {
                  badge.textContent = spotNumber.toString();
                  processedSpotIds.add(spotId);
                  spotOrder.set(spotId, spotNumber); // マップ用に番号を保存
                  spotNumber++;
                }
              }
            });
          }
        });
      });
    });
  
    // マーカーの番号を更新
    this.updateMarkerNumbers(spotOrder);
  }

  deleteFromList(event) {
    const item = event.target.closest('.spot-item');
    if (!item || !confirm('このスポットを削除してもよろしいですか？')) {
      return;
    }
  
    const spotId = item.dataset.spotId;
    const category = item.dataset.category;
  
    if (!this.deletedSpotIds) {
      this.deletedSpotIds = new Set();
    }
    this.deletedSpotIds.add(spotId);
  
    // DOM上の要素を削除
    document.querySelectorAll(`.spot-item[data-spot-id="${spotId}"]`).forEach(card => {
      card.remove();
    });
  
    // temporarySpotsから削除
    if (category && this.temporarySpots[category]) {
      this.temporarySpots[category] = this.temporarySpots[category].filter(
        spot => spot.id.toString() !== spotId.toString()
      );
    }
  
    // マーカーを削除
    this.removeMarker(spotId);
  
    // 番号を振り直す
    this.updateAllSpotNumbers();
  
    event.stopPropagation();
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

  addMarker(spot, category, number = null) {
    console.log('Adding marker for:', spot);
  
    const categoryColors = {
      sightseeing: '#198754',
      restaurant: '#ffc107',
      hotel: '#0dcaf0'
    };
  
    this.removeMarker(spot.id);
  
    try {
      const position = {
        lat: parseFloat(spot.lat),
        lng: parseFloat(spot.lng)
      };
  
      // SVGパスを使用してマーカーを作成
      const markerOptions = {
        position: position,
        map: this.map,
        title: spot.name,
        label: number ? {
          text: number.toString(),
          color: 'white',
          fontSize: '14px',
          fontWeight: 'bold'
        } : null,
        icon: {
          path: 'M 12,2 C 8.1340068,2 5,5.1340068 5,9 c 0,5.25 7,13 7,13 0,0 7,-7.75 7,-13 0,-3.8659932 -3.134007,-7 -7,-7 z',
          fillColor: categoryColors[category],
          fillOpacity: 1.0,
          strokeColor: 'white',
          strokeWeight: 2,
          scale: 2,
          anchor: new google.maps.Point(12, 24),
          labelOrigin: new google.maps.Point(12, 10)  // ラベル（番号）の位置を調整
        }
      };
  
      const marker = new google.maps.Marker(markerOptions);
      marker.spotId = spot.id;
      this.markers.push(marker);
  
      return marker;
    } catch (error) {
      console.error('Error creating marker:', error);
      return null;
    }
  }
  
  // カテゴリーの日本語変換用ヘルパーメソッド
  categoryToJapanese(category) {
    const categories = {
      sightseeing: '観光スポット',
      restaurant: '食事処',
      hotel: '宿泊先'
    };
    return categories[category] || category;
  }

  createMarkerContent(category, number) {
    const colors = {
      sightseeing: '#198754',
      restaurant: '#ffc107',
      hotel: '#0dcaf0'
    };
  
    const div = document.createElement('div');
    div.className = 'custom-marker';
    div.style.backgroundColor = colors[category];
    div.style.borderRadius = '50%';
    div.style.padding = '8px';
    div.style.color = 'white';
    div.style.fontWeight = 'bold';
    div.style.minWidth = '30px';
    div.style.minHeight = '30px';
    div.style.display = 'flex';
    div.style.alignItems = 'center';
    div.style.justifyContent = 'center';
    div.style.border = '2px solid white';
    div.textContent = number;
  
    return div;
  }

  removeMarker(spotId) {
    if (!spotId) return;
  
    console.log('Removing marker for spot:', spotId);
    
    const markerIndex = this.markers.findIndex(marker => 
      marker && marker.spotId && marker.spotId.toString() === spotId.toString()
    );
    
    if (markerIndex !== -1) {
      const marker = this.markers[markerIndex];
      if (marker) {
        console.log('Found marker to remove at index:', markerIndex);
        marker.setMap(null);
        this.markers.splice(markerIndex, 1);
      }
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
          // マーカーのラベルを更新
          marker.setLabel(number ? {
            text: number.toString(),
            color: 'white',
            fontSize: '14px',
            fontWeight: 'bold'
          } : null);
        } catch (error) {
          console.error('Error updating marker label:', error, marker);
        }
      }
    });
  }

  generateSpotItemHtml(spot, index, category) {
    return `
      <div class="spot-item" data-spot-id="${spot.id}" data-category="${category}">
        <div class="card p-2">
          <div class="d-flex justify-content-between align-items-center">
            <div class="d-flex align-items-center">
              <span class="badge bg-${this.getColorClass(category)} me-2" data-spot-number></span>
              <span class="spot-name">${spot.name}</span>
            </div>
            <button type="button" 
                    class="btn btn-outline-danger btn-sm"
                    data-action="spots-registration#deleteFromList">
              <i class="bi bi-trash"></i>
            </button>
          </div>
        </div>
      </div>
    `;
  }

  // 保存ボタンクリック時の処理を修正
  async saveSchedules() {
    // 「保存中...」というメッセージを表示
    const savingMessage = document.createElement('div');
    savingMessage.className = 'position-fixed top-0 start-50 translate-middle-x bg-info text-white p-3 rounded mt-3';
    savingMessage.style.zIndex = '9999';
    savingMessage.textContent = '保存中...';
    document.body.appendChild(savingMessage);
    
    // スケジュール情報を収集
    const schedules = [];
    const deletedSpots = Array.from(this.deletedSpotIds || []);
    
    // スケジュールに追加されたスポットの情報を収集
    this.scheduleListTargets.forEach(list => {
      const day = parseInt(list.dataset.day);
      const timeZone = list.dataset.timeZone;
      
      Array.from(list.children).forEach((spotItem, index) => {
        if (spotItem.style.display === 'none') return;
  
        const spotId = spotItem.dataset.spotId;
        if (!spotId) return;
        
        schedules.push({
          spot_id: spotId,
          day_number: day,
          time_zone: timeZone,
          order_number: index + 1
        });
      });
    });
    
    // アプリケーションロジックの修正: スケジュールに追加されていないスポットも保存できるようにする
    // 各カテゴリのスポットリストが空かどうかを確認
    const hasAnySpots = Object.values(this.temporarySpots).some(spots => spots.length > 0);
    
    if (!hasAnySpots && deletedSpots.length === 0) {
      document.body.removeChild(savingMessage);
      alert('保存するスポットがありません');
      return;
    }
  
    // ここが重要: 空のスケジュールでも正常に動作するように修正
    const saveData = {
      schedules: schedules,
      deleted_spot_ids: deletedSpots
    };
  
    try {
      const response = await fetch(`/travels/${this.travelIdValue}/spots/save_schedules`, {
        method: 'POST',
        headers: {
          'Content-Type': 'application/json',
          'X-CSRF-Token': document.querySelector('[name="csrf-token"]').content
        },
        body: JSON.stringify(saveData)
      });
  
      // 応答が JSON でない場合のエラーハンドリングを追加
      const contentType = response.headers.get("content-type");
      if (!contentType || !contentType.includes("application/json")) {
        throw new Error("サーバーからの応答が不正です。JSON形式ではありません。");
      }
  
      const data = await response.json();
      
      // 保存中...メッセージを削除
      document.body.removeChild(savingMessage);
      
      if (data.success) {
        // 成功メッセージをトースト通知で表示
        this.showToast('success', data.message || 'スケジュールを保存しました');
        
        // 削除されたスポットIDのリストをクリア
        this.deletedSpotIds = new Set();
      } else {
        throw new Error(data.message || '保存に失敗しました');
      }
    } catch (error) {
      console.error('Save error:', error);
      document.body.removeChild(savingMessage);
      alert('保存に失敗しました: ' + error.message);
    }
  }

  // トースト通知を表示するヘルパーメソッド
  showToast(type, message) {
    // トーストコンテナがなければ作成
    let toastContainer = document.querySelector('.toast-container');
    if (!toastContainer) {
      toastContainer = document.createElement('div');
      toastContainer.className = 'toast-container position-fixed top-0 end-0 p-3';
      toastContainer.style.zIndex = '9999';
      document.body.appendChild(toastContainer);
    }
    
    // トーストエレメントを作成
    const toastEl = document.createElement('div');
    toastEl.className = `toast align-items-center ${type === 'success' ? 'bg-success' : 'bg-danger'} text-white border-0`;
    toastEl.setAttribute('role', 'alert');
    toastEl.setAttribute('aria-live', 'assertive');
    toastEl.setAttribute('aria-atomic', 'true');
    
    toastEl.innerHTML = `
      <div class="d-flex">
        <div class="toast-body">
          ${message}
        </div>
        <button type="button" class="btn-close btn-close-white me-2 m-auto" data-bs-dismiss="toast" aria-label="Close"></button>
      </div>
    `;
    
    toastContainer.appendChild(toastEl);
    
    // Bootstrapのトースト機能を初期化
    const toast = new bootstrap.Toast(toastEl, {
      delay: 5000
    });
    toast.show();
    
    // トーストが非表示になったら要素を削除
    toastEl.addEventListener('hidden.bs.toast', () => {
      toastEl.remove();
      // コンテナが空になったら削除
      if (toastContainer.children.length === 0) {
        toastContainer.remove();
      }
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

  getSpotCategory(spotId) {
    for (const category in this.temporarySpots) {
      const spot = this.temporarySpots[category].find(s => s.id.toString() === spotId.toString());
      if (spot) return category;
    }
    return 'sightseeing'; // デフォルト値
  }

  getColorClass(category) {
    switch (category) {
      case 'sightseeing': return 'success';
      case 'restaurant': return 'warning';
      case 'hotel': return 'info';
      default: return 'secondary';
    }
  }

  async sendNotification(event) {
    const notificationType = event.target.dataset.notificationType;
    
    try {
      const response = await fetch(`/travels/${this.travelIdValue}/spots/create_notification`, {
        method: 'POST',
        headers: {
          'Content-Type': 'application/json',
          'X-CSRF-Token': document.querySelector('[name="csrf-token"]').content
        },
        body: JSON.stringify({ notification_type: notificationType })
      });
  
      if (!response.ok) {
        const errorData = await response.json();
        throw new Error(errorData.error || '通知の送信に失敗しました');
      }
  
      const data = await response.json();
      this.showToast('success', data.message || '通知を送信しました');
    } catch (error) {
      console.error('Notification error:', error);
      this.showToast('error', '通知の送信に失敗しました: ' + error.message);
    }
  }

  // マーカーのクリーンアップ
  cleanupMarkers() {
    if (this.markers && Array.isArray(this.markers)) {
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
}
