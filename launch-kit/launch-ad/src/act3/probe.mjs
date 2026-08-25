import { chromium } from 'playwright';
import { resolve } from 'path';
const b = await chromium.launch({executablePath:'/opt/pw-browsers/chromium-1194/chrome-linux/chrome',
  args:['--no-sandbox','--disable-gpu','--font-render-hinting=none']});
const p = await b.newPage({viewport:{width:1080,height:1920},deviceScaleFactor:1});
p.on('console', m=>{ if(m.type()==='error') console.error('PAGE:',m.text()); });
p.on('pageerror', e=>console.error('PAGEERROR:', e.message));
await p.goto('file://'+resolve('act3.html'));
await p.waitForFunction(()=>window.READY===true,{timeout:60000});
console.log('textures:', await p.evaluate(()=>Object.keys(window.TEX||{})));
const el = await p.$('#c');
for (const t of [1.8, 4.4, 8.2, 10.6, 14.0, 16.8]) {
  await p.evaluate(tt=>window.SEEK(tt), t);
  await el.screenshot({path:`probe_${String(t).replace('.','_')}.png`});
}
await b.close(); console.log('probes written');
