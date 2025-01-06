class Schedule < ApplicationRecord
  belongs_to :spot
  enum time_zone: { morning: 0, noon: 1, night: 2 }
  validates :order_number, presence: true
  validates :day_number, presence: true
  validates :time_zone, presence: true
end
