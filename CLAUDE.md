# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project Overview

Bunko is a Rails gem that provides a lightweight CMS structure based on a "one model, infinite collections" philosophy. It allows developers to create multiple content collections (blog, docs, changelog, tutorials, etc.) without duplicate code or migrations, routing all content through a single Post model.

**Core Philosophy:**
- Out-of-the-box blog without the bloat
- One Post model routes to many collections (`/blog/`, `/docs/`, `/changelog/`, etc.)
- Database, editor, and view layer agnostic
- No opinions on JavaScript, CSS, authentication, authorization, or admin UI
- Conventions over configuration with escape hatches

## Development Commands

### Testing
```bash
# Run all tests
rake test
# or
bundle exec rake test

# Run a single test file
ruby test/test_bunko.rb

# Run a specific test
ruby test/test_bunko.rb --name test_that_it_has_a_version_number
```

### Linting
```bash
# Run Standard Ruby linter
rake standard
# or
bundle exec standardrb

# Auto-fix linting issues
bundle exec standardrb --fix
```

### Default Task (Tests + Linting)
```bash
# Runs both test suite and standard linter
rake
# or
bundle exec rake
```

### Console
```bash
# Interactive console for experimentation
bin/console
```

### Setup
```bash
# Install dependencies after cloning
bin/setup
```

### Gem Management
```bash
# Install gem locally
bundle exec rake install

# Build gem file
bundle exec rake build

# Release new version (updates version.rb, creates git tag, pushes to rubygems)
bundle exec rake release
```

## Project Structure

```
lib/
├── bunko/
│   ├── version.rb              # Version constant
│   ├── configuration.rb        # Configuration system with post_type DSL
│   ├── models/                 # ActiveRecord model concerns
│   │   ├── acts_as.rb          # acts_as_bunko_post/post_type macros
│   │   ├── post_methods.rb     # Post behavior (concern)
│   │   └── post_type_methods.rb # PostType behavior (concern)
│   ├── controllers/            # ActionController concerns
│   │   ├── acts_as.rb          # bunko_collection macro
│   │   └── collection.rb       # Collection behavior (concern)
│   ├── routing/                # ActionDispatch routing extensions
│   │   └── mapper_methods.rb   # bunko_collection DSL method
│   └── railtie.rb              # Rails integration (loads rake tasks, routing)
├── generators/bunko/install/
│   ├── install_generator.rb    # rails generate bunko:install
│   └── templates/              # Migration and model templates
└── tasks/
    └── bunko/
        ├── setup.rake          # rails bunko:setup task
        ├── add.rake            # rails bunko:add[name] task
        └── sample_data.rake    # rails bunko:sample_data task
    └── templates/              # Controller and view templates
        ├── controller.rb.tt
        ├── index.html.erb.tt
        ├── show.html.erb.tt
        ├── pages_controller.rb.tt    # PagesController template for static pages
        ├── page_show.html.erb.tt     # Default page view template
        ├── bunko_nav.html.erb.tt     # Shared nav partial
        ├── bunko_styles.html.erb.tt  # Shared styles partial (Pico CSS)
        └── bunko_footer.html.erb.tt  # Shared footer partial
test/
├── dummy/                  # Rails dummy app for integration testing
├── models/                 # Model tests (organized by functionality)
│   ├── post_scopes_test.rb           # Query scopes (6 tests)
│   ├── post_slug_test.rb             # Slug generation (10 tests)
│   ├── post_publishing_test.rb       # Publishing workflow (11 tests)
│   ├── post_reading_time_test.rb     # Reading time (7 tests)
│   ├── post_content_formatting_test.rb # Excerpt method (7 tests)
│   ├── post_date_formatting_test.rb  # Date formatting (5 tests)
│   ├── post_meta_tags_test.rb        # Meta tags (5 tests)
│   └── post_type_test.rb             # PostType model (16 tests)
├── controllers/            # Controller integration tests
├── routing/                # Routing DSL tests
├── generators/             # Generator tests
├── configuration/          # Configuration tests
└── tasks/                  # Rake task tests
.github/workflows/         # CI/CD pipeline (runs rake: test + standard)
```

### Test Dummy App

Integration tests run against a minimal Rails app in `test/dummy/`:
- Provides real Rails environment for testing migrations, controllers, routes, views
- Committed to git (excluding tmp/, log/, etc.)
- Database schema is managed via migrations in `test/dummy/db/migrate/`

## Requirements

- Ruby >= 3.2.0
- Rails >= 8.0
- Bundler

## Development Notes

- This gem uses **Standard** for Ruby linting (configured in `.standard.yml`)
- Tests use **Minitest** framework
- CI runs on GitHub Actions (`.github/workflows/main.yml`) and executes `bundle exec rake`

## Current Features (Implemented)

**Milestone 1 - Post Model Behavior:**
- `acts_as_bunko_post` concern with scopes (`.published`, `.draft`, `.scheduled`, `.by_post_type`)
- Automatic slug generation from titles (URL-safe, unique within post_type)
- Publishing workflow (auto-sets `published_at` when status changes to "published")
- Reading time calculation based on word_count

**Milestone 2 - Collection Controllers:**
- `bunko_collection` concern for automatic index/show actions
- Built-in pagination (configurable per_page, default: 10)
- Scoped queries (each collection only sees its post_type)
- Available instance variables: `@posts`, `@post`, `@collection_name`, `@pagination`

**Milestone 3 - Installation Generator:**
- Two-phase installation pattern:
  1. `rails generate bunko:install` - Creates migrations, models, initializer
  2. `rails bunko:setup` - Generates controllers, views, routes from configuration
- Generator options: `--skip-seo`, `--json-content`
- Configuration-driven: Define post_types in `config/initializers/bunko.rb`
- Idempotent setup task (safe to re-run when adding new collections)
- Single-collection setup: `rails bunko:add[name]` for adding individual collections
- Generated views include:
  - Semantic HTML structure (`<header>`, `<main>`, `<section>`, `<footer>`)
  - Shared partials: `_bunko_nav.html.erb`, `_bunko_styles.html.erb`, `_bunko_footer.html.erb`
  - Basic styling with Pico CSS (https://picocss.com/) - easily removable for custom designs
  - Responsive navigation with collection links
  - Clean, customizable templates

**Milestone 4 - Routing Helpers:**
- `bunko_collection` DSL method extends `ActionDispatch::Routing::Mapper`
- Automatic hyphenation: underscored slugs (`:case_study`) convert to hyphenated URLs (`/case-study/`)
- Custom path support: `bunko_collection :case_study, path: "case-studies"`
- Custom controller support: `bunko_collection :blog, controller: "articles"`
- Action limiting: `bunko_collection :blog, only: [:index]`
- Follows Rails idiomatic conventions (like `resources :blog_posts` → `/blog-posts/`)

**Smart Collections (v1):**
- `config.collection` for defining virtual collections
- Multi-type collections: aggregate posts from multiple PostTypes
- Optional scopes: filter collections with custom ActiveRecord scopes
- Smart lookup: controllers check PostType first, then Collection
- Name conflict validation: prevents PostType/Collection slug collisions
- Future-ready: designed to support features like authorship, featured flags, taxonomies

**Milestone 5 - Post Convenience Methods:**
- Instance methods for common view patterns (no namespace conflicts)
- Implementation: Methods added directly to PostMethods concern (not view helpers)
  - Avoids namespace conflicts - `post.excerpt` instead of `bunko_excerpt(post)`
  - Works identically in index loops and show views
  - No helper prefix needed
- Methods:
  - `post.excerpt(length:, omission:)` - Smart content truncation with HTML stripping
  - `post.published_date(format)` - Locale-aware date formatting via I18n.l
  - `post.reading_time_text` - Returns "X min read" string

**Sample Data Generator:**
- `rails bunko:sample_data` - Generate realistic sample posts for all configured post types
- Configurable options:
  - `COUNT=N` - Number of posts per post type (default: 100)
  - `FORMAT=plain|markdown|html` - Content format (default: plain)
  - `MIN_WORDS=N` and `MAX_WORDS=N` - Word count range (default: 200-2000)
  - `CLEAR=true` - Clear existing posts before generating
- Generated posts include:
  - Realistic titles based on post type
  - Unique slugs
  - Meta descriptions and title tags
  - Published dates (90% past, 10% scheduled for future)
  - Automatic word count calculation
  - Formatted content with headings, paragraphs, lists, blockquotes, and links
- HTML format includes semantic tags and optional CSS classes for styling
- Markdown format includes full Markdown syntax
- Useful for testing, demos, and development

**Static Pages (Milestone 6):**
- `bunko_page` routing DSL for standalone pages (e.g., About, Contact, Privacy)
- Single shared `PagesController` for all pages (no per-page controller generation)
- Smart view resolution: checks for custom templates (e.g., `pages/about.html.erb`) or falls back to default
- Opt-out configuration: `config.allow_static_pages = false`
- Reserved "pages" post_type namespace with validation
- Auto-generated during `rails bunko:setup` if enabled (default: true)
- Supports custom paths and controllers: `bunko_page :about, path: "about-us"`
- Works with namespaces: `namespace :legal do bunko_page :privacy end`
- Same Post model as collections (one-model architecture maintained)

## Development Roadmap

See ROADMAP.md for the complete 1.0.0 release plan with specs and milestones.

**Current Status:**
- ✅ Milestone 1: Post Model Behavior - COMPLETED
- ✅ Milestone 2: Collection Controllers - COMPLETED
- ✅ Milestone 3: Installation Generator - COMPLETED
- ✅ Milestone 4: Routing Helpers - COMPLETED
- ✅ Milestone 5: Post Convenience Methods - COMPLETED
- ✅ Milestone 6: Static Pages - COMPLETED
- 🚧 Milestone 7: Configuration - PENDING (core system exists, may need expansion)
- 🚧 Milestone 8: Documentation - PENDING
- 🚧 Milestone 9: Release - PENDING

## Architecture Principles

When implementing features for this gem:

1. **Keep it lightweight** - Avoid dependencies unless absolutely necessary
2. **Stay agnostic** - Don't force opinions on editors, view layers, auth, etc.
3. **One model architecture** - All content types share the Post model with collection-based routing
4. **Convention with escape hatches** - Provide sensible defaults but allow customization
5. **No forced UI** - Helpers over components; let developers control their HTML
6. **Specs over implementation** - Focus on behavior and outcomes, not prescriptive solutions

## Concern Pattern Architecture

Bunko follows a consistent concern pattern inspired by gems like Devise and RubyLLM. This pattern:
- Avoids namespace collisions with user models/controllers
- Provides clean, extensible organization
- Follows Rails conventions for `acts_as_*` style macros

### Pattern Structure

```
lib/bunko/<layer>/
  acts_as.rb          # Public macros (acts_as_bunko_post, bunko_collection)
  *_methods.rb        # Internal concern modules (PostMethods, Collection)
```

**Key principles:**
- **Public API:** Users call macros like `acts_as_bunko_post` or `bunko_collection`
- **Internal modules:** Implementation lives in `Bunko::Models::PostMethods`, `Bunko::Controllers::Collection`
- **No `::` prefixes needed:** Namespacing avoids collisions with `Post`, `PostType`, etc.

### Current Implementations

**Models Layer (`lib/bunko/models/`):**
```ruby
# acts_as.rb - Defines the acts_as macros
ActiveRecord::Base.include Bunko::Models::ActsAs

# post_methods.rb - Post behavior concern
module Bunko::Models::PostMethods
  # Associations, validations, scopes, callbacks
end

# post_type_methods.rb - PostType behavior concern
module Bunko::Models::PostTypeMethods
  # Associations, validations
end
```

**Controllers Layer (`lib/bunko/controllers/`):**
```ruby
# acts_as.rb - Defines bunko_collection macro
ActionController::Base.include Bunko::Controllers::ActsAs

# collection.rb - Collection behavior concern
module Bunko::Controllers::Collection
  # Index/show actions, pagination, routing
end
```

**Routing Layer (`lib/bunko/routing/`):**
```ruby
# Extends ActionDispatch::Routing::Mapper with bunko_collection DSL
# Loaded via railtie initializer on :action_controller load

# mapper_methods.rb - Routing DSL methods
module Bunko::Routing::MapperMethods
  def bunko_collection(collection_slug, **options)
    # Creates resourceful routes with slug param
    # Automatically converts underscored slugs to hyphenated URLs
  end
end
```

**Note on slug storage and URL formatting:**
- Slugs are stored with underscores in the database (`:case_study`)
- URLs automatically use hyphens (`/case-study/`)
- This follows Rails conventions (e.g., `resources :blog_posts` → `/blog-posts/`)
- Users call routes with underscores: `bunko_collection :case_study`
- Generated helpers use underscores: `case_study_path(post)`

### When to Deviate from This Pattern

Use the `Bunko::<Layer>::<Methods>` pattern when:
- ✅ Adding behavior to existing classes (models, controllers)
- ✅ Using `include` to mix functionality in
- ✅ Providing an `acts_as_*` style API

Use different patterns for:
- ❌ Standalone utility classes (use `Bunko::Services::ClassName`)
- ❌ Rails conventions (validators, helpers, generators - follow Rails patterns)
- ❌ Service/Query objects (use `Bunko::Services::`, `Bunko::Queries::`)
- ❌ Presenters/Serializers (use `Bunko::Serializers::`, `Bunko::Presenters::`)
- ❌ Configuration objects (use `Bunko::Configuration`)
- ❌ Middleware (use `Bunko::Middleware::`)

**Example of future helpers (when needed):**
```ruby
# lib/bunko/helpers/post_helper.rb
module Bunko::Helpers::PostHelper
  def bunko_reading_time(post)
    # Helper logic
  end
end

# Included in views via railtie
ActionView::Base.include Bunko::Helpers::PostHelper
```
