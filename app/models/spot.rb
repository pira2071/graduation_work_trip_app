class Spot < ApplicationRecord
  belongs_to :travel
  has_one :schedule, dependent: :destroy

  enum category: { sightseeing: 0, restaurant: 1, hotel: 2 }
  
  validates :name, :category, presence: true
  validates :lat, :lng, presence: true, if: :google_maps_spot?
  validates :order_number, presence: true, numericality: { only_integer: true, greater_than: 0 }

  # スコープを追加
  scope :with_schedule, -> { includes(:schedule).where.not(schedules: { id: nil }) }
  scope :ordered_by_schedule, -> { 
    joins(:schedule)
      .order('schedules.day_number ASC')
      .order('schedules.time_zone ASC')
      .order('schedules.order_number ASC')
  }

  def schedule_details
    schedule&.attributes&.slice('day_number', 'time_zone', 'order_number')
  end

  private

  def google_maps_spot?
    lat.present? || lng.present?
  end
end
