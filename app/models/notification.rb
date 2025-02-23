class Notification < ApplicationRecord
  belongs_to :recipient, class_name: 'User'
  belongs_to :notifiable, polymorphic: true

  validates :action, presence: true
  validates :recipient_id, presence: true

  scope :unread, -> { where(read: false) }
  scope :recent, -> { order(created_at: :desc).limit(10) }

  def mark_as_read!
    update!(read: true, read_at: Time.current)
  end
end
