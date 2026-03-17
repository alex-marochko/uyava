import { getCollection, type CollectionEntry } from 'astro:content';

export type BlogEntry = CollectionEntry<'blog'>;

export async function getBlogEntries(options?: {
  includeDrafts?: boolean;
}): Promise<BlogEntry[]> {
  const includeDrafts = options?.includeDrafts ?? !import.meta.env.PROD;
  const entries = await getCollection(
    'blog',
    ({ data }) => includeDrafts || !data.draft,
  );

  return entries.sort(
    (left, right) => right.data.pubDate.valueOf() - left.data.pubDate.valueOf(),
  );
}
