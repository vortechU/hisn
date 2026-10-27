// node render.js stills 1.2,5.5,...   -> stills/t_<t>.png
// node render.js video out.mp4 [fps]  -> H.264 9:16 MP4, no audio track
const fs = require('fs');
const path = require('path');
const { spawn } = require('child_process');
const puppeteer = require('puppeteer-core');
const ffmpeg = require('ffmpeg-static');

const CHROME = 'C:/Program Files/Google/Chrome/Application/chrome.exe';
const URL = 'file:///' + path.join(__dirname, 'index.html').replace(/\\/g, '/');

async function openPage(browser) {
  const page = await browser.newPage();
  await page.setViewport({ width: 1080, height: 1920, deviceScaleFactor: 1 });
  page.on('console', (m) => console.log('[page]', m.text()));
  page.on('pageerror', (e) => console.error('[pageerror]', e.message));
  await page.goto(URL, { waitUntil: 'load' });
  await page.evaluate(() => window.ready);
  return page;
}
const grab = (page, t) =>
  page.evaluate((t) => { window.render(t); return document.getElementById('c').toDataURL('image/png'); }, t)
    .then((u) => Buffer.from(u.slice(u.indexOf(',') + 1), 'base64'));

(async () => {
  const [mode, arg, fpsArg] = process.argv.slice(2);
  const launch = () => puppeteer.launch({
    executablePath: CHROME, headless: true, protocolTimeout: 600000,
    args: ['--force-color-profile=srgb', '--disable-background-timer-throttling',
      '--disable-renderer-backgrounding', '--disable-backgrounding-occluded-windows'],
  });
  const browser = await launch();
  const extra = [];
  try {
    if (mode === 'stills') {
      const page = await openPage(browser);
      fs.mkdirSync(path.join(__dirname, 'stills'), { recursive: true });
      for (const t of arg.split(',').map(Number)) {
        fs.writeFileSync(path.join(__dirname, 'stills', `t_${t.toFixed(2)}.png`), await grab(page, t));
      }
      console.log('stills done');
      return;
    }
    const fps = Number(fpsArg || 60);
    const duration = await (await openPage(browser)).evaluate(() => window.DURATION);
    const total = Math.round(duration * fps);
    const workers = 6;
    // One browser per worker: background tabs get throttled and stall.
    for (let i = 0; i < workers; i++) extra.push(await launch());
    const pages = await Promise.all(extra.map((b) => openPage(b)));
    console.log('workers ready');
    const ff = spawn(ffmpeg, ['-y', '-f', 'image2pipe', '-framerate', String(fps), '-c:v', 'png', '-i', '-',
      '-c:v', 'libx264', '-preset', 'slow', '-crf', '16', '-pix_fmt', 'yuv420p', '-profile:v', 'high',
      '-color_primaries', 'bt709', '-color_trc', 'bt709', '-colorspace', 'bt709',
      '-movflags', '+faststart', '-an', arg], { stdio: ['pipe', 'inherit', 'inherit'] });
    const done = new Promise((res, rej) => ff.on('close', (c) => (c === 0 ? res() : rej(new Error('ffmpeg ' + c)))));
    const t0 = Date.now();
    for (let base = 0; base < total; base += workers) {
      const batch = await Promise.all(pages.map((pg, i) => (base + i < total ? grab(pg, (base + i) / fps) : null)));
      for (const buf of batch) if (buf && !ff.stdin.write(buf)) await new Promise((r) => ff.stdin.once('drain', r));
      if (base % (fps * 2) < workers) console.log(`frame ${base}/${total}  ${((Date.now() - t0) / 1000).toFixed(0)}s`);
    }
    ff.stdin.end();
    await done;
    console.log('video done', arg);
  } finally {
    await Promise.all([browser, ...extra].map((b) => b.close()));
  }
})();
