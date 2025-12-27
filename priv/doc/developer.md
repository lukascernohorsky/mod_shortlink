# Developer Guide – mod_shortlink

This guide summarizes the architecture and extension points for the Zotonic shortlink module.

## Architecture overview

* **Model** – `m_shortlink` exposes CRUD-like helpers (`get/2`, `insert/4`, `incr_clicks/2`, `stats/3`) backed by PostgreSQL.
* **Controllers**
  * `controller_shortlink_api` implements the HTTP API at `/api/shortlink/:action`.
  * `controller_shortlink_redirect` resolves a keyword and issues a redirect (301/302).
* **Dispatch rules** – see `priv/dispatch/mod_shortlink.erl` for API and redirect routes.
* **Notifications**
  * `#shortlink_created{id, url, keyword}` emitted after a successful insert.
  * `#shortlink_redirect{id, url, keyword, request_data}` emitted before redirecting.
* **Configuration**
  * `redirect_code` (301 or 302) – controls the redirect status code.

## Data model

Table `shortlink`:

| Column    | Type           | Notes                          |
|-----------|----------------|--------------------------------|
| id        | serial         | Primary key                    |
| keyword   | varchar(100)   | Unique keyword                 |
| url       | text           | Target URL                     |
| title     | varchar(255)   | Optional label                 |
| timestamp | timestamptz    | Creation time (default `now()`)|
| clicks    | integer        | Click counter                  |
| ip        | inet           | Creator IP (optional)          |

Schema is created in `mod_shortlink:manage_schema/2`.

## API reference

See the OpenAPI document at `priv/api/swagger.yaml` for endpoint details. Key actions:

* `shorturl` – create a short link; generates a keyword if none is provided.
* `expand` – resolve a short URL to the original URL.
* `url-stats` – per-link metadata and counters.
* `stats` – list aggregated stats (`top`, `bottom`, `rand`, `last`).
* `db-stats` – global totals.
* `version` – module version (1.2).

## Extending the module

### Custom keyword generation

Implement a notifier for `shortlink_random_keyword` to override the generated keyword. The payload is the proposed keyword; return an updated value to change it.

### Reacting to events

```erlang
-module(my_shortlink_logger).
-export([observe_shortlink_created/2]).

observe_shortlink_created(#shortlink_created{id = Id, url = Url, keyword = Keyword}, Context) ->
    z_logger:info(\"shortlink created ~p -> ~p (~p)\", [Keyword, Url, Id]),
    ok.
```

### CLI helpers

* `mod_shortlink:add_link(Context, Url, Keyword)` – manually create links.
* `mod_shortlink:delete_link(Context, Keyword)` – delete links.

## Testing

* **Unit/EUnit** – focus on URL validation, keyword generation, and duplication handling.
* **Integration/Common Test** – exercise API flows and redirect behavior.
* **Static analysis** – Dialyzer and Xref should pass without warnings.
