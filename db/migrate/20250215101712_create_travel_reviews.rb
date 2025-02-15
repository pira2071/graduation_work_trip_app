class CreateTravelReviews < ActiveRecord::Migration[7.1]
  def change
    create_table :travel_reviews do |t|
      t.references :travel, null: false, foreign_key: true
      t.references :user, null: false, foreign_key: true
      t.text :content, null: false
      t.timestamps
    end
  end
end
