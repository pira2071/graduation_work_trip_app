require 'rails_helper'

RSpec.describe Schedule, type: :model do
  describe 'associations' do
    it { should belong_to(:spot) }
  end

  describe 'validations' do
    it { should validate_presence_of(:order_number) }
    it { should validate_presence_of(:day_number) }
    it { should validate_presence_of(:time_zone) }
    it { should validate_inclusion_of(:time_zone).in_array(Schedule.time_zones.keys) }
  end

  describe 'enums' do
    it 'defines time_zone enum' do
      expect(Schedule.time_zones).to include(
        'morning' => 'morning',
        'noon' => 'noon',
        'night' => 'night'
      )
    end
  end

  describe 'scopes' do
    let!(:schedule1) { create(:schedule, day_number: 1, order_number: 2) }
    let!(:schedule2) { create(:schedule, day_number: 1, order_number: 1) }
    let!(:schedule3) { create(:schedule, day_number: 2, order_number: 1) }
    
    describe '.ordered' do
      it 'returns schedules ordered by day_number and order_number' do
        expect(Schedule.ordered).to eq([schedule2, schedule1, schedule3])
      end
    end
  end
end
