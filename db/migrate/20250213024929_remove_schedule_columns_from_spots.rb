class RemoveScheduleColumnsFromSpots < ActiveRecord::Migration[7.1]
  def change
    remove_column :spots, :day_number, :integer
    remove_column :spots, :time_zone, :string
  end
end
