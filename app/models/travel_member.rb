class TravelMember < ApplicationRecord
  belongs_to :travel
  belongs_to :user, optional: true

  enum role: { guest: 0, organizer: 1 }

  validates :name, presence: true, unless: -> { user_id.present? }
end
