# Bunko

Bunko (文庫) in Japanese means a small personal library or book collection - a perfect name for a Rails gem that organizes your content elegantly.

## ⚠️ Development Status

**Bunko is currently in active development and not yet ready for production use.** We're building toward a 1.0.0 release with core functionality that we think is safe for production usage. See the roadmap below for progress.

### 1.0.0 Roadmap Progress

- [x] **Milestone 1: Post Model Behavior** - Core `acts_as_bunko_post` concern with scopes, slug generation, publishing workflow, and reading time calculation
- [x] **Milestone 2: Collection Controllers** - `bunko_collection` concern for automatic index/show actions with built-in pagination
- [ ] **Milestone 3: Installation Generator** - `rails generate bunko:install` command
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

## Current Usage (Manual Setup)

**Note:** The installation generator is not yet available. For now, you'll need to set up Bunko manually:

### 1. Add to Gemfile

```ruby
gem "bunko"
```

### 2. Create Database Migrations

```ruby
# db/migrate/YYYYMMDDHHMMSS_create_post_types.rb
class CreatePostTypes < ActiveRecord::Migration[8.0]
  def change
    create_table :post_types do |t|
      t.string :name, null: false
      t.string :slug, null: false
      t.timestamps
    end
    add_index :post_types, :slug, unique: true
  end
end

# db/migrate/YYYYMMDDHHMMSS_create_posts.rb
class CreatePosts < ActiveRecord::Migration[8.0]
  def change
    create_table :posts do |t|
      t.string :title, null: false
      t.string :slug, null: false
      t.text :content
      t.references :post_type, null: false, foreign_key: true
      t.string :status, null: false, default: "draft"
      t.datetime :published_at

      # SEO fields
      t.string :meta_title
      t.text :meta_description

      # Metrics
      t.integer :word_count

      t.timestamps
    end

    add_index :posts, [:post_type_id, :slug], unique: true
  end
end
```

### 3. Create Your Post Model

```ruby
# app/models/post.rb
class Post < ApplicationRecord
  acts_as_bunko_post
  belongs_to :post_type

  validates :title, presence: true
  validates :slug, presence: true, uniqueness: { scope: :post_type_id }
  validates :status, presence: true
end

# app/models/post_type.rb
class PostType < ApplicationRecord
  has_many :posts, dependent: :destroy
  validates :name, presence: true
  validates :slug, presence: true, uniqueness: true
end
```

### 4. Create Collection Controllers

```ruby
# app/controllers/blog_controller.rb
class BlogController < ApplicationController
  bunko_collection :blog  # Creates index and show actions
end

# app/controllers/docs_controller.rb
class DocsController < ApplicationController
  bunko_collection :docs, per_page: 20, order: "title ASC"
end
```

### 5. Add Routes

```ruby
# config/routes.rb
Rails.application.routes.draw do
  resources :blog, only: [:index, :show], param: :slug
  resources :docs, only: [:index, :show], param: :slug
end
```

### 6. Create Views

```erb
<!-- app/views/blog/index.html.erb -->
<h1>Blog</h1>
<% @posts.each do |post| %>
  <article>
    <h2><%= link_to post.title, blog_path(post.slug) %></h2>
    <time><%= post.published_at.strftime("%B %d, %Y") %></time>
    <p><%= post.content.truncate(200) %></p>
  </article>
<% end %>

<%= link_to "Previous Page", blog_index_path(page: @pagination[:page] - 1) if @pagination[:prev_page] %>
<%= link_to "Next Page", blog_index_path(page: @pagination[:page] + 1) if @pagination[:next_page] %>

<!-- app/views/blog/show.html.erb -->
<article>
  <h1><%= @post.title %></h1>
  <time><%= @post.published_at.strftime("%B %d, %Y") %></time>
  <div><%= @post.content %></div>
</article>
```

### 7. Seed Your Database

```ruby
# db/seeds.rb
blog_type = PostType.find_or_create_by!(slug: "blog") do |pt|
  pt.name = "Blog"
end

docs_type = PostType.find_or_create_by!(slug: "docs") do |pt|
  pt.name = "Documentation"
end

Post.create!(
  title: "Welcome to Bunko",
  content: "This is your first blog post!",
  post_type: blog_type,
  status: "published",
  published_at: Time.current
)
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
post.reading_time  # => 2 (minutes, based on 200 wpm default)
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
  config.reading_speed = 200  # words per minute for reading time calculation
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
