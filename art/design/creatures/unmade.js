import * as THREE from 'three';
import {makeSculpt,makeRigKit,stdClips,sstep,vnoise,clamp,ease,bump,blink,cyc,TAU,merge,gait} from './creature-kit.js';
import {parts} from './creature-parts.js';
// ============ THE UNMADE · Legendary paradox-born · from Unmaking · a colourless paper figure with torn edges (GDD 11.8, 21.6) ============
// A paper-doll cut-out: flat parts pinned at the joints, torn edges, a folded dog-ear, ink-drawn eyes. No colour anywhere.
const COL={paper:0xEDEAE2,paperL:0xFBFAF6,paperD:0x9A968C,fibre:0xFFFFFF,ink:0x26262C,inkL:0x55555E,pencil:0x8A8A90,pin:0x3A3A40};
const K=Object.fromEntries(Object.entries(COL).map(([k,v])=>[k,new THREE.Color(v)]));
const mir=(p,s)=>[p[0]*s,p[1],p[2]];let A0=null;
const T=.013;// half thickness of the card
const def={name:'unmade',box:[[-.28,0,-.12],[.28,.84,.12]],res:.0044,warm:0x101014,aoWarm:.05,sheen:0xFFFFFF,rim:0xFFFFFF,
 bodyMat:{roughness:.92,sheen:.35,sheenRoughness:.8},fur:{shells:0},
 sculpt(A){const{E,C}=A;A0=A;
  // flat cut-out parts at slightly different angles, like a pinned paper doll
  E('head:disc',[0,.62,.0],[.15,.145,T],[.0,.0,.04],.012);
  E('T:cloak',[0,.34,-.004],[.13,.17,T],null,.02);E('T:hem',[0,.21,-.004],[.155,.06,T],null,.03);
  E('T:collar',[0,.47,.004],[.07,.03,T],null,.02);
  for(const s of[-1,1]){const L=s<0?'L':'R';
   E('sh'+L+':arm1',mir([.155,.4,.008],s),[.026,.075,T*.7],[0,0,s*.55],.012);E('el'+L+':arm2',mir([.2,.29,.012],s),[.022,.065,T*.65],[0,0,s*.25],.012);
   E('ha'+L+':hand',mir([.215,.215,.014],s),[.03,.034,T*.8],null,.01);
   E('th'+L+':leg1',mir([.055,.15,.006],s),[.03,.07,T*.85],[0,0,s*.08],.012);E('kn'+L+':leg2',mir([.062,.06,.008],s),[.027,.055,T*.8],null,.012);
   E('ft'+L+':foot',mir([.07,.016,.03],s),[.036,.013,.045],null,.01);}
  E('tail:scrap',[0,.2,-.02],[.01,.01,.01],null,.005);
  // torn edges: small bites taken out of every outline (deterministic, so the silhouette is always the same)
  let sd=1;const rnd=()=>{sd=(sd*9301+49297)%233280;return sd/233280;};
  const bite=(pre,cx,cy,rx,ry,n,a0=0,a1=TAU,z=0)=>{for(let k=0;k<n;k++){const a=a0+(a1-a0)*(k+rnd()*.6)/n;const r=.006+rnd()*.011;E(pre+':cut'+k,[cx+Math.cos(a)*rx,cy+Math.sin(a)*ry,z],[r,r*(.6+rnd()*.8),.03],[0,0,rnd()*3],.003,'s');}};
  bite('head',0,.62,.152,.147,16,0,TAU);bite('T',-.12,.16,.03,.012,3,Math.PI*.9,Math.PI*1.4);bite('T',.12,.16,.03,.012,3,Math.PI*1.6,Math.PI*2.1);
  for(const s of[-1,1]){bite('T',s*.15,.3,.012,.08,3,s<0?Math.PI*.6:-Math.PI*.4,s<0?Math.PI*1.4:Math.PI*.4);}},
 disp(x,y,z,d){if(Math.abs(d)>.03)return d;
  // torn edges: where the card is thin (its rim), the outline is jagged and fibrous; faces stay flat
  
  const crease=sstep(.004,0,Math.abs(x+.02))*sstep(.46,.44,y)*sstep(.18,.22,y);
  return d+crease*.0012;},
 paint(x,y,z,nx,ny,nz,ao,c,A){
  const flat=Math.abs(nz);c.copy(K.paper).lerp(K.paperL,flat*.35).lerp(K.paperD,(1-ao)*.35+(1-flat)*.12);
  // paper fibres and a faint pencil hatch on the cloak
  c.lerp(K.paperD,Math.pow(vnoise(x*160,y*160,z*40),4)*.2);
  const cloak=A.minD(/^T:(cloak|hem)/,x,y,z)<.003;if(cloak&&nz>.5){const h=Math.sin((x+y)*260)*.5+.5;c.lerp(K.pencil,sstep(.9,.97,h)*sstep(.5,.75,vnoise(x*10,y*10,1))*.35);}
  // torn rim shows lighter fibre
  if(flat<.45)c.lerp(K.fibre,.55);
  // ink outline drawn a little inside the edge of every part
  const face=nz>.6;
  // a vertical fold down the cloak
  if(Math.abs(x+.02)<.0035&&y>.18&&y<.46)c.lerp(K.paperD,.55);
  // ink face on the head disc: a small line smile and a squiggle nose
  if(face&&A.dist('head:disc',x,y,z)<.004){if(Math.abs(x)<.03){const u=x/.03,cy=.565-.009*(1-u*u);const dd=Math.abs(y-cy),w=.0024;if(dd<w)c.copy(K.ink);}
   const rr=Math.hypot(x-.0,y-.6);if(rr<.004)c.lerp(K.inkL,.6);
   for(const s of[-1,1])c.lerp(K.pencil,sstep(.022,.0,Math.hypot(x-s*.085,y-.575))*.3);}
  // buttons drawn on the cloak
  if(face&&cloak)for(const by of[.4,.33,.26]){const r=Math.hypot(x-.03,y-by);if(r<.011&&r>.007)c.copy(K.ink);}
  // the sole of the feet slightly grubby
  if(A.minD(/^ft[LR]:/,x,y,z)<.003&&ny<-.5)c.lerp(K.paperD,.5);
  return 0;},
 accessories(A){const G=new THREE.Group();const P=parts(A,G);const{PB,add,glowTex}=P;
  const ink=PB(COL.ink,{roughness:.9});const paper=PB(COL.paper,{roughness:.92,side:THREE.DoubleSide});
  // ink-drawn eyes on paper decals: they squash to blink with the rig
  const ec=document.createElement('canvas');ec.width=ec.height=256;{const x=ec.getContext('2d');x.clearRect(0,0,256,256);x.lineCap='round';
   x.fillStyle='#26262C';x.beginPath();x.ellipse(128,132,84,98,0,0,TAU);x.fill();x.fillStyle='#F7F5EF';x.beginPath();x.ellipse(96,92,26,30,-.3,0,TAU);x.fill();x.beginPath();x.arc(160,178,11,0,TAU);x.fill();
   x.strokeStyle='#26262C';x.lineWidth=9;x.beginPath();x.ellipse(128,132,106,120,0,.2,TAU-.4);x.stroke();}
  const et=new THREE.CanvasTexture(ec);et.colorSpace=THREE.SRGBColorSpace;const em=new THREE.MeshBasicMaterial({map:et,transparent:true,depthWrite:false,polygonOffset:true,polygonOffsetFactor:-2});
  for(const s of[-1,1]){const e=new THREE.Group();e.name=s<0?'eye_L':'eye_R';e.userData.bone='head';e.position.set(s*.052,.64,T+.0035);G.add(e);add(new THREE.PlaneGeometry(.058,.066),em,null,null,null,e).castShadow=false;
   // pencil brow
   add(new THREE.PlaneGeometry(.04,.005),new THREE.MeshBasicMaterial({color:COL.pencil,polygonOffset:true,polygonOffsetFactor:-2}),[s*.004,.048,0],[0,0,-s*.2],null,e).castShadow=false;}
  // dog-ear: the top-right corner of the head folded down, showing its back
  {const g=new THREE.Group();g.userData.bone='head';g.position.set(.085,.735,T+.002);g.rotation.set(0,0,-.72);G.add(g);const sh=new THREE.Shape();sh.moveTo(-.035,0);sh.lineTo(.035,0);sh.lineTo(0,-.034);sh.closePath();
   add(new THREE.ShapeGeometry(sh),PB(0xD8D4CA,{roughness:.95,side:THREE.DoubleSide}),null,null,null,g);}
  // brass-less split pins at every joint, drawn in graphite
  const pinM=PB(COL.pin,{metalness:.7,roughness:.35});for(const [b,p] of[['shL',[-.135,.435,.023]],['shR',[.135,.435,.023]],['thL',[-.05,.205,.021]],['thR',[.05,.205,.021]]]){const g=new THREE.Group();g.userData.bone=b;G.add(g);
   add(new THREE.CylinderGeometry(.009,.009,.004,16),pinM,p,[Math.PI/2,0,0],null,g);}
  // loose scraps that hang in the air beside it
  const scr=(w,h,seed)=>{const sh=new THREE.Shape();const n=9;for(let k=0;k<n;k++){const a=k/n*TAU;const r=1+(vnoise(k*2.3,seed,1)-.5)*.6;const X=Math.cos(a)*w*r,Y=Math.sin(a)*h*r;k?sh.lineTo(X,Y):sh.moveTo(X,Y);}sh.closePath();return new THREE.ShapeGeometry(sh);};
  for(const [p,r,sd] of[[[-.24,.62,.02],.4,1],[[.25,.5,-.02],-.6,2],[[.2,.7,.03],.9,3]]){const g=new THREE.Group();g.userData.bone='chest';g.position.set(...p);g.userData.spin=[1.1+sd*.3,.35];g.userData.spinAx='y';G.add(g);add(scr(.022,.016,sd),paper,null,[0,0,r],null,g);}
  // unmaking (ability): law runes around it tear in half and fall away
  const fx=new THREE.Group();fx.userData.bone='root';fx.userData.fx='split';fx.userData.fxMode='show';fx.position.set(0,.4,0);fx.userData.spin=1.5;fx.userData.spinAx='y';G.add(fx);
  const rc=document.createElement('canvas');rc.width=rc.height=128;{const x=rc.getContext('2d');x.strokeStyle='#26262C';x.lineWidth=7;x.lineCap='round';x.beginPath();x.arc(64,64,44,0,TAU);x.stroke();x.beginPath();x.moveTo(64,28);x.lineTo(64,100);x.moveTo(36,52);x.lineTo(92,76);x.stroke();x.strokeStyle='#F7F5EF';x.lineWidth=10;x.beginPath();x.moveTo(20,20);x.lineTo(60,64);x.lineTo(44,80);x.lineTo(108,108);x.stroke();}
  const rt=new THREE.CanvasTexture(rc);const rm=new THREE.MeshBasicMaterial({map:rt,transparent:true,side:THREE.DoubleSide,depthWrite:false});
  for(let k=0;k<5;k++){const a=k/5*TAU;const m=add(new THREE.PlaneGeometry(.1,.1),rm,[Math.sin(a)*.34,(k%2)*.1,Math.cos(a)*.34],[0,a,0],null,fx);m.castShadow=false;}
  return G;}};
export const S=makeSculpt(def);
const J={root:[null,[0,0,0]],hips:['root',[0,.21,0]],chest:['hips',[0,.34,0]],head:['chest',[0,.49,0]],earL:['head',[-.06,.72,0]],earR:['head',[.06,.72,0]],
 shL:['chest',[-.13,.44,0]],elL:['shL',[-.185,.335,.01]],haL:['elL',[-.21,.235,.014]],shR:['chest',[.13,.44,0]],elR:['shR',[.185,.335,.01]],haR:['elR',[.21,.235,.014]],
 thL:['hips',[-.05,.21,0]],knL:['thL',[-.06,.1,.008]],ftL:['knL',[-.066,.03,.01]],thR:['hips',[.05,.21,0]],knR:['thR',[.06,.1,.008]],ftR:['knR',[.066,.03,.01]],tail:['hips',[0,.2,-.02]]};
const cfg={name:'unmade',J,TIP:{haL:[-.22,.18,.014],haR:[.22,.18,.014],ftL:[-.07,.003,.07],ftR:[.07,.003,.07]},
 TORSO:{hips:[[0,.14,0],[0,.26,0],.14],chest:[[0,.26,0],[0,.48,0],.12],head:[[0,.5,0],[0,.76,0],.15]},
 AIM:[],floor:.003,pivot:.21,shMin:-2.4,springs:[]};
const RK=makeRigKit(S,cfg);export const makeRig=RK.makeRig,skinGeo=RK.skinGeo;
// laws do not touch it, so it moves in stiff, paper-puppet beats: small stutters and flat, hinged swings
const stut=(t,k=1)=>Math.round(Math.sin(t*9)*2)/2*.03*k;
export const CLIPS=stdClips({w:.5,arm:.55,x:{
 idle:{label:'Idle',len:4,f:t=>{const u=cyc(t,4);const b=Math.sin(u*TAU)*.5+.5;const flut=Math.sin(t*2.3);return{sq:b*.01,rz:flut*.03+stut(t,.5),ry:Math.sin(t*.7)*.15,hz:Math.sin(u*TAU)*.08,eye:blink(t,4,.5),b:{chest:[0,0,flut*.03],shL:[0,0,.3+b*.06],shR:[0,0,-.3-b*.06],elL:[0,0,.2],elR:[0,0,-.2]}};}},
 idle2:{label:'Idle 2',len:4.6,f:t=>{const u=cyc(t,4.6);const turn=ease(sstep(.1,.35,u))*(1-ease(sstep(.6,.85,u)));return{ry:turn*Math.PI*.5,hz:-.1*turn,eye:blink(t,2.3,.2),b:{shL:[0,0,.3+.9*turn],shR:[0,0,-.3],elL:[0,0,.5*turn]}};}},
 ability:{label:'Unmaking',len:2.6,f:t=>{const u=cyc(t,2.6);const on=sstep(.08,.25,u)*(1-sstep(.82,.96,u));const tear=bump(u,.25,.7);return{y:on*.05,rz:stut(t*3,on*2),sq:tear*.04,hx:-.15*on,split:on,eye:1-tear*.3,b:{shL:[0,0,1.6*on],shR:[0,0,-1.6*on],elL:[0,0,.4*on],elR:[0,0,-.4*on],thL:[0,0,.2*on],thR:[0,0,-.2*on]}};}},
 work:{label:'Folds itself flat',len:4.4,f:t=>{const u=cyc(t,4.4);const fold=ease(sstep(.1,.4,u))*(1-ease(sstep(.6,.9,u)));return{y:-fold*.1,sq:-fold*.35,rx:fold*.2,eye:1-fold*.6,b:{chest:[fold*.4,0,0],shL:[0,0,-.2*fold],shR:[0,0,.2*fold],thL:[-1.2*fold,0,0],knL:[1.5*fold,0,0],thR:[-1.2*fold,0,0],knR:[1.5*fold,0,0]}};}},
 nap:{label:'Nap',len:5,f:t=>{const b=Math.sin(t*TAU/5)*.5+.5;return{y:-.06,sq:-.06+b*.02,rx:.15,hx:.35,hz:.25,eye:.05,b:{thL:[-1.5,0,-.2],knL:[1.4,0,0],thR:[-1.5,0,.2],knR:[1.4,0,0],shL:[-.4,0,.2],elL:[-1.2,0,0],shR:[-.4,0,-.2],elR:[-1.2,0,0],chest:[.3+b*.03,0,0]}};}}}});
{const NEG=['shL','shR','elL','elR','thL','thR'];const fix=q=>{if(q&&q.b){q.b=Object.assign({},q.b);for(const k of NEG)if(q.b[k])q.b[k]=[q.b[k][0],q.b[k][1],-q.b[k][2]];}return q;};for(const k of['idle','idle2','ability','work']){const f0=CLIPS[k].f;CLIPS[k]={...CLIPS[k],f:t=>fix(f0(t))};}globalThis.__unfix=fix;}
export const EXPR={
 happy:{label:'Content',hz:-.12,eye:.85,b:{shL:[0,0,.6],shR:[0,0,-.6]}},
 focus:{label:'Blank',eye:.6,hx:.05,b:{shL:[0,0,.15],shR:[0,0,-.15]}},
 startled:{label:'Crumpled',hx:-.12,eye:1.2,eyeW:1.1,sq:-.06,b:{shL:[0,0,1.2],shR:[0,0,-1.2]}},
 caught:{label:'Torn',hx:.3,hz:.2,eye:.55,b:{chest:[.2,0,.1],shL:[.2,0,.1],shR:[.2,0,-.1]}}};
for(const k in EXPR)EXPR[k]=globalThis.__unfix(EXPR[k]);
export const build=o=>S.build(o),loadBaked=(u,r)=>S.loadBaked(u,r);
export const BIN='unmade.bin?v=1',RES=.0044,GAME_SCALE=1.1;
export const EMBERS=[['head',[-.1,.74,0]],['head',[.1,.74,0]],['hands',[0,.8,0]]].filter(e=>e[0]!=='hands');
export const ROUTE=[{to:[1.1,-.4],clip:'walk',sp:.22},{at:true,clip:'work',dur:4.4,face:[2,-1]},{to:[-.7,1],clip:'walk',sp:.24},{at:true,clip:'ability',dur:2.6,face:[1,3]},{at:true,clip:'idle',dur:4,face:[1,3]},{to:[.2,.2],clip:'run',sp:.32},{at:true,clip:'nap',dur:5,face:[2,2]}];
export const HERO={cam:[.9,.6,2.05],target:[0,.42,0],clip:'idle'};
