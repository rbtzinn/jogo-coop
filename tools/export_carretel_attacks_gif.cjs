// Encodes Godot-rendered frames without redrawing the generated art.
const fs = require('fs');
const path = require('path');
const sharp = require('C:/Users/roberto.gabriel/.cache/codex-runtimes/codex-primary-runtime/dependencies/node/node_modules/sharp');
const arena = process.argv.includes('--arena');
const dir = path.resolve(__dirname,arena ? '../build/qa/carretel/arena' : '../build/qa/carretel/attacks');
const lengths = [2.32,2.8,3.3,3.3,4.1,3.7];
(async () => {
  const names = fs.readdirSync(dir).filter(n=>/^gif_\d\d_\d\d\.png$/.test(n)).sort();
  if(names.length!==180) throw Error(`Expected 180 rendered frames, got ${names.length}`);
  const pages = await Promise.all(names.map(n=>sharp(path.join(dir,n)).ensureAlpha().raw().toBuffer()));
  const delays = names.map(n=>Math.round(lengths[Number(n.slice(4,6))]*1000/30));
  const out = path.join(dir,arena ? 'carretel_cenario.gif' : 'carretel_ataques.gif');
  await sharp(Buffer.concat(pages),{raw:{width:960,height:540*pages.length,channels:4,pageHeight:540}})
    .gif({loop:0,delay:delays,colours:256,effort:3,dither:0}).toFile(out);
  console.log(JSON.stringify({file:out,frames:pages.length,...await sharp(out,{animated:true}).metadata()}));
})().catch(error=>{console.error(error);process.exit(1);});
