require "csv"

# ---------------------------------------------------------------------------
# Categories (browse grid). Seeded first so the CSV can reference them by slug
# and they carry nice display metadata + icons. Idempotent on :slug.
# ---------------------------------------------------------------------------
CATEGORIES = [
  { slug: "write-things",   display_name: "write things",    subtitle: "emails, posts, essays",  icon: "pencil",          position: 1 },
  { slug: "chat-assistant", display_name: "chat & ask",      subtitle: "answers to anything",    icon: "message-chatbot", position: 2 },
  { slug: "code",           display_name: "write code",      subtitle: "build & fix software",   icon: "code",            position: 3 },
  { slug: "summarize",      display_name: "summarise",       subtitle: "shrink long documents",  icon: "file-text",       position: 4 },
  { slug: "research",       display_name: "research",        subtitle: "find & cite sources",    icon: "search",          position: 5 },
  { slug: "audio-to-text",  display_name: "transcribe",      subtitle: "audio & interviews",     icon: "microphone",      position: 6 },
  { slug: "translate",      display_name: "translate",       subtitle: "across languages",       icon: "language",        position: 7 }
].freeze

CATEGORIES.each do |attrs|
  Category.find_or_initialize_by(slug: attrs[:slug]).update!(attrs)
end
puts "Categories: #{Category.count}"

# ---------------------------------------------------------------------------
# Tools, imported from the CSV. Idempotent on :name. Re-running updates in
# place and never duplicates tools or join rows.
# ---------------------------------------------------------------------------
def yes?(value)
  value.to_s.strip.downcase.start_with?("y")
end

VALID_RETENTION = Tool.data_retentions.keys.freeze # %w[none optional yes unclear]

csv_path = Rails.root.join("db/seeds/ai_tool_catalogue_text_models.csv")
abort "Catalogue CSV not found at #{csv_path}" unless File.exist?(csv_path)

imported = 0
CSV.foreach(csv_path, headers: true) do |row|
  tool = Tool.find_or_initialize_by(name: row["name"].to_s.strip)

  retention = row["data_retention"].to_s.strip.downcase
  retention = "unclear" unless VALID_RETENTION.include?(retention)

  tool.assign_attributes(
    provider:                 row["provider"].presence,
    website_url:              row["website_url"].presence,
    status:                   (row["status"].presence || "live"),
    last_verified:            row["last_verified"].presence,
    data_pricing_confidence:  row["data_pricing_confidence"].presence,
    input_usd_per_m:          row["input_usd_per_m"].presence,
    output_usd_per_m:         row["output_usd_per_m"].presence,
    pricing_unit:             row["pricing_unit"].presence,
    price_low_usd:            row["price_low_usd"].presence,
    price_high_usd:           row["price_high_usd"].presence,
    context_window:           row["context_window"].presence,
    api_free_tier:            yes?(row["api_free_tier"]),
    consumer_free_app:        yes?(row["consumer_free_app"]),
    data_retention:           retention,
    runs_locally:             yes?(row["runs_locally"]),
    privacy_label:            row["privacy_label"].presence,
    price_label:              row["price_label"].presence,
    ease_label:               row["ease_label"].presence,
    why_this_one:             row["why_this_one"].presence,
    quality_score:            row["quality_score"].presence,
    ease_score:               row["ease_score"].presence,
    value_score:              row["value_score"].presence
  )
  tool.save!

  # Wire up categories. Assigning the full set is idempotent: it adds new
  # links and removes stale ones without creating duplicates.
  slugs = row["categories"].to_s.split(",").map(&:strip).reject(&:blank?)
  cats = slugs.map do |slug|
    Category.find_or_create_by!(slug: slug) do |c|
      c.display_name = slug.tr("-", " ")
    end
  end
  tool.categories = cats

  imported += 1
end

puts "Tools: #{Tool.count} (imported/updated #{imported})"
puts "Tool-category links: #{ToolCategory.count}"
