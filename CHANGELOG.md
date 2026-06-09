# Changelog

All notable changes to AI Finder are documented here. The format is based on
[Keep a Changelog](https://keepachangelog.com/), and the project follows
[Semantic Versioning](https://semver.org/) (pre-1.0: minor versions may include
breaking changes).

## [Unreleased]

### Added
- Human reviews: a `Review` model tied to a tool, a "Read our review" link on
  result cards and the tool detail page when a published review exists, and a
  per-review page (`/reviews/:slug`) with a star rating. Seeded a sample Claude
  Code review linked from the Claude card. Reviews are preloaded to avoid N+1
  on results pages.

## [0.1.0] — 2026-06-09

First working prototype — plain-English search that returns a few honest AI tool
recommendations, built on Rails + PostgreSQL.

### Added

**Search & matching pipeline**
- Plain-English search with an LLM parse (Claude, Haiku-class, forced tool-use)
  that falls back to a deterministic keyword parser on any failure.
- Strict hard filter (free / private / runs-locally / category) that never pads
  results with tools failing a stated requirement.
- Weighted-random pick of 4–5 tools, value-weighted when cost is signalled.
- Honest empty/insufficient states ("we won't pad the list").

**Catalogue**
- `tools`, `categories`, `tool_categories` schema with string-backed enums.
- 22 starter tools + 7 categories, seeded from a CSV via an idempotent importer.
- `catalogue_review.csv` curation worksheet with per-tool "what to verify" notes.

**Pages & UI**
- Landing page: search bar + browse-by-category grid.
- Results as a vertical, Google-style list with human labels and the catch.
- Tool detail page with full specs and a `last_verified` trust signal.
- Side-by-side `/compare` view (up to 4 tools), scoped to your previous search
  results, shareable by URL.
- Blog ("Latest in AI"): landing-page section, `/blog` index, and per-post pages.

**Data & automation**
- Event logging: `search`, `specs_expand`, and outbound `card_click`.
- Daily GitHub Action that researches current figures (Claude + web search) and
  opens a review PR proposing catalogue updates — never auto-commits.

**Tooling**
- App version surfaced in the footer (`AiFinder::VERSION`).

### Notes

- Deployment is deferred (runs locally). The LLM parse and freshness job need an
  `ANTHROPIC_API_KEY` with API credit; without it everything falls back to the
  keyword parser and still works.
- Catalogue figures are reasonable approximations pending human curation.

[Unreleased]: https://github.com/mototaxuk-lab/ai-finder/compare/v0.1.0...HEAD
[0.1.0]: https://github.com/mototaxuk-lab/ai-finder/releases/tag/v0.1.0
