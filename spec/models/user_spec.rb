require 'rails_helper'

RSpec.describe User, type: :model do
  describe 'associations' do
    it { should have_many(:organized_travels).class_name('Travel').with_foreign_key('user_id') }
    it { should have_many(:travel_members) }
    it { should have_many(:participating_travels).through(:travel_members).source(:travel) }
    it { should have_many(:packing_lists).dependent(:destroy) }
    it { should have_many(:photos).dependent(:destroy) }
    it { should have_many(:requested_friendships).class_name('Friendship').with_foreign_key('requester_id').dependent(:destroy) }
    it { should have_many(:received_friendships).class_name('Friendship').with_foreign_key('receiver_id').dependent(:destroy) }
    it { should have_many(:notifications).with_foreign_key(:recipient_id).dependent(:destroy) }
  end

  describe "validations" do
    # パスワードのバリデーションを修正
    it "validates presence of password with custom message" do
      user = User.new(password: nil)
      user.valid?
      expect(user.errors[:password]).to include("は3文字以上で入力してください")
    end

    # パスワードの長さバリデーション（これは問題なし）
    it { should validate_length_of(:password).is_at_least(3) }

    it { should validate_confirmation_of(:password) }
    it { should validate_presence_of(:password_confirmation).with_message("を入力してください") }

    # メールアドレスのバリデーション
    it { should validate_presence_of(:email).with_message("を入力してください") }
    it { should validate_uniqueness_of(:email).with_message("はすでに使用されています") }

    # 名前のバリデーションを修正
    it "validates length of name with custom message" do
      user = User.new(name: "a")  # 1文字は短すぎる
      user.valid?
      expect(user.errors[:name]).to include("は2〜50文字で入力してください")

      user = User.new(name: "a" * 51)  # 51文字は長すぎる
      user.valid?
      expect(user.errors[:name]).to include("は2〜50文字で入力してください")
    end

    it { should validate_presence_of(:name).with_message("を入力してください") }

    # メールフォーマットのテスト
    it { should allow_value("user@example.com").for(:email) }
    it { should_not allow_value("user@").for(:email) }
    it { should_not allow_value("@example.com").for(:email) }
  end

  describe '#friends' do
    let(:user) { create(:user) }
    let(:friend) { create(:user) }

    context 'when friendship is accepted' do
      before do
        create(:friendship, requester: user, receiver: friend, status: 'accepted')
      end

      it 'returns the friend' do
        expect(user.friends).to include(friend)
      end
    end

    context 'when friendship is pending' do
      before do
        create(:friendship, requester: user, receiver: friend, status: 'pending')
      end

      it 'does not return the friend' do
        expect(user.friends).not_to include(friend)
      end
    end
  end

  describe "#pending_friend_requests" do
    context "when friend request is pending" do
      let(:user) { create(:user, name: "受信者") }
      let(:friend) { create(:user, name: "送信者") }

      before do
        create(:friendship, requester: friend, receiver: user, status: 'pending')
      end

      it "returns the pending request" do
        expect(user.pending_friend_requests).to include(
          have_attributes(requester: friend, receiver: user, status: 'pending')
        )
      end
    end

    context "when friend request is accepted" do
      let(:user) { create(:user, name: "受信者2") }
      let(:friend) { create(:user, name: "送信者2") }

      before do
        create(:friendship, requester: friend, receiver: user, status: 'accepted')
      end

      it "does not return the accepted request" do
        expect(user.pending_friend_requests).not_to include(
          have_attributes(requester: friend, receiver: user, status: 'accepted')
        )
      end
    end
  end

  describe '#all_travels' do
    let(:user) { create(:user) }
    let(:organized_travel) { create(:travel, user: user) }
    let(:participated_travel) { create(:travel) }

    before do
      create(:travel_member, travel: participated_travel, user: user)
    end

    it 'returns both organized and participating travels' do
      expect(user.all_travels).to include(organized_travel, participated_travel)
    end
  end
end
