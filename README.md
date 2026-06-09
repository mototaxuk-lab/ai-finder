# AI Finder

**A "Google for AI" for individuals.** Type what you need in plain English, get 4–5 honest, human-translated tool recommendations — and the catch with each one.

> Status: v1 prototype. Runs locally; deployment deferred. Search works today via a keyword parser, with an LLM parser that activates automatically when an Anthropic API key + credit are present.

---

## What it does

1. You type something like *"transcribe my interviews without my data being kept"* (or tap a browse tile).
2. The input is parsed into structured filters — must-be-free, must-be-private, runs-locally, category.
3. Tools that **fail a stated requirement are dropped** (never padded back in).
4. From the survivors, 4–5 are chosen by a weighted-random pick and shown as cards with plain-English labels.

The guiding principle is **honesty over completeness**: a wrong "free" or "private" label is worse than none, so the catalogue is small, hand-curated, and surfaces a "last checked" date.

## Stack

- **Ruby on Rails 7.1** (server-rendered ERB + a little Hotwire/Turbo)
- **PostgreSQL**
- **Claude API** (`anthropic` gem, Haiku-class model) for the free-text parse — optional, with a deterministic fallback

## The matching pipeline

| Stage | What happens | Code |
|---|---|---|
| 1. Parse | Free text → structured filters. Claude via forced tool-use; **falls back to a keyword parser** on any failure (no key, timeout, bad output). | `app/services/need_parser.rb`, `app/services/parsed_need.rb` |
| 2. Hard filter | Strict, deterministic SQL. Drops anything failing a stated must-have. Never randomised. | `app/services/tool_matcher.rb` |
| 3. Pick | Weighted-random sample (by quality + ease + value, value-weighted when cost is signalled). | `ToolMatcher#weighted_sample` |
| 4. Render | 4–5 cards with human labels; a detail page bridges to the full specs. | `app/views/search/`, `app/views/tools/` |

Browse tiles skip the LLM entirely — a tile already *is* a structured filter.

## Data model

- `tools` — the catalogue (identity, raw price/specs, hard-filter flags, human-display labels, 1–10 scores).
- `categories` + `tool_categories` — the browse grid and many-to-many tagging.
- `events` — a bare-bones log of searches / clicks (schema present; wiring is a later step).

## Local setup

Requires Ruby 3.3.x and PostgreSQL.

```bash
bundle install
bin/rails db:create db:migrate db:seed   # seeds ~22 starter tools + 7 categories
bin/rails server                          # http://localhost:3000
```

### LLM parsing (optional)

Without a key, search uses the keyword parser and works fully. To enable the Claude parse, add a gitignored `.env` in the project root:

```
ANTHROPIC_API_KEY=sk-ant-...
```

Get a key at <https://console.anthropic.com> (pay-as-you-go; the parse is a few hundred Haiku tokens per search — pennies). The key is read at boot by `config/initializers/load_dotenv.rb`.

## Catalogue

The catalogue is seeded from `db/seeds/ai_tool_catalogue_text_models.csv`. Regenerate the CSV from source data with:

```bash
bin/rails runner db/seeds/generate_catalogue.rb
```

The seed importer (`db/seeds.rb`) is idempotent — re-running never duplicates tools or category links. Figures in the starter CSV are *reasonable approximations* (see the `data_pricing_confidence` column); curate before any real launch.

### Automated freshness (optional, human-in-the-loop)

A scheduled GitHub Action (`.github/workflows/catalogue-freshness.yml`) runs `script/freshness.rb` daily: it asks Claude (with web search) for each tool's current pricing/policy figures and **opens a PR** proposing edits to `catalogue_review.csv`, with per-tool source + confidence notes. It **never** edits the live seed catalogue — you review and merge, then copy verified rows into the seed CSV. Requires the `ANTHROPIC_API_KEY` repo secret on an account with API credit. Run it manually anytime from the Actions tab.

This is deliberately a *draft → human review* loop, not blind auto-commit: machine-scraped figures are low-confidence, and a wrong "free"/"private" label is worse than none.

## Not yet (deliberately deferred)

User accounts · a real ranking algorithm (weighted-random stands in) · admin UI (edit via seed/console) · deployment.

## Versioning & changelog

Current version: **v0.2.0** (surfaced in the site footer via `AiFinder::VERSION`).

This project follows [Semantic Versioning](https://semver.org/) (pre-1.0). All notable changes are recorded in [`CHANGELOG.md`](CHANGELOG.md), and each release is tagged in git (`vMAJOR.MINOR.PATCH`). To cut a release: bump `AiFinder::VERSION` in `config/application.rb`, move the `Unreleased` notes into a dated version section in the changelog, then tag and push.
