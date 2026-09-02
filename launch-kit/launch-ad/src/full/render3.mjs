/* Full render with progress, so a stall is visible instead of silent. */
import { chromium } from 'playwright';
import { mkdirSync, rmSync } from 'fs';
import { resolve } from 'path';
const name='film3', FPS=30, OUT='frames_film3';
rmSync(OUT,{recursive:true,force:true}); mkdirSync(OUT,{recursive:true});
const b=await chromium.launch({executablePath:'/opt/pw-browsers/chromium-1194/chrome-linux/chrome',
  args:['--no-sandbox','--disable-gpu','--font-render-hinting=none']});
const p=await b.newPage({viewport:{width:1080,height:1920},deviceScaleFactor:1});
p.on('pageerror',e=>console.error('PAGEERROR:',e.message));
p.on('console',m=>{if(m.type()==='error')console.error('PAGE:',m.text())});
await p.goto('file://'+resolve(`${name}.html`));
await p.waitForFunction(()=>window.READY===true,{timeout:90000});
const dur=await p.evaluate(()=>window.DURATION), total=Math.round(dur*FPS);
const el=await p.$('#c');
const t0=Date.now();
for(let i=0;i<total;i++){
  await p.evaluate(t=>window.SEEK(t), i/FPS);
  await el.screenshot({path:`${OUT}/f${String(i).padStart(4,'0')}.jpg`,type:'jpeg',quality:96});
  if(i%120===0||i===total-1){
    const el2=(Date.now()-t0)/1000;
    console.log(`${i+1}/${total}  ${el2.toFixed(0)}s  eta ${(el2/(i+1)*(total-i-1)).toFixed(0)}s`);
  }
}
await b.close();
console.log(`done: ${total} frames (${dur}s)`);
