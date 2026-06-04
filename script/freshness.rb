#!/usr/bin/env ruby
# frozen_string_literal: true
#
# Catalogue freshness checker (runs in CI — see .github/workflows/catalogue-freshness.yml).
#
# Reads the seed catalogue, asks Claude (with web search) for each tool's
# CURRENT pricing/policy figures, and writes a PROPOSED catalogue_review.csv.
# It NEVER edits the live seed catalogue — a human reviews the PR this produces.
#
# Self-contained: needs only the `anthropic` and `csv` gems (no Rails/DB), so
# CI can run it with a bare `gem install anthropic`.
#
#   ANTHROPIC_API_KEY=sk-ant-... ruby script/freshness.rb
#
# Honesty rules: the model is told to return "unknown" when it can't verify a
# figure, and we only overwrite a field when it comes back with a concrete,
# changed value. Anything uncertain is left as-is and flagged for human review.

require "csv"
require "json"
require "date"
require "anthropic"

ROOT       = File.expand_path("..", __dir__)
SEED_CSV   = File.join(ROOT, "db/seeds/ai_tool_catalogue_text_models.csv")
REVIEW_CSV = File.join(ROOT, "catalogue_review.csv")
MODEL      = ENV.fetch("FRESHNESS_MODEL", "claude-sonnet-4-6")
TODAY      = Date.today.iso8601

REVIEW_HEADERS = %w[
  name provider website_url categories status last_verified data_pricing_confidence
  consumer_free_app api_free_tier runs_locally data_retention
  input_usd_per_m output_usd_per_m pricing_unit price_low_usd price_high_usd context_window
  privacy_label price_label ease_label why_this_one
  quality_score ease_score value_score
  needs_review review_notes
].freeze

# Only these (volatile) fields are auto-proposed. Labels, scores and the
# editorial blurb stay human-owned.
RESEARCHABLE = %w[
  consumer_free_app data_retention input_usd_per_m output_usd_per_m
  price_low_usd price_high_usd pricing_unit
].freeze

def prompt_for(row)
  <<~TEXT
    Research the CURRENT public facts for this AI tool and report what you can verify today.

    Tool: #{row["name"]} (by #{row["provider"]})
    Website: #{row["website_url"]}

    Use web search. Then output a SINGLE JSON object (and nothing after it) with these keys:
      - consumer_free_app: "yes" | "no" | "unknown"  (is there a genuinely free app/tier for individuals?)
      - data_retention: "none" | "optional" | "yes" | "unclear" | "unknown"  (does it keep/train on user data?)
      - input_usd_per_m: number or null   (API input price per 1M tokens, if token-priced)
      - output_usd_per_m: number or null  (API output price per 1M tokens)
      - price_low_usd: number or null     (consumer plan low price, for non-token tools)
      - price_high_usd: number or null
      - pricing_unit: string or null      (e.g. "per 1M tokens", "per month")
      - source_url: string                (the page you trusted most)
      - confidence: "high" | "medium" | "low"
      - summary: string                   (one sentence on what looks current or changed)

    Rules: only state a figure you actually found. If unsure, use "unknown" (for the
    yes/no fields) or null (for numbers). Do NOT guess. Output ONLY the JSON object last.
  TEXT
end

def research(client, row)
  messages = [{ role: "user", content: prompt_for(row) }]
  6.times do
    msg = client.messages.create(
      model: MODEL,
      max_tokens: 1024,
      tools: [{ type: "web_search_20260209", name: "web_search" }],
      messages: messages
    )

    if msg.stop_reason.to_s == "pause_turn"
      messages << { role: "assistant", content: msg.content }
      next
    end

    text = msg.content.select { |b| b.type.to_s == "text" }.map(&:text).join("\n")
    return extract_json(text)
  end
  nil
end

# Defensively pull the last JSON object out of the model's text.
def extract_json(text)
  candidates = text.scan(/\{[^{}]*\}/m)
  candidates.reverse_each do |candidate|
    return JSON.parse(candidate)
  rescue JSON::ParserError
    next
  end
  nil
end

def normalize(value)
  value.to_s.strip.downcase
end

# Returns [updated_row, changes(array of strings)].
def apply(row, data)
  return [row, ["auto-check failed — left unchanged"]] if data.nil?

  changes = []
  RESEARCHABLE.each do |field|
    proposed = data[field]
    next if proposed.nil?
    next if proposed.is_a?(String) && %w[unknown].include?(normalize(proposed))

    current = row[field]
    if normalize(current) != normalize(proposed)
      changes << "#{field}: #{current.to_s.empty? ? '∅' : current} → #{proposed}"
      row[field] = proposed.to_s
    end
  end
  [row, changes]
end

# --- run ---
def run!
abort "Seed CSV not found at #{SEED_CSV}" unless File.exist?(SEED_CSV)

client = Anthropic::Client.new(api_key: ENV.fetch("ANTHROPIC_API_KEY"))
rows = CSV.read(SEED_CSV, headers: true, encoding: "UTF-8")
total_changes = 0

CSV.open(REVIEW_CSV, "w") do |out|
  out << REVIEW_HEADERS

  rows.each do |seed|
    # Project the seed row onto the review schema (booleans already yes/no in the CSV).
    row = REVIEW_HEADERS.each_with_object({}) { |h, acc| acc[h] = seed[h] }

    data =
      begin
        research(client, seed)
      rescue => e
        warn "[freshness] #{seed['name']}: #{e.class}: #{e.message}"
        nil
      end

    row, changes = apply(row, data)
    total_changes += changes.size unless changes == ["auto-check failed — left unchanged"]

    note = +"[auto #{TODAY}] "
    note << (changes.empty? ? "no change detected." : "PROPOSED: #{changes.join('; ')}.")
    if data
      note << " source: #{data['source_url']}." if data["source_url"].to_s != ""
      note << " confidence: #{data['confidence']}." if data["confidence"].to_s != ""
      note << " #{data['summary']}" if data["summary"].to_s != ""
    end
    row["review_notes"]  = note
    row["needs_review"]  = changes.empty? ? "auto-ok" : "yes"

    out << REVIEW_HEADERS.map { |h| row[h] }
    warn "[freshness] #{seed['name']}: #{changes.empty? ? 'no change' : changes.join('; ')}"
  end
end

  puts "Freshness pass complete: #{rows.size} tools checked, #{total_changes} field change(s) proposed."
  puts "Wrote #{REVIEW_CSV}"
end

run! if __FILE__ == $PROGRAM_NAME
