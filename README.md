# Bunko
Bunko (文庫) in Japanese means a small personal library or book collection - a perfect name for a Rails gem that organizes your content elegantly.

## Philosophy

**One model, infinite collections.** Bunko gives you a robust CMS structure in 5 minutes. Whether you just want a classic blog, or if you want dozens of post types across your site, Bunko scales to handle dozens of content collections without new database migrations or excessive code duplication every time you launch a new collection. All content are posts - and you can mount collections of posts to whatever routes you like with #index & #show actions.

## Overview

* **Out-of-the-box blog without the bloat** - Install, generate, and publish in under 5 minutes
* **One Post model, many collections** - Route the same content model to `/blog/`, `/docs/`, `/changelog/`, `/tutorials/` - whatever you need
* **Database agnostic** - Works fine with SQLite, PostgreSQL, etc.
* **Editor agnostic** - ActionText, Lexxy, Trix, markdown, plain text - use what works for your team, or hook it up to a tool like Avo.
* **View layer agnostic** - We provide helpers, you control the HTML. Works just fine with ERB, HAML, Slim, ViewComponent, or Phlex
* **Zero JavaScript/CSS opinions** - Bring your own Tailwind, Bootstrap, or vanilla styles


## Quick Start

```bash
# Add to Gemfile
gem "bunko"

# Install
$ bundle install
$ rails generate bunko:install # coming soon
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
