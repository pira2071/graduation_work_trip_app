require 'rails_helper'

RSpec.describe Contact, type: :model do
  describe 'validations' do
    it { should validate_presence_of(:name) }
    it { should validate_presence_of(:email) }
    it { should validate_presence_of(:subject) }
    it { should validate_presence_of(:message) }
    
    it { should validate_length_of(:name).is_at_most(50) }
    it { should validate_length_of(:email).is_at_most(255) }
    it { should validate_length_of(:subject).is_at_most(100) }
    it { should validate_length_of(:message).is_at_most(2000) }
    
    it { should allow_value('user@example.com').for(:email) }
    it { should_not allow_value('user@').for(:email) }
    it { should_not allow_value('@example.com').for(:email) }
  end

  describe '#no_dangerous_patterns' do
    # Note: This would require actual implementation of SecurityPatterns module or stubbing it
    it 'validates against dangerous patterns'
  end
end
