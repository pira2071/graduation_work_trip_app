class CreateFriendships < ActiveRecord::Migration[7.1]
  def change
    create_table :friendships do |t|
      t.references :requester, null: false, foreign_key: { to_table: :users }
      t.references :receiver, null: false, foreign_key: { to_table: :users }
      t.string :status, default: 'pending'
      t.datetime :accepted_at
      t.datetime :rejected_at

      t.timestamps
    end

    add_index :friendships, [:requester_id, :receiver_id], unique: true
  end
end
