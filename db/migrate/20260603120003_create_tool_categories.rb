class CreateToolCategories < ActiveRecord::Migration[7.1]
  def change
    create_table :tool_categories do |t|
      t.references :tool, null: false, foreign_key: true
      t.references :category, null: false, foreign_key: true

      t.timestamps
    end

    # Prevent duplicate join rows so seeding stays idempotent.
    add_index :tool_categories, [:tool_id, :category_id], unique: true
  end
end
