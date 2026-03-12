#!/usr/bin/env node

import fs from 'fs';
import path from 'path';
import { fileURLToPath } from 'url';

const __dirname = path.dirname(fileURLToPath(import.meta.url));
const blogDir = path.join(__dirname, '../src/content/blog');

/**
 * Parse frontmatter from a markdown file
 * Returns { frontmatter: string, content: string }
 */
function parseFrontmatter(fileContent) {
  const match = fileContent.match(/^---\n([\s\S]*?)\n---\n([\s\S]*)$/);
  if (!match) {
    return null;
  }
  return { frontmatter: match[1], content: match[2] };
}

/**
 * Parse YAML-like frontmatter into an object
 */
function parseFrontmatterYAML(frontmatterText) {
  const lines = frontmatterText.split('\n');
  const obj = {};

  for (const line of lines) {
    const match = line.match(/^([^:]+):\s*(.*)$/);
    if (match) {
      const key = match[1].trim();
      let value = match[2].trim();

      // Remove quotes if present
      if ((value.startsWith('"') && value.endsWith('"')) || 
          (value.startsWith("'") && value.endsWith("'"))) {
        value = value.slice(1, -1);
      }

      obj[key] = value;
    }
  }

  return obj;
}

/**
 * Convert date to YYYY-MM-DD format
 */
function formatDate(date) {
  const year = date.getFullYear();
  const month = String(date.getMonth() + 1).padStart(2, '0');
  const day = String(date.getDate()).padStart(2, '0');
  return `${year}-${month}-${day}`;
}

/**
 * Update frontmatter with new updatedDate
 */
function updateFrontmatterDate(frontmatterText, newDate) {
  // Check if updatedDate already exists
  if (frontmatterText.includes('updatedDate:')) {
    // Replace existing updatedDate
    return frontmatterText.replace(
      /updatedDate:\s*\d{4}-\d{2}-\d{2}/,
      `updatedDate: ${newDate}`
    );
  } else {
    // Add updatedDate after pubDate
    return frontmatterText.replace(
      /(pubDate:\s*\d{4}-\d{2}-\d{2})/,
      `$1\nupdatedDate: ${newDate}`
    );
  }
}

/**
 * Process a single blog file
 */
function processBlogFile(filePath) {
  const fileContent = fs.readFileSync(filePath, 'utf-8');
  const parsed = parseFrontmatter(fileContent);

  if (!parsed) {
    console.warn(`⚠️  Could not parse frontmatter in ${path.basename(filePath)}`);
    return false;
  }

  const { frontmatter, content } = parsed;
  const frontmatterObj = parseFrontmatterYAML(frontmatter);
  const fileStats = fs.statSync(filePath);
  const fileModTime = new Date(fileStats.mtime);
  const fileModDateStr = formatDate(fileModTime);

  // Parse pubDate from frontmatter
  const pubDateStr = frontmatterObj.pubDate;
  const pubDate = new Date(pubDateStr);

  // Only update if file was modified after pubDate
  if (fileModTime > pubDate) {
    const currentUpdatedDate = frontmatterObj.updatedDate;

    // Only write if updatedDate is missing or needs updating
    if (!currentUpdatedDate || currentUpdatedDate !== fileModDateStr) {
      const updatedFrontmatter = updateFrontmatterDate(frontmatter, fileModDateStr);
      const updatedContent = `---\n${updatedFrontmatter}\n---\n${content}`;

      fs.writeFileSync(filePath, updatedContent, 'utf-8');
      console.log(`✓ Updated ${path.basename(filePath)} - updatedDate: ${fileModDateStr}`);
      return true;
    } else {
      console.log(`✓ ${path.basename(filePath)} - already up to date (${fileModDateStr})`);
      return false;
    }
  } else {
    console.log(`✓ ${path.basename(filePath)} - no changes since publication`);
    return false;
  }
}

/**
 * Main script
 */
function main() {
  console.log('🔍 Scanning blog posts for updates...\n');

  if (!fs.existsSync(blogDir)) {
    console.error(`❌ Blog directory not found: ${blogDir}`);
    process.exit(1);
  }

  const files = fs.readdirSync(blogDir).filter(file => 
    (file.endsWith('.mdx') || file.endsWith('.md')) && !file.startsWith('.')
  );

  if (files.length === 0) {
    console.log('No blog posts found.');
    return;
  }

  let updated = 0;
  for (const file of files) {
    const filePath = path.join(blogDir, file);
    if (processBlogFile(filePath)) {
      updated++;
    }
  }

  console.log(`\n✨ Complete! Updated ${updated} file(s).`);
}

main();
