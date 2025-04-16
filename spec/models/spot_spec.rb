require 'rails_helper'

RSpec.describe Spot, type: :model do
  describe 'associations' do
    it { should belong_to(:travel) }
    it { should have_one(:schedule).dependent(:destroy) }
  end

  describe 'validations' do
    it { should validate_presence_of(:name) }
    it { should validate_presence_of(:category) }
    it { should validate_presence_of(:order_number) }

    context 'when google_maps_spot' do
      subject { build(:spot, lat: nil, lng: nil) }

      before do
        allow(subject).to receive(:google_maps_spot?).and_return(true)
      end

      it { should validate_presence_of(:lat) }
      it { should validate_presence_of(:lng) }
    end
  end

  describe 'enums' do
    it 'defines category enum' do
      should define_enum_for(:category).with_values(sightseeing: 0, restaurant: 1, hotel: 2)
    end
  end

  describe 'scopes' do
    let!(:spot_with_schedule) { create(:spot, :with_schedule) }
    let!(:spot_without_schedule) { create(:spot) }

    describe '.with_schedule' do
      it 'returns spots with schedules' do
        expect(Spot.with_schedule).to include(spot_with_schedule)
        expect(Spot.with_schedule).not_to include(spot_without_schedule)
      end
    end
  end

  describe '#schedule_details' do
    let(:spot) { create(:spot, :with_schedule) }

    it 'returns schedule attributes' do
      expect(spot.schedule_details).to include(
        'day_number' => spot.schedule.day_number,
        'time_zone' => spot.schedule.time_zone,
        'order_number' => spot.schedule.order_number
      )
    end
  end
end
