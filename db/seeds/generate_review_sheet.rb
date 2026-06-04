# Generates catalogue_review.csv at the project root: a human-editable review
# worksheet built from the seeded catalogue.
#
#   bin/rails runner db/seeds/generate_review_sheet.rb
#
# It mirrors every editable field, adds `needs_review` + `review_notes`
# columns (an honest, per-tool "what to double-check" pass), and appends a few
# blank rows for adding new tools. Column headers match the seed importer, so
# a curated version of this file could later replace the seed CSV (drop the
# blank template rows + the two review-only columns first).
require "csv"

HEADERS = %w[
  name provider website_url categories status last_verified data_pricing_confidence
  consumer_free_app api_free_tier runs_locally data_retention
  input_usd_per_m output_usd_per_m pricing_unit price_low_usd price_high_usd context_window
  privacy_label price_label ease_label why_this_one
  quality_score ease_score value_score
  needs_review review_notes
].freeze

# Tool-specific things genuinely worth a human's eyes, keyed by name.
SPECIFIC_NOTES = {
  "ChatGPT"           => "Token prices move often — re-check GPT input/output per-M and the Plus price.",
  "Claude"            => "Re-check Sonnet token prices and that the consumer free tier still exists.",
  "Google Gemini"    => "Tiering is tangled (Google One / AI plans) — confirm the free vs paid split.",
  "Microsoft Copilot" => "No token price recorded; confirm consumer vs enterprise data handling.",
  "Perplexity"        => "Confirm the free tier's limits and the training opt-out claim.",
  "GitHub Copilot"    => "Free tier exists but is capped — confirm current caps and the $10 Pro price.",
  "Cursor"            => "Confirm free-tier limits and that 'privacy mode' keeps code off their servers.",
  "Whisper"           => "Open-source/local claim is the whole point here — verify it still holds.",
  "MacWhisper"        => "Confirm the one-off Pro price and that transcription is fully on-device.",
  "Otter.ai"          => "Privacy-sensitive: confirm it stores recordings server-side; check free minutes.",
  "Llama"             => "Confirm latest open-weight licence terms and that it's free to self-host.",
  "Mistral Le Chat"   => "Confirm the free tier and which models are open-weight.",
  "DeepSeek"          => "Privacy-critical: confirm data is stored in China and surface it clearly.",
  "Ollama"            => "Confirm it's still free/open and the fully-local claim.",
  "LM Studio"         => "Confirm 'free for personal use' licensing is unchanged.",
  "NotebookLM"        => "Confirm the 'doesn't train on uploads' claim — it's the main selling point.",
  "DeepL"             => "Confirm Pro deletes text after translating; check free vs Pro split.",
  "Grammarly"         => "Privacy: confirm server-side processing wording; check Premium price.",
  "Poe"               => "Privacy depends on the underlying model — wording may need nuance.",
  "DeepGram"          => "Confirm per-audio-hour pricing and the no-retention option on paid plans.",
  "Cohere Command"    => "Developer-only (no consumer app) — confirm pricing and opt-out controls.",
  "Jasper"            => "Confirm it's still paid-only and the current monthly price range."
}.freeze

def generic_notes(tool)
  notes = []
  if tool.data_pricing_confidence != "high"
    notes << "Pricing is #{tool.data_pricing_confidence || 'un'}-confidence — verify on the official pricing page."
  end
  if %w[yes unclear].include?(tool.data_retention)
    notes << "Verify the data-retention/training policy and the privacy label wording."
  end
  notes << "Re-check the last_verified date."
  notes
end

rows = Tool.order(:name).map do |tool|
  all_notes = [SPECIFIC_NOTES[tool.name], *generic_notes(tool)].compact
  {
    name: tool.name,
    provider: tool.provider,
    website_url: tool.website_url,
    categories: tool.categories.order(:position).pluck(:slug).join(","),
    status: tool.status,
    last_verified: tool.last_verified,
    data_pricing_confidence: tool.data_pricing_confidence,
    consumer_free_app: tool.consumer_free_app ? "yes" : "no",
    api_free_tier: tool.api_free_tier ? "yes" : "no",
    runs_locally: tool.runs_locally ? "yes" : "no",
    data_retention: tool.data_retention,
    input_usd_per_m: tool.input_usd_per_m,
    output_usd_per_m: tool.output_usd_per_m,
    pricing_unit: tool.pricing_unit,
    price_low_usd: tool.price_low_usd,
    price_high_usd: tool.price_high_usd,
    context_window: tool.context_window,
    privacy_label: tool.privacy_label,
    price_label: tool.price_label,
    ease_label: tool.ease_label,
    why_this_one: tool.why_this_one,
    quality_score: tool.quality_score,
    ease_score: tool.ease_score,
    value_score: tool.value_score,
    needs_review: "yes",
    review_notes: all_notes.join(" ")
  }
end

out = Rails.root.join("catalogue_review.csv")
CSV.open(out, "w") do |csv|
  csv << HEADERS
  rows.each { |r| csv << HEADERS.map { |h| r[h.to_sym] } }
  # Blank template rows for adding new tools.
  3.times do
    csv << HEADERS.map { |h| h == "needs_review" ? "new" : (h == "review_notes" ? "← add a new tool on this row" : nil) }
  end
end

puts "Wrote #{rows.size} tools + 3 template rows to #{out}"
