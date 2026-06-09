class CreateReviews < ActiveRecord::Migration[7.1]
  def change
    create_table :reviews do |t|
      t.references :tool, null: false, foreign_key: true
      t.string :slug, null: false
      t.string :title, null: false
      t.string :byline
      t.integer :rating # out of 5; nullable
      t.text :body
      t.datetime :published_at # nil = draft

      t.timestamps
    end

    add_index :reviews, :slug, unique: true
  end
end
