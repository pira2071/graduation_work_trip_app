require 'rails_helper'

RSpec.describe PackingItem, type: :model do
  describe 'associations' do
    it { should belong_to(:packing_list) }
  end

  describe 'validations' do
    it { should validate_presence_of(:name) }
  end
end
