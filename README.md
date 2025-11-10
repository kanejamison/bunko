# Bunko

Bunko (文庫) in Japanese means a small personal library or book collection - a perfect name for a Rails gem that organizes your content elegantly.

## ⚠️ Development Status

**Bunko is currently in active development and not yet ready for production use.** We're building toward a 1.0.0 release with core functionality that we think is safe for production usage. See the roadmap below for progress.

### 1.0.0 Roadmap Progress

- [x] **Milestone 1: Post Model Behavior** - Core `acts_as_bunko_post` concern with scopes, slug generation, publishing workflow, and reading time calculation
- [x] **Milestone 2: Collection Controllers** - `bunko_collection` concern for automatic index/show actions with built-in pagination
- [x] **Milestone 3: Installation Generator** - `rails generate bunko:install` command and `rails bunko:setup` task
- [x] **Milestone 4: Routing Helpers** - `bunko_collection` DSL for simple collection routing with automatic hyphenation
- [x] **Milestone 5: Post Convenience Methods** - Instance methods for excerpts, date formatting, reading time text, and meta tags
- [ ] **Milestone 6: Configuration** - Expanded configuration system
- [ ] **Milestone 7: Documentation** - Usage guides and examples
- [ ] **Milestone 8: Release** - Version 1.0.0 to RubyGems

## Philosophy

**One model, infinite collections.** Bunko gives you a robust CMS structure in 5 minutes. Whether you just want a classic blog, or if you want dozens of post types across your site, Bunko scales to handle dozens of content collections without new database migrations or excessive code duplication every time you launch a new collection. All content are posts - and you can mount collections of posts to whatever routes you like with #index & #show actions.

## Overview

* **Out-of-the-box blog without the bloat** - Install, generate, and publish in under 5 minutes
* **One Post model, many collections** - Route the same content model to `/blog/`, `/docs/`, `/changelog/`, `/tutorials/` - whatever you need
* **Database agnostic** - Works fine with SQLite, PostgreSQL, etc.
* **Editor agnostic** - ActionText, Lexxy, Trix, markdown, plain text - use what works for your team, or hook it up to a tool like Avo.
* **View layer agnostic** - We provide helpers, you control the HTML. Works just fine with ERB, HAML, Slim, ViewComponent, or Phlex
* **Zero JavaScript/CSS opinions** - Bring your own Tailwind, Bootstrap, or vanilla styles

## Requirements

- Ruby >= 3.2.0
- Rails >= 8.0

## Quick Start

### 1. Add to Gemfile

```ruby
gem "bunko"
```

```bash
bundle install
```

### 2. Install Bunko

```bash
rails generate bunko:install
```

This creates:
- Database migrations for `post_types` and `posts`
- `Post` and `PostType` models with `acts_as_bunko_post`
- `config/initializers/bunko.rb` with configuration

### 3. (Optional) Customize Collections

Edit `config/initializers/bunko.rb` to define your content collections:

```ruby
Bunko.configure do |config|
  config.post_type "blog"  # Title auto-generated as "Blog"

  config.post_type "docs" do |type|
    type.title = "Documentation"  # Custom title
  end

  config.post_type "changelog"  # Title: "Changelog"
end
```

### 4. Run Migrations

```bash
rails db:migrate
```

### 5. Generate Controllers, Views, and Routes

```bash
rails bunko:setup
```

For each Post Type and Collection you have defined this generates:
- Controllers (e.g., `BlogController`, `DocsController`)
- View templates (e.g., `/app/views/blog/index`, `/app/views/blog/show`, etc)
- Routes (e.g., `bunko_collection :blog`, `bunko_collection :docs`)

**Adding more collections later?** Just update the initializer and run:
```bash
rails bunko:setup[new_collection_name]
```

### 6. Create Your First Post

```ruby
# In Rails console or your admin interface
blog_type = PostType.find_by(name: "blog")

Post.create!(
  title: "Welcome to Bunko",
  content: "This is your first blog post!",
  post_type: blog_type,
  status: "published",
  published_at: Time.current
)
```

### 7. Visit Your Blog

Start your Rails server and visit:
- `http://localhost:3000/blog` - Blog index
- `http://localhost:3000/docs` - Documentation index
- `http://localhost:3000/changelog` - Changelog index

### 8. (Optional) Generate Sample Data

Want to see your collections in action? Bunko includes a sample data generator that creates realistic posts for all your configured post types:

```bash
# Generate 100 posts per post type (default)
rails bunko:sample_data

# Generate 50 posts per post type
rails bunko:sample_data COUNT=50

# Generate posts with specific word counts
rails bunko:sample_data MIN_WORDS=500 MAX_WORDS=1500

# Clear existing posts first
rails bunko:sample_data CLEAR=true
```

**Content Formats:**

The generator supports three content formats:

```bash
# Plain text (default) - Simple text with ## headings
rails bunko:sample_data FORMAT=plain

# Markdown - Full markdown formatting with bold, italic, lists, links, blockquotes
rails bunko:sample_data FORMAT=markdown

# HTML - Semantic HTML with optional CSS classes
rails bunko:sample_data FORMAT=html
```

**What gets generated:**

The sample data generator creates structured content tailored to each post type:

- **Blog posts**: Introduction, body content, and conclusion
- **Documentation**: Overview, getting started, examples (with code blocks), and configuration
- **Changelogs**: Version numbers with Added/Fixed/Changed/Improved sections
- **Case studies**: Challenge, solution, results (with metrics), and conclusion
- **Tutorials**: Prerequisites, numbered steps, and troubleshooting

All posts include:
- Realistic titles based on post type
- Unique slugs
- Meta descriptions
- Title tags
- Published dates (90% past, 10% scheduled for future)
- Automatic word count calculation

**HTML Format Features:**

When using `FORMAT=html`, content includes:
- Semantic HTML5 tags (`<h2>`, `<p>`, `<blockquote>`, `<ul>`, `<li>`)
- Random inline formatting (`<strong>`, `<em>`, `<u>`)
- Optional CSS classes for styling:
  - `class="content-paragraph"` on some paragraphs
  - `class="section-heading"` on some headings
  - `class="content-list"` on some lists
  - `class="content-quote"` on some blockquotes
- Safe external links (Ruby on Rails, RubyGems, Bunko GitHub)

**Markdown Format Features:**

When using `FORMAT=markdown`, content includes:
- Markdown headings (`## Heading`)
- Bold (`**text**`) and italic (`_text_`) formatting
- Unordered lists (`- item`)
- Blockquotes (`> quote`)
- Links to safe external resources

## Generator Options

Customize the installation to fit your needs:

```bash
# Exclude SEO fields (title_tag, meta_description)
rails generate bunko:install --skip-seo

# Use JSON/JSONB for content field (for JSON-based editors)
rails generate bunko:install --json-content

# Minimal install (no SEO fields)
rails generate bunko:install --skip-seo
```

## Available Features

### Post Model Scopes

```ruby
Post.published           # All published posts with published_at <= now
Post.draft              # All draft posts
Post.scheduled          # Published posts with published_at > now
Post.by_post_type("blog")  # All posts for a specific collection
```

### Automatic Slug Generation

```ruby
post = Post.new(title: "Hello World!")
post.save
post.slug  # => "hello-world"

# Handles uniqueness within post_type (adds random suffix)
post2 = Post.new(title: "Hello World!", post_type: blog_type)
post2.save
post2.slug  # => "hello-world-a1b2c3d4" (8-character random hex)
```

### Publishing Workflow

```ruby
post = Post.create(title: "My Post", status: "draft")
post.published_at  # => nil

# Schedule a post for future publication
post.update(status: "published", published_at: 1.hour.from_now)
post.scheduled?  # => true

# Publish immediately (auto-sets published_at)
post.update(status: "published")
post.published_at  # => automatically set to current time
```

### Reading Time Calculation

```ruby
post = Post.create(title: "Article", word_count: 500)
post.reading_time       # => 2 (minutes, based on 250 wpm default)
post.reading_time_text  # => "2 min read"
```

### Post Convenience Methods

Bunko provides instance methods on Post for common view patterns:

```ruby
# Content formatting
post.excerpt                           # => "This is a preview of the content..."
post.excerpt(length: 100, omission: "…")  # Custom length and omission

# Date formatting
post.published_date              # => "November 09, 2025" (locale-aware, :long format)
post.published_date(:short)      # => "Nov 09" (or locale-specific short format)

# Reading time
post.reading_time_text           # => "5 min read"
```

**In your views:**

```erb
<!-- Index: loop over posts -->
<% @posts.each do |post| %>
  <h2><%= link_to post.title, blog_post_path(post) %></h2>
  <p><%= post.published_date %> · <%= post.reading_time_text %></p>
  <p><%= post.excerpt %></p>
<% end %>

<!-- Show: single post -->
<h1><%= @post.title %></h1>
<p><%= @post.published_date(:long) %> · <%= @post.reading_time_text %></p>
<div><%= @post.content %></div>
```

### Controller Instance Variables

When using `bunko_collection`, these instance variables are available in your views:

- `@posts` - Collection of posts (index action)
- `@post` - Single post (show action)
- `@collection_name` - Name of the collection (e.g., "blog")
- `@pagination` - Hash with `:page`, `:per_page`, `:total`, `:total_pages`, `:prev_page`, `:next_page`

### Routing Helpers

Bunko provides a `bunko_collection` DSL method to simplify route definitions:

```ruby
# config/routes.rb
Rails.application.routes.draw do
  bunko_collection :blog
  # Generates: /blog (index), /blog/:slug (show)
end
```

**Automatic hyphenation** - Underscored slugs are automatically converted to hyphens in URLs:

```ruby
bunko_collection :case_study
# Generates: /case-study/:slug (slug stored as :case_study in database)
```

**Custom paths:**

```ruby
bunko_collection :case_study, path: "case-studies"
# Generates: /case-studies (index), /case-studies/:slug (show)
# Path helpers: case_studies_path, case_study_path(post)
```

**Custom controllers:**

```ruby
bunko_collection :blog, controller: "articles"
# Routes to: articles#index, articles#show
```

**Limit actions:**

```ruby
bunko_collection :blog, only: [:index]
# Only generates index route (no show route)
```

### Configuration

```ruby
# config/initializers/bunko.rb
Bunko.configure do |config|
  # Define content collections (used by rails bunko:setup)
  config.post_type "blog"  # Title auto-generated as "Blog"

  config.post_type "docs" do |type|
    type.title = "Documentation"  # Custom title
  end

  # Optional configuration
  config.reading_speed = 250           # words per minute for reading time calculation (default: 250)
  config.excerpt_length = 160          # characters for post.excerpt method (default: 160)
  config.auto_update_word_count = true # automatically update word_count when content changes (default: true)
end
```

### Smart Collections (v1)

Bunko supports **smart collections** - virtual collections that aggregate multiple post types or apply custom scopes:

```ruby
# config/initializers/bunko.rb
Bunko.configure do |config|
  # Define individual post types
  config.post_type "articles"
  config.post_type "videos"
  config.post_type "tutorials"

  # Define a multi-type collection
  config.collection "Resources", post_types: ["articles", "videos", "tutorials"]

  # Define a scoped collection (e.g., long-form content)
  config.collection "Long Reads", post_types: ["articles", "tutorials"] do |c|
    c.scope -> { where("word_count > ?", 1500) }
  end
end
```

Then use them in your controller and routes like any other collection:

```ruby
# app/controllers/resources_controller.rb
class ResourcesController < ApplicationController
  bunko_collection :resources  # Automatically loads articles, videos, and tutorials
end

# config/routes.rb
bunko_collection :resources
```

**Smart Lookup:** When you call `bunko_collection :name`, Bunko:
1. First checks for a PostType with that name
2. Then checks for a Collection with that name
3. Returns 404 if neither exists

**Name conflicts are prevented:** You cannot have a PostType and Collection with the same name.

## What Bunko Doesn't Do

- **No authentication** - Use Devise, Rodauth, or whatever you like
- **No authorization** - Use Pundit, CanCanCan, or your own solution
- **No admin UI required** - Generate one or build your own
- **No JavaScript** - No Stimulus controllers or Turbo frames forced on you
- **No CSS** - Style it however you want
- **No image handling** - Use ActiveStorage, Cloudinary, or anything else
- **No comments** - Integrate Disqus, build your own, or skip them
- **No search** - Use pg_search, Meilisearch, or implement your own

## Why Bunko?

**For developers who:**
- Want a blog/CMS that takes 5 minutes to set up
- Need flexibility to customize everything later
- Prefer conventions over configuration, but want escape hatches
- Value clean, understandable code over feature bloat
- Want to manage multiple content types without duplicate code
- Want to manage a number of sites with consistent CMS structure


## Development

After checking out the repo, run `bin/setup` to install dependencies. Then, run `rake test` to run the tests. You can also run `bin/console` for an interactive prompt that will allow you to experiment.

To install this gem onto your local machine, run `bundle exec rake install`. To release a new version, update the version number in `version.rb`, and then run `bundle exec rake release`, which will create a git tag for the version, push git commits and the created tag, and push the `.gem` file to [rubygems.org](https://rubygems.org).

## Contributing

Bug reports and pull requests are welcome on GitHub at https://github.com/kanejamison/bunko. This project is intended to be a safe, welcoming space for collaboration, and contributors are expected to adhere to the [code of conduct](https://github.com/kanejamison/bunko/blob/main/CODE_OF_CONDUCT.md).

## License

The gem is available as open source under the terms of the [MIT License](https://opensource.org/licenses/MIT).

## Code of Conduct

Everyone interacting in the Bunko project's codebases, issue trackers, chat rooms and mailing lists is expected to follow the [code of conduct](https://github.com/kanejamison/bunko/blob/main/CODE_OF_CONDUCT.md).
