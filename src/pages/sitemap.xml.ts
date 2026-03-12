import type { APIRoute } from 'astro';
import { getCollection } from 'astro:content';
import { tagToSlug } from '../utils/tags';

const SITE_URL = 'https://modrzejewski.it';

const toSlug = (entryId: string) => entryId.replace(/\.(md|mdx)$/, '');
const toUrl = (path: string) => `${SITE_URL}${path}`;

const xmlEscape = (value: string) =>
  value
    .replace(/&/g, '&amp;')
    .replace(/</g, '&lt;')
    .replace(/>/g, '&gt;')
    .replace(/"/g, '&quot;')
    .replace(/'/g, '&apos;');

export const GET: APIRoute = async () => {
  const [blogPosts, projects] = await Promise.all([
    getCollection('blog', ({ data }) => !data.draft),
    getCollection('projects'),
  ]);

  const staticPages = [
    '/',
    '/blog',
    '/tags',
    '/about-me',
    '/contact',
    '/privacy-policy',
    '/llm/blog',
    '/llm/projects',
  ];

  const blogPages = blogPosts.map((post) => `/blog/${toSlug(post.id)}`);
  const projectPages = projects.map((project) => `/projects/${toSlug(project.id)}`);
  const tagPages = [
    ...new Set([
      ...blogPosts.flatMap((post) => post.data.tags),
      ...projects.flatMap((project) => project.data.tags),
    ]),
  ].map((tag) => `/tags/${tagToSlug(tag)}`);

  const allPages = [...staticPages, ...blogPages, ...projectPages, ...tagPages];
  const nowIso = new Date().toISOString();

  const body = allPages
    .map((path) => {
      const priority = path === '/' ? '1.0' : '0.7';
      return [
        '  <url>',
        `    <loc>${xmlEscape(toUrl(path))}</loc>`,
        `    <lastmod>${nowIso}</lastmod>`,
        '    <changefreq>weekly</changefreq>',
        `    <priority>${priority}</priority>`,
        '  </url>',
      ].join('\n');
    })
    .join('\n');

  const xml = [
    '<?xml version="1.0" encoding="UTF-8"?>',
    '<urlset xmlns="http://www.sitemaps.org/schemas/sitemap/0.9">',
    body,
    '</urlset>',
  ].join('\n');

  return new Response(xml, {
    headers: {
      'Content-Type': 'application/xml; charset=utf-8',
      'Cache-Control': 'public, max-age=3600',
    },
  });
};
