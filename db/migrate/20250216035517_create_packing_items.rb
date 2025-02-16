class CreatePackingItems < ActiveRecord::Migration[7.0]
  def change
    create_table :packing_items do |t|
      t.string :name, null: false
      t.boolean :checked, default: false
      t.references :packing_list, null: false, foreign_key: true

      t.timestamps
    end
  end
end
