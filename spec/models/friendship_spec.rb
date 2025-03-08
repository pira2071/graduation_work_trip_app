require 'rails_helper'

RSpec.describe Friendship, type: :model do
  describe 'associations' do
    it { should belong_to(:requester).class_name('User') }
    it { should belong_to(:receiver).class_name('User') }
    it { should have_many(:notifications).dependent(:destroy) }
  end

  describe 'validations' do
    let(:user1) { create(:user) }
    let(:user2) { create(:user) }
    
    subject { build(:friendship, requester: user1, receiver: user2) }
    
    it { should validate_uniqueness_of(:requester_id).scoped_to(:receiver_id) }
    it { should validate_inclusion_of(:status).in_array(%w[pending accepted rejected]) }
  end

  describe 'scopes' do
    let!(:pending_friendship) { create(:friendship, status: 'pending') }
    let!(:accepted_friendship) { create(:friendship, status: 'accepted') }
    
    describe '.pending' do
      it 'returns pending friendships' do
        expect(Friendship.pending).to include(pending_friendship)
        expect(Friendship.pending).not_to include(accepted_friendship)
      end
    end
    
    describe '.accepted' do
      it 'returns accepted friendships' do
        expect(Friendship.accepted).to include(accepted_friendship)
        expect(Friendship.accepted).not_to include(pending_friendship)
      end
    end
  end

  describe 'callbacks' do
    describe 'after_create' do
      it 'creates a notification for the receiver' do
        friendship = build(:friendship)
        expect { friendship.save }.to change(Notification, :count).by(1)
        
        notification = Notification.last
        expect(notification.recipient).to eq(friendship.receiver)
        expect(notification.notifiable).to eq(friendship)
        expect(notification.action).to eq('friend_request')
      end
    end
  end
end
