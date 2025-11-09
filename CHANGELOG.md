## [Unreleased]

Building toward 1.0.0 release. Using 0.x versions during active development.

### Added
- Core `acts_as_bunko_post` concern for ActiveRecord models
  - Scopes: `.published`, `.draft`, `.scheduled`, `.by_post_type(slug)`
  - Automatic slug generation from title (URL-safe, unique within post_type)
  - Publishing workflow with auto-setting of `published_at`
  - Reading time calculation from word_count
  - Status validation
- Core `bunko_collection` concern for ActionController
  - Index action with built-in pagination (no external dependencies)
  - Show action with slug-based lookup and proper scoping
  - 404 handling for missing/draft/scheduled posts
  - Configurable per_page, ordering, and layout
- Configuration system via `Bunko.configure` block
  - Configurable reading speed (default: 200 wpm)
  - Configurable valid statuses (default: draft, published, scheduled)
- Test suite with 37 tests, 67 assertions (100% passing)
- CI/CD pipeline testing Ruby 3.2, 3.3, 3.4, 3.5

### In Progress
- Installation generator (`rails generate bunko:install`)
- Routing helpers
- View helpers
- Expanded configuration options
- Documentation and examples

## [0.1.0] - 2025-11-09

- Initial release to register gem name on RubyGems
- Placeholder release with basic gem structure and working tests
