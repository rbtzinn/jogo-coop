// Codificação da prévia animada a partir dos PNGs finais; não redesenha a arte.
const path = require('path');
const sharp = require('C:/Users/roberto.gabriel/.cache/codex-runtimes/codex-primary-runtime/dependencies/node/node_modules/sharp');
const root = path.resolve(__dirname, '..');
const order = ['idle', 'scissors', 'tape', 'needles', 'cloth', 'hurt', 'armor', 'armor_attack', 'defeat'];
const fps = {idle:6,scissors:8,tape:8,needles:8,cloth:7,hurt:10,armor:6,armor_attack:8,defeat:5};

(async () => {
  const pages = [];
  const delays = [];
  for (const key of order) {
    for (let i = 0; i < 4; i++) {
      const png = path.join(root, 'bosses', 'madame_carretel', 'art', `${key}_${i+1}.png`);
      pages.push(await sharp(png).resize(768,768).ensureAlpha().raw().toBuffer());
      const duration = key === 'idle' ? (i === 2 ? 0.5 : 2) : [4,2,1,3][i];
      delays.push(Math.round(duration/fps[key]*1000) + (i === 3 ? 600 : 0));
    }
  }
  const out = path.join(root, 'build', 'qa', 'carretel', 'carretel_animacoes.gif');
  await sharp(Buffer.concat(pages), {raw:{width:768,height:768*pages.length,channels:4,pageHeight:768}})
    .gif({loop:0,delay:delays,colours:256,effort:3,dither:0})
    .toFile(out);
  const info = await sharp(out,{animated:true}).metadata();
  console.log(JSON.stringify({file:out,pages:info.pages,pageHeight:info.pageHeight,width:info.width}));
})().catch(error => {console.error(error);process.exit(1);});
