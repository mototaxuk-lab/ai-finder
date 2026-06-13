# An individual model offered by a tool (e.g. Claude → Sonnet / Opus / Fable).
# Variants are evidence on the product, not search results in their own right:
# the hard filter and weighted pick operate on tools only, and variants are
# surfaced on result cards, the detail page, and (later) compare.
class ModelVariant < ApplicationRecord
  belongs_to :tool, inverse_of: :model_variants

  validates :name, presence: true, uniqueness: { scope: :tool_id }

  scope :ordered, -> { order(:position, :id) }

  # The five output-quality sub-scores (label => column), 1-10, nullable.
  OUTPUT_FIELDS = {
    "Text generation"  => :score_text_generation,
    "Email writing"    => :score_email_writing,
    "Logic"            => :score_logic,
    "Coding"           => :score_coding,
    "Image generation" => :score_image_generation
  }.freeze

  # Average of whichever output sub-scores are filled (nil if none yet).
  def output_quality
    vals = OUTPUT_FIELDS.values.filter_map { |f| public_send(f) }
    vals.any? ? vals.sum.to_f / vals.size : nil
  end

  # Gated verdict (1-10): the average of output quality + the tool's ease &
  # privacy, then capped by accuracy (a low accuracy score caps everything).
  # nil = not enough has been scored to form a verdict.
  def verdict
    parts = [output_quality, tool.ease_score, tool.privacy_score].compact
    return nil if parts.empty?

    base = parts.sum.to_f / parts.size
    score_accuracy ? [base, score_accuracy.to_f].min : base
  end

  # "$3 in / $15 out per 1M tokens" — mirrors Tool#price_summary.
  def price_summary
    return nil if input_usd_per_m.blank? && output_usd_per_m.blank?

    parts = []
    parts << "$#{format_price(input_usd_per_m)} in"   if input_usd_per_m.present?
    parts << "$#{format_price(output_usd_per_m)} out" if output_usd_per_m.present?
    [parts.join(" / "), pricing_unit].compact_blank.join(" ")
  end

  # Tooltip text for the compact chip on result cards.
  def chip_title
    [price_summary, best_for].compact_blank.join(" — ")
  end

  private

  # Trim trailing zeros so a decimal(12,4) column reads "$3", not "$3.0000".
  def format_price(value)
    value.to_f % 1 == 0 ? value.to_i.to_s : value.to_f.to_s
  end
end
