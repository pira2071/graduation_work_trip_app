class Notification < ApplicationRecord
  belongs_to :recipient, class_name: 'User'
  belongs_to :notifiable, polymorphic: true

  validates :action, presence: true
  validates :recipient_id, presence: true

  scope :recent, -> { order(created_at: :desc) }
end
