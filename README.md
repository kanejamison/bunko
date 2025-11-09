# Bunko

Bunko (文庫) in Japanese means a small personal library or book collection - a perfect name for a Rails gem that organizes your content elegantly.

## ⚠️ Development Status

**Bunko is currently in active development and not yet ready for production use.** We're building toward a 1.0.0 release with core functionality that we think is safe for production usage. See the roadmap below for progress.

### 1.0.0 Roadmap Progress

- [x] **Milestone 1: Post Model Behavior** - Core `acts_as_bunko_post` concern with scopes, slug generation, publishing workflow, and reading time calculation
- [x] **Milestone 2: Collection Controllers** - `bunko_collection` concern for automatic index/show actions with built-in pagination
- [x] **Milestone 3: Installation Generator** - `rails generate bunko:install` command and `rails bunko:setup` task
- [ ] **Milestone 4: Routing Helpers** - Convenience methods for collection routes
- [ ] **Milestone 5: View Helpers** - Formatting, metadata, and display helpers
- [ ] **Milestone 6: Configuration** - Expanded configuration system
- [ ] **Milestone 7: Documentation** - Usage guides and examples
- [ ] **Milestone 8: Release** - Version 0.1.0 to RubyGems

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
  config.post_types = [
    { name: "Blog", slug: "blog" },
    { name: "Documentation", slug: "docs" },
    { name: "Changelog", slug: "changelog" }
  ]
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

This generates:
- Controllers for each post type (e.g., `BlogController`, `DocsController`)
- View templates (index + show) for each collection
- Routes for each collection

**Adding more collections later?** Just update the initializer and run:
```bash
rails bunko:setup[new_collection_slug]
```

### 6. Create Your First Post

```ruby
# In Rails console or your admin interface
blog_type = PostType.find_by(slug: "blog")

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

## Generator Options

Customize the installation to fit your needs:

```bash
# Exclude SEO fields (meta_title, meta_description)
rails generate bunko:install --skip-seo

# Exclude metrics fields (word_count, reading_time)
rails generate bunko:install --skip-metrics

# Add metadata jsonb field for custom data
rails generate bunko:install --metadata

# Minimal install
rails generate bunko:install --skip-seo --skip-metrics
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

# Handles uniqueness within post_type
post2 = Post.new(title: "Hello World!", post_type: blog_type)
post2.save
post2.slug  # => "hello-world-2"
```

### Publishing Workflow

```ruby
post = Post.create(title: "My Post", status: "draft")
post.published_at  # => nil

post.update(status: "published")
post.published_at  # => automatically set to current time
```

### Reading Time Calculation

```ruby
post = Post.create(title: "Article", word_count: 500)
post.reading_time  # => 2 (minutes, based on 250 wpm default)
```

### Controller Instance Variables

When using `bunko_collection`, these instance variables are available in your views:

- `@posts` - Collection of posts (index action)
- `@post` - Single post (show action)
- `@collection_name` - Name of the collection (e.g., "blog")
- `@pagination` - Hash with `:page`, `:per_page`, `:total`, `:total_pages`, `:prev_page`, `:next_page`

### Configuration

```ruby
# config/initializers/bunko.rb
Bunko.configure do |config|
  # Define content collections (used by rails bunko:setup)
  config.post_types = [
    { name: "Blog", slug: "blog" },
    { name: "Documentation", slug: "docs" }
  ]

  config.reading_speed = 250  # words per minute for reading time calculation (default: 250)
  config.valid_statuses = %w[draft published scheduled]  # allowed post statuses
end
```

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
