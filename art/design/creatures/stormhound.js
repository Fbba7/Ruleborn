import * as THREE from 'three';
import {makeSculpt,makeRigKit,stdClips,sstep,vnoise,clamp,ease,bump,blink,cyc,TAU,merge,gait} from './creature-kit.js';
import {parts} from './creature-parts.js';
// ============ STORMHOUND · Scout · Energy · lean fox-hound with a lightning mane, 0.9 m, orange and electric blue (GDD 11.4) ============
const COL={fur:0xC25A26,furL:0xE09456,furD:0x6A240C,saddle:0x9A3A12,cream:0xF7EBD6,creamD:0xCDB898,sock:0x2A2030,sockL:0x4A3E50,nose:0x1A1218,blue:0x3CC8FF,blueD:0x1A6AD0,inner:0xF4B8A0};
const K=Object.fromEntries(Object.entries(COL).map(([k,v])=>[k,new THREE.Color(v)]));
const mir=(p,s)=>[p[0]*s,p[1],p[2]];let A0=null;
const def={name:'stormhound',box:[[-.22,0,-.36],[.22,1,.32]],res:.0056,warm:0x3A1606,aoWarm:.22,sheen:0xFFD8B0,rim:0xA8E4FF,
 bodyMat:{roughness:.7,sheen:.5,sheenRoughness:.4},fur:{len:.0095,dens:[1500,1100,1500],shells:7,strand:[0,-1,-.45]},
 sculpt(A){const{E,C}=A;A0=A;const HK=1.25,HP=[0,.58,.05],hp=p=>p.map((v,i)=>HP[i]+(v-HP[i])*HK);const HE=(n,p,s,r,b,o)=>E(n,hp(p),s.map(v=>v*HK),r,b*HK,o),HC=(n,a,b,r1,r2,k)=>C(n,hp(a),hp(b),r1*HK,r2*HK,k*HK);
  // lean upright hound: deep chest, tucked waist, long neck, long narrow muzzle
  E('T:hips',[0,.3,-.035],[.092,.09,.088],null,.06);E('T:waist',[0,.37,0],[.07,.06,.065],null,.05);E('T:chest',[0,.46,.035],[.098,.085,.088],null,.06);
  E('T:ruff',[0,.52,.065],[.08,.065,.06],null,.05);C('T:neck',[0,.5,.03],[0,.6,.06],.058,.052,.04);
  HE('T:head',[0,.655,.04],[.122,.1,.11],null,.05);HE('T:brow',[0,.69,.1],[.085,.03,.045],[-.2,0,0],.028);
  HC('T:snout',[0,.64,.1],[0,.607,.215],.05,.028,.03);HE('T:nose',[0,.615,.222],[.024,.018,.016],[-.2,0,0],.008);HE('T:jaw',[0,.59,.14],[.048,.024,.062],[-.15,0,0],.02);
  
  for(const s of[-1,1]){const L=s<0?'L':'R';
   HE('T:cheek'+L,mir([.085,.615,.05],s),[.055,.05,.05],null,.035);
   // tall pointed ears
   HC('ear'+L+':ear1',mir([.06,.72,.02],s),mir([.1,.81,0],s),.036,.02,.02);HC('ear'+L+':ear2',mir([.1,.81,0],s),mir([.122,.865,-.015],s),.02,.004,.008);
   HE('ear'+L+':cup',mir([.086,.78,.022],s),[.022,.045,.006],[-.1,0,s*-.35],.004,'s');
   const sh=mir([.085,.47,.035],s),el=mir([.11,.37,.055],s),wr=mir([.118,.28,.085],s);C('sh'+L+':arm1',sh,el,.028,.022,.022);C('el'+L+':arm2',el,wr,.022,.018,.014);
   E('ha'+L+':paw',mir([.12,.255,.095],s),[.024,.022,.026],null,.012);
   // digitigrade legs: thigh forward, shin back to the hock, long foot to the paw
   C('th'+L+':thigh',mir([.058,.28,-.03],s),mir([.066,.18,.03],s),.047,.032,.032);C('kn'+L+':shin',mir([.066,.18,.03],s),mir([.07,.075,-.045],s),.023,.017,.015);
   C('ft'+L+':foot',mir([.07,.075,-.045],s),mir([.072,.02,.02],s),.019,.017,.012);E('ft'+L+':paw',mir([.072,.016,.035],s),[.026,.016,.034],null,.01);}
  // big brush of a tail curving up behind
  C('tail:t1',[0,.28,-.1],[0,.34,-.2],.036,.05,.03);C('tail:t2',[0,.34,-.2],[0,.46,-.26],.05,.055,.03);C('tail:t3',[0,.46,-.26],[0,.58,-.25],.055,.03,.03);},
 disp(x,y,z,d){if(Math.abs(d)>.03)return d;const fl=sstep(.02,.004,A0.minD(/^T:(ruff|cheek)|^tail:/,x,y,z));
  return d+fl*(vnoise(x*70,y*40,z*70)-.5)*.004+(vnoise(x*120,y*120,z*120)-.5)*.0006;},
 paint(x,y,z,nx,ny,nz,ao,c,A){
  c.copy(K.fur).lerp(K.furL,sstep(.2,.95,ny)*.22+sstep(.3,.9,nz)*.1).lerp(K.saddle,sstep(-.1,-.7,nz)*sstep(.25,.6,y)*.55).lerp(K.furD,(1-ao)*.5+sstep(-.2,-.8,ny)*.22);
  {const st=vnoise(x*420,y*46,z*420);c.lerp(st>.5?K.furL:K.furD,Math.abs(st-.5)*.34);}
  // cream muzzle, throat, chest and belly blaze
  const mz=sstep(.02,-.004,A.minD(/^T:(jaw|cheek)/,x,y,z))*sstep(.662,.61,y)+sstep(.01,0,A.dist('T:snout',x,y,z))*sstep(.642,.611,y);
  const blaze=sstep(.05,-.01,Math.abs(x)-.035+(.5-y)*.1)*sstep(-.1,.5,nz)*sstep(.25,.33,y)*sstep(.6,.55,y);
  const ruff=sstep(.02,.004,A.dist('T:ruff',x,y,z))*sstep(0,.6,nz);
  c.lerp(K.cream,clamp(mz+blaze+ruff*.9,0,1));c.lerp(K.creamD,clamp(mz+blaze,0,1)*(1-ao)*.4);
  // white brow spots, dark socks, dark ear backs, cream ear cups
  c.lerp(K.cream,sstep(.014,0,Math.hypot(Math.abs(x)-.044,y-.736,z-.144))*.9);
  const sk=A.minD(/^(kn|ft|el|ha)[LR]:/,x,y,z);if(sk<.004){const k=A.minD(/^(ft|ha)[LR]:paw/,x,y,z)<.004?1:A.minD(/^ft[LR]:/,x,y,z)<.004?sstep(.06,.03,y):0;c.lerp(K.sock,clamp(k,0,1)*.85);c.lerp(K.sockL,clamp(k,0,1)*sstep(.3,.9,ny)*.3);}
  if(A.minD(/^ear[LR]:/,x,y,z)<.004){c.lerp(K.sock,sstep(.855,.918,y)*.9);if(nz>.2)c.lerp(K.inner,sstep(.02,0,A.minD(/^ear[LR]:cup/,x,y,z)+.002)*.8);}
  // electric-blue tail tip
  if(A.minD(/^tail:/,x,y,z)<.006)c.lerp(K.cream,sstep(.535,.555,y)*.85).lerp(K.blueD,sstep(.575,.6,y)*.85);
  if(A.dist('T:nose',x,y,z)<.003)c.copy(K.nose);
  const bare=A.dist('T:nose',x,y,z)<.004||A.minD(/^(ft|ha)[LR]:paw/,x,y,z)<.002&&ny<-.3;return bare?0:clamp(.55+sstep(.004,-.004,A.minD(/^T:(ruff|cheek)|^tail:/,x,y,z))*.45,0,1);},
 accessories(A){const G=new THREE.Group();const P=parts(A,G);const{PB,add,onSurf,irisTex,eye}=P;
  const tex=irisTex('#04101E','#1A8AE8','#8AE8FF','#082A4A',{pup:.3});
  for(const s of[-1,1])eye(s,{r:.045,ctr:[0,.685,.035],dir:[.72,.14,1],off:-.013,tex,lid:COL.furD,lidCut:.2,yaw:.5,irisK:1.35,tilt:-.08});
  // lightning mane: zigzag bolts from the crown down the back of the neck
  const bolt=(h,w)=>{const s=new THREE.Shape();s.moveTo(0,h);s.lineTo(w*.55,h*.38);s.lineTo(w*.12,h*.42);s.lineTo(w*.4,0);s.lineTo(-w*.45,h*.55);s.lineTo(-w*.05,h*.52);s.closePath();return new THREE.ExtrudeGeometry(s,{depth:.02,bevelEnabled:true,bevelSize:.003,bevelThickness:.003,bevelSegments:1});};
  const bm=PB(0x0A7AF0,{emissive:0x0A5AD8,emissiveIntensity:1.1,roughness:.3,clearcoat:1}),bmC=PB(0xC8F2FF,{emissive:0x5AD0FF,emissiveIntensity:2});
  const M=[['head',[0,.774,.025],.15,.075,-.1],['head',[0,.755,-.05],.15,.08,-.55],['chest',[0,.63,-.055],.095,.055,-1],['chest',[0,.56,-.06],.085,.05,-1.25],['chest',[0,.5,-.055],.07,.045,-1.5]];
  M.forEach(([b,p,h,w,rx],k)=>{const g=new THREE.Group();g.userData.bone=b;g.position.set(...p);g.rotation.set(rx,Math.PI/2,0);G.add(g);add(bolt(h,w),bm,[-.006,0,0],[0,-Math.PI/2,0],null,g);const c=add(bolt(h*.55,w*.5),bmC,[-.0065,h*.2,.004],[0,-Math.PI/2,0],null,g);c.castShadow=false;});
  const pl=new THREE.PointLight(0x5AC8FF,.6,.6,2);pl.position.set(0,.64,-.08);pl.userData.bone='chest';G.add(pl);
  // Scout gear: copper collar with a bolt tag, leather scout bracer
  const copper=PB(0xC8703A,{metalness:1,roughness:.32}),lea=PB(0x5A3420,{roughness:.75});
  const col=new THREE.TorusGeometry(.058,.009,10,32);const cm=add(col,copper,[0,.55,.055],[1.35,0,0],[1.12,1.05,1],G,'chest');
  {const g=new THREE.Group();g.userData.bone='chest';g.position.set(0,.51,.115);g.rotation.set(-.25,0,0);G.add(g);add(new THREE.CylinderGeometry(.02,.02,.006,20),copper,null,[Math.PI/2,0,0],null,g);
   const s=new THREE.Shape();s.moveTo(.004,.012);s.lineTo(-.006,-.001);s.lineTo(.001,-.001);s.lineTo(-.003,-.012);s.lineTo(.007,.002);s.lineTo(0,.002);s.closePath();add(new THREE.ExtrudeGeometry(s,{depth:.002,bevelEnabled:false}),PB(0xFFF0C8,{emissive:0x7ADCFF,emissiveIntensity:1.2}),[0,0,.003],null,null,g);}
  for(const s of[-1,1]){const b=add(new THREE.CylinderGeometry(.024,.022,.045,16,1,true),lea,mir([.114,.31,.074],s),[.35,0,s*.25],null,G,s<0?'elL':'elR');b.material.side=THREE.DoubleSide;}
  // sprint (ability): blue spark afterimages trailing behind
  const fx=new THREE.Group();fx.userData.bone='root';fx.userData.fx='split';fx.userData.fxMode='show';fx.position.set(0,.4,-.2);G.add(fx);
  const sp=PB(0xC8F4FF,{emissive:0x5AC8FF,emissiveIntensity:3,transparent:true,opacity:.85});
  for(let k=0;k<16;k++){const m=add(new THREE.BoxGeometry(.006,.006,.08+(k%3)*.05),sp,[(k%4-1.5)*.07,(Math.floor(k/4)-1.5)*.12,-(k%3)*.08],null,null,fx);m.castShadow=false;}
  return G;}};
export const S=makeSculpt(def);
const J={root:[null,[0,0,0]],hips:['root',[0,.3,-.03]],chest:['hips',[0,.45,.03]],head:['chest',[0,.58,.06]],earL:['head',[-.075,.755,.0125]],earR:['head',[.075,.755,.0125]],
 shL:['chest',[-.085,.47,.035]],elL:['shL',[-.11,.37,.055]],haL:['elL',[-.118,.28,.085]],shR:['chest',[.085,.47,.035]],elR:['shR',[.11,.37,.055]],haR:['elR',[.118,.28,.085]],
 thL:['hips',[-.058,.28,-.03]],knL:['thL',[-.066,.18,.03]],ftL:['knL',[-.07,.075,-.045]],thR:['hips',[.058,.28,-.03]],knR:['thR',[.066,.18,.03]],ftR:['knR',[.07,.075,-.045]],tail:['hips',[0,.28,-.1]]};
const cfg={name:'stormhound',J,TIP:{haL:[-.12,.235,.1],haR:[.12,.235,.1],ftL:[-.072,.004,.06],ftR:[.072,.004,.06]},
 TORSO:{hips:[[0,.22,-.04],[0,.4,0],.11],chest:[[0,.4,.02],[0,.58,.05],.1],head:[[0,.555,.05],[0,.78,.14],.17]},
 AIM:[],floor:.004,pivot:.3,shMin:-1.8,springs:[['earL','vx',-.35,190,10,0,.25],['earR','vx',-.35,190,10,0,.25],['tail','vy',-.5,110,7,0,.55]]};
const RK=makeRigKit(S,cfg);export const makeRig=RK.makeRig,skinGeo=RK.skinGeo;
export const CLIPS=stdClips({w:.1,arm:.5,x:{
 idle:{label:'Idle',len:3,f:t=>{const u=cyc(t,3);const b=Math.sin(u*TAU)*.5+.5;const perk=bump(u,.5,.75);const wag=Math.sin(t*9);return{sq:b*.012,hx:-.05-perk*.1,hy:Math.sin(u*TAU)*.25,hz:perk*.12,elx:-.1+perk*.25,eye:blink(t,3,.7),b:{chest:[-b*.03,0,0],shL:[-.05,0,-.05],shR:[-.05,0,.05],elL:[-.3,0,0],elR:[-.3,0,0],tail:[0,wag*.35,0]}};}},
 idle2:{label:'Idle 2',len:3.4,f:t=>{const u=cyc(t,3.4);const bounce=Math.abs(Math.sin(u*TAU*3))*bump(u,.1,.7);return{y:bounce*.03,sq:bounce*.03,hy:.4*Math.sin(u*TAU*2)*bump(u,.1,.7),hx:-.1,eye:1+bounce*.1,b:{shL:[-.6*bounce,0,-.1],shR:[-.6*bounce,0,.1],elL:[-.5,0,0],elR:[-.5,0,0],tail:[0,Math.sin(t*14)*.5,0]}};}},
 ability:{label:'Sprint',len:1.8,f:t=>{const u=cyc(t,1.8);const cr=bump(u,0,.25),go=sstep(.2,.35,u)*(1-sstep(.85,1,u));const ph=cyc(t,.32);return{z:-.1+sstep(.2,.9,u)*.35,y:go*.03*Math.abs(Math.sin(ph*TAU)),rx:.1*cr+.42*go,sq:-cr*.08,hx:-.2*go+.15*cr,eye:.8,split:go,
  b:merge(gait(ph,{leg:.95*go,knee:1.4*go,arm:.9*go,elb:1.2,lean:.08,twist:.1,toe:.5}),{thL:[-.8*cr,0,0],knL:[1.1*cr,0,0],thR:[-.8*cr,0,0],knR:[1.1*cr,0,0],tail:[-.6*go,0,0]})};}},
 work:{label:'Chases its sparks',len:3,f:t=>{const u=cyc(t,3);const a=u*TAU;return{x:Math.sin(a)*.1,z:Math.cos(a)*.1-.1,ry:a+Math.PI/2,rz:-.12,hy:-.5,hx:-.1,y:Math.abs(Math.sin(a*4))*.02,eye:blink(t,3,1),split:bump(u,.4,.6)*.5,b:merge(gait(cyc(t,.42),{leg:.6,knee:1,arm:.6}),{tail:[0,.9,0]})};}},
 nap:{label:'Nap',len:4,f:t=>{const b=Math.sin(t*TAU/4)*.5+.5;return{y:-.09,sq:-.04+b*.03,rx:.3,hx:.5,hz:.25,elx:.5,eye:.04,b:{thL:[-1.5,0,-.3],knL:[2.1,0,0],thR:[-1.5,0,.3],knR:[2.1,0,0],shL:[-.9,0,.3],elL:[-.6,0,0],shR:[-.9,0,-.3],elR:[-.6,0,0],chest:[.35+b*.04,0,0],tail:[.4,1.2,0]}};}}}});
export const EXPR={
 happy:{label:'Eager',hz:-.14,hx:-.08,elx:-.2,eye:1.08,b:{shL:[-.5,0,-.2],shR:[-.3,0,.2],elL:[-.8,0,0],elR:[-.6,0,0],tail:[0,.5,0]}},
 focus:{label:'On the scent',hx:.18,elx:-.5,eye:.66,eyeW:1.04,b:{chest:[.12,0,0],shL:[-.4,0,-.1],shR:[-.4,0,.1],elL:[-.9,0,0],elR:[-.9,0,0]}},
 startled:{label:'Startled',hx:-.18,elx:.35,eye:1.24,eyeW:1.1,b:{shL:[-.3,0,-.8],shR:[-.3,0,.8],tail:[-.6,0,0]}},
 caught:{label:'Caught',hx:.35,hz:.12,elx:.8,eye:.5,b:{chest:[.25,0,0],shL:[.1,0,.15],shR:[.1,0,-.15],tail:[.5,0,0]}}};
export const build=o=>S.build(o),loadBaked=(u,r)=>S.loadBaked(u,r);
export const BIN='stormhound.bin?v=1',RES=.0056,GAME_SCALE=1.05;
export const EMBERS=[['earL',[-.15,.936,-.031]],['earR',[.15,.936,-.031]],['tail',[0,.58,-.25]]];
export const ROUTE=[{to:[1.3,-.4],clip:'run',sp:.55},{at:true,clip:'work',dur:6,face:[2,1]},{to:[-.8,1],clip:'ability',sp:.6},{at:true,clip:'idle',dur:3,face:[1,3]},{to:[.2,.2],clip:'walk',sp:.28},{at:true,clip:'nap',dur:4,face:[2,2]}];
export const HERO={cam:[1.5,.85,1.95],target:[0,.44,0],clip:'idle'};
