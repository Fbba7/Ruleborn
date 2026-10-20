import * as THREE from 'three';
import {makeSculpt,makeRigKit,stdClips,sstep,vnoise,clamp,ease,bump,blink,cyc,TAU,merge,gait} from './creature-kit.js';
import {parts,hourglass} from './creature-parts.js';
// ============ TIDEWALKER · Carrier · Time · otter-like wader with a shell pack, 0.8 m, cyan and sand (GDD 11.4) ============
const COL={fur:0x9C6A3E,furL:0xC08A56,furD:0x4E3018,cream:0xF2E4C4,creamD:0xC8B08A,nose:0x2A1A16,paw:0x5A3C24,cyan:0x2FB8CC,cyanL:0x9BEAF3,inner:0xF0C8A8};
const K=Object.fromEntries(Object.entries(COL).map(([k,v])=>[k,new THREE.Color(v)]));
const mir=(p,s)=>[p[0]*s,p[1],p[2]];let A0=null;
const def={name:'tidewalker',box:[[-.26,0,-.62],[.26,.76,.28]],res:.0058,warm:0x3A2210,aoWarm:.2,sheen:0xFFE8C8,rim:0xBFEFFF,
 bodyMat:{roughness:.72,sheen:.45,sheenRoughness:.45},fur:{len:.008,dens:[1200,900,1200],shells:5},
 sculpt(A){const{E,C}=A;A0=A;
  // long, soft body that widens to the hips; small round head with a broad whiskered muzzle
  E('T:hips',[0,.22,-.04],[.14,.135,.145],null,.07);E('T:belly',[0,.32,.02],[.128,.14,.12],null,.07);E('T:chest',[0,.44,.03],[.11,.09,.09],null,.06);
  C('T:neck',[0,.46,.03],[0,.55,.05],.088,.09,.05);E('T:head',[0,.61,.045],[.135,.104,.112],null,.05);E('T:crown',[0,.655,.03],[.108,.045,.09],null,.04);
  E('T:muzzle',[0,.568,.148],[.084,.054,.062],null,.035);E('T:chin',[0,.532,.135],[.046,.03,.036],null,.025);E('T:nose',[0,.592,.202],[.032,.02,.017],[-.25,0,0],.012);
  E('T:mouth',[0,.547,.188],[.03,.004,.02],[.1,0,0],.004,'s');
  for(const s of[-1,1]){const L=s<0?'L':'R';
   E('T:whisk'+L,mir([.044,.568,.176],s),[.048,.038,.032],null,.02);E('T:sock'+L,mir([.066,.62,.138],s),[.024,.02,.018],null,.01,'s');
   E('ear'+L+':ear',mir([.1,.675,.02],s),[.03,.026,.016],[0,0,s*.3],.02);E('T:earcut'+L,mir([.1,.675,.032],s),[.017,.014,.006],[0,0,s*.3],.006,'s');
   const sh=mir([.1,.46,.06],s),el=mir([.138,.37,.1],s),wr=mir([.15,.29,.12],s);C('sh'+L+':arm1',sh,el,.042,.036,.04);C('el'+L+':arm2',el,wr,.036,.03,.025);
   E('ha'+L+':paw',mir([.153,.264,.13],s),[.032,.026,.032],null,.018);for(let k=0;k<4;k++){const o=(k-1.5)*.014;E('ha'+L+':toe'+k,mir([.153+o,.248,.155],s),[.009,.008,.01],null,.006);}
   E('th'+L+':haunch',mir([.09,.19,-.03],s),[.075,.085,.088],null,.05);C('kn'+L+':shin',mir([.1,.13,.0],s),mir([.105,.05,.02],s),.05,.04,.035);
   E('ft'+L+':foot',mir([.106,.018,.075],s),[.052,.018,.098],null,.018);for(let k=0;k<4;k++){const o=(k-1.5)*.024;E('ft'+L+':toe'+k,mir([.106+o,.016,.162],s),[.013,.012,.016],null,.008);}}
  C('tail:t1',[0,.2,-.15],[0,.12,-.3],.08,.06,.05);C('tail:t2',[0,.12,-.3],[0,.05,-.45],.06,.036,.04);C('tail:t3',[0,.05,-.45],[0,.025,-.57],.036,.012,.03);},
 disp(x,y,z,d){const st=vnoise(x*160,y*26,z*160);return d+(vnoise(x*60,y*60,z*60)-.5)*.0012+(st-.5)*.0009;},
 paint(x,y,z,nx,ny,nz,ao,c,A){
  const belly=sstep(.1,.75,nz)*sstep(.13,.03,Math.abs(x))*sstep(.5,.34,y)*sstep(.14,.22,y);
  const face=sstep(.02,.0,A.minD(/^T:(muzzle|whisk|chin)/,x,y,z))*sstep(.6,.575,y+Math.abs(x)*.25)+sstep(.03,.0,A.minD(/^T:(chin|neck)/,x,y,z))*sstep(.1,.5,nz)*sstep(.1,.05,Math.abs(x))*.8;
  c.copy(K.fur).lerp(K.furL,sstep(-.2,.9,ny)*.25).lerp(K.furD,sstep(.1,-.8,nz)*.35+(1-ao)*.4+sstep(.62,.72,vnoise(x*150,y*24,z*150))*.22).offsetHSL(0,0,(vnoise(x*14,y*14,z*14)-.5)*.06);
  c.lerp(K.furD,sstep(.63,.7,y)*sstep(.06,0,Math.abs(x))*sstep(.0,.5,nz)*.2);
  c.lerp(K.cream,clamp(belly+face,0,1)*.88);c.lerp(K.creamD,clamp(belly+face,0,1)*(1-ao)*.3);
  const pw=A.minD(/^(ha|ft)[LR]:/,x,y,z);if(pw<.004)c.lerp(K.paw,.8);
  c.lerp(K.nose,sstep(.004,-.001,A.dist('T:nose',x,y,z)));
  const er=A.minD(/^ear[LR]:/,x,y,z);if(er<.004)c.lerp(K.inner,sstep(.2,.8,nz)*.55);
  // Time cyan: two rings near the tail tip and a band at each wrist
  const tt=A.minD(/^tail:t3/,x,y,z);if(tt<.004){const u=(-z-.44)/.035;c.lerp(K.cyan,sstep(.3,.1,Math.abs(u-Math.round(u)))*.9*(u>0?1:0));}
  const wr=A.minD(/^el[LR]:arm2/,x,y,z);if(wr<.004&&y<.31)c.lerp(K.cyan,.85);
  return 0;},
 accessories(A){const G=new THREE.Group();const P=parts(A,G);const{PB,add,onSurf,irisTex,eye}=P;
  const tex=irisTex('#060302','#2A1A10','#6A4424','#140A06',{pup:.42});
  for(const s of[-1,1])eye(s,{r:.027,ctr:[0,.618,.045],dir:[.6,.0,1],off:-.001,tex,lid:COL.furD,lidCut:.32,yaw:.46,irisK:1.3});
  // whiskers
  const wm=PB(0xF6EEDC,{roughness:.4});for(const s of[-1,1])for(let k=0;k<3;k++){const w=new THREE.Mesh(new THREE.CylinderGeometry(.0009,.0005,.1,4),wm);w.position.set(s*(.06+.012*k),.566-.008*k,.18);w.rotation.set(.1*k,0,s*(Math.PI/2-.12+.14*k));w.translateY(s*.045);w.userData.bone='head';G.add(w);}
  // the shell pack: a cyan spiral conch strapped to the back
  const pack=new THREE.Group();pack.userData.bone='chest';pack.position.set(.02,.4,-.17);pack.rotation.set(.15,Math.PI/2,-.1);pack.scale.setScalar(1.45);G.add(pack);
  const shA=PB(COL.cyan,{roughness:.28,clearcoat:.8,clearcoatRoughness:.2,sheen:.3}),shB=PB(0xE8D6B0,{roughness:.35,clearcoat:.6}),lip=PB(COL.inner,{roughness:.3,clearcoat:.8});
  for(let i=0;i<30;i++){const t=i/29;const a=t*TAU*1.55,r=.018+t*.075,rad=.014+t*.058;const sp=new THREE.SphereGeometry(rad,22,16);const col=new THREE.Color(0xE8D6B0).lerp(new THREE.Color(COL.cyan),sstep(.05,.7,t)).lerp(new THREE.Color(0x1F7E90),sstep(.7,1,t)*.35);const m=PB(col.getHex(),{roughness:.3,clearcoat:.8,clearcoatRoughness:.2});add(sp,m,[Math.cos(a)*r,Math.sin(a)*r,-t*.02],null,[1,1,.74],pack);}
  add(new THREE.TorusGeometry(.06,.014,10,26),lip,[Math.cos(TAU*1.55)*.093,Math.sin(TAU*1.55)*.093,-.02],[0,Math.PI/2.4,0],[1,1.2,1],pack);
  const lea=PB(0x5A3A24,{roughness:.8}),brass=PB(0xC8963E,{metalness:1,roughness:.3});
  for(const s of[-1,1]){const st=new THREE.Mesh(new THREE.TorusGeometry(.105,.009,6,26,Math.PI*1.05),lea);st.position.set(s*.06,.43,-.01);st.rotation.set(0,Math.PI/2,-.35);st.userData.bone='chest';st.castShadow=true;G.add(st);}
  {const b=new THREE.Group();onSurf(b,[0,0,1],[0,.43,.0],.004,'chest');add(new THREE.CylinderGeometry(.03,.03,.008,20),brass,null,[Math.PI/2,0,0],null,b);const hg=hourglass(P,.036,COL.cyanL);hg.position.z=.008;b.add(hg);}
  // wade ripples (ability)
  const fx=new THREE.Group();fx.userData.bone='root';fx.userData.fx='ripple';fx.userData.fxMode='show';fx.position.set(0,.01,0);G.add(fx);
  for(let k=0;k<3;k++){const rg=P.ring(0xBFF4FF,.14+k*.08,.155+k*.08);rg.rotation.x=-Math.PI/2;fx.add(rg);}
  return G;}};
export const S=makeSculpt(def);
const J={root:[null,[0,0,0]],hips:['root',[0,.24,-.03]],chest:['hips',[0,.42,.02]],head:['chest',[0,.54,.05]],earL:['head',[-.1,.675,.02]],earR:['head',[.1,.675,.02]],
 shL:['chest',[-.1,.46,.06]],elL:['shL',[-.138,.37,.1]],haL:['elL',[-.15,.29,.12]],shR:['chest',[.1,.46,.06]],elR:['shR',[.138,.37,.1]],haR:['elR',[.15,.29,.12]],
 thL:['hips',[-.09,.2,-.03]],knL:['thL',[-.1,.13,0]],ftL:['knL',[-.105,.05,.02]],thR:['hips',[.09,.2,-.03]],knR:['thR',[.1,.13,0]],ftR:['knR',[.105,.05,.02]],tail:['hips',[0,.2,-.15]]};
const cfg={name:'tidewalker',J,TIP:{haL:[-.154,.245,.15],haR:[.154,.245,.15],ftL:[-.106,.005,.17],ftR:[.106,.005,.17]},
 TORSO:{hips:[[0,.08,-.08],[0,.3,-.02],.17],chest:[[0,.3,0],[0,.5,.03],.14],head:[[0,.5,.05],[0,.72,.08],.16]},
 AIM:[],floor:.006,pivot:.24,shMin:-1.6,springs:[['tail','vy',-.35,110,8,0,.35],['earL','vy',-.3,160,10,0,.2],['earR','vy',-.3,150,10,0,.2]]};
const RK=makeRigKit(S,cfg);export const makeRig=RK.makeRig,skinGeo=RK.skinGeo;
export const CLIPS=stdClips({w:.35,arm:.35,x:{
 idle:{label:'Idle',len:5,f:t=>{const b=Math.sin(t*TAU/5)*.5+.5;const groom=bump(t%10,6,8.5);const rub=Math.sin(t*14)*groom;return{sq:b*.012,hx:.05+groom*.25,hz:Math.sin(t*.4)*.05,eye:blink(t,5,.5)*(1-groom*.5),b:{chest:[-b*.03+groom*.15,0,0],shL:[-1.5*groom+Math.sin(t*1.1)*.03,0,.2*groom-.04],shR:[-1.5*groom,0,-.2*groom+.04],elL:[-1.3*groom-.2+rub*.2,0,0],elR:[-1.3*groom-.2-rub*.2,0,0],tail:[.05,Math.sin(t*.6)*.25,0]}};}},
 ability:{label:'Stride',len:1.8,f:t=>{const ph=cyc(t,.9);const u=cyc(t,1.8);const s=Math.sin(ph*TAU);return{y:Math.abs(Math.cos(ph*TAU))*.02,rx:.08,hx:-.06,hz:s*.04,eye:.9,ripple:.5+.5*Math.sin(u*TAU),b:merge(gait(ph,{leg:.62,knee:1.1,arm:.25,twist:.08}),{tail:[.35,s*.3,0],chest:[-.05,0,0]})};}},
 wade:{label:'Wade',len:2.4,f:t=>{const ph=cyc(t,2.4);const s=Math.sin(ph*TAU);return{y:-.08,rx:.05,rz:s*.05,hx:-.08,eye:.85,ripple:.4,b:merge(gait(ph,{leg:.35,knee:.9,arm:0,twist:.04}),{shL:[-.2,0,-.3],shR:[-.2,0,.3],elL:[-.5,0,0],elR:[-.5,0,0],tail:[.4,s*.2,0]})};}},
 nap:{label:'Floats on its back',len:5,f:t=>{const b=Math.sin(t*TAU/5)*.5+.5;return{y:.13+b*.012,rx:-1.45,rz:Math.sin(t*.5)*.08,hx:-.25,eye:.08,ripple:.3,b:{shL:[-1.6,0,.55],elL:[-1.1,0,0],shR:[-1.6,0,-.55],elR:[-1.1,0,0],thL:[-.9,0,-.2],knL:[.7,0,0],thR:[-.9,0,.2],knR:[.7,0,0],tail:[-.6,Math.sin(t*.7)*.3,0],chest:[b*.03,0,0]}};}},
 work:{label:'Washes a pebble',len:2.4,f:t=>{const rub=Math.sin(t*TAU/.4);const u=cyc(t,2.4);const look=bump(u,.7,.95);return{y:-.04,rx:.12,hx:.22-look*.3,eye:.9+look*.2,b:{chest:[.2,0,0],hips:[.08,0,0],shL:[-1.05+rub*.08,0,.25],shR:[-1.05-rub*.08,0,-.25],elL:[-1.2+rub*.15,0,0],elR:[-1.2-rub*.15,0,0],thL:[-.6,0,-.1],knL:[1,0,0],thR:[-.6,0,.1],knR:[1,0,0],tail:[.15,Math.sin(t)*.2,0]}};}}}});
export const EXPR={
 calm:{label:'Unbothered',hx:.05,hz:.08,eye:.72,b:{shL:[-.3,0,.2],shR:[-.3,0,-.2],elL:[-1,0,0],elR:[-1,0,0]}},
 focus:{label:'Focused',hx:.12,eye:.6,eyeW:1.04,b:{chest:[.1,0,0],shL:[-.5,0,-.2],shR:[-.5,0,.2],elL:[-.7,0,0],elR:[-.7,0,0]}},
 startled:{label:'Startled',hx:-.15,eye:1.2,eyeW:1.08,b:{shL:[-.4,0,-.7],shR:[-.4,0,.7],elL:[-.4,0,0],elR:[-.4,0,0],tail:[.6,0,0]}},
 caught:{label:'Caught',hx:.35,hz:.1,eye:.5,b:{shL:[.1,0,.12],shR:[.1,0,-.12],chest:[.22,0,0],tail:[-.3,0,0]}}};
export const build=o=>S.build(o),loadBaked=(u,r)=>S.loadBaked(u,r);
export const BIN='tidewalker.bin?v=1',RES=.0058,GAME_SCALE=1.12;
export const EMBERS=[['earL',[-.1,.71,.02]],['earR',[.1,.71,.02]],['tail',[0,.05,-.56]]];
export const ROUTE=[{to:[1.2,-.4],clip:'walk',sp:.22},{at:true,clip:'work',dur:4.8,face:[2,-1]},{to:[-.8,1],clip:'ability',sp:.3},{at:true,clip:'idle',dur:4,face:[1,3]},{to:[.2,.2],clip:'carry',sp:.22},{at:true,clip:'nap',dur:5,face:[2,2]}];
export const HERO={cam:[1.45,.78,1.6],target:[0,.36,-.04],clip:'idle'};
