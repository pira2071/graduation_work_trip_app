class ChangeTimeZoneTypeInSchedules < ActiveRecord::Migration[7.1]
  def up
    change_column :schedules, :time_zone, :string
  end

  def down
    change_column :schedules, :time_zone, :integer
  end
end
