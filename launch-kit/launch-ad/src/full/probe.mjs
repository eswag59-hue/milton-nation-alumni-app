import { chromium } from 'playwright';
import { resolve } from 'path';
const b=await chromium.launch({executablePath:'/opt/pw-browsers/chromium-1194/chrome-linux/chrome',args:['--no-sandbox','--disable-gpu','--font-render-hinting=none']});
const p=await b.newPage({viewport:{width:1080,height:1920},deviceScaleFactor:1});
p.on('pageerror',e=>console.error('PAGEERROR:',e.message));
p.on('console',m=>{if(m.type()==='error')console.error('PAGE:',m.text())});
await p.goto('file://'+resolve('film2.html'));
await p.waitForFunction(()=>window.READY===true,{timeout:60000});
console.log('textures:',Object.keys(await p.evaluate(()=>window.T||{})).length||'(local)');
const el=await p.$('#c');
const ts=[2,4,7,9,12,15,19,25,31,37,42,45];
for(const t of ts){await p.evaluate(x=>window.SEEK(x),t);
  await el.screenshot({path:`pb_${String(t).padStart(2,'0')}.png`})}
await b.close();console.log('probes ok');
