import { defineConfig } from 'astro/config';
import sitemap from '@astrojs/sitemap';

const site = 'https://uyava.io';
const base = process.env.BASE_PATH ?? '/';

export default defineConfig({
  site,
  base,
  output: 'static',
  integrations: [sitemap()],
});
