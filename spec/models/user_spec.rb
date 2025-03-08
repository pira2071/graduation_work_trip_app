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

  describe 'validations' do
    subject { build(:user) }
    
    it { should validate_presence_of(:password) }
    it { should validate_length_of(:password).is_at_least(3) }
    it { should validate_confirmation_of(:password) }
    it { should validate_presence_of(:password_confirmation) }
    it { should validate_presence_of(:email) }
    it { should validate_uniqueness_of(:email) }
    it { should validate_presence_of(:name) }
    it { should validate_length_of(:name).is_at_least(2).is_at_most(50) }
    it { should allow_value('user@example.com').for(:email) }
    it { should_not allow_value('user@').for(:email) }
    it { should_not allow_value('@example.com').for(:email) }
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

  describe '#pending_friend_requests' do
    let(:user) { create(:user) }
    let(:requester) { create(:user) }
    
    context 'when friend request is pending' do
      let!(:pending_request) { create(:friendship, requester: requester, receiver: user, status: 'pending') }
      
      it 'returns the pending request' do
        expect(user.pending_friend_requests).to include(pending_request)
      end
    end
    
    context 'when friend request is accepted' do
      let!(:accepted_request) { create(:friendship, requester: requester, receiver: user, status: 'accepted') }
      
      it 'does not return the accepted request' do
        expect(user.pending_friend_requests).not_to include(accepted_request)
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
