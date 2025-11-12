# Bunko

Bunko (文庫) in Japanese means a small personal library or book collection - a perfect name for a Rails gem that organizes your content elegantly.

## ⚠️ Development Status

**Bunko is currently in active development and not yet ready for production use.** We're building toward a 1.0.0 release with core functionality that we think is safe for production usage. See the roadmap below for progress.

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
- `Post` and `PostType` models with `acts_as_bunko_post` and `acts_as_bunko_post_type`
- `config/initializers/bunko.rb` with starter configuration

### 3. Run Migrations

```bash
rails db:migrate
```

### 4. (Optional) Customize Collections

Edit `config/initializers/bunko.rb` to define your content collections:

```ruby
Bunko.configure do |config|
  config.post_type "blog"  # Title auto-generated as "Blog"

  config.post_type "docs", title: "Documentation"  # Param style

  config.post_type "changelog" do |type|  # Block style
    type.title = "Changelog"
  end
end
```

### 5. Generate Controllers, Views, and Routes

```bash
rails bunko:setup
```

This generates everything you need for each configured post type and collection:
- ✅ PostTypes in the database
- ✅ Controllers (e.g., `BlogController`, `DocsController`)
- ✅ View templates (`app/views/blog/index.html.erb`, `app/views/blog/show.html.erb`)
- ✅ Routes (`bunko_collection :blog`, `bunko_collection :docs`)
- ✅ Navigation partial with all collections

These are all vanilla Rails assets - you can delete or customize them to fit your needs.

**That's it for initial setup!** See "Adding New Post Types or Collections" below for how to add more later.

### 6. Create Your First Post
Create a post in CLI or using the sample data generator described below.

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

### 9. Wait that's it?
Yes! For now anyways.

- Hook up your own editor however you like.
- Route your admin/editor behind whatever auth you like.
- Use whatever SEO gem or helper you like.
- Use whatever sitemap generator you like.

We'll continue building new generators and possibly a mountable UI to help with this. For now we're recommending just using an admin tool like Avo with markdown or Rhino editor which gives you solid editing and Active Record integrations.

## Adding More Content Types

Need to add a new blog, documentation section, or any content type? Update your initializer and run one command:

```ruby
# config/initializers/bunko.rb
Bunko.configure do |config|
  config.post_type "blog"
  config.post_type "changelog"  # Add this
end
```

```bash
rails bunko:add[changelog]
```

Bunko creates the database entry if it's a post_type and generates the controller, views, routes, and updates your navigation automatically.

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

The sample data generator creates structured content some what randomly. It's a combination of lorem ipsum and random words, plus various formatted content.

All posts include:
- Realistic titles based on post type
- Unique slugs
- Meta descriptions
- Title tags
- Published dates (90% past, 10% scheduled for future)
- Realistic lengths and automatic word count calculation

**HTML Format Features:**

When using `FORMAT=html`, content includes:
- Semantic tags (`<h2>`, `<p>`, `<blockquote>`, `<ul>`, `<li>`)
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
# This creates a JSONB column for Post.content instead of a text column
rails generate bunko:install --json-content
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
Slugs are generated on save if the slug field is empty. Edit it however you like and it will persist even if you change the title.

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

  # words per minute for reading time calculation (default: 250)
  # config.reading_speed = 250

  # characters for post.excerpt method (default: 160)
  # config.excerpt_length = 160

  # automatically update word_count when content changes (default: true)
  # turn this off if you want to update the word count with different logic
  # config.auto_update_word_count = true

end
```

### Collections

Every post_type automatically gets its own collection (e.g., `blog` gets `/blog/`).

But Bunko also lets you create **dynamic collections** that aggregate or filter content in powerful ways.

**Example: Multi-Type Collection**

Combine multiple post types into a single collection:

```ruby
config.post_type "articles"
config.post_type "videos"
config.post_type "tutorials"
config.post_type "updates"

config.collection "resources", post_types: ["articles", "videos", "tutorials"]
# Auto-generates title "Resources", creates /resources/
```

This displays all three types together at `/resources/`.
Posts will still be properly shown through their standard post_type URL.

**Example: Scoped Collection**

Filter content by word count to create a long-form reading collection:

```ruby
config.collection "long_reads" do |c|
  c.post_types = ["articles", "tutorials"]
  c.scope = -> { where("word_count > ?", 1500) }
end
# Auto-generates title "Long Reads", creates /long-reads/
```

This shows only articles and tutorials over 1,500 words at `/long-reads/`.

**Example: Custom Title**

Override the auto-generated title:

```ruby
# Param style
config.collection "greatest_hits", title: "Greatest Hits", post_types: ["articles"]

# Block style
config.collection "greatest_hits" do |c|
  c.title = "Greatest Hits"
  c.post_types = ["articles", "videos", "tutorials"]
  c.scope = -> { where(featured: true) }
end

# Mixed style (block overrides params if both set the same option)
config.collection "greatest_hits", title: "Param Title", post_types: ["articles"] do |c|
  c.title = "Block Title"  # Block overrides param → final title is "Block Title"
  c.post_types = ["articles", "videos"]  # Block overrides param → final post_types is ["articles", "videos"]
  c.scope = -> { where(featured: true) }
end
# Final: title = "Block Title", post_types = ["articles", "videos"], URL: /greatest-hits/
```

**Planned Collections (Not Yet Working)**

Future versions will support additional collection types:

```ruby
# Author collections - index of all authors, show page per author
config.collection "authors", scope_by: :author
# Title: "Authors"
# /authors/ - index of all authors
# /authors/:author_slug - all posts by that author

# Tag collections - index of all tags, show page per tag
config.collection "tags", scope_by: :tag
# Title: "Tags"
# /tags/ - index of all tags
# /tags/:tag_slug - all posts with that tag

# Date-based collections - index of years/months, show page per period
config.collection "archives", scope_by: :year
# Title: "Archives"
# /archives/ - index of all years
# /archives/2024 - all posts from 2024

# Featured collections - simple filtered collection
config.collection "featured", scope_by: :featured
# Title: "Featured"
# /featured/ - all featured posts

# Combined filters
config.collection "popular_long_reads" do |c|
  c.post_types = ["articles"]
  c.scope = -> { where("word_count > ?", 1500).where("views > ?", 1000) }
end
# Title: "Popular Long Reads", URL: /popular-long-reads/
```

**Usage**

Use collections exactly like post types - same command, same routes:

```bash
rails bunko:add[resources]
rails bunko:add[long_reads]
```

```ruby
# config/routes.rb
bunko_collection :resources
bunko_collection :long_reads
```

Bunko automatically detects whether you're adding a post type or a collection and handles it accordingly.

## What Bunko Doesn't Do

- **No editor restrictions** - Use Lexxy, Trix, Rhino, markdown, etc.
- **No authentication** - Use Devise, etc, or whatever you like
- **No authorization** - Use Pundit, CanCanCan, or your own solution to decide who can edit Posts
- **No admin UI required** - Use Avo, etc, or build your own
- **No JavaScript** - No Stimulus controllers or Turbo frames forced on you
- **No CSS** - Style it however you want
- **No image handling** - Use ActiveStorage, Cloudinary, or anything else
- **No comments** - Integrate third party comments, build your own, or skip them
- **No search** - Use pg_search, etc. Add your own indexes to the Post table as needed

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

Bug reports and pull requests are welcome on GitHub at https://github.com/kanejamison/bunko. This project is intended to be a safe, welcoming space for collaboration, and contributors are expected to be kind and respectful.

## License

The gem is available as open source under the terms of the [MIT License](https://opensource.org/licenses/MIT).
