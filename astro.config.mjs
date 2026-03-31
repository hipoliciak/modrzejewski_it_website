import { defineConfig } from 'astro/config';
import mdx from '@astrojs/mdx';

export default defineConfig({
  site: 'https://modrzejewski.it',
  build: {
    inlineStylesheets: 'always',
  },
  integrations: [
    mdx(),
  ],
  markdown: {
    shikiConfig: {
      theme: 'github-dark',
      langs: [],
    },
  },
});
