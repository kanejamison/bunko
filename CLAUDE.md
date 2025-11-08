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
lib/bunko/           # Main gem code (currently minimal, awaiting implementation)
  version.rb         # Version constant
test/                # Minitest test suite
  dummy/             # Rails dummy app for integration testing (to be created)
  test_helper.rb     # Test configuration
  test_bunko.rb      # Main test file
.github/workflows/   # CI/CD pipeline (runs rake: test + standard)
```

### Test Dummy App

Following standard Rails gem patterns, integration tests will run against a minimal Rails app in `test/dummy/`:
- Created via `rails plugin new` or manually scaffolded
- Provides real Rails environment for testing migrations, controllers, routes, views
- Committed to git (excluding tmp/, log/, etc.)
- Examples: Devise, Kaminari, and most Rails engines use this pattern

## Requirements

- Ruby >= 3.1.0
- Bundler
- Rails (when gem is used, though gem itself is framework-agnostic structure)

## Development Notes

- This gem uses **Standard** for Ruby linting (configured in `.standard.yml`)
- Tests use **Minitest** framework
- CI runs on GitHub Actions (`.github/workflows/main.yml`) and executes `bundle exec rake`
- The gem is in early development - core functionality not yet implemented
- Future generator: `rails generate bunko:install` (marked as "coming soon")

## Development Roadmap

See ROADMAP.md for the complete 0.1.0 release plan with specs and milestones.

## Architecture Principles

When implementing features for this gem:

1. **Keep it lightweight** - Avoid dependencies unless absolutely necessary
2. **Stay agnostic** - Don't force opinions on editors, view layers, auth, etc.
3. **One model architecture** - All content types share the Post model with collection-based routing
4. **Convention with escape hatches** - Provide sensible defaults but allow customization
5. **No forced UI** - Helpers over components; let developers control their HTML
6. **Specs over implementation** - Focus on behavior and outcomes, not prescriptive solutions
