import * as THREE from 'three';
import * as F from './featherkin.js';
// ============ ILLUSORY GUARDS · law creature from Mirror images: one guard in three is an illusion ============
// A mirror copy of the defender's real guard: the same Featherkin, but cut from glassy, rainbow-sheened light that
// flickers, drifts a hair off its footing and shows a faint scanline shimmer. Raiders can walk straight through it.
export const S=F.S,build=F.build,loadBaked=F.loadBaked,CLIPS=F.CLIPS,EXPR=F.EXPR,BIN=F.BIN,RES=F.RES,GAME_SCALE=F.GAME_SCALE,ROUTE=F.ROUTE,EMBERS=F.EMBERS;
export const HERO=F.HERO;
let tx=null;const scanTex=()=>{if(tx)return tx;const c=document.createElement('canvas');c.width=4;c.height=128;const x=c.getContext('2d');for(let i=0;i<128;i++){x.fillStyle=i%4<2?'rgba(255,255,255,1)':'rgba(170,190,255,1)';x.fillRect(0,i,4,1);}tx=new THREE.CanvasTexture(c);tx.wrapS=tx.wrapT=THREE.RepeatWrapping;tx.repeat.set(1,18);return tx;};
function mirrorMat(m){const n=new THREE.MeshPhysicalMaterial({color:0x8A9CFF,emissive:0x5A4AE8,emissiveIntensity:.5,roughness:.1,metalness:.15,transparent:true,opacity:.78,
  iridescence:1,iridescenceIOR:1.7,iridescenceThicknessRange:[150,650],clearcoat:1,side:THREE.FrontSide,depthWrite:true});
 if(m&&m.vertexColors){n.vertexColors=true;n.color.set(0x9AA8FF);}if(m&&m.map){n.map=m.map;}n.emissiveMap=scanTex();n.userData.base=.62;
 if(m&&m.onBeforeCompile&&m.skinning!==false){} return n;}
export function makeRig(src,o){const r=F.makeRig(src,o);const mats=[];
 const inEye=o=>{for(let p=o;p;p=p.parent)if(/^eye_/.test(p.name))return true;return false;};
 r.root.traverse(ob=>{if(ob.isMesh&&/^fur_shell/.test(ob.name)){ob.visible=false;return;}if(ob.isMesh&&inEye(ob)){const a=Array.isArray(ob.material)?ob.material:[ob.material];ob.material=a.map(m=>{const n=m.clone();if(n.color&&!n.isMeshBasicMaterial)n.color.lerp(new THREE.Color(0x8A9CFF),.35);return n;});if(ob.material.length===1)ob.material=ob.material[0];return;}if(ob.isSprite){ob.material=ob.material.clone();ob.material.color.set(0xB8C8FF);mats.push(ob.material);return;}if(!ob.isMesh||!ob.material)return;const arr=Array.isArray(ob.material)?ob.material:[ob.material];
  const nm=arr.map(m=>{const n=mirrorMat(m);mats.push(n);return n;});ob.material=Array.isArray(ob.material)?nm:nm[0];ob.castShadow=false;});
 // a faint mirror halo on the ground where its shadow should be
 const ring=new THREE.Mesh(new THREE.RingGeometry(.26,.3,48),new THREE.MeshBasicMaterial({color:0x9AAEFF,transparent:true,opacity:.35,depthWrite:false,side:THREE.DoubleSide}));ring.rotation.x=-Math.PI/2;ring.position.y=.004;r.root.add(ring);
 const t0=performance.now();let glitch=0,next=1.2;
 const tick=(p)=>{const t=(performance.now()-t0)/1000;if(t>next){glitch=.12;next=t+1.4+Math.random()*2.2;}glitch=Math.max(0,glitch-1/60);
  const fl=.74+Math.sin(t*9)*.05+Math.sin(t*23)*.03-(glitch>0?.3:0);for(const m of mats){m.opacity=m.isSpriteMaterial?.8:fl;if(m.emissiveMap)m.emissiveMap.offset.y=-t*.6;}
  ring.material.opacity=.25+Math.sin(t*3)*.08;const q=Object.assign({},p);q.y=(p.y||0)+.03+Math.sin(t*1.6)*.012;if(glitch>0){q.x=(p.x||0)+(Math.random()-.5)*.04;}return q;};
 const set0=r.set.bind(r),play0=r.play?r.play.bind(r):null;r.set=p=>set0(tick(p));if(play0)r.play=(p,c)=>play0(tick(p),c);return r;}
