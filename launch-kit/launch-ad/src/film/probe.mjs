import { chromium } from 'playwright';
import { resolve } from 'path';
const b=await chromium.launch({executablePath:'/opt/pw-browsers/chromium-1194/chrome-linux/chrome',args:['--no-sandbox','--disable-gpu','--font-render-hinting=none']});
const p=await b.newPage({viewport:{width:1080,height:1920},deviceScaleFactor:1});
p.on('pageerror',e=>console.error('PAGEERROR:',e.message));
p.on('console',m=>{if(m.type()==='error')console.error('PAGE:',m.text())});
await p.goto('file://'+resolve('film.html'));
await p.waitForFunction(()=>window.READY===true,{timeout:60000});
console.log('textures:',Object.keys(await p.evaluate(()=>window.TEX)));
const el=await p.$('#c');
const ts=[2.0,4.4,6.5,9.5,13.0,16.5,20.0,24.5,28.0,34.0,40.0,43.0,48.0,50.5];
for(const t of ts){await p.evaluate(x=>window.SEEK(x),t);await el.screenshot({path:`pb_${String(t).replace('.','_')}.png`})}
await b.close();console.log('ok');
