import { z, defineCollection } from 'astro:content';

const legal = defineCollection({
  type: 'content',
});

const blog = defineCollection({
  type: 'content',
  schema: ({ image }) =>
    z.object({
      title: z.string(),
      description: z.string(),
      pubDate: z.coerce.date(),
      updatedDate: z.coerce.date().optional(),
      tags: z.array(z.string()).default([]),
      draft: z.boolean().default(false),
      heroImage: image().optional(),
    }),
});

export const collections = {
  legal,
  blog,
};
