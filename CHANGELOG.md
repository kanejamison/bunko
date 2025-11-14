## [Unreleased]

Building toward 1.0.0 release. Using 0.x versions during active development.

## [0.2.0] - 2025-11-14

First functional release of Bunko - a lightweight Rails CMS based on the "one model, infinite collections" philosophy.

**Core Features:**
- One `Post` model routes to many collections (`/blog/`, `/docs/`, `/changelog/`, etc.)
- Two-phase installation: `rails bunko:install` → `rails bunko:setup`
- Configuration-driven setup via `config/initializers/bunko.rb`
- Generated controllers, views, and routes with Pico CSS styling (easily customizable)
- Publishing workflow with draft/published/scheduled states
- Automatic slug generation and reading time calculation
- Post convenience methods: `excerpt`, `published_date`, `reading_time_text`
- Built-in pagination (no external dependencies)

**Static Pages:**
- `bunko_page` routing for standalone pages (About, Contact, Privacy)
- Shared `PagesController` with smart view resolution
- Same Post model, different post_type

**Smart Collections:**
- Aggregate multiple post types: `config.collection "resources", post_types: ["articles", "videos"]`
- Filter with scopes: `config.collection "long_reads" { |c| c.scope = -> { where("word_count > ?", 1500) } }`

**Sample Data Generator:**
- `rails bunko:sample_data` - Generate realistic posts for testing
- HTML and Markdown format support
- Configurable word counts, post counts, and content styles

**Routing:**
- `bunko_collection :blog` - Simple DSL for content routes
- `bunko_page :about` - Single-page routes without collection index
- Automatic hyphenation: `:case_study` → `/case-study/`

## [0.1.0] - 2025-11-09

- Initial release to register gem name on RubyGems
- Placeholder release with basic gem structure and working tests
