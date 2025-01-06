import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["map", "sightseeingList", "restaurantList", "hotelList"]
  static values = {
    travelId: String,
    totalDays: Number,
    existingSpots: { type: Array, default: [] }
  }

  connect() {
    console.log('SpotsRegistrationController connected');
    this.setupEventListeners();
    
    // temporarySpotsの初期化を追加
    this.temporarySpots = {
      sightseeing: [],
      restaurant: [],
      hotel: []
    };
    
    this.markers = [];  // markersの初期化も追加
    
    // Google Maps APIの状態をリセット
    if (window.google && window.google.maps) {
      delete window.google.maps;
      delete window.google;
    }
    
    // イベントリスナーを一旦削除して再追加
    window.removeEventListener('spots-map-loaded', this.initializeMap.bind(this));
    window.addEventListener('spots-map-loaded', () => {
      console.log('Spots map loaded event received');
      this.initializeMap();
    });
  }
  
  disconnect() {
    this.cleanupSpots();
    this.removeEventListeners();
    
    // Google Maps APIの状態をクリア
    if (window.google && window.google.maps) {
      if (this.autocomplete) {
        google.maps.event.clearInstanceListeners(this.autocomplete);
      }
      if (this.map) {
        google.maps.event.clearInstanceListeners(this.map);
      }
      delete window.google.maps;
      delete window.google;
    }
  }

  setupEventListeners() {
    this.boundCleanup = this.cleanupSpots.bind(this);
    
    document.addEventListener('turbo:before-visit', this.boundCleanup);
    document.addEventListener('turbo:before-cache', this.boundCleanup);
    document.addEventListener('turbo:before-render', this.boundCleanup);
    window.addEventListener('beforeunload', this.boundCleanup);
    window.addEventListener('popstate', this.boundCleanup);
  }
  
  removeEventListeners() {
    document.removeEventListener('turbo:before-visit', this.boundCleanup);
    document.removeEventListener('turbo:before-cache', this.boundCleanup);
    document.removeEventListener('turbo:before-render', this.boundCleanup);
    window.removeEventListener('beforeunload', this.boundCleanup);
    window.removeEventListener('popstate', this.boundCleanup);
  }

  initializeMap() {
    console.log('Initializing map and autocomplete...');
    if (typeof google === 'undefined') {
      console.log('Waiting for Google Maps to load...');
      window.addEventListener('google-maps-loaded', () => this.setupMap());
      return;
    }
    this.setupMap();
  }
  
  setupMap() {
    console.log('Setting up map and autocomplete...');
    try {
      this.map = new google.maps.Map(this.mapTarget, {
        center: { lat: 35.6812, lng: 139.7671 },
        zoom: 12,
      });
  
      const input = document.getElementById("pac-input");
      if (!input) {
        console.error('Search input element not found');
        return;
      }
  
      this.autocomplete = new google.maps.places.Autocomplete(input);
      this.autocomplete.bindTo("bounds", this.map);
  
      // place_changedイベントリスナーを追加
      this.autocomplete.addListener("place_changed", () => {
        console.log('Place changed event fired');
        this.handlePlaceSelection();
      });
  
      console.log('Autocomplete initialized successfully');
  
      // 既存のスポットがあれば読み込む
      if (this.hasExistingSpotsValue) {
        this.loadExistingSpots();
      }
  
    } catch (error) {
      console.error('Error in setupMap:', error);
    }
  }

  handlePlaceSelection() {
    if (this.marker) {
      this.marker.setMap(null);
    }

    const place = this.autocomplete.getPlace();
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

    this.marker = new google.maps.Marker({
      map: this.map,
      position: place.geometry.location,
      title: place.name
    });
  }

  loadExistingSpots() {
    if (this.hasExistingSpotsValue) {
      this.existingSpotsValue.forEach(spot => {
        if (parseInt(spot.travel_id) === parseInt(this.travelIdValue)) {
          const category = spot.category;
          this.temporarySpots[category].push(spot);
          if (this.map) {  // マップが初期化されている場合のみマーカーを追加
            this.addMarker(spot, category, spot.order_number);
          }
        }
      });
  
      Object.keys(this.temporarySpots).forEach(category => {
        this.updateSpotsList(category);
      });
    }
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
    // travel_idの値が正しく取得できていることを確認するためのデバッグログ
    console.log('Travel ID:', this.travelIdValue);
    
    // URLを構築する際にトラベルIDが存在することを確認
    if (!this.travelIdValue) {
      console.error('Travel ID is missing');
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
      console.error('Registration error:', error);
      alert(error.message);
    });
  }

  handleSuccessfulRegistration(spot, category) {
    this.temporarySpots[category].push(spot);
    this.updateSpotsList(category);
    this.addMarker(spot, category, spot.order_number);
    
    document.getElementById("pac-input").value = '';
    this.selectedPlace = null;
    if (this.marker) this.marker.setMap(null);
    
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

    this.markers.push(newMarker);
    return newMarker;
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

  generateSpotItemHtml(spot, index, category, dayOptions) {
    return `
      <div class="card-body">
        <div class="d-flex align-items-center mb-2">
          <span class="badge bg-${this.getColorClass(category)} me-2">${index + 1}</span>
          <span class="flex-grow-1">${spot.name}</span>
        </div>
        <div class="schedule-selectors d-flex gap-2">
          <select class="form-select form-select-sm day-select" data-spot-id="${spot.id}">
            <option value="">日付選択</option>
            ${dayOptions}
          </select>
          <select class="form-select form-select-sm time-select" data-spot-id="${spot.id}">
            <option value="">時間帯選択</option>
            <option value="morning" ${spot.time_zone === 'morning' ? 'selected' : ''}>朝</option>
            <option value="noon" ${spot.time_zone === 'noon' ? 'selected' : ''}>昼</option>
            <option value="night" ${spot.time_zone === 'night' ? 'selected' : ''}>夜</option>
          </select>
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
      console.error('Save error:', error);
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

  cleanupSpots() {
    console.log('Cleaning up spots...');
    if (this.marker) {
      this.marker.setMap(null);
    }
  
    if (this.markers && this.markers.length > 0) {
      this.markers.forEach(marker => {
        if (marker) marker.setMap(null);
      });
      this.markers = [];
    }
  
    if (this.autocomplete) {
      google.maps.event.clearInstanceListeners(this.autocomplete);
      this.autocomplete = null;
    }
  
    if (this.map) {
      google.maps.event.clearInstanceListeners(this.map);
      this.map = null;
    }
  
    this.temporarySpots = {
      sightseeing: [],
      restaurant: [],
      hotel: []
    };
  
    const input = document.getElementById("pac-input");
    if (input) {
      input.value = '';
    }
  }

  cleanupServerData() {
    fetch(`/travels/${this.travelIdValue}/spots/cleanup`, {
      method: 'POST',
      headers: {
        'Content-Type': 'application/json',
        'X-CSRF-Token': document.querySelector('[name="csrf-token"]').content
      }
    }).catch(error => console.error('Cleanup error:', error));
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
