class Schedule < ApplicationRecord
  belongs_to :spot

  # time_zoneの定義を文字列ベースに修正
  enum time_zone: {
    "morning" => "morning",
    "noon" => "noon",
    "night" => "night"
  }, _prefix: true

  validates :order_number, :day_number, presence: true
  validates :time_zone, presence: true, inclusion: { in: time_zones.keys }

  # スコープを追加
  scope :ordered, -> { order(day_number: :asc).order(order_number: :asc) }
end
