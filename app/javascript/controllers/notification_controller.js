import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["count", "list"]
  static values = {
    pollInterval: { type: Number, default: 5000 }
  }

  connect() {
    this.loadNotifications()
    this.startPolling()
  }

  disconnect() {
    this.stopPolling()
  }

  async loadNotifications() {
    try {
      const response = await fetch('/notifications')
      const notifications = await response.json()
      this.updateNotificationCount(notifications)
      this.updateNotificationList(notifications)
    } catch (error) {
      console.error("Error loading notifications:", error)
    }
  }

  updateNotificationCount(notifications) {
    const count = notifications.length
    this.countTarget.textContent = count || ''
    this.countTarget.classList.toggle('d-none', count === 0)
  }

  updateNotificationList(notifications) {
    const list = this.listTarget
    if (notifications.length === 0) {
      list.innerHTML = '<div class="dropdown-item text-muted">通知はありません</div>'
      return
    }

    list.innerHTML = notifications
      .map(notification => this.renderNotification(notification))
      .join('')
  }

  renderNotification(notification) {
    return `
      <a href="${notification.url}" 
         class="dropdown-item"
         data-notification-id="${notification.id}"
         data-action="click->notification#handleNotificationClick">
        <div class="d-flex align-items-center">
          <div class="flex-grow-1">
            <div class="notification-message">${notification.message}</div>
            <small class="text-muted">${notification.created_at}</small>
          </div>
        </div>
      </a>
    `
  }

  async handleNotificationClick(event) {
    event.preventDefault()
    const notificationId = event.currentTarget.dataset.notificationId
    const url = event.currentTarget.href
    
    // URLにパラメータを追加
    const finalUrl = new URL(url, window.location.origin);
    finalUrl.searchParams.append('from_notification', 'true');
  
    try {
      const response = await fetch(`/notifications/${notificationId}`, {
        method: 'DELETE',
        headers: {
          'X-CSRF-Token': document.querySelector('[name="csrf-token"]').content,
          'Content-Type': 'application/json'
        }
      })
  
      if (response.ok) {
        // 通知削除後に通知一覧を更新
        await this.loadNotifications()
        // パラメータを追加したURLに遷移
        window.location.href = finalUrl.toString()
      }
    } catch (error) {
      console.error("Error deleting notification:", error)
      // エラーが発生しても遷移は実行
      window.location.href = finalUrl.toString()
    }
  }

  startPolling() {
    this.pollingId = setInterval(() => {
      this.loadNotifications()
    }, this.pollIntervalValue)
  }

  stopPolling() {
    if (this.pollingId) {
      clearInterval(this.pollingId)
    }
  }
}
