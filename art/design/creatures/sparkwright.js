import * as THREE from 'three';
import {makeSculpt,makeRigKit,stdClips,sstep,vnoise,clamp,ease,bump,blink,cyc,TAU,merge,gait} from './creature-kit.js';
import {parts} from './creature-parts.js';
// ============ SPARKWRIGHT · Mender · Energy · little tinker with a coil backpack, 0.8 m, orange and copper (GDD 11.4) ============
const COL={fur:0xB04C2C,furL:0xD8804E,furD:0x5A1E10,saddle:0x8A3218,dark:0x3A1E1A,darkL:0x5A342A,cream:0xF8EEDC,creamD:0xD2BEA0,nose:0x201416,ring:0x8A3418,pad:0x3A2624};
const K=Object.fromEntries(Object.entries(COL).map(([k,v])=>[k,new THREE.Color(v)]));
const mir=(p,s)=>[p[0]*s,p[1],p[2]];let A0=null;
const def={name:'sparkwright',box:[[-.26,0,-.34],[.26,.76,.26]],res:.0052,warm:0x3A1408,aoWarm:.22,sheen:0xFFD8B8,rim:0xFFC89A,
 bodyMat:{roughness:.72,sheen:.5,sheenRoughness:.45},fur:{len:.0095,dens:[1400,1050,1400],shells:7,strand:[0,-1,-.4]},
 sculpt(A){const{E,C}=A;A0=A;
  // round head, soft pear body: a red-panda cub of a tinker
  E('T:hips',[0,.19,-.02],[.1,.095,.09],null,.06);E('T:belly',[0,.25,.03],[.094,.088,.08],null,.06);E('T:chest',[0,.33,.02],[.082,.066,.07],null,.05);
  E('T:head',[0,.53,.025],[.158,.138,.138],null,.06);E('T:crown',[0,.6,.0],[.12,.06,.1],null,.05);
  for(const s of[-1,1])E('T:cheek'+(s<0?'L':'R'),mir([.1,.485,.07],s),[.07,.062,.062],null,.04);
  E('T:muzzle',[0,.475,.13],[.062,.044,.05],null,.035);E('T:nose',[0,.492,.176],[.022,.016,.014],[-.15,0,0],.008);E('T:chin',[0,.44,.12],[.036,.022,.03],null,.02);
  E('T:mouthcut',[0,.455,.168],[.02,.0025,.012],[.15,0,0],.003,'s');
  for(const s of[-1,1]){const L=s<0?'L':'R';
   // round, tufted ears
   E('ear'+L+':ear',mir([.118,.655,-.005],s),[.052,.056,.026],[0,0,s*-.35],.02);E('ear'+L+':cup',mir([.122,.66,.018],s),[.034,.036,.01],[0,0,s*-.35],.008,'s');
   const sh=mir([.078,.33,.02],s),el=mir([.108,.26,.05],s),wr=mir([.118,.195,.075],s);C('sh'+L+':arm1',sh,el,.03,.026,.024);C('el'+L+':arm2',el,wr,.026,.022,.016);
   E('ha'+L+':paw',mir([.12,.175,.085],s),[.028,.026,.028],null,.014);for(let k=0;k<3;k++)E('ha'+L+':f'+k,mir([.112+k*.01,.158,.105],s),[.009,.009,.01],null,.005);
   E('th'+L+':haunch',mir([.058,.15,-.01],s),[.05,.055,.05],null,.035);C('kn'+L+':shin',mir([.062,.11,.005],s),mir([.064,.035,.02],s),.032,.027,.02);
   E('ft'+L+':foot',mir([.064,.02,.04],s),[.034,.02,.05],null,.014);}
  // big ringed tail swept up behind
  C('tail:t1',[0,.16,-.08],[0,.18,-.2],.045,.058,.03);C('tail:t2',[0,.18,-.2],[.05,.27,-.3],.058,.056,.03);C('tail:t3',[.05,.27,-.3],[.09,.36,-.31],.056,.032,.03);},
 disp(x,y,z,d){if(Math.abs(d)>.03)return d;const fl=sstep(.02,.004,A0.minD(/^T:cheek|^tail:/,x,y,z));
  return d+fl*(vnoise(x*70,y*50,z*70)-.5)*.004+(vnoise(x*120,y*120,z*120)-.5)*.0006;},
 paint(x,y,z,nx,ny,nz,ao,c,A){
  c.copy(K.fur).lerp(K.furL,sstep(.2,.95,ny)*.22+sstep(.3,.9,nz)*.1).lerp(K.saddle,sstep(-.1,-.7,nz)*.45).lerp(K.furD,(1-ao)*.5+sstep(-.2,-.8,ny)*.2);
  {const st=vnoise(x*420,y*46,z*420);c.lerp(st>.5?K.furL:K.furD,Math.abs(st-.5)*.34);}
  // dark legs, arms and belly, red-panda style
  const lim=A.minD(/^(sh|el|ha|th|kn|ft)[LR]:/,x,y,z);if(lim<.016)c.lerp(K.dark,(A.minD(/^sh[LR]:/,x,y,z)<.006?sstep(.31,.25,y)*.9:.94)*sstep(.016,.003,lim));
  c.lerp(K.dark,sstep(.02,.004,A.dist('T:belly',x,y,z))*sstep(.3,.8,nz)*sstep(.3,.22,y)*.75);c.lerp(K.darkL,sstep(.3,.9,ny)*(lim<.012?.25:0));
  // white mask: cheeks, muzzle, brow spots, ear rims
  const mask=sstep(.018,-.004,A.minD(/^T:(cheek|muzzle|chin)/,x,y,z))*sstep(.06,.12,z-Math.abs(x)*.3+.05);
  c.lerp(K.cream,clamp(mask,0,1));c.lerp(K.creamD,clamp(mask,0,1)*(1-ao)*.35);
  c.lerp(K.cream,sstep(.018,0,Math.hypot(Math.abs(x)-.052,y-.585,z-.13))*.95);
  if(A.minD(/^ear[LR]:/,x,y,z)<.005){const cup=sstep(.004,-.002,A.minD(/^ear[LR]:cup/,x,y,z));c.lerp(K.cream,cup>.5?.9:sstep(.006,.0,A.minD(/^ear[LR]:ear/,x,y,z)+.004)*.6);}
  // dark tear marks under the eyes
  c.lerp(K.furD,sstep(.012,0,Math.hypot((Math.abs(x)-.06)*1.3,y-.49,z-.14))*.5);
  // tail rings
  if(A.minD(/^tail:/,x,y,z)<.006){const u=(y*9-z*6);c.lerp(K.dark,sstep(.3,.45,Math.abs((u%1+1)%1-.5))*.85);}
  if(A.dist('T:nose',x,y,z)<.003)c.copy(K.nose);if(Math.abs(A.dist('T:mouthcut',x,y,z))<.0025&&z>.16)c.lerp(K.nose,.55);
  if(A.minD(/^ha[LR]:f|^ft[LR]:/,x,y,z)<.002&&ny<-.4)c.copy(K.pad);
  return A.dist('T:nose',x,y,z)<.004?0:clamp(.6+sstep(.004,-.004,A.minD(/^T:cheek|^tail:/,x,y,z))*.4,0,1);},
 accessories(A){const G=new THREE.Group();const P=parts(A,G);const{PB,add,onSurf,irisTex,eye,hit}=P;
  const tex=irisTex('#0A0402','#5A2A10','#C8782E','#1A0A04',{pup:.32});
  for(const s of[-1,1])eye(s,{r:.046,ctr:[0,.535,.025],dir:[.5,.08,1],off:-.016,tex,lid:COL.furD,lidCut:.22,yaw:.38,irisK:1.3});
  const copper=PB(0xC8703A,{metalness:1,roughness:.28}),copperD=PB(0x7A3A18,{metalness:1,roughness:.45}),brass=PB(0xD8A84A,{metalness:1,roughness:.3});
  const lea=PB(0x4A2A1A,{roughness:.78}),glass=PB(0xDFF6FF,{roughness:.04,transmission:.92,thickness:.01,ior:1.45,transparent:true,opacity:.35,clearcoat:1});
  // goggles: thick copper rims over both eyes, clear lenses, a leather strap round the head
  for(const s of[-1,1]){const g=new THREE.Group();onSurf(g,[s*.5,.08,1],[0,.535,.025],.018,'head');add(new THREE.TorusGeometry(.056,.011,12,32),copper,null,null,null,g);add(new THREE.TorusGeometry(.049,.004,8,32),copperD,[0,0,.006],null,null,g);
   const l=add(new THREE.CircleGeometry(.05,28),glass,[0,0,.004],null,null,g);l.castShadow=false;for(let k=0;k<4;k++)add(new THREE.SphereGeometry(.0045,8,6),brass,[Math.cos(k*1.57+.78)*.056,Math.sin(k*1.57+.78)*.056,.008],null,null,g);}
  {const b=add(new THREE.CylinderGeometry(.011,.011,.03,10),copper,[0,.545,.155],[0,0,Math.PI/2],null,G,'head');}
  const strap=add(new THREE.TorusGeometry(.146,.009,8,48,Math.PI*1.3),lea,[0,.54,.0],[Math.PI/2,0,-Math.PI*.15-.07],[1.08,.98,1],G,'head');strap.rotation.set(Math.PI/2,0,Math.PI*.35);
  // the coil backpack: copper tank, a Tesla coil and a crackling bulb
  const pk=new THREE.Group();pk.userData.bone='chest';pk.position.set(.075,.42,-.14);pk.rotation.set(-.12,0,-.5);pk.scale.setScalar(1.5);G.add(pk);
  add(new THREE.CylinderGeometry(.055,.06,.13,20),copper,[0,0,0],null,null,pk);add(new THREE.CylinderGeometry(.062,.062,.012,20),copperD,[0,-.06,0],null,null,pk);add(new THREE.CylinderGeometry(.058,.058,.01,20),copperD,[0,.06,0],null,null,pk);
  for(let k=0;k<3;k++)add(new THREE.TorusGeometry(.057,.003,6,24),brass,[0,-.03+k*.03,0],[Math.PI/2,0,0],null,pk);
  const hx=new THREE.Curve();hx.getPoint=(t,o=new THREE.Vector3())=>o.set(Math.cos(t*TAU*6)*.02,.07+t*.1,Math.sin(t*TAU*6)*.02);add(new THREE.TubeGeometry(hx,160,.0032,6),copper,null,null,null,pk);
  add(new THREE.CylinderGeometry(.006,.006,.11,8),copperD,[0,.12,0],null,null,pk);
  const bulb=add(new THREE.SphereGeometry(.03,20,14),PB(0xE8FAFF,{emissive:0x6ADCFF,emissiveIntensity:2.2,roughness:.1}),[0,.2,0],null,null,pk);bulb.castShadow=false;
  add(new THREE.TorusGeometry(.034,.004,6,24),brass,[0,.185,0],[Math.PI/2,0,0],null,pk);
  const pl=new THREE.PointLight(0x7ADCFF,.8,.8,2);pl.position.set(0,.2,0);pk.add(pl);
  for(const k of[0,1,2]){const s=new THREE.Shape();s.moveTo(0,0);s.lineTo(.012,.018);s.lineTo(.005,.02);s.lineTo(.02,.042);s.lineTo(-.002,.016);s.lineTo(.006,.015);s.closePath();const m=add(new THREE.ShapeGeometry(s),PB(0xFFFFFF,{emissive:0x9AE8FF,emissiveIntensity:2.5,side:THREE.DoubleSide}),[Math.cos(k*2.1)*.03,.205,Math.sin(k*2.1)*.03],[0,k*2.1,.5],[1.1,1.1,1],pk);m.castShadow=false;}
  // wire running from the tank to the left glove, and pack straps
  for(const s of[-1,1]){const st=new THREE.Mesh(new THREE.TorusGeometry(.07,.007,6,24,Math.PI*1.05),lea);st.position.set(s*.05,.33,-.03);st.rotation.set(0,Math.PI/2,-.35);st.userData.bone='chest';st.castShadow=true;G.add(st);}
  // Mender tool belt with a wrench, Energy bolt on the buckle
  add(new THREE.TorusGeometry(.098,.012,8,40),lea,[0,.225,.01],[Math.PI/2+.1,0,0],[1,1.02,1],G,'hips');
  {const g=new THREE.Group();g.userData.bone='hips';g.position.set(0,.23,.108);g.rotation.set(-.15,0,0);G.add(g);add(new THREE.BoxGeometry(.036,.03,.008),brass,null,null,null,g);
   const s=new THREE.Shape();s.moveTo(.004,.011);s.lineTo(-.005,-.001);s.lineTo(.001,-.001);s.lineTo(-.003,-.011);s.lineTo(.006,.002);s.lineTo(0,.002);s.closePath();add(new THREE.ExtrudeGeometry(s,{depth:.002,bevelEnabled:false}),PB(0xFFE8B0,{emissive:0xFF9A3C,emissiveIntensity:1.2}),[0,0,.004],null,null,g);}
  {const g=new THREE.Group();g.userData.bone='hips';g.position.set(.09,.2,.05);g.rotation.set(.1,.5,.2);G.add(g);const st=PB(0xA8A8B8,{metalness:1,roughness:.3});add(new THREE.BoxGeometry(.008,.07,.004),st,null,null,null,g);add(new THREE.TorusGeometry(.012,.004,6,16,Math.PI*1.6),st,[0,.04,0],[0,0,-.3],null,g);}
  // zap (ability): blue arcs leaping from the coil
  const fx=new THREE.Group();fx.userData.bone='chest';fx.userData.fx='split';fx.userData.fxMode='show';fx.position.set(.2,.66,-.14);G.add(fx);
  const zm=PB(0xFFFFFF,{emissive:0x7ADCFF,emissiveIntensity:3,side:THREE.DoubleSide});
  for(let k=0;k<6;k++){const pts=[];let p=new THREE.Vector3();const a=k/6*TAU;for(let i=0;i<7;i++){pts.push(p.clone());p.add(new THREE.Vector3(Math.cos(a)*.03+(Math.random()-.5)*.03,.02+(Math.random()-.3)*.02,Math.sin(a)*.03+(Math.random()-.5)*.03));}const m=add(new THREE.TubeGeometry(new THREE.CatmullRomCurve3(pts),24,.003,4),zm,null,null,null,fx);m.castShadow=false;}
  return G;}};
export const S=makeSculpt(def);
const J={root:[null,[0,0,0]],hips:['root',[0,.18,-.02]],chest:['hips',[0,.32,.02]],head:['chest',[0,.41,.03]],earL:['head',[-.118,.655,-.005]],earR:['head',[.118,.655,-.005]],
 shL:['chest',[-.078,.33,.02]],elL:['shL',[-.108,.26,.05]],haL:['elL',[-.118,.195,.075]],shR:['chest',[.078,.33,.02]],elR:['shR',[.108,.26,.05]],haR:['elR',[.118,.195,.075]],
 thL:['hips',[-.058,.15,-.01]],knL:['thL',[-.062,.11,.005]],ftL:['knL',[-.064,.035,.02]],thR:['hips',[.058,.15,-.01]],knR:['thR',[.062,.11,.005]],ftR:['knR',[.064,.035,.02]],tail:['hips',[0,.16,-.08]]};
const cfg={name:'sparkwright',J,TIP:{haL:[-.12,.15,.1],haR:[.12,.15,.1],ftL:[-.064,.004,.09],ftR:[.064,.004,.09]},
 TORSO:{hips:[[0,.1,-.02],[0,.28,.02],.12],chest:[[0,.27,.02],[0,.38,.02],.1],head:[[0,.37,.03],[0,.68,.03],.18]},
 AIM:[],floor:.004,pivot:.18,shMin:-1.9,springs:[['earL','vx',-.3,190,10,0,.2],['earR','vx',-.3,190,10,0,.2],['tail','vy',-.4,110,8,0,.5]]};
const RK=makeRigKit(S,cfg);export const makeRig=RK.makeRig,skinGeo=RK.skinGeo;
export const CLIPS=stdClips({w:.2,arm:.45,x:{
 idle:{label:'Idle',len:3.2,f:t=>{const u=cyc(t,3.2);const b=Math.sin(u*TAU)*.5+.5;const talk=Math.sin(t*10)*bump(u,.2,.7);return{sq:b*.014,hx:-.04+talk*.03,hz:Math.sin(u*TAU)*.12,hy:Math.sin(u*TAU*.5)*.15,eye:blink(t,3.2,.5),b:{chest:[-b*.03,0,0],shL:[-.35+talk*.5,0,-.2-talk*.2],shR:[-.1,0,.08],elL:[-.9+talk*.3,0,0],elR:[-.3,0,0],tail:[0,Math.sin(t*2)*.2,0]}};}},
 idle2:{label:'Idle 2',len:4,f:t=>{const u=cyc(t,4);const adj=bump(u,.15,.55),nod=bump(u,.6,.85);return{hx:-.12*adj+.15*nod,hz:.1*adj,eye:1-nod*.3,b:{shL:[-2.2*adj,0,-.3],shR:[-2.2*adj,0,.3],elL:[-1.4*adj,0,0],elR:[-1.4*adj,0,0],haL:[-.3*adj,0,0],haR:[-.3*adj,0,0]}};}},
 ability:{label:'Zap',len:2.2,f:t=>{const u=cyc(t,2.2);const wind=bump(u,0,.35),zap=bump(u,.35,.75),jolt=bump(u,.38,.55);return{y:jolt*.03,sq:jolt*.05-wind*.04,x:Math.sin(u*160)*.008*jolt,rx:-.1*zap,hx:-.2*zap,eye:1+zap*.25,eyeW:1+zap*.1,split:zap,
  b:{shR:[-2.4*zap-.6*wind,0,.3],elR:[-.3*zap-.8*wind,0,0],shL:[-.4*wind,0,-.6*zap],elL:[-1*wind,0,0],chest:[-.15*zap,.3*wind,0],tail:[-.5*zap,0,0]}};}},
 work:{label:'Rewires the lantern',len:5,f:t=>{const u=cyc(t,5);const fid=Math.sin(t*16)*.12*(1-bump(u,.45,.6)),shock=bump(u,.45,.58),fix=bump(u,.7,.95);return{y:shock*.05,sq:-shock*.06,hx:.3-shock*.4,hz:fix*.12,eye:1+shock*.3-fix*.35,split:shock,
  b:{chest:[.2-shock*.3,0,0],shL:[-1+fid,0,.2],shR:[-1-fid,0,-.2],elL:[-1.2,0,0],elR:[-1.2,0,0],haL:[.2,0,0],haR:[.2,0,0],tail:[-.6*shock,0,0]}};}},
 nap:{label:'Nap',len:4,f:t=>{const b=Math.sin(t*TAU/4)*.5+.5;return{y:-.06,sq:-.06+b*.03,rx:.1,hx:.45,hz:.22,eye:.04,b:{thL:[-1.5,0,-.35],knL:[2,0,0],thR:[-1.5,0,.35],knR:[2,0,0],shL:[-.8,0,.35],elL:[-1.1,0,0],shR:[-.8,0,-.35],elR:[-1.1,0,0],chest:[.3+b*.04,0,0],tail:[.5,1.4,0]}};}}}});
export const EXPR={
 happy:{label:'Chatty',hz:-.14,hx:-.06,eye:1.06,b:{shL:[-1.2,0,-.3],shR:[-.3,0,.2],elL:[-1.2,0,0],elR:[-.4,0,0]}},
 focus:{label:'Tinkering',hx:.22,eye:.68,eyeW:1.03,b:{chest:[.12,0,0],shL:[-.9,0,.2],shR:[-.9,0,-.2],elL:[-1.3,0,0],elR:[-1.3,0,0]}},
 startled:{label:'Zapped',hx:-.2,eye:1.25,eyeW:1.1,b:{shL:[-.3,0,-1],shR:[-.3,0,1],tail:[-.6,0,0]}},
 caught:{label:'Caught',hx:.35,hz:.12,eye:.5,b:{chest:[.25,0,0],shL:[.1,0,.15],shR:[.1,0,-.15]}}};
export const build=o=>S.build(o),loadBaked=(u,r)=>S.loadBaked(u,r);
export const BIN='sparkwright.bin?v=1',RES=.0052,GAME_SCALE=1.12;
export const EMBERS=[['earL',[-.14,.68,-.005]],['earR',[.14,.68,-.005]],['chest',[0,.55,-.12]]];
export const ROUTE=[{to:[1.1,-.4],clip:'walk',sp:.24},{at:true,clip:'work',dur:5,face:[2,-1]},{to:[-.8,1],clip:'walk',sp:.24},{at:true,clip:'ability',dur:2.2,face:[1,3]},{at:true,clip:'idle',dur:3.2,face:[1,3]},{to:[.2,.2],clip:'carry',sp:.22},{at:true,clip:'nap',dur:4,face:[2,2]}];
export const HERO={cam:[1.35,.72,1.72],target:[0,.38,0],clip:'idle'};
