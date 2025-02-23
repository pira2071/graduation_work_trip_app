class NotificationsController < ApplicationController
  before_action :require_login

  def index
    @notifications = current_user.notifications.order(created_at: :desc)
    render json: format_notifications(@notifications)
  end

  def destroy
    notification = current_user.notifications.find(params[:id])
    notification.destroy
    render json: { success: true }
  end

  private

  def format_notifications(notifications)
    notifications.map do |notification|
      {
        id: notification.id,
        action: notification.action,
        created_at: notification.created_at.strftime("%Y/%m/%d %H:%M"),
        url: notification_url(notification),
        message: notification_message(notification)
      }
    end
  end

  def notification_url(notification)
    case notification.action
    when 'friend_request'
      friendships_path
    when 'itinerary_proposed', 'itinerary_modified', 'itinerary_confirmed'  # 新しい通知タイプを追加
      new_travel_spot_path(notification.notifiable)
    else
      root_path
    end
  end

  def notification_message(notification)
    case notification.action
    when 'friend_request'
      "#{notification.notifiable.requester.name}さんから友達申請が届いています"
    when 'friend_request_accepted'
      "#{notification.notifiable.receiver.name}さんがあなたの友達申請を承認しました"
    when 'itinerary_proposed'
      "旅程表が提出されました。確認してレビューしてください。"
    when 'itinerary_modified'
      "旅程表が修正されました。確認してレビューしてください。"
    when 'itinerary_confirmed'
      "旅程表が確定しました。確認してください。"
    else
      "旅程表が更新されました"
    end
  end
end
