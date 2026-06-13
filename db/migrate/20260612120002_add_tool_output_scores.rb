class AddToolOutputScores < ActiveRecord::Migration[7.1]
  # For tools without a model lineup: score the single product directly (its
  # "one model"). Same six fields as model_variants. Multi-model tools leave
  # these blank and score per variant instead.
  def change
    change_table :tools, bulk: true do |t|
      t.integer :score_text_generation
      t.integer :score_email_writing
      t.integer :score_logic
      t.integer :score_coding
      t.integer :score_image_generation
      t.integer :score_accuracy
    end
  end
end
