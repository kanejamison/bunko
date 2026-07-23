# Security Policy

## Supported Versions

Bunko is pre-1.0; only the latest release receives security fixes.

| Version | Supported          |
| ------- | ------------------ |
| 0.2.x   | :white_check_mark: |
| < 0.2   | :x:                |

## Reporting a Vulnerability

Please report vulnerabilities **privately**, not via public issues:

- Preferred: open a [GitHub Security Advisory](https://github.com/kanejamison/bunko/security/advisories/new).
- Or email the maintainer at 918780+kanejamison@users.noreply.github.com.

We aim to acknowledge reports within a few days and will coordinate a fix and disclosure with you.

## Security Model

Bunko is a content-routing layer, not a security boundary:

- **Public controllers are read-only by design.** Generated collection and page controllers only expose `index`/`show`.
- **Writes are the host application's responsibility.** Bunko ships no admin UI and no authentication or authorization. Any content editing — including an Avo (or other) admin — must be secured by the host app.
- **Sanitize and scope your own content.** Bunko does not escape post content for you; use Rails' `sanitize` helpers and strong parameters as appropriate.
