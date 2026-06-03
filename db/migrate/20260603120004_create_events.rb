class CreateEvents < ActiveRecord::Migration[7.1]
  def change
    create_table :events do |t|
      # event_type: search / card_click / specs_expand
      t.string :event_type, null: false
      t.text :search_query
      t.jsonb :parsed_filters, null: false, default: {}
      t.jsonb :shown_tool_ids, null: false, default: []
      # Named FK to tools (nullable; only set on card_click).
      t.bigint :clicked_tool_id

      t.datetime :created_at, null: false
    end

    add_foreign_key :events, :tools, column: :clicked_tool_id
    add_index :events, :event_type
    add_index :events, :clicked_tool_id
    add_index :events, :created_at
  end
end
