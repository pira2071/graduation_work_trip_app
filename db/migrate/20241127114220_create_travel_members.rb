class CreateTravelMembers < ActiveRecord::Migration[7.1]
  def change
    create_table :travel_members do |t|
      t.references :travel, null: false, foreign_key: true
      t.references :user, null: false, foreign_key: true
      t.integer :role, null: false, default: 0

      t.timestamps
    end
    add_index :travel_members, [:travel_id, :user_id], unique: true
  end
end
