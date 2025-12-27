# User Guide – mod_shortlink

This guide explains how site editors and contributors can shorten URLs and review statistics in the Zotonic admin interface.

## Creating a short link

1. Open **Admin → Shortlinks**.
2. Enter the target URL.
3. Optionally specify a custom keyword (otherwise one is generated).
4. Optionally add a title for easier identification.
5. Click **Shorten**.

The resulting short URL is displayed in the table; click it to test the redirect.

## Viewing statistics

* The dashboard lists the most recent links with their click counts.
* Use the **Statistics** view to see top links, creation times, and a chart placeholder for click history.

## Bookmarklet (placeholder)

Add a bookmark with the following URL to quickly shorten the current page (replace `example.com` with your domain):

```
javascript:(function(){window.open('https://example.com/admin/shortlink?url='+encodeURIComponent(location.href),'_blank');})();
```

Drag the snippet to your bookmarks bar to install. A production-ready bookmarklet should include session detection and better error handling.

## FAQ

* **The link returns 404:** The keyword does not exist or was deleted. Create a new link or choose a different keyword.
* **The redirect is 302 instead of 301:** Check the module configuration key `redirect_code` in admin settings.
* **Can I use custom domains?** Point your short domain to the Zotonic site and ensure the `shortlink_redirect` dispatch rule remains at the end of the dispatch table to catch keyword paths.
