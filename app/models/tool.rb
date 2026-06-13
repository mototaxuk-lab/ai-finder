class Tool < ApplicationRecord
  include Scoreable

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
  has_many :reviews, dependent: :destroy
  has_many :model_variants, dependent: :destroy, inverse_of: :tool

  validates :name, presence: true, uniqueness: true

  # --- hard-filter scopes (deterministic; never randomised) ---
  scope :visible,    -> { where(status: "live") }
  scope :free_app,   -> { where(consumer_free_app: true) }
  scope :local,      -> { where(runs_locally: true) }
  scope :private_ok, -> { where(data_retention: %w[none optional]) }

  # Neutral baseline so un-scored tools don't sink in the weighted pick.
  # (Ranking is effectively flat until the team fills in scores.)
  RANK_BASELINE = 5.0

  # Headline verdict (1-10) for the scorecard + ranking: the best of this
  # tool's per-model verdicts. For a tool with no model lineup, score the
  # product directly from its own output quality + accuracy. nil = not yet rated.
  def overall_verdict
    verdicts = model_variants.map(&:verdict).compact
    return verdicts.max.round(1) if verdicts.any?

    self_verdict&.round(1)
  end

  # Verdict from the tool's own scores — used when there are no scored
  # variants (single-model products). Same gated formula as a model verdict.
  def self_verdict
    verdict_with(ease: ease_score, privacy: privacy_score)
  end

  # Weight for the weighted-random pick.
  def rank_weight
    overall_verdict || RANK_BASELINE
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

  # The review to surface, if any. Filters in Ruby so a preloaded :reviews
  # association doesn't trigger a query per card (avoids N+1 on results pages).
  def display_review
    reviews.to_a.select(&:published?).max_by(&:published_at)
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
