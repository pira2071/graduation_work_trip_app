class PackingList < ApplicationRecord
  belongs_to :user
  has_many :packing_items, dependent: :destroy

  validates :name, presence: true
end
