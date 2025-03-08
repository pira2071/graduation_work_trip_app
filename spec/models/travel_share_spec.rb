require 'rails_helper'

RSpec.describe TravelShare, type: :model do
  describe 'associations' do
    it { should belong_to(:travel) }
  end

  describe 'validations' do
    it { should validate_presence_of(:travel_id) }
    it { should validate_presence_of(:notification_type) }
  end
end
