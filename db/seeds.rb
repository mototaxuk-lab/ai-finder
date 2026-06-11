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

# ---------------------------------------------------------------------------
# Model variants (individual models under a product, e.g. Claude → Sonnet /
# Opus / Fable). Idempotent on [tool, name]. Only lineups we've actually
# verified belong in this CSV — a wrong price is worse than no variant, and
# cards simply omit the row for tools without variants.
# ---------------------------------------------------------------------------
variants_path = Rails.root.join("db/seeds/model_variants.csv")
if File.exist?(variants_path)
  variant_count = 0
  CSV.foreach(variants_path, headers: true) do |row|
    tool = Tool.find_by(name: row["tool_name"].to_s.strip)
    next unless tool

    tool.model_variants.find_or_initialize_by(name: row["name"].to_s.strip).update!(
      model_id_string:  row["model_id_string"].presence,
      input_usd_per_m:  row["input_usd_per_m"].presence,
      output_usd_per_m: row["output_usd_per_m"].presence,
      pricing_unit:     row["pricing_unit"].presence,
      context_window:   row["context_window"].presence,
      best_for:         row["best_for"].presence,
      last_verified:    row["last_verified"].presence,
      position:         row["position"].presence || 0
    )
    variant_count += 1
  end
  puts "Model variants: #{ModelVariant.count} (imported/updated #{variant_count})"
end

# ---------------------------------------------------------------------------
# Blog posts (the "Latest in AI" section). Idempotent on :slug.
# ---------------------------------------------------------------------------
POSTS = [
  {
    slug: "spring-2026-chat-assistants",
    title: "Spring 2026: the big chat assistants all leveled up",
    published_at: Time.zone.parse("2026-06-02 09:00"),
    excerpt: "ChatGPT, Claude and Gemini each shipped updates in recent weeks. Here's what actually matters for everyday use — and what's just noise.",
    body: <<~BODY
      It's been a busy few weeks. The three assistants most people reach for all pushed updates, and the marketing is, as ever, louder than the real-world difference.

      For everyday writing, chatting and quick answers, the gap between them is now small — pick the one that fits where you already work. The bigger differences show up at the edges: very long documents, careful step-by-step reasoning, and how each one handles your data.

      Our take: don't chase the leaderboard. Decide what you actually need (free? private? good at long writing?), then let those requirements narrow the field. That's exactly what the search box at the top of this page is for.
    BODY
  },
  {
    slug: "local-ai-good-enough",
    title: "Local AI is finally good enough for real work",
    published_at: Time.zone.parse("2026-05-26 09:00"),
    excerpt: "Tools like Ollama and LM Studio let you run capable models on your own laptop — private, free, and offline. Here's where they shine and where they don't.",
    body: <<~BODY
      A year ago, running a model on your own machine was a fun experiment. Today it's genuinely useful for a lot of everyday tasks — drafting, summarising, brainstorming — without anything leaving your computer.

      The trade-off is setup and horsepower. You'll need a reasonably modern machine, and the very best quality still lives in the big cloud models. But if privacy or cost matters more than squeezing out the last 10% of quality, local is a real option now.

      If that's you, search for something like "a chatbot I can run offline on my own machine" and we'll show only the tools that actually qualify.
    BODY
  },
  {
    slug: "what-free-really-means",
    title: "What 'free' really means across AI tools",
    published_at: Time.zone.parse("2026-05-19 09:00"),
    excerpt: "A free tier can mean anything from 'genuinely generous' to 'bait'. Here's the honest version for the kinds of tools in our catalogue.",
    body: <<~BODY
      "Free" is doing a lot of work in AI marketing. Sometimes it means a generous everyday allowance. Sometimes it means a trial that runs out in an afternoon. Sometimes it means free for you, because you (and your data) are the product.

      We split the difference two ways: is there a genuinely free app for individuals, and separately, is there a free API tier for builders? They're not the same thing, and most people only care about the first.

      When you ask for something "free" in the search box, we filter to the free consumer app — not the API — so the results match what you actually meant.
    BODY
  },
  {
    slug: "private-transcription-options",
    title: "Transcription without sending your audio to the cloud",
    published_at: Time.zone.parse("2026-05-12 09:00"),
    excerpt: "If you're transcribing interviews or sensitive recordings, where your audio goes matters. The privacy-first options, explained.",
    body: <<~BODY
      Transcription is one of the clearest cases where privacy really matters — interviews, medical notes, legal recordings. Many popular services upload your audio to their servers and keep it.

      The good news: open-source transcription you run locally has become both accurate and approachable. If you're comfortable with a little setup, you can transcribe entirely on your own machine.

      Try "transcribe my interviews without my data being kept" — we'll drop anything that keeps your recordings and show only what genuinely fits.
    BODY
  }
].freeze

POSTS.each do |attrs|
  Post.find_or_initialize_by(slug: attrs[:slug]).update!(attrs)
end
puts "Posts: #{Post.count}"

# ---------------------------------------------------------------------------
# Human reviews, linked to a tool. Idempotent on :slug.
# ---------------------------------------------------------------------------
if (claude = Tool.find_by(name: "Claude"))
  Review.find_or_initialize_by(slug: "claude-code-review").update!(
    tool: claude,
    title: "Claude Code: a hands-on review",
    byline: "Reviewed by the AI Finder team",
    rating: 5,
    published_at: Time.zone.parse("2026-06-05 09:00"),
    body: <<~BODY
      Claude Code is Anthropic's coding agent that lives in your terminal. Unlike a chat window you paste snippets into, it reads and edits files in your actual project, runs commands, and works through multi-step tasks on its own — closer to pairing with a fast junior engineer than using an autocomplete.

      What stands out is how well it holds the thread on real work. Point it at a bug and it will explore the codebase, form a plan, make changes across several files, and run the tests — narrating as it goes. On larger refactors it stays coherent where lighter tools lose the plot. The underlying model's reasoning is the differentiator.

      The catch: this is a developer tool. You need to be comfortable in a terminal, and because it works through the API, long autonomous sessions cost real money — keep an eye on usage. And like any agent, it needs supervision: read its diffs before you commit, especially on anything destructive. It is not a tool for non-coders.

      On privacy, Anthropic does not train on your code by default, which matters if you're pointing it at proprietary work — but confirm the current policy for your account type.

      Verdict: for developers who live in the terminal, it's the most capable coding agent we've used. For everyone else, start with a chat assistant instead. Five stars — with the honest caveat that "five stars for developers" is the right way to read it.
    BODY
  )
  puts "Reviews: #{Review.count}"
end
