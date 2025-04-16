class CreatePhotos < ActiveRecord::Migration[7.0]
  def change
    create_table :photos do |t|
      t.string :image, null: false
      t.references :travel, null: false, foreign_key: true
      t.references :user, null: false, foreign_key: true
      t.integer :day_number, null: false

      t.timestamps
    end
  end
end
