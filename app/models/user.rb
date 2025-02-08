class User < ApplicationRecord
  authenticates_with_sorcery!

  has_many :organized_travels, class_name: 'Travel', foreign_key: 'user_id'
  has_many :travel_members
  has_many :participating_travels, through: :travel_members, source: :travel

  validates :password, length: { minimum: 3 }, if: -> { new_record? || changes[:crypted_password] }
  validates :password, confirmation: true, if: -> { new_record? || changes[:crypted_password] }
  validates :password_confirmation, presence: true, if: -> { new_record? || changes[:crypted_password] }
  validates :email, presence: true, uniqueness: true
  validates :name, presence: true

  has_many :requested_friendships, 
           class_name: 'Friendship',
           foreign_key: 'requester_id',
           dependent: :destroy
  has_many :received_friendships,
           class_name: 'Friendship',
           foreign_key: 'receiver_id',
           dependent: :destroy
  
  # フレンドを取得するためのメソッド
  def friends
    friend_ids = Friendship.accepted
                          .where('requester_id = ? OR receiver_id = ?', id, id)
                          .pluck(:requester_id, :receiver_id)
                          .flatten
                          .uniq
    User.where(id: friend_ids).where.not(id: id)
  end

  # 保留中のフレンド申請を取得
  def pending_friend_requests
    received_friendships.pending
  end

  # すべての関連する旅行を取得するメソッド
  def all_travels
    Travel.where('user_id = :user_id OR id IN (:participating_ids)', 
                user_id: id, 
                participating_ids: participating_travels.pluck(:id))
  end
end
