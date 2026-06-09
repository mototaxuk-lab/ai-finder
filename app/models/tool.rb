class Tool < ApplicationRecord
  # String-backed enums. Use prefixes so values like `none`/`yes` don't
  # clobber ActiveRecord methods (e.g. the built-in `Tool.none` scope).
  enum :status, { live: "live", dead: "dead", review: "review" }, default: "live"
  enum :data_retention,
       { none: "none", optional: "optional", yes: "yes", unclear: "unclear" },
       prefix: :retention
  enum :data_pricing_confidence,
       { low: "low", medium: "medium", high: "high" },
       prefix: :pricing_confidence

  has_many :tool_categories, dependent: :destroy
  has_many :categories, through: :tool_categories

  validates :name, presence: true, uniqueness: true

  # --- hard-filter scopes (deterministic; never randomised) ---
  scope :visible,    -> { where(status: "live") }
  scope :free_app,   -> { where(consumer_free_app: true) }
  scope :local,      -> { where(runs_locally: true) }
  scope :private_ok, -> { where(data_retention: %w[none optional]) }

  # Baseline used when a hand-assigned score hasn't been curated yet.
  # Without this, freshly-imported tools (nil scores) would break the
  # weighted pick (nil + nil + nil).
  DEFAULT_SCORE = 5

  def quality
    quality_score || DEFAULT_SCORE
  end

  def ease
    ease_score || DEFAULT_SCORE
  end

  def value
    value_score || DEFAULT_SCORE
  end

  # Weight for the weighted-random pick. Optional emphasis bumps a single
  # dimension (e.g. :value when the user signalled "on a budget").
  def weight(emphasis: nil)
    base = quality + ease + value
    case emphasis
    when :value   then base + value
    when :ease    then base + ease
    when :quality then base + quality
    else base
    end
  end

  # --- display helpers (graceful fallback for un-curated labels) ---
  def display_privacy_label
    privacy_label.presence || retention_blurb
  end

  def display_price_label
    price_label.presence || (consumer_free_app? ? "has a free option" : "paid")
  end

  def display_ease_label
    ease_label.presence || "setup varies"
  end

  # Human-readable price, token-based or flat, for the compare table.
  def price_summary
    if input_usd_per_m.present? || output_usd_per_m.present?
      parts = []
      parts << "$#{input_usd_per_m} in"  if input_usd_per_m.present?
      parts << "$#{output_usd_per_m} out" if output_usd_per_m.present?
      [parts.join(" / "), pricing_unit].compact_blank.join(" ")
    elsif price_low_usd.present?
      range = price_high_usd.present? ? "$#{price_low_usd}–$#{price_high_usd}" : "$#{price_low_usd}"
      [range, pricing_unit].compact_blank.join(" ")
    else
      "—"
    end
  end

  private

  def retention_blurb
    case data_retention
    when "none"     then "doesn't keep your data"
    when "optional" then "you can turn off data keeping"
    when "yes"      then "keeps your data"
    else "data handling unclear"
    end
  end
end
