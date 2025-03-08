require 'rails_helper'

RSpec.describe TravelMember, type: :model do
  describe 'associations' do
    it { should belong_to(:travel) }
    it { should belong_to(:user).optional }
  end

  describe 'validations' do
    let(:travel) { create(:travel) }
    let(:user) { create(:user) }
    
    subject { build(:travel_member, travel: travel, user: user) }
    
    it { should validate_uniqueness_of(:user_id).scoped_to(:travel_id).allow_nil }
    
    context 'when user_id is not present' do
      subject { build(:travel_member, travel: travel, user: nil) }
      
      it { should validate_presence_of(:name) }
    end
  end

  describe 'enums' do
    it 'defines role enum' do
      should define_enum_for(:role).with_values(guest: 0, organizer: 1)
    end
  end
end
