// node render.js stills t1 t2 ...   |   node render.js video out.mp4 [fps]
const { chromium } = require('playwright-core');
const { spawn } = require('child_process');
const path = require('path');
const EXE = path.join(process.env.LOCALAPPDATA, 'ms-playwright/chromium_headless_shell-1194/chrome-win/headless_shell.exe');
const FF = process.env.FFMPEG;
(async () => {
  const [mode, ...args] = process.argv.slice(2);
  const b = await chromium.launch({ executablePath: EXE, args: ['--allow-file-access-from-files'] });
  const p = await b.newPage({ viewport: { width: 1080, height: 1920 } });
  p.on('console', m => console.log('page:', m.text())); p.on('pageerror', e => console.log('ERR', e.message));
  await p.goto(require('url').pathToFileURL(path.join(__dirname, 'promo.html')).href + '?render=1');
  await p.evaluate(() => window.ready);
  const dur = await p.evaluate(() => DURATION);
  if (mode === 'stills') {
    for (const t of args) { await p.evaluate(t => renderAt(t), +t); await p.screenshot({ path: `still-${t}.png` }); }
    console.log('duration', dur);
  } else {
    const fps = +(args[1] || 30), out = args[0], n = Math.round(dur * fps);
    const ff = spawn(FF, ['-y', '-f', 'image2pipe', '-framerate', String(fps), '-c:v', 'mjpeg', '-i', '-',
      '-c:v', 'libx264', '-preset', 'slow', '-crf', '17', '-pix_fmt', 'yuv420p', '-movflags', '+faststart', out], { stdio: ['pipe', 'inherit', 'inherit'] });
    for (let i = 0; i < n; i++) {
      await p.evaluate(t => renderAt(t), i / fps);
      const buf = await p.screenshot({ type: 'jpeg', quality: 95 });
      if (!ff.stdin.write(buf)) await new Promise(r => ff.stdin.once('drain', r));
      if (i % 150 === 0) console.log(`frame ${i}/${n}`);
    }
    ff.stdin.end(); await new Promise(r => ff.on('close', r));
  }
  await b.close();
})();
