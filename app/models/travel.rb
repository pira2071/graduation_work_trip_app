class Travel < ApplicationRecord
  belongs_to :user
  has_many :travel_members, dependent: :destroy
  has_many :members, through: :travel_members, source: :user
  has_many :spots, dependent: :destroy
  has_many :travel_reviews, dependent: :destroy
  has_many :photos, dependent: :destroy
  has_many :notifications, as: :notifiable, dependent: :destroy

  validates :title, presence: true
  validates :start_date, presence: true
  validates :end_date, presence: true
  validate :end_date_after_start_date

  attr_accessor :member_names

  def self.ransackable_attributes(auth_object = nil)
    %w[title]
  end

  def self.ransackable_associations(auth_object = nil)
    []
  end

  def shared?
    notifications.exists?(action: ['itinerary_proposed', 'itinerary_modified', 'itinerary_confirmed'])
  end

  private

  def end_date_after_start_date
    return if end_date.blank? || start_date.blank?
    if end_date < start_date
      errors.add(:end_date, "は開始日より後の日付にしてください")
    end
  end

  # 既存のメンバーの名前を、で区切った文字列で返すメソッド
  def member_names_string
    travel_members.where(role: :guest).pluck(:name).join('、')
  end
end
