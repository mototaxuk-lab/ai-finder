class AddEvaluationScores < ActiveRecord::Migration[7.1]
  def change
    # Per-model output-quality sub-scores + accuracy (1-10, nullable) — these
    # genuinely vary by model, so they live on the variant.
    change_table :model_variants, bulk: true do |t|
      t.integer :score_text_generation
      t.integer :score_email_writing
      t.integer :score_logic
      t.integer :score_coding
      t.integer :score_image_generation
      t.integer :score_accuracy
    end

    # Product/provider-level criteria live on the tool. ease_score already
    # exists (= ease of use); add privacy. Retire the old quality/value scores
    # (output quality now comes from the variant sub-scores; "value" is gone).
    add_column :tools, :privacy_score, :integer
    remove_column :tools, :quality_score, :integer
    remove_column :tools, :value_score, :integer
  end
end
