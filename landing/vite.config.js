import { defineConfig } from 'vite';
import react from '@vitejs/plugin-react';
import path from 'path';

export default defineConfig({
  plugins: [react()],
  resolve: {
    alias: {
      // Map @docs to the docs directory at project root
      '@docs': path.resolve(__dirname, '../docs'),
    },
  },
  test: {
    environment: 'jsdom',
    globals: true,
    setupFiles: './src/test-setup.js',
    coverage: {
      provider: 'v8',
      reporter: ['text', 'json', 'html'],
      exclude: [
        'node_modules/',
        'public/',       // Godot WASM / compiled artifacts — not testable source
        'src/test-setup.js',
        '**/*.test.{js,jsx}',
        '**/__tests__/**',
      ],
    },
  },
  build: {
    outDir: '../dist',
    emptyOutDir: false, // Don't delete Godot files
    rollupOptions: {
      output: {
        manualChunks: undefined, // Single bundle for speed
      },
    },
  },
  server: {
    port: 3000,
    fs: {
      allow: [
        // Allow serving files from the landing root
        '.',
        // Allow access to docs/ directory at project root
        path.resolve(__dirname, '../docs'),
      ],
    },
  },
});
