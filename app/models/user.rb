class User < ApplicationRecord
  authenticates_with_sorcery!

  has_many :organized_travels, class_name: "Travel", foreign_key: "user_id"
  has_many :travel_members
  has_many :participating_travels, through: :travel_members, source: :travel
  has_many :packing_lists, dependent: :destroy
  has_many :photos, dependent: :destroy

  validates :password, length: { minimum: 3 }, if: -> { new_record? || changes[:crypted_password] }
  validates :password, confirmation: true, if: -> { new_record? || changes[:crypted_password] }
  validates :password_confirmation, presence: true, if: -> { new_record? || changes[:crypted_password] }
  # validates :reset_password_token, uniqueness: true, allow_nil: true
  validates :reset_password_token, uniqueness: true, allow_nil: true, if: -> { respond_to?(:reset_password_token) }
  validates :email,
            presence: { message: "を入力してください" },
            uniqueness: { message: "はすでに使用されています" },
            format: {
              with: URI::MailTo::EMAIL_REGEXP,
              message: "は正しい形式で入力してください"
            }
  validates :name,
            presence: { message: "を入力してください" },
            length: {
              minimum: 2,
              maximum: 50,
              message: "は2〜50文字で入力してください"
            }

  has_many :requested_friendships,
           class_name: "Friendship",
           foreign_key: "requester_id",
           dependent: :destroy
  has_many :received_friendships,
           class_name: "Friendship",
           foreign_key: "receiver_id",
           dependent: :destroy
  has_many :notifications,
           foreign_key: :recipient_id,
           dependent: :destroy

  # フレンドを取得するためのメソッド
  def friends
    friend_ids = Friendship.accepted
                          .where("requester_id = ? OR receiver_id = ?", id, id)
                          .pluck(:requester_id, :receiver_id)
                          .flatten
                          .uniq
    User.where(id: friend_ids).where.not(id: id)
  end

  # パスワードリセット用のメソッド
  def deliver_reset_password_instructions!
    temp_token = SecureRandom.uuid
    self.reset_password_token = temp_token
    self.reset_password_token_expires_at = 24.hours.from_now
    save!

    UserMailer.reset_password_email(self).deliver_now
  end

  # 保留中のフレンド申請を取得するメソッド
  def pending_friend_requests
    received_friendships.pending
  end

  # すべての関連する旅行を取得するメソッド
  def all_travels
    Travel.where("user_id = :user_id OR id IN (:participating_ids)",
                user_id: id,
                participating_ids: participating_travels.pluck(:id))
  end

  # 未読の通知を取得するメソッド
  def unread_notifications_count
    notifications.unread.count
  end

  # Googleログイン用のメソッド
  def self.from_omniauth(auth)
    # まずメールアドレスでユーザーを検索
    user = find_by(email: auth.info.email)

    if user
      # 既存ユーザーの場合はprovider/uidを更新してユーザーを返す
      user.update(
        provider: auth.provider,
        uid: auth.uid
      )
      user
    else
      # 新規ユーザー作成（ユーザーがいない場合）
      where(provider: auth.provider, uid: auth.uid).first_or_initialize do |user|
        user.email = auth.info.email
        user.name = auth.info.name
        # ランダムパスワードを設定
        user.password = SecureRandom.hex(10)
        user.password_confirmation = user.password
      end
    end
  end
end
