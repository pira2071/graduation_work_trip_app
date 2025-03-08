require 'rails_helper'

RSpec.describe Notification, type: :model do
  describe 'associations' do
    it { should belong_to(:recipient).class_name('User') }
    it { should belong_to(:notifiable) }
  end

  describe 'validations' do
    it { should validate_presence_of(:action) }
    it { should validate_presence_of(:recipient_id) }
  end

  describe 'scopes' do
    let!(:notification1) { create(:notification, created_at: 1.day.ago) }
    let!(:notification2) { create(:notification, created_at: Time.current) }
    
    describe '.recent' do
      it 'returns notifications in descending order of creation' do
        expect(Notification.recent).to eq([notification2, notification1])
      end
    end
  end
end
