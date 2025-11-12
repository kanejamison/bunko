## [Unreleased]

Building toward 1.0.0 release. Using 0.x versions during active development.

### Breaking Changes

**PostType Schema Refactor** - Changed PostType from `name/slug` to `name/title` schema:
- **OLD**: `config.post_type "Blog" do |type| type.slug = "blog" end`
- **NEW**: `config.post_type "blog" do |type| type.title = "Blog" end`
- PostType `name` is now the lowercase identifier (e.g., "blog", "case_studies")
- PostType `title` is the display name (e.g., "Blog", "Case Studies")
- Titles are auto-generated from names using `.titleize`
- Database migration required: rename `slug` column to `title`, rename `name` to `name` (keep identifier)
- Updated: Configuration DSL, rake tasks, controllers, tests, all documentation

### Completed Milestones

**✅ Milestone 1: Post Model Behavior**
- Core `acts_as_bunko_post` concern for ActiveRecord models
  - Scopes: `.published`, `.draft`, `.scheduled`, `.by_post_type(name)`
  - Automatic slug generation from title (URL-safe, unique within post_type)
  - Publishing workflow with auto-setting of `published_at`
  - Reading time calculation from word_count
  - Status validation

**✅ Milestone 2: Collection Controllers**
- Core `bunko_collection` macro for ActionController (no manual includes needed)
  - Index action with built-in pagination (no external dependencies)
  - Show action with slug-based lookup and proper scoping
  - 404 handling for missing/draft/scheduled posts
  - Configurable per_page, ordering, and layout
  - Instance variables: `@posts`, `@post`, `@collection_name`, `@pagination`

**✅ Milestone 3: Installation**
- Two-phase installation system (#2)
  - `rails bunko:install` - Creates migrations, models, and initializer
  - `rails bunko:setup` - Generates controllers, views, and routes from configuration
  - Install options: `SKIP_SEO=true`, `JSON_CONTENT=true`
  - Idempotent setup task (safe to re-run when adding collections)
  - Single-collection setup: `rails bunko:setup[name]`
  - Template-based code generation from `lib/tasks/templates/`

**✅ Milestone 4: Routing Helpers**
- `bunko_collection` DSL method for routes (#4)
  - Automatic hyphenation: `:case_study` → `/case-study/`
  - Custom path support: `bunko_collection :blog, path: "articles"`
  - Custom controller support: `bunko_collection :blog, controller: "articles"`
  - Action limiting: `only: [:index]` or `except: [:show]`
  - Follows Rails conventions (like `resources :blog_posts` → `/blog-posts/`)

**✅ Smart Collections (v1)**
- Virtual collections that aggregate multiple post types
  - `config.collection` DSL for defining multi-type collections
  - Optional scopes for filtering: `config.collection "Long Reads", post_types: ["articles"] { |c| c.scope -> { where("word_count > ?", 1500) } }`
  - Smart lookup: controllers check PostType first, then Collection
  - Name conflict validation prevents name collisions

**✅ Milestone 5: Post Convenience Methods**
- Instance methods for common view patterns (no namespace conflicts)
  - `post.excerpt(length: 160, omission: "...")` - Smart content truncation with HTML stripping
  - `post.published_date(format = :long)` - Locale-aware date formatting via I18n.l
  - `post.reading_time_text` - Returns "X min read" string
- Works identically in index loops and show views
- Clean API: `post.excerpt` instead of `bunko_excerpt(post)`

**Test Suite Improvements**
- Reorganized Post model tests into focused files by functionality:
  - `post_scopes_test.rb` - Query scopes
  - `post_slug_test.rb` - Slug generation and uniqueness
  - `post_publishing_test.rb` - Status and publishing workflow
  - `post_reading_time_test.rb` - Reading time calculations and word count
  - `post_content_formatting_test.rb` - excerpt method
  - `post_date_formatting_test.rb` - published_date method
- Added comprehensive PostType model tests covering validations, associations, edge cases

**Configuration & Infrastructure**
- Configuration system via `Bunko.configure` block (#3)
  - `config.post_type` DSL for defining content collections
  - `config.collection` DSL for smart/virtual collections
  - Configurable reading speed (default: 250 wpm)
  - Configurable excerpt length (default: 160 characters)
  - Configurable auto_update_word_count (default: true)
  - Name conflict validation between PostTypes and Collections
- CI/CD pipeline testing Ruby 3.2, 3.3, 3.4, 3.5

### Next Up
- **Milestone 6: Configuration Expansion** - Additional configuration options
- **Milestone 7: Documentation** - Comprehensive guides and examples
- **Milestone 8: Release** - Version 1.0.0 to RubyGems

## [0.1.0] - 2025-11-09

- Initial release to register gem name on RubyGems
- Placeholder release with basic gem structure and working tests
