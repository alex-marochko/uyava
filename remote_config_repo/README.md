# Uyava Remote Config (Public)

Static JSON for the desktop Remote Config.

- File: `remote_config.json`
- Schema: `{ "purchaseUrl": "https://uyava.io/pricing", "supportIssueUrl": "https://github.com/.../issues/new/choose", "supportEmail": "support@uyava.io" }`
- Usage: pass the URL of this file via `UYAVA_REMOTE_CONFIG_URL` when building/running Uyava Desktop. The client caches the payload and falls back to `UYAVA_PURCHASE_URL`, `UYAVA_SUPPORT_ISSUE_URL`, and `UYAVA_SUPPORT_EMAIL` if the remote is unavailable.

## Publish via GitHub Pages
1. Repo must be public.
2. Enable Pages (branch `main`, root `/` or `/docs` if you move files).
3. After push, verify the page URL serves the JSON; optionally add custom headers/Cache-Control via a CDN if needed.

## Update URL without rebuild
- Update `remote_config.json` and deploy.
- Desktop will pick up the new URLs after fetch; if offline, it will use cache or the build-time fallbacks.

## Validation
- Client ignores empty/invalid values; expected: non-empty URL strings and a non-empty support email.
