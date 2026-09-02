import { chromium } from 'playwright';
import { rename } from 'fs/promises';

const V = '/tmp/claude-0/-home-user-milton-nation-alumni-app/dd2da122-5343-58be-9237-b6e112802222/scratchpad/video';
const SEGS = [
  ['seg01', 5.0], ['seg02', 4.0], ['seg03', 8.0], ['seg04', 4.5], ['seg05', 7.0],
  ['seg06', 6.5], ['seg07', 6.0], ['seg08', 5.5], ['seg09', 6.0], ['seg10', 9.0],
];
const mode = process.argv[2] || 'shot';           // shot | rec
const only = process.argv[3];                      // optional single segment

const browser = await chromium.launch();
for (const [name, dur] of SEGS) {
  if (only && name !== only) continue;
  if (mode === 'shot') {
    const page = await browser.newPage({ viewport: { width: 1080, height: 1920 } });
    await page.goto(`file://${V}/seg/${name}.html`);
    const tShot = Math.min(dur - 1.2, dur * 0.62) * 1000;
    await page.waitForTimeout(tShot);
    await page.screenshot({ path: `${V}/out/qa-${name}.png` });
    await page.close();
    console.log(`shot qa-${name}.png @${(tShot / 1000).toFixed(1)}s`);
  } else {
    const ctx = await browser.newContext({
      viewport: { width: 1080, height: 1920 },
      recordVideo: { dir: `${V}/rec`, size: { width: 1080, height: 1920 } },
    });
    const page = await ctx.newPage();
    await page.goto(`file://${V}/seg/${name}.html`);
    await page.waitForTimeout(dur * 1000 + 250);
    const vid = page.video();
    await ctx.close();
    await rename(await vid.path(), `${V}/rec/${name}.webm`);
    console.log(`rec ${name}.webm (${dur}s)`);
  }
}
await browser.close();
