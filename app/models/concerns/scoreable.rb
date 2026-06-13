# Shared output-quality scoring for Tool (its "one model") and ModelVariant
# (a specific model). Both carry the same five sub-score columns.
module Scoreable
  extend ActiveSupport::Concern

  # Label => column, in display order.
  OUTPUT_FIELDS = {
    "Text generation"  => :score_text_generation,
    "Email writing"    => :score_email_writing,
    "Logic"            => :score_logic,
    "Coding"           => :score_coding,
    "Image generation" => :score_image_generation
  }.freeze

  # Average of whichever output sub-scores are filled (nil if none yet).
  def output_quality
    vals = OUTPUT_FIELDS.values.filter_map { |field| public_send(field) }
    vals.any? ? vals.sum.to_f / vals.size : nil
  end

  # Gated verdict (1-10): average of output quality + the given ease & privacy,
  # capped by accuracy (a low accuracy score caps everything). Requires this
  # record's own output quality or accuracy — ease/privacy alone don't make a
  # verdict. nil = not yet rated.
  def verdict_with(ease:, privacy:)
    return nil if output_quality.nil? && score_accuracy.nil?

    parts = [output_quality, ease, privacy].compact
    base = parts.empty? ? nil : parts.sum.to_f / parts.size

    if score_accuracy
      base ? [base, score_accuracy.to_f].min : score_accuracy.to_f
    else
      base
    end
  end
end
