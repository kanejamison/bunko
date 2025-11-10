# Bunko 1.0 Roadmap

**Goal:** Ship a production-ready CMS gem where a Rails developer can add `gem "bunko"`, run one generator, and have a working blog in under 5 minutes. Officially we are only targeting support for Rails but we are trying to keep dependencies as light as possible.

**Note:** Version 0.1.0 was released as a placeholder to register the gem name. We're now building toward 1.0.0, using 0.x versions during active development.

---

## Development Status

- [x] **Milestone 1: Post Model Behavior** - ✅ COMPLETED
- [x] **Milestone 2: Collection Controllers** - ✅ COMPLETED
- [x] **Milestone 3: Installation Generator** - ✅ COMPLETED
- [x] **Milestone 4: Routing Helpers** - ✅ COMPLETED
- [x] **Milestone 5: Post Convenience Methods** - ✅ COMPLETED
- [ ] **Milestone 6: Configuration** - 🚧 PENDING (core system exists, needs expansion)
- [ ] **Milestone 7: Documentation** - 🚧 PENDING
- [ ] **Milestone 8: Release** - 🚧 PENDING

---

## Success Criteria

By 1.0, a Rails developer should be able to:

1. ✅ Install Bunko and generate a working blog in < 5 minutes
2. ✅ Add a second content collection (e.g., `/docs`) in < 2 minutes
3. ✅ Attach the text editor of their choice to create and edit posts
4. ✅ Schedule posts for future publication
5. ✅ Organize content into different post types without migrations
6. ✅ Customize views with their own HTML/CSS
7. ✅ Automatically use slug-based URLs instead of IDs

---

## Milestone 1: Post Model Behavior

**Spec:** A Post model with Bunko enabled should have all essential CMS functionality.

### Required Behavior

**Scopes & Queries:**
- Developer can query `Post.published` and only see published posts with `published_at <= Time.current`
- Developer can query `Post.draft` and only see draft posts
- Developer can query `Post.scheduled` and only see posts scheduled for future publication
- Developer can filter posts by type: `Post.by_post_type('blog')` or similar API
- Default ordering shows most recent posts first

**Slug Generation:**
- When a post is created without a slug, one is auto-generated from the title
- Slugs are URL-safe (e.g., "Hello World" becomes "hello-world")
- Slugs are unique within their post_type
- Developer can provide custom slug and it won't be overwritten

**Publishing Workflow:**
- Post status can be: 'draft', 'published', or 'scheduled'
- When status changes to 'published' and `published_at` is blank, it auto-sets to current time
- Posts with status='published' but `published_at` in future are treated as scheduled
- Invalid status values are rejected

**Reading Metrics:**
- If post has `word_count`, developer can get estimated reading time
- Reading time calculation is configurable (default ~250 words/minute)

**Routing Support:**
- Users should be able to route #index/#show collections of posts with a simple routes entry, eg something like "mount_bunko :case_studies" should automatically show all posts where post_type = 'case_study' (or 'case_studies'?) in the subfolder /case-studies/ with the slug for that post. Similar to if they wrote this:
    - resources :case_studies, controller: 'case_studies', path: 'case-studies', param: :slug, only: %i[index show]
- Users should possibly be able to route their core Posts model behind their existing admin / auth area, similar to how they mount sidekiq. This section is intended to be admin only for post editing - so full CRUD but not publicly visible. This should be optional, eg if they want to use a tool like Avo with their [Rhino editor](https://docs.avohq.io/3.0/fields/rhino.html) or [Markdown editor](https://docs.avohq.io/3.0/fields/markdown.html), they don't need to mount this section at all. https://avohq.io/

```
require "sidekiq/web" # require the web UI

Rails.application.routes.draw do
  mount Sidekiq::Web => "/sidekiq" # access it at http://localhost:3000/sidekiq
  ...
end
```

### Acceptance Test

```ruby
# Developer can do this:
class Post < ApplicationRecord
  acts_as_bunko_post  # or whatever the API is
end

# And get this behavior:
post = Post.create!(title: "Hello World", content: "...", post_type: 'blog')
post.slug # => "hello-world"
post.to_param # => "hello-world"
post.status # => "draft"

post.update!(status: 'published')
post.published_at # => Time.current (auto-set)

Post.published.count # => 1
Post.draft.count # => 0
```

---

## Milestone 2: Collection Controllers

**Spec:** A controller should be able to serve a content collection with minimal code.

### Required Behavior

**Defaults**
- If user just adds a routes, all of our standard behaviors should be observed.
- If user chooses to generate their own controller, we should allow that.
- If user wants to use our controllers but adjust settings through bunko.rb initializer, we should allow that.

**Index Action:**
- Shows all published posts for a given post_type
- Does not leak other configured posts types in any way or scopes
- Paginates results - recommend pagy but this should be adaptable? Or perhaps enable Pagy or kamanari behavior in a bunko.rb initializer
- Allows customization of per_page, ordering, layout
- Provides access to collection name in views

**Show Action:**
- Finds post by slug
- Scoped to the correct  - eg you should be able to have same slug on 2 different post types
- Returns 404 if not found (and routes doesn't take over with a 301 or something)
- Provides access to the post in views

**Multiple Post Types:**
- Single controller can serve multiple related post types
- Example: Resources controller serves guides, templates, checklists

### Acceptance Test

```ruby
# Developer can do this:
class BlogController < ApplicationController
  bunko_collection :blog  # or whatever the API is
end

# And get these routes working:
GET /blog          # => BlogController#index (lists blog posts)
GET /blog/:slug    # => BlogController#show (shows single post)

# Views have access to:
@posts             # in index
@post              # in show
@collection_name   # 'blog'

# Developer can customize:
class ChangelogController < ApplicationController
  bunko_collection :changelog, per_page: 20, layout: 'docs'
end
```

---

## Milestone 3: Installation Generator

**Spec:** Running `rails generate bunko:install` should create everything needed for a working blog.

**Implementation Note:** This milestone was implemented as a two-phase pattern:
1. `rails generate bunko:install` - Creates migrations, models, and initializer
2. `rails bunko:setup` - Generates controllers, views, and routes based on configuration

This approach allows users to customize their post types in the initializer before generating the controllers/views, and makes it easy to add new collections later.

### Required Behavior

**Migration Creation:**
- Detects database type (PostgreSQL, SQLite, MySQL) and generates appropriate migration
- Creates `posts` table with essential fields:
  - `title` (string, required)
  - `slug` (string, required, indexed)
  - `content` (text by default, json/jsonb with `--json-content` flag for JSON-based editors)
  - `post_type` (references, required)
  - `status` (string, indexed, default: 'draft') # should this be references to a post_status table?
  - `published_at` (datetime, indexed)
  - Timestamps for created_at and updated_at
- Creates `post_types` table with essential fields:
  - `name` (string, required)
  - `slug` (string, required, indexed)
  - Timestamps
- Adds unique constraint on `[slug, post_type]`
- A post should always have only one post_type, or allow nil? Never multiple though. By default we should load in Post? Or allow nil?
- Optional fields based on flags (see Generator Options below)
- User should be able to override our migration and add something like "acts_as_post" to the model to get the same behaviors.

**Model Generation:**
- Creates `app/models/post.rb` with Bunko enabled
- Creates `app/models/post_type.rb` with Bunko enabled
- Includes comments explaining customization

**Controller Generation:**
- Creates `app/controllers/blog_controller.rb`
- Configured to serve 'blog' post type
- Includes comments explaining how to add more collections

**View Generation:**
- Creates `app/views/blog/index.html.erb` with semantic HTML
- Creates `app/views/blog/show.html.erb` with semantic HTML
- No CSS, no JavaScript - just clean HTML with helpful comments
- Shows title, content, published date, reading time

**Route Generation:**
- Adds routes for blog (index + show)
- Uses slug as param, not ID

**Initializer Generation:**
- Creates `config/initializers/bunko.rb`
- Includes common configuration options (commented out with examples)

**Post-Install Message:**
- Shows next steps (run migration, create first post)
- Links to documentation

### Generator Options

- `--skip-seo` - Skip adding SEO fields (meta_title, meta_description)
- `--json-content` - Use json/jsonb for content field instead of text (for JSON-based editors)

### Acceptance Test

```bash
# Developer runs:
$ rails generate bunko:install
$ rails db:migrate

# Result: They can visit /blog and see a working (empty) blog
# They can create a post in console and see it at /blog/post-slug
```

---

## Milestone 4: Routing Helpers

**Spec:** Setting up routes for collections should be simple and conventional.

### Required Behavior

**Route DSL:**
- Developer can call `bunko_collection :blog` instead of writing full resources line
- Supports custom paths (e.g., `bunko_collection :case_study, path: 'case-studies'`)
- Supports limiting actions (e.g., `only: [:index]` for index-only collection) # not critical
- Supports custom controller names

### Acceptance Test

```ruby
# Developer can do this in config/routes.rb:
Rails.application.routes.draw do
  bunko_collection :blog
  bunko_collection :docs
  bunko_collection :case_study, path: 'case-studies' #perhaps path should be automatically hyphenated and/or inflected/pluralized?
end

# And get these routes:
# /blog          => blog#index
# /blog/:slug    => blog#show
# /docs          => docs#index
# /docs/:slug    => docs#show
# /case-studies      => case_study#index
# /case-studies/:slug => case_study#show
```

---

## Milestone 5: Post Convenience Methods

**Spec:** Common CMS view patterns should be available as Post instance methods for clean, conflict-free usage in views.

**Implementation Note:** Originally planned as view helpers, we decided to implement these as Post model methods instead. This approach:
- Avoids namespace conflicts (no `bunko_` prefix needed)
- Keeps views cleaner (`post.excerpt` vs `bunko_excerpt(post)`)
- Follows Rails conventions for model presentation logic
- Works identically in index loops and show views

### Required Behavior

**Content Formatting:**
- `post.excerpt(length: 160, omission: "...")` - returns truncated content, strips HTML, preserves word boundaries
- `post.reading_time_text` - returns "X min read" string (extends existing `reading_time` integer method)

**Date Formatting:**
- `post.published_date(format = :long)` - returns formatted published_at using I18n.l
- Supports Rails date formats: `:long`, `:short`, `:db`, custom strftime

**Meta Tags:**
- `post.meta_description_tag` - returns HTML-safe `<meta>` tag if meta_description field exists
- Returns nil if field doesn't exist or is blank
- Minimal SEO helper - users handle title tags via Rails' `content_for`

**Navigation:**
- Not needed - routing DSL automatically generates helpers like `blog_path`, `blog_post_path(post)`

### Acceptance Test

```erb
<!-- Index view: loop over posts -->
<% @posts.each do |post| %>
  <article>
    <h2><%= link_to post.title, blog_post_path(post) %></h2>
    <p class="meta">
      <%= post.published_date %> · <%= post.reading_time_text %>
    </p>
    <p><%= post.excerpt %></p>
  </article>
<% end %>

<!-- Show view: single post -->
<head>
  <%= @post.meta_description_tag %>
</head>

<article>
  <h1><%= @post.title %></h1>
  <p class="meta">
    <%= @post.published_date(:long) %> · <%= @post.reading_time_text %>
  </p>
  <div class="content">
    <%= @post.content %>
  </div>
</article>
```

---

## Milestone 6: Configuration

**Spec:** Bunko behavior should be customizable via initializer without modifying gem code.

### Required Behavior

**Configurable Options:**
- Post model name (default: 'Post')
- Valid post types (default: ['post'])
- Valid statuses (default: ['draft', 'published', 'scheduled'])
- Default status (default: 'draft')
- Reading speed in words/minute (default: 250)
- Excerpt length (default: 160)
- Slug generation strategy (default: parameterize)

**Configuration API:**
- Developer uses block syntax in initializer
- Configuration is globally accessible
- Invalid configuration values are validated

### Acceptance Test

```ruby
# Developer can configure in config/initializers/bunko.rb:
Bunko.configure do |config|
  config.post_type "Post"
  config.post_type "Page"
  config.post_type "Doc"
  config.post_type "Tutorial"

  config.reading_speed = 200
  config.excerpt_length = 200
  config.slug_generator = ->(title) { title.parameterize.truncate(50) }
end

# And it affects behavior:
post = Post.create!(title: "Very Long Title...")
# slug uses custom generator
```

---

## Milestone 7: Documentation

**Spec:** Documentation should be excellent, examples should be practical.

### Required Deliverables

**README.md:**
- Philosophy and goals clearly stated
- Installation instructions (add to Gemfile, run generator)
- Quick start guide (5 minute blog)
- Multi-collection setup example
- Configuration options documented
- Customization patterns explained
- What Bunko doesn't do (auth, admin UI, etc.)

**EXAMPLES.md:**
- Basic blog setup
- Blog + docs setup
- Custom fields using metadata
- Custom scopes
- Overriding views
- Integration with admin gems (Avo, Administrate, etc.)

**Code Documentation:**
- All public APIs have clear documentation
- Generated code includes helpful comments
- Configuration options explained in generated initializer

**Example Apps:**
- `examples/basic_blog` - Minimal blog
- `examples/multi_collection` - Blog + docs + changelog

### Acceptance Test

New developer can:
- Read README and understand what Bunko does in < 2 minutes
- Follow quick start and have working blog in < 5 minutes
- Find answer to "how do I customize X?" in documentation
- Clone an example app and see Bunko in action

---

## Milestone 8: Release

**Spec:** 0.1.0 is published to RubyGems and ready for production use.

### Required Before Release

**Compatibility:**
- Works with Rails 7.2+ and follows Rails EOL maintenance policy
- Works with Ruby 3.1, 3.2, 3.3, 3.4 and follows Ruby EOL maintenance policy
- Works with PostgreSQL, SQLite, MySQL
- Test coverage > 90%
- All Standard linter checks pass

**Package:**
- bunko.gemspec has no TODOs
- Proper description and summary
- Correct homepage and source URLs
- Appropriate version number (0.1.0)
- CHANGELOG.md updated

**Documentation:**
- README complete and accurate
- EXAMPLES.md or docs have practical examples
- Generated code has helpful comments
- GitHub release notes written

**Distribution:**
- Gem builds successfully
- Gem published to RubyGems
- GitHub release created
- Installation tested in fresh Rails app

### Acceptance Test

```bash
# Any developer can:
$ gem install bunko
$ rails new myblog
$ cd myblog
$ bundle add bunko
$ rails generate bunko:install
$ rails db:migrate
$ rails server

# Visit http://localhost:3000/blog and see working blog
```

---

## Out of Scope for 0.1

These are excellent features but not required for initial release:

- **Admin UI generator** - `rails generate bunko:admin` (0.2.0)
- **Seed task** - `rails bunko:seed` for sample content (0.2.0)
- **Custom fields DSL** - Beyond metadata jsonb (0.3.0)
- **Publishing callbacks** - `after_publish`, etc. (0.3.0)
- **Versioning support** - Draft history, rollback (0.3.0)
- **Multi-collection controllers** - Single controller, many types (0.2.0)
- **Author associations** - belongs_to :author (0.2.0)
- **Category/tag models** - For now, use strings or metadata (0.3.0)

---

## Initial Release Development Approach

**PR-Based Development:**
- Each milestone is one or more PRs
- PRs focus on making specs pass
- Implementation details are decided in PR, not roadmap
- Tests confirm specs are met

**Testing Strategy:**
- Write specs first (behavior-driven)
- Create test app in test/dummy
- Aim for high test coverage
- Test across Ruby/Rails versions in CI

**Quality Standards:**
- All code passes Standard linter
- No runtime dependencies beyond Rails
- Public APIs are documented
