const fs = require('fs');
const path = require('path');
const { minify: htmlMinify } = require('html-minifier-terser');
const { minify: jsMinify } = require('terser');

const DIST_DIR = path.resolve(__dirname, '../dist');

async function processFiles() {
  if (!fs.existsSync(DIST_DIR)) {
    console.error('❌ dist/ directory not found');
    process.exit(1);
  }

  const files = await fs.promises.readdir(DIST_DIR);
  
  for (const file of files) {
    const filePath = path.join(DIST_DIR, file);
    const stats = await fs.promises.stat(filePath);
    
    if (stats.isDirectory()) continue;

    if (file.endsWith('.html')) {
      console.log(`Processing HTML: ${file}`);
      const content = await fs.promises.readFile(filePath, 'utf8');
      try {
        const minified = await htmlMinify(content, {
          collapseWhitespace: true,
          removeComments: true,
          minifyJS: true,
          minifyCSS: true,
          removeScriptTypeAttributes: true,
          removeStyleLinkTypeAttributes: true
        });
        await fs.promises.writeFile(filePath, minified);
        console.log(`✅ Minified HTML: ${file}`);
      } catch (err) {
        console.error(`❌ Failed to minify HTML ${file}:`, err);
      }
    } else if (file.endsWith('.js')) {
      // Skip worker/support files if they are huge or problematic, but for Godot exports, main .js is usually fine.
      // Godot exports typically include index.js and index.pck/wasm.
      console.log(`Processing JS: ${file}`);
      const content = await fs.promises.readFile(filePath, 'utf8');
      try {
        const result = await jsMinify(content, {
          compress: {
            drop_console: true, // Remove console logs for prod
            passes: 2
          },
          mangle: true
        });
        if (result.code) {
          await fs.promises.writeFile(filePath, result.code);
          console.log(`✅ Minified JS: ${file}`);
        }
      } catch (err) {
        console.error(`❌ Failed to minify JS ${file}:`, err);
      }
    }
  }
}

processFiles().catch(console.error);
