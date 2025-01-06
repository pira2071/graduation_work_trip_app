class AddNameToTravelMembers < ActiveRecord::Migration[7.1]
  def change
    add_column :travel_members, :name, :string
    change_column_null :travel_members, :user_id, true
  end
end
