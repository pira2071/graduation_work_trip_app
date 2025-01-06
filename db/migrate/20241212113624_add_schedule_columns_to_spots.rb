class AddScheduleColumnsToSpots < ActiveRecord::Migration[7.1]
  def change
    add_column :spots, :day_number, :integer
    add_column :spots, :time_zone, :string
  end
end
