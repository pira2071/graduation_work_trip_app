require 'rails_helper'

RSpec.describe Schedule, type: :model do
  describe 'associations' do
    it { should belong_to(:spot) }
  end

  describe 'validations' do
    it { should validate_presence_of(:order_number) }
    it { should validate_presence_of(:day_number) }
    it { should validate_presence_of(:time_zone) }
    
    # enumで許可されている値のみを受け入れることを確認
    it 'allows only valid time_zone values' do
      valid_time_zones = %w[morning noon night]
      schedule = build(:schedule)
      
      # 有効な値をテスト
      valid_time_zones.each do |zone|
        expect {
          schedule.time_zone = zone
        }.not_to raise_error
      end
      
      # 検証をより基本的な方法で確認
      schedule = build(:schedule, time_zone: nil)
      expect(schedule).not_to be_valid
      
      schedule = build(:schedule, time_zone: 'morning')
      expect(schedule).to be_valid
      
      # ダミーの値を設定せず、直接モデルの動作を検証
      allow_any_instance_of(Schedule).to receive(:time_zone).and_return('invalid_value')
      schedule = build(:schedule)
      schedule.valid?
      expect(schedule.errors[:time_zone]).to be_present
    end
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
