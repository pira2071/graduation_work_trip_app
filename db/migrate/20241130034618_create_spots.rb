class CreateSpots < ActiveRecord::Migration[7.1]
  def change
    create_table :spots do |t|
      t.string :name, null: false
      t.integer :category, null: false
      t.decimal :lat, precision: 10, scale: 8  # 緯度を追加
      t.decimal :lng, precision: 11, scale: 8  # 経度を追加
      t.references :travel, null: false, foreign_key: true
      t.timestamps
    end
  end
end
