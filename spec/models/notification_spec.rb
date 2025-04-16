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
    describe '.recent' do
      it 'orders notifications by created_at in descending order' do
        # スコープの実装だけをテスト
        scope_relation = Notification.recent

        # SQL文を検証して、ORDER BY created_at DESC が含まれていることを確認
        expect(scope_relation.to_sql).to include("ORDER BY \"notifications\".\"created_at\" DESC")
      end
    end
  end
end
