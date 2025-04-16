require 'rails_helper'

RSpec.describe Travel, type: :model do
  describe 'associations' do
    it { should belong_to(:user) }
    it { should have_many(:travel_members).dependent(:destroy) }
    it { should have_many(:members).through(:travel_members).source(:user) }
    it { should have_many(:spots).dependent(:destroy) }
    it { should have_many(:travel_reviews).dependent(:destroy) }
    it { should have_many(:photos).dependent(:destroy) }
    it { should have_many(:notifications).dependent(:destroy) }
    it { should have_many(:travel_shares).dependent(:destroy) }
  end

  describe 'validations' do
    it { should validate_presence_of(:title) }
    it { should validate_presence_of(:start_date) }
    it { should validate_presence_of(:end_date) }

    context 'end_date_after_start_date' do
      let(:travel) { build(:travel, start_date: Date.current, end_date: Date.current - 1.day) }

      it 'is invalid if end_date is before start_date' do
        expect(travel).not_to be_valid
        expect(travel.errors[:end_date]).to include('は開始日より後の日付にしてください')
      end
    end
  end

  describe '#shared?' do
    let(:travel) { create(:travel) }

    context 'when travel has travel_shares' do
      before do
        create(:travel_share, travel: travel)
      end

      it 'returns true' do
        expect(travel.shared?).to be_truthy
      end
    end

    context 'when travel has no travel_shares' do
      it 'returns false' do
        expect(travel.shared?).to be_falsey
      end
    end
  end

  describe '#mark_as_shared!' do
    let(:travel) { create(:travel) }

    it 'sets @is_shared to true' do
      travel.mark_as_shared!
      expect(travel.instance_variable_get(:@is_shared)).to be_truthy
    end
  end
end
