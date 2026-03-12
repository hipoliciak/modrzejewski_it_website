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
	assets/
		blog/          Blog images (covers + inline post images)
		images/        Site profile/source images optimized via Astro pipeline
	content/
		blog/          Blog posts (.mdx)
		projects/      Project entries (.md) and project-local assets
		config.ts      Content collection schema definitions
	layouts/         Layouts for blog and project detail pages
	pages/           Route files (home, blog, projects, contact, privacy policy)
	data/            JSON data (CV)

public/
	images/          Static images/icons copied as-is (e.g. logos, SVG icons, favicon)

deploy.sh          Legacy local deployment script (optional)
.github/workflows/
	deploy.yml       CI/CD deployment on push to main
```