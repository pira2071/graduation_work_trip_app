class CreateSchedules < ActiveRecord::Migration[7.1]
  def change
    create_table :schedules do |t|
      t.references :spot, null: false, foreign_key: true
      t.integer :order_number, null: false
      t.integer :day_number, null: false
      t.integer :time_zone, null: false
      t.timestamps
    end
  end
end
