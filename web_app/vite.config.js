import { defineConfig } from 'vite'
import react from '@vitejs/plugin-react'
import tailwindcss from '@tailwindcss/vite'
import { viteSingleFile } from "vite-plugin-singlefile"

// https://vite.dev/config/
export default defineConfig({
  plugins: [
    tailwindcss(),
    react(),
    viteSingleFile()
  ],
  build: {
    // Generate the output inside the Flutter project's assets
    outDir: '../assets/web_app',
    emptyOutDir: true,
  },
  // Use relative paths for assets so flutter can load it from file:// protocol
  base: './'
})
