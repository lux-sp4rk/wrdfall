#!/usr/bin/env node

/**
 * Analyze used glyphs in the app
 * Scans HTML, CSS, and JS files to find emoji and special characters
 * Outputs glyph list for font subsetting
 */

const fs = require('fs');
const path = require('path');

const INCLUDE_DIRS = [
  'landing/src',
  'landing/index.html',
  'godot'
];

const glyphSet = new Set();

// Regular expressions for different types of glyphs
const EMOJI_REGEX = /[\p{Emoji}]/gu; // Unicode emoji
const HEX_ENTITY_REGEX = /&#x([0-9A-Fa-f]+);/g; // Hex entities like &#x1F600;
const UNICODE_ESCAPE_REGEX = /\\u([0-9A-Fa-f]{4})/g; // Unicode escapes

function scanFile(filePath) {
  try {
    const content = fs.readFileSync(filePath, 'utf-8');

    // Extract emoji using Unicode regex
    let match;
    while ((match = EMOJI_REGEX.exec(content)) !== null) {
      const glyph = match[0];
      const codePoint = glyph.codePointAt(0).toString(16).toUpperCase();
      glyphSet.add(codePoint);
    }

    // Extract hex entities
    while ((match = HEX_ENTITY_REGEX.exec(content)) !== null) {
      glyphSet.add(match[1].toUpperCase());
    }

    // Extract Unicode escapes
    while ((match = UNICODE_ESCAPE_REGEX.exec(content)) !== null) {
      glyphSet.add(match[1].toUpperCase());
    }
  } catch (error) {
    // Ignore binary files
    if (error.code !== 'ENOENT') {
      console.warn(`Warning: could not read ${filePath}: ${error.message}`);
    }
  }
}

function scanDirectory(dirPath) {
  const entries = fs.readdirSync(dirPath, { withFileTypes: true });

  for (const entry of entries) {
    const fullPath = path.join(dirPath, entry.name);

    // Skip node_modules, .git, dist, etc.
    if (entry.name.startsWith('.') || entry.name === 'node_modules' || entry.name === 'dist') {
      continue;
    }

    if (entry.isDirectory()) {
      scanDirectory(fullPath);
    } else if (entry.isFile()) {
      scanFile(fullPath);
    }
  }
}

console.log('🔍 Analyzing glyphs used in the app...');

for (const dir of INCLUDE_DIRS) {
  if (fs.existsSync(dir)) {
    if (fs.statSync(dir).isDirectory()) {
      scanDirectory(dir);
    } else {
      scanFile(dir);
    }
  }
}

// Output results
const glyphList = Array.from(glyphSet).sort();
console.log(`\n✅ Found ${glyphList.length} unique glyphs:`);
console.log('\nUnicode ranges (for fonttools):');

// Group into ranges for more compact representation
const ranges = [];
let currentRange = null;

for (const glyph of glyphList) {
  const code = parseInt(glyph, 16);

  if (currentRange && code === currentRange.end + 1) {
    currentRange.end = code;
  } else {
    if (currentRange) {
      ranges.push(currentRange);
    }
    currentRange = { start: code, end: code };
  }
}

if (currentRange) {
  ranges.push(currentRange);
}

console.log(ranges.map(r => {
  if (r.start === r.end) {
    return `U+${r.start.toString(16).toUpperCase().padStart(4, '0')}`;
  }
  return `U+${r.start.toString(16).toUpperCase().padStart(4, '0')}-U+${r.end.toString(16).toUpperCase().padStart(4, '0')}`;
}).join(',\\\n'));

console.log('\nComma-separated glyph codes (for pyftsubset):');
console.log(glyphList.map(g => `U+${g.padStart(4, '0')}`).join(','));

// Save to file for use in subset-font.sh
const outputFile = 'scripts/glyphs.txt';
fs.writeFileSync(outputFile, glyphList.join('\n'));
console.log(`\n📝 Glyph list saved to ${outputFile}`);
