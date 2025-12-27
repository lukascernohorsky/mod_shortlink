# Admin Guide – mod_shortlink

This guide covers installation, configuration, and troubleshooting for administrators.

## Installation

1. Add `mod_shortlink` to your Zotonic site’s module list.
2. Deploy the code and restart Zotonic.
3. Run the install task to create the database table:

   ```bash
   zotonic cmd mod_shortlink install
   ```

4. Confirm the dispatch rules are loaded (API and keyword redirects).

## Configuration

Set module configuration keys in the admin UI or via `m_config`:

| Key            | Purpose                                  | Default |
|----------------|------------------------------------------|---------|
| `redirect_code`| Redirect status code (`301` or `302`).   | `301`   |
| `api_public`   | Allow API usage without a signature.     | `false` |
| `api_token`    | Shared secret for signature validation.  | _unset_ |

## Access control

Use ACL rights to gate the admin interface:

* `use.mod_shortlink` – view and create links in the dashboard.
* `admin.mod_shortlink` – manage configuration and delete links.

Assign these permissions to user groups in the Zotonic admin.

## Troubleshooting

* **Schema errors:** Re-run `mod_shortlink:install/1` to recreate the table. Verify database connectivity.
* **Redirect loops or 404s:** Ensure the `shortlink_redirect` dispatch rule is placed after more specific routes to avoid conflicts.
* **Statistics not incrementing:** Check that `controller_shortlink_redirect` is reachable and that background increments are not blocked. Inspect application logs for errors.
* **Reset statistics:** Run `z_db:q("update shortlink set clicks = 0", Context)` from the Zotonic shell to zero all counters.
