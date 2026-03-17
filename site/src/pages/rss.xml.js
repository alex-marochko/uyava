import { SITE } from '../config';
import { getBlogEntries } from '../data/blog';

export const prerender = true;

function escapeXml(value) {
  return value
    .replaceAll('&', '&amp;')
    .replaceAll('<', '&lt;')
    .replaceAll('>', '&gt;')
    .replaceAll('"', '&quot;')
    .replaceAll("'", '&apos;');
}

export async function GET() {
  const posts = await getBlogEntries({ includeDrafts: false });
  const siteUrl = SITE.url.endsWith('/') ? SITE.url.slice(0, -1) : SITE.url;
  const lastBuildDate = new Date().toUTCString();

  const items = posts
    .map((post) => {
      const postUrl = `${siteUrl}/blog/${post.slug}/`;
      const pubDate = post.data.pubDate.toUTCString();
      const description = escapeXml(post.data.description);
      const title = escapeXml(post.data.title);

      return [
        '<item>',
        `<title>${title}</title>`,
        `<link>${postUrl}</link>`,
        `<guid>${postUrl}</guid>`,
        `<pubDate>${pubDate}</pubDate>`,
        `<description>${description}</description>`,
        '</item>',
      ].join('');
    })
    .join('');

  const xml = [
    '<?xml version="1.0" encoding="UTF-8"?>',
    '<rss version="2.0">',
    '<channel>',
    `<title>${escapeXml(SITE.title)} Blog</title>`,
    `<link>${siteUrl}/blog/</link>`,
    `<description>${escapeXml('Articles, launch notes, and product updates from Uyava.')}</description>`,
    `<lastBuildDate>${lastBuildDate}</lastBuildDate>`,
    items,
    '</channel>',
    '</rss>',
  ].join('');

  return new Response(xml, {
    headers: {
      'Content-Type': 'application/xml; charset=utf-8',
    },
  });
}
