class CreateTravelShares < ActiveRecord::Migration[7.1]
  def change
    create_table :travel_shares do |t|
      t.references :travel, null: false, foreign_key: true
      t.string :notification_type, null: false
      
      t.timestamps
    end
    
    add_index :travel_shares, [:travel_id, :notification_type], unique: true
  end
end
