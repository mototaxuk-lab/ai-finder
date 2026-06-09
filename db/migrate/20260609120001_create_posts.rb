class CreatePosts < ActiveRecord::Migration[7.1]
  def change
    create_table :posts do |t|
      t.string :title, null: false
      t.string :slug, null: false
      t.text :excerpt
      t.text :body
      t.datetime :published_at # nil = draft

      t.timestamps
    end

    add_index :posts, :slug, unique: true
    add_index :posts, :published_at
  end
end
