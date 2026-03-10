# Uyava Website

Static site for uyava.io built with Astro.

## Requirements

- Node.js 20+

## Development

```bash
npm ci
npm run dev
```

Optional checkout-related env vars:

- `PUBLIC_BILLING_API_BASE` (for example, `https://<billing-host>`)
- `PUBLIC_BILLING_PRODUCT_ID` (defaults to `desktop_pro`)
- `PUBLIC_PADDLE_CLIENT_TOKEN` (Paddle.js client-side token: `test_...` for sandbox, `live_...` for production)
- `PUBLIC_PADDLE_ENV` (optional override: `sandbox` or `live`; auto-inferred from token when omitted)

Legal docs source of truth:

- `src/content/legal/terms.md`
- `src/content/legal/privacy.md`
- `src/content/legal/refunds.md`
- `src/content/legal/licenses.md`

## Build

```bash
npm run build
```

The output is generated in `dist/` and deployed via GitHub Pages.

## Remote config

The desktop remote config is hosted alongside the site at
`/remote_config.json`. Update `public/remote_config.json` to publish purchase
links, support contacts, and update metadata (`latestDesktopVersion`,
`downloadUrl`, `releaseNotesUrl`, `minRequiredVersion`).
