import { defineConfig } from "vite";
import react from "@vitejs/plugin-react";

export default defineConfig({
  plugins: [react()],
  server: {
    // local dev: forward relative /api calls to a locally running backend
    proxy: { "/api": "http://localhost:8080" },
  },
});
