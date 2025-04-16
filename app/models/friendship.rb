class Friendship < ApplicationRecord
  belongs_to :requester, class_name: "User"
  belongs_to :receiver, class_name: "User"
  has_many :notifications, as: :notifiable, dependent: :destroy

  validates :requester_id, uniqueness: { scope: :receiver_id }
  validates :status, inclusion: { in: %w[pending accepted rejected] }

  scope :pending, -> { where(status: "pending") }
  scope :accepted, -> { where(status: "accepted") }

  # フレンド申請時に通知を作成するメソッドを追加
  after_create :create_request_notification

  private

  def create_request_notification
    notifications.create!(
      recipient: receiver,
      action: "friend_request",
      read: false
    )
  rescue => e
    Rails.logger.error "Failed to create notification: #{e.message}"
    # 通知の作成に失敗しても、フレンド申請自体は継続させる
    true
  end
end
