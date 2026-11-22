import { deflateSync } from 'node:zlib';
import { writeFileSync } from 'node:fs';

const S = 1024;
const px = Buffer.alloc(S*S*4);
const clamp=(v,a=0,b=1)=>v<a?a:v>b?b:v;
const mix=(a,b,t)=>a+(b-a)*t;
function segDist(px_,py_,ax,ay,bx,by){
  const vx=bx-ax, vy=by-ay, wx=px_-ax, wy=py_-ay;
  const t=clamp((wx*vx+wy*vy)/(vx*vx+vy*vy));
  const dx=px_-(ax+vx*t), dy=py_-(ay+vy*t);
  return Math.sqrt(dx*dx+dy*dy);
}
// glyph strokes in normalized space
const cap = [
  {a:[0.235,0.285], b:[0.775,0.285], r:0.075},
  {a:[0.775,0.285], b:[0.435,0.790], r:0.075},
];
for(let y=0;y<S;y++){
  for(let x=0;x<S;x++){
    const u=x/(S-1), v=y/(S-1);
    // background: radial glow + vertical tint
    const cx=u-0.5, cy=v-0.42;
    const d=Math.sqrt(cx*cx+cy*cy);
    const glow=Math.exp(-d*d*7.5);
    let r=mix(5,26,glow), g=mix(5,26,glow), b=mix(10,40,glow);
    // glyph alpha via SDF
    let dist=1e9;
    for(const s of cap) dist=Math.min(dist, segDist(u,v,s.a[0],s.a[1],s.b[0],s.b[1])-s.r);
    const aa=0.0018;
    const ga=clamp(0.5-dist/aa);
    if(ga>0){
      const t=clamp((v-0.26)/0.55);
      // cyan -> blue -> violet
      let gr,gg,gb;
      if(t<0.5){const k=t/0.5; gr=mix(34,59,k); gg=mix(211,130,k); gb=mix(238,246,k);}
      else {const k=(t-0.5)/0.5; gr=mix(59,168,k); gg=mix(130,85,k); gb=mix(246,247,k);}
      r=mix(r,gr,ga); g=mix(g,gg,ga); b=mix(b,gb,ga);
    }
    const i=(y*S+x)*4;
    px[i]=r|0; px[i+1]=g|0; px[i+2]=b|0; px[i+3]=255;
  }
}
// PNG: filter 0 per scanline
const raw=Buffer.alloc(S*(S*4+1));
for(let y=0;y<S;y++){
  raw[y*(S*4+1)]=0;
  px.copy(raw, y*(S*4+1)+1, y*S*4, (y+1)*S*4);
}
function crc32(buf){
  let c, crc=0xffffffff;
  for(let n=0;n<buf.length;n++){
    c=(crc^buf[n])&0xff;
    for(let k=0;k<8;k++) c=c&1?0xedb88320^(c>>>1):c>>>1;
    crc=(crc>>>8)^c;
  }
  return (crc^0xffffffff)>>>0;
}
function chunk(type,data){
  const len=Buffer.alloc(4); len.writeUInt32BE(data.length);
  const t=Buffer.from(type,'ascii');
  const crc=Buffer.alloc(4); crc.writeUInt32BE(crc32(Buffer.concat([t,data])));
  return Buffer.concat([len,t,data,crc]);
}
const ihdr=Buffer.alloc(13);
ihdr.writeUInt32BE(S,0); ihdr.writeUInt32BE(S,4);
ihdr[8]=8; ihdr[9]=6; ihdr[10]=0; ihdr[11]=0; ihdr[12]=0;
const png=Buffer.concat([
  Buffer.from([0x89,0x50,0x4e,0x47,0x0d,0x0a,0x1a,0x0a]),
  chunk('IHDR',ihdr),
  chunk('IDAT',deflateSync(raw,{level:9})),
  chunk('IEND',Buffer.alloc(0)),
]);
writeFileSync(process.argv[2]||'icon1024.png', png);
console.log('ok', png.length);
