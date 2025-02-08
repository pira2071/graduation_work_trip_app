class Friendship < ApplicationRecord
  belongs_to :requester, class_name: 'User'
  belongs_to :receiver, class_name: 'User'

  validates :requester_id, uniqueness: { scope: :receiver_id }
  validates :status, inclusion: { in: %w[pending accepted rejected] }

  scope :pending, -> { where(status: 'pending') }
  scope :accepted, -> { where(status: 'accepted') }
end
