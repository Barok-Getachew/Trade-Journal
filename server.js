const express = require('express');
const path = require('path');
const app = express();

const port = process.env.PORT || 8080;

const buildDir = path.join(__dirname, 'build/web');

// ── Never cache index.html or the Flutter service worker ─────────────────────
// This forces the browser to always fetch the latest version on deploy.
const noCacheFiles = /\/(index\.html|flutter_service_worker\.js|flutter\.js)$/;

app.use((req, res, next) => {
  if (noCacheFiles.test(req.path)) {
    res.setHeader('Cache-Control', 'no-store, no-cache, must-revalidate, proxy-revalidate');
    res.setHeader('Pragma', 'no-cache');
    res.setHeader('Expires', '0');
  }
  next();
});

// ── Serve Flutter build with long-term cache for hashed assets ────────────────
app.use(express.static(buildDir, {
  maxAge: '1y',     // JS/CSS/fonts/images have content hashes — safe to cache
  etag: true,
}));

// ── SPA fallback ──────────────────────────────────────────────────────────────
app.get('*', (req, res) => {
  res.setHeader('Cache-Control', 'no-store, no-cache, must-revalidate');
  res.sendFile(path.join(buildDir, 'index.html'));
});

app.listen(port, () => {
  console.log(`Server started on port ${port}`);
});
