import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["map", "sightseeingList", "restaurantList", "hotelList"]
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

    this.markers.push(newMarker);
    return newMarker;
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
