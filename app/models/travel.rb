class Travel < ApplicationRecord
  belongs_to :user
  has_many :travel_members, dependent: :destroy
  has_many :members, through: :travel_members, source: :user
  has_many :spots, dependent: :destroy
  has_many :travel_reviews, dependent: :destroy
  has_many :photos, dependent: :destroy
  has_many :notifications, as: :notifiable, dependent: :destroy
  has_many :travel_shares, dependent: :destroy
  mount_uploader :thumbnail, ThumbnailUploader

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
    # 通知ではなく travel_shares の存在をチェック
    travel_shares.exists?
  end

  # 通知作成時に共有状態を設定するメソッドを追加
  def mark_as_shared!
    # 本来はDBカラムを更新すべきですが、一時的な対応としてキャッシュを使用
    @is_shared = true
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
    travel_members.where(role: :guest).pluck(:name).join("、")
  end
end
