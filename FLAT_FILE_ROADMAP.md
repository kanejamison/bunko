# Bunko Flat-File Mode Roadmap

**Goal:** A post-1.0 storage mode where content lives as markdown files in the repo instead of database rows — same Post API, same generated controllers and views, zero database. A Rails developer can add `gem "bunko"`, opt into flat-file storage, and have a working blog in under 5 minutes with no `db:migrate` step.

**Primary motivation: agent-native authoring.** An agent (Claude Code or similar) with only file tools can create, edit, and publish content directly — no MCP server, no API tokens, no admin auth. Git becomes the editorial workflow: the agent drafts or edits a post, opens a PR, a human reviews the diff like copy, and merge + deploy publishes it. Git is also the audit trail and rollback mechanism, for free.

**Status:** Planned for post-1.0 (a 1.x minor release). The database mode remains the default; flat-file storage is opt-in via `config.storage = :flat_file`. Milestone F1 is an invisible refactor and may land before 1.0.

---

## How This Differs from Other Markdown-to-Content Gems

Most file-based content tools for Rails treat content files as **templates** — each file is a routable page, often with embedded ERB. Bunko's flat-file mode treats content files as **data**: inert markdown with YAML front matter, loaded into Post objects and rendered through the same generated views as the database mode. That's what preserves Bunko's publishing workflow (draft/published/scheduled), pagination, collections, and one-model architecture on top of files — behaviors page-serving engines don't provide.

---

## Design Principles

These extend the core philosophy in the README:

1. **Content is data, not templates** — Markdown + YAML front matter only. Content files never execute ERB or any code. This is a deliberate safety property: an agent editing prose cannot inject executable Ruby into the app.
2. **One Post API, two backends** — The generated controllers, views, and `.tt` templates are identical in both modes. Switching storage never changes view code. `post.title`, `post.excerpt`, `post.reading_time_text`, `@posts`, `@pagination` all behave the same.
3. **Deterministic conventions** — Directory = post_type, filename = slug, front matter = metadata. An agent told "write a changelog entry" knows exactly where the file goes and what it's called, with zero lookups. No auto-set `published_at` magic in this mode: dates are explicit in front matter and enforced by validation, because implicit callbacks are hidden state an agent can't see.
4. **Still lightweight** — The gem itself gains no hard dependencies and its gemspec never references a markdown library. The flat-file installer adds commonmarker to the *host app's* Gemfile as a default suggestion, but the renderer is resolved at runtime and any markdown-to-HTML library (redcarpet, kramdown, etc.) can be swapped in via a one-line config lambda. Database mode remains dependency-free.
5. **Publishing requires a deploy** — Merge-to-publish is the feature, not a bug. Content changes go live when the app deploys (or content files sync). This is documented plainly as the tradeoff versus database mode.

---

## Success Criteria

By the release of flat-file mode, a developer should be able to:

1. Install Bunko in flat-file mode and have a working blog in < 5 minutes with no database migrations
2. Point an agent at the repo and have it create, edit, and publish a post using only file tools, verifying its work with one command (`rails bunko:validate`)
3. Use the exact same generated views and templates in either storage mode
4. Schedule posts for future publication via a front matter date (no cron, no callbacks)
5. Switch an app's docs or changelog to flat-file storage without touching view code

And the existing database mode must be completely unchanged: the current test suite stays green throughout every milestone.

---

## Milestone F1: Storage Adapter Seam

**Spec:** Introduce a storage abstraction between controllers and content storage, with zero behavior change. The database backend becomes the first adapter.

*This milestone is an invisible refactor and is eligible to land before 1.0.*

### Required Behavior

**Shared Post API:**
- Extract the storage-agnostic instance methods already free of ActiveRecord — `excerpt`, `published_date`, `reading_time`, `reading_time_text`, `scheduled?`, `to_param` — from `lib/bunko/models/post_methods.rb` into a mixin both backends include
- Database-mode `Post` behavior is unchanged (validations, callbacks, and scopes stay where they are)

**Repository Interface:**
- `Bunko::Controllers::Collection` (`lib/bunko/controllers/collection.rb`) stops referencing `Post` and `PostType` directly and resolves a storage adapter instead
- The interface is deliberately narrow — everything the controllers actually use today: `published`, `by_post_type(name)`, ordering (`published_at`/`created_at`, asc/desc), `count`, limit/offset pagination, `find_by_slug(slug)`
- The database adapter is a thin wrapper over the existing ActiveRecord queries

**Storage-Agnostic Errors:**
- `bunko_not_found!` raises a new `Bunko::NotFoundError` instead of `ActiveRecord::RecordNotFound`
- `Bunko::NotFoundError` is registered with `config.action_dispatch.rescue_responses` so it maps to 404 exactly as before

### Acceptance Test

```bash
# The entire existing test suite passes with zero test edits:
bundle exec rake

# Database mode behavior is byte-for-byte identical.
# No public API changes. No new configuration required.
```

---

## Milestone F2: File-Backed Content Engine

**Spec:** Markdown files with YAML front matter load into Post objects that satisfy the shared Post API.

### Required Behavior

**File Conventions:**
- Content lives under `config.content_path` (default: `app/content/`)
- Directory name = post_type, filename = slug: `app/content/blog/why-we-chose-rails.md` is a `blog` post with slug `why-we-chose-rails`
- Front matter can override the slug explicitly; the filename is the default

**Front Matter Schema:**
```yaml
---
title: Why We Chose Rails        # required
status: published                 # draft | published (scheduled = published + future date)
published_at: 2026-09-01 09:00   # required when status is published
title_tag: Why We Chose Rails    # optional SEO fields, matching DB columns
meta_description: A look at...
template: featured                # optional: render via blog/featured.html.erb instead of show
---
```

**Content Formats:**
- `.md` files render markdown through the configured renderer (F3)
- `.html` files are supported alongside markdown: same front matter, body passed through as-is with no markdown rendering — parity with database mode, where `content` can already hold arbitrary HTML. Word count strips tags before counting, matching existing behavior

**Post Objects:**
- `Bunko::FlatFile::Post` is an ActiveModel-based PORO including the shared mixin from F1, so `excerpt`, `published_date`, `reading_time_text`, and `to_param` work identically to database posts
- `word_count` is computed at parse time from the markdown body (replacing the `before_save` callback path in the database mode)

**Content Registry:**
- Files are scanned and parsed into an in-memory index — once and memoized in production, reloaded via `Rails.application.config.to_prepare` in development so edits appear on refresh
- Slug collisions within a post_type are detected at load time with a clear error naming both files
- `published` / `draft` / `scheduled` are Enumerable filters over the index; scheduled posts work correctly because the `published_at <= Time.current` comparison happens at request time — a future-dated post appears automatically when its time arrives, no cron needed

**PostTypes Without a Database:**
- In flat-file mode, PostTypes derive entirely from `config/initializers/bunko.rb` (name + title already live there); there is no `post_types` table and no database lookup

### Acceptance Test

```ruby
# Given app/content/blog/hello-world.md with valid front matter:
post = Bunko::FlatFile::Post.find_by_slug("blog", "hello-world")
post.title            # => "Hello World"
post.slug             # => "hello-world" (from filename)
post.reading_time_text # => "2 min read" (computed at parse)
post.excerpt          # => "This is the beginning of the post..."

# Scheduling works with no callbacks:
# status: published + published_at: <future> => excluded from .published today,
# included automatically after that time passes.
```

---

## Milestone F3: Flat-File Collection Serving

**Spec:** `bunko_collection` and `bunko_page` routes serve flat-file content through the same controllers and views as database mode.

### Required Behavior

**Adapter:**
- A flat-file adapter implements the F1 repository interface over the content registry
- Pagination slices the in-memory collection and produces the same `@pagination` metadata hash the views already consume

**Markdown Rendering:**
- `post.content` returns rendered HTML in flat-file mode, so existing views work unchanged
- The renderer is resolved at runtime, in order:
  1. `config.markdown_renderer` lambda, if set — always wins
  2. commonmarker, if the app bundles it (the installer's default Gemfile suggestion — delete or swap it freely)
  3. Otherwise a clear error at boot explaining both options — never a silent raw-markdown dump
- Bunko's gemspec never depends on any markdown library; swapping renderers is one line:

  ```ruby
  # config/initializers/bunko.rb — bring whatever md-to-html library you prefer
  config.markdown_renderer = ->(md) { Redcarpet::Markdown.new(Redcarpet::Render::HTML).render(md) }
  # or
  config.markdown_renderer = ->(md) { Kramdown::Document.new(md).to_html }
  ```
- Raw markdown remains accessible (e.g., `post.raw_content`) for apps that want to render their own way

**Open-Ended HTML:**
- Inline HTML inside markdown follows the renderer's posture, and the default is the safe one: commonmarker escapes raw HTML unless the app opts in. This is deliberate for agent-written content, and documented so it never silently surprises — the docs show the one-liner to enable inline HTML for apps that want it (via renderer options or the `config.markdown_renderer` lambda)
- Posts that are mostly custom markup skip markdown entirely: write the file as `.html` with front matter (see F2) and the body renders as-is, exactly like an HTML-content post in database mode

**Per-Post Templates:**
- A `template:` front matter key opts a single post into a custom view: `template: featured` renders `app/views/blog/featured.html.erb` instead of `blog/show.html.erb`, falling back to `show` if the template doesn't exist — the same resolution pattern static pages already use in `PagesController`
- Resolution keys off `post.template` on the shared Post API, so it isn't flat-file-only: database mode gets the same behavior if the app adds a `template` column (an escape hatch, not a required migration)

**Collections:**
- Multi-type smart collections (`config.collection "resources", post_types: [...]`) work by aggregating across the index
- ActiveRecord `scope:` lambdas are **database-mode only in v1**: configuring one in flat-file mode raises a clear error at boot. (An Enumerable-compatible scope API is a candidate for a later release — see Out of Scope.)

**Static Pages:**
- `bunko_page :about` serves `app/content/pages/about.md` through the same shared `PagesController`, preserving custom template resolution (`pages/about.html.erb` first, `pages/show.html.erb` fallback)

**Images:**
- Convention: images live in the repo (e.g., `public/content/<post_type>/`), referenced by relative path in markdown; the renderer rewrites relative refs to served URLs
- A broken-image-ref check belongs to `bunko:validate` (F5); variants and optimization are out of scope

### Acceptance Test

```bash
# With config.storage = :flat_file and app/content/blog/*.md files:
GET /blog          # => paginated index of published posts, newest first
GET /blog/:slug    # => rendered post, 404 for drafts and unknown slugs
GET /about         # => renders app/content/pages/about.md

# The controllers and views involved are the same generated files
# used in database mode, unmodified.
```

---

## Milestone F4: Installer & Generators

**Spec:** Installing in flat-file mode is the same 5-minute experience, minus the database.

### Required Behavior

**Install:**
- `rails bunko:install STORAGE=flat_file`:
  - Skips migrations and model generation entirely
  - Creates `app/content/` with a directory per starter post_type and a sample post
  - Generates the initializer with `config.storage = :flat_file` and flat-file options documented
  - Adds `commonmarker` to the host app's Gemfile
- Database-mode install is unchanged and remains the default

**Setup:**
- `rails bunko:setup` and `rails bunko:add[name]` work identically in both modes — the existing `.tt` templates only call the shared Post API (`post.title`, `.slug`, `.content`, `.published_at`, `.excerpt`, `.reading_time`), so no template forks
- In flat-file mode, setup creates the content directory for each configured post_type instead of database PostType rows

**Sample Data:**
- `rails bunko:sample_data` writes `.md` files with front matter in flat-file mode, reusing the existing generator's markdown format and options (`COUNT`, `MIN_WORDS`/`MAX_WORDS`, `CLEAR`)

### Acceptance Test

```bash
$ bundle add bunko
$ rails bunko:install STORAGE=flat_file
$ rails bunko:setup
$ rails bunko:sample_data
$ rails server

# Visit http://localhost:3000/blog — working blog, no db:migrate ever ran.
```

---

## Milestone F5: Validation & Agent-Native Authoring

**Spec:** An agent editing content gets a lint-fast feedback loop and self-documenting conventions. This is the differentiating milestone.

### Required Behavior

**Validation Task:**
- `rails bunko:validate` checks every content file and reports all problems at once:
  - Front matter parses and contains required fields (`title`)
  - `status` is a valid status
  - `status: published` has a `published_at`
  - No slug collisions within a post_type
  - Directory names match configured post_types
  - Relative image references resolve to existing files
  - `template:` keys that don't resolve to an existing view produce a warning (not a failure — the fallback to `show` still renders)
- Exits non-zero on failure so it slots into CI as a content-PR gate

**Agent Instructions:**
- `rails bunko:setup` (flat-file mode) generates `app/content/CLAUDE.md` documenting: the front matter schema, directory/filename conventions, valid statuses, how scheduling works, and the validate command — so any agent session in the repo is immediately productive with zero explanation

**Documented Workflow:**
- The agent authoring loop is documented end to end: write or edit a `.md` file → run `rails bunko:validate` → open a PR → human reviews the diff → merge publishes on deploy

### Acceptance Test

```bash
# An agent with only Read/Edit/Write and Bash can:
$ cat > app/content/changelog/v1-2-0.md   # write a post with front matter
$ rails bunko:validate                     # => "✓ 42 content files valid"

# Break it, and the error is actionable:
# "app/content/changelog/v1-2-0.md: status is 'published' but published_at is missing"
```

---

## Milestone F6: Documentation & Release

**Spec:** Flat-file mode is documented, tested against both backends, and shipped as a minor release.

### Required Behavior

**Documentation:**
- README section covering: opting in, file conventions, front matter schema, the agent workflow, images convention, and the publish-requires-a-deploy tradeoff stated plainly
- Example content directory in docs or an example app

**Testing:**
- Content fixtures added to `test/dummy` (following the existing generated-vs-committed file approach)
- Controller and routing suites run against **both** storage backends so the adapters cannot drift apart
- Validation task has its own test coverage

**Release:**
- Ships as a 1.x minor release; CHANGELOG and SECURITY.md supported-versions table updated per release process

### Acceptance Test

```bash
# Both of these produce a working blog with identical views:
$ rails bunko:install && rails db:migrate && rails bunko:setup       # database mode
$ rails bunko:install STORAGE=flat_file && rails bunko:setup         # flat-file mode

$ bundle exec rake   # full suite green across both backends
```

---

## Out of Scope

Deliberately excluded from the initial flat-file release:

- **Image variants/optimization** - Repo-stored originals with relative refs only; use a CDN or asset pipeline if you need more
- **Hybrid file→database sync** - Violates the "no database copies" goal; flat-file mode is fully file-backed or not used
- **Executable content (ERB/MDX)** - Content stays inert data by design; this is a safety property, not a missing feature
- **Per-post_type mixed storage** - `config.storage` is global in v1; splitting storage per post_type is a candidate for later
- **ActiveRecord `scope:` lambdas on flat-file collections** - Database-mode only in v1; an Enumerable scope API may follow
- **Full-text search** - Grep the files, or bring your own search
- **Editor UI for files** - Your editor (or your agent) is the editor
