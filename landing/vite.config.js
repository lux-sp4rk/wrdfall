import { defineConfig } from 'vite';
import react from '@vitejs/plugin-react';

export default defineConfig({
  plugins: [react()],
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
  },
});
