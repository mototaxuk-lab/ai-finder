class CreateCategories < ActiveRecord::Migration[7.1]
  def change
    create_table :categories do |t|
      t.string :slug, null: false
      t.string :display_name, null: false
      t.string :subtitle
      t.string :icon
      t.integer :position, default: 0, null: false

      t.timestamps
    end

    add_index :categories, :slug, unique: true
    add_index :categories, :position
  end
end
