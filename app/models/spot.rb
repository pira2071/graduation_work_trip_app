class Spot < ApplicationRecord
  belongs_to :travel
  has_one :schedule, dependent: :destroy

  enum category: { sightseeing: 0, restaurant: 1, hotel: 2 }
  
  validates :name, :category, presence: true
  validates :lat, :lng, presence: true, if: :google_maps_spot?
  validates :order_number, presence: true, numericality: { only_integer: true, greater_than: 0 }
  validates :time_zone, inclusion: { in: %w(morning noon night) }, allow_nil: true
  validates :schedule, presence: true, if: :schedule_required?

  private

  def google_maps_spot?
    # Google Mapsから取得したスポットの場合にのみ位置情報を必須とする
    lat.present? || lng.present?
  end

  def schedule_required?
    day_number.present? || time_zone.present?
  end
end
