mod_shortlink
=============

Native Zotonic module providing YOURLS-like URL shortening with redirects, statistics, and a small admin dashboard.

## Features

* API compatible endpoints under `/api/shortlink/:action` supporting JSON, XML and simple text responses.
* Redirect controller for `/:keyword` with configurable 301/302 response codes.
* PostgreSQL-backed model (`m_shortlink`) handling creation, validation, and statistics.
* Admin dashboard templates for quick link creation and overview pages.
* Notifications `#shortlink_created` and `#shortlink_redirect` for extensibility.

## Layout

* `src/` – Erlang modules for the Zotonic model, controllers, and module entry point.
* `priv/dispatch/` – Dispatch rules hooking the API and redirect routes.
* `templates/` – Admin templates for menu integration, dashboard, and statistics view.
* `priv/doc/` – Documentation (developer, user, and admin guides).
* `priv/api/swagger.yaml` – OpenAPI specification for the HTTP API.

## Quick start

1. Add `mod_shortlink` to your Zotonic site’s enabled modules.
2. Run the schema install: `zotonic cmd mod_shortlink install`.
3. Create a link via API:

```bash
curl -X POST "http://localhost:8000/api/shortlink/shorturl" \
  -d "url=https://example.com" \
  -d "keyword=ex" \
  -H "Accept: application/json"
```

4. Visit `http://localhost:8000/ex` to follow the redirect.
