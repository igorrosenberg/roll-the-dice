// Renders tool/icons/*.svg to the PNGs in web/. Run: node tool/render_icons.js
const { chromium } = require('playwright');
const fs = require('fs');
const path = require('path');
const root = path.join(__dirname, '..');
const jobs = [
  ['icon.svg', 'web/icons/Icon-512.png', 512],
  ['icon.svg', 'web/icons/Icon-192.png', 192],
  ['icon-maskable.svg', 'web/icons/Icon-maskable-512.png', 512],
  ['icon-maskable.svg', 'web/icons/Icon-maskable-192.png', 192],
  ['icon-opaque.svg', 'web/icons/apple-touch-icon.png', 180],
  ['icon.svg', 'web/favicon.png', 32],
];
(async () => {
  const browser = await chromium.launch();
  const page = await browser.newPage();
  for (const [src, dst, size] of jobs) {
    const svg = fs.readFileSync(path.join(__dirname, 'icons', src), 'utf8');
    await page.setViewportSize({ width: size, height: size });
    await page.setContent(`<html><body style="margin:0;background:transparent">` +
      `<img src="data:image/svg+xml;base64,${Buffer.from(svg).toString('base64')}" width="${size}" height="${size}" style="display:block"></body></html>`);
    await page.screenshot({ path: path.join(root, dst), omitBackground: true });
  }
  await browser.close();
})();
