class CreateTools < ActiveRecord::Migration[7.1]
  def change
    create_table :tools do |t|
      # --- identity ---
      t.string :name, null: false
      t.string :provider
      t.string :website_url

      # --- housekeeping ---
      # status: live / dead / review  (string-backed Rails enum)
      t.string :status, null: false, default: "live"
      t.date :last_verified
      # data_pricing_confidence: high / medium / low
      t.string :data_pricing_confidence

      # --- raw price ---
      t.decimal :input_usd_per_m, precision: 12, scale: 4
      t.decimal :output_usd_per_m, precision: 12, scale: 4
      t.string :pricing_unit
      t.decimal :price_low_usd, precision: 12, scale: 2
      t.decimal :price_high_usd, precision: 12, scale: 2

      # --- raw spec ---
      t.integer :context_window

      # --- hard-filter flags ---
      # Default false: never claim a capability we don't know about.
      t.boolean :api_free_tier, null: false, default: false
      t.boolean :consumer_free_app, null: false, default: false
      # data_retention: none / optional / yes / unclear
      t.string :data_retention, null: false, default: "unclear"
      t.boolean :runs_locally, null: false, default: false

      # --- display ---
      t.string :privacy_label
      t.string :price_label
      t.string :ease_label
      t.text :why_this_one

      # --- scores (1-10, hand-assigned; nullable until curated) ---
      t.integer :quality_score
      t.integer :ease_score
      t.integer :value_score

      # --- audit ---
      t.text :raw_pricing_text
      t.text :raw_privacy_text

      t.timestamps
    end

    add_index :tools, :name, unique: true
    add_index :tools, :status
    add_index :tools, :consumer_free_app
    add_index :tools, :runs_locally
    add_index :tools, :data_retention
  end
end
