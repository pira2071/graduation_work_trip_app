class Photo < ApplicationRecord
  belongs_to :travel
  belongs_to :user

  mount_uploader :image, ImageUploader

  validates :image, presence: true
  validates :day_number, presence: true

  # デバッグ用のコールバックを追加
  after_initialize do
    Rails.logger.debug "Photo initialized with attributes: #{attributes.inspect}"
  end

  before_save do
    Rails.logger.debug "Saving photo with image: #{image.inspect}"
  end
end
