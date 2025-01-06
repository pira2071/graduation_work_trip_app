class CreateTravels < ActiveRecord::Migration[7.1]
  def change
    create_table :travels do |t|
      t.string :title, null: false
      t.date :start_date, null: false
      t.date :end_date, null: false
      t.string :thumbnail
      t.references :user, null: false, foreign_key: true

      t.timestamps
    end
  end
end
