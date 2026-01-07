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
