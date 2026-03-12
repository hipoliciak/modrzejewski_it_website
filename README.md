# Personal Website

Astro-based personal website with:
- Home page with featured projects and featured articles
- Blog (MDX) with tags, Mermaid rendering, and cover images
- Projects portfolio
- Contact form with anti-spam safeguards and privacy consent
- Privacy policy and sitemap integration

## Tech Stack

- Astro 5
- Tailwind CSS (+ Typography plugin)
- MDX content collections
- Mermaid (client-side rendering in blog posts)
- Sharp (image optimization via Astro image pipeline)

## Project Structure

```text
src/
	components/      Reusable UI (Header, Footer, Hero, cards, ContactForm)
	content/
		blog/          Blog posts (.mdx) and post-local assets
		projects/      Project entries (.md) and project-local assets
		config.ts      Content collection schema definitions
	layouts/         Layouts for blog and project detail pages
	pages/           Route files (home, blog, projects, contact, privacy policy)
	data/            JSON data (CV)

public/
	images/          Global/static images not tied to one content entry

deploy.sh          Production deployment script (scp + atomic switch)
```

## Getting Started

### 1) Install dependencies

```bash
npm install
```

### 2) Run locally

```bash
npm run dev
```

Default local URL: `http://localhost:4321`

### 3) Build for production

```bash
npm run build
```

### 4) Preview production build

```bash
npm run preview
```

## Content Authoring

Content schemas are defined in `src/content/config.ts`.

### Blog post frontmatter

Required:
- `title`
- `description`
- `pubDate`
- `category`

Common optional fields:
- `updatedDate`
- `author` (defaults to `Dominik Modrzejewski`)
- `featured` (`true/false`)
- `featuredOrder` (lower number appears earlier among featured posts)
- `tags` (array)
- `image` (local image path, e.g. `./cover.png`)
- `imageAlt`
- `draft`

### Project frontmatter

Required:
- `title`
- `description`

Common optional fields:
- `tags`
- `github`
- `demo`
- `image` (local image path)
- `imageAlt`
- `featured`
- `order`

### Recommended image workflow

- Keep post-specific images next to the post (inside the same folder under `src/content/blog/...`).
- Reference covers in frontmatter with a relative path (`image: ./cover.png`).
- Use modern formats when practical (`.avif`, optimized `.png`, `.webp`).

## Deployment

This project includes `deploy.sh` for server deployment.

### 1) Create deployment env file

Create `.deploy.env` in the repository root:

```bash
VPS_HOST=your-host
VPS_PORT=22
VPS_USER=root
REMOTE_WEBROOT=/var/www/html
KEEP_BACKUPS=5
SKIP_NPM_CI=0
```

You can also point to a different env file:

```bash
DEPLOY_ENV_FILE=/path/to/env.file ./deploy.sh
```

### 2) Run deployment

```bash
./deploy.sh
```

What it does:
- Builds the site
- Archives `dist/`
- Uploads archive via `scp`
- Performs atomic release switch on VPS
- Keeps only the newest `KEEP_BACKUPS` backup folders

## Scripts

- `npm run dev` — start development server
- `npm run build` — build static output
- `npm run preview` — preview production build
- `npm run astro` — run Astro CLI commands

## Notes

- Site URL is configured in `astro.config.mjs` as `https://modrzejewski.it`.
- Mermaid diagrams in blog posts are rendered on the client side.