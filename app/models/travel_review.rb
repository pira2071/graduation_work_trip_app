class TravelReview < ApplicationRecord
  belongs_to :travel
  belongs_to :user

  validates :content, presence: true
end
