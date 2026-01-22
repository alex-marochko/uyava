# Uyava Website

Static site for uyava.io built with Astro.

## Requirements

- Node.js 20+
- `legal_3.zip` in the repository root (one level above `site/`)

## Development

```bash
npm ci
npm run dev
```

The legal documents are synced automatically via `npm run sync-legal`.

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
