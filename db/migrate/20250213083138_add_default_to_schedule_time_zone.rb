class AddDefaultToScheduleTimeZone < ActiveRecord::Migration[7.1]
  def change
    change_column_default :schedules, :time_zone, 'morning'
  end
end
