class CreateModelVariants < ActiveRecord::Migration[7.1]
  def change
    create_table :model_variants do |t|
      t.references :tool, null: false, foreign_key: true
      t.string :name, null: false
      t.string :model_id_string
      t.decimal :input_usd_per_m, precision: 12, scale: 4
      t.decimal :output_usd_per_m, precision: 12, scale: 4
      t.string :pricing_unit
      t.integer :context_window
      t.string :best_for
      t.date :last_verified
      t.integer :position, null: false, default: 0

      t.timestamps
    end

    add_index :model_variants, [:tool_id, :name], unique: true
  end
end
