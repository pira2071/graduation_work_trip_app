require 'rails_helper'

RSpec.describe TravelReview, type: :model do
  describe 'associations' do
    it { should belong_to(:travel) }
    it { should belong_to(:user) }
  end

  describe 'validations' do
    it { should validate_presence_of(:content) }
  end
end
