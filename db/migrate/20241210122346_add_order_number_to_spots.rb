class AddOrderNumberToSpots < ActiveRecord::Migration[7.1]
  def change
    add_column :spots, :order_number, :integer
  end
end
