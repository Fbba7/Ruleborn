import * as THREE from 'three';
import {makeSculpt,makeRigKit,stdClips,sstep,vnoise,clamp,ease,bump,blink,cyc,TAU,merge,gait} from './creature-kit.js';
import {parts} from './creature-parts.js';
// ============ EMBERLING · Breaker · Energy · flame-headed imp, 0.7 m, orange and charcoal (GDD 11.4) ============
const COL={coal:0x2E2428,coalL:0x5A4A4C,coalD:0x120C10,ash:0x8A7C78,glow:0xFF7A1C,glowH:0xFFD27A,belly:0xFF9A3C,cheek:0xFF6A3C,mouth:0x3A0A08};
const K=Object.fromEntries(Object.entries(COL).map(([k,v])=>[k,new THREE.Color(v)]));
const mir=(p,s)=>[p[0]*s,p[1],p[2]];let A0=null;
// cooling-ember crack lines: thin ridges of a warped noise field
const crack=(x,y,z,f)=>{const w=vnoise(x*f*.35+3,y*f*.35,z*f*.35)*.9;const n=vnoise(x*f+w,y*f-w,z*f+w*.5);return sstep(.028,.0,Math.abs(n-.5));};
const def={name:'emberling',box:[[-.24,0,-.2],[.24,.62,.22]],res:.0046,warm:0x3A0C04,aoWarm:.28,sheen:0xFFB070,rim:0xFF9A50,
 bodyMat:{roughness:.62,sheen:.2,sheenRoughness:.5,clearcoat:.25,clearcoatRoughness:.5},fur:{shells:0},vcGlow:1.6,
 sculpt(A){const{E,C}=A;A0=A;
  // a big round coal head over a tiny, pot-bellied body
  E('T:body',[0,.14,-.005],[.085,.09,.078],null,.05);E('T:belly',[0,.13,.03],[.07,.07,.06],null,.04);E('T:chest',[0,.205,.0],[.07,.05,.06],null,.04);
  E('T:head',[0,.37,.02],[.158,.138,.14],null,.06);E('T:crown',[0,.44,.0],[.128,.07,.11],null,.05);
  E('T:brow',[0,.405,.1],[.12,.035,.05],[-.2,0,0],.03);E('T:cheeks',[0,.325,.1],[.13,.06,.07],null,.04);E('T:chin',[0,.29,.1],[.06,.035,.045],null,.03);
  E('T:mouthcut',[0,.3,.155],[.05,.007,.02],[.12,0,0],.006,'s');
  for(const s of[-1,1]){const L=s<0?'L':'R';
   // little pointed imp ears, swept back
   C('ear'+L+':ear1',mir([.13,.4,.02],s),mir([.19,.44,-.03],s),.03,.012,.02);C('ear'+L+':ear2',mir([.19,.44,-.03],s),mir([.225,.465,-.06],s),.012,.004,.006);
   const sh=mir([.06,.2,.01],s),el=mir([.09,.155,.03],s),wr=mir([.098,.11,.05],s);C('sh'+L+':arm1',sh,el,.022,.018,.016);C('el'+L+':arm2',el,wr,.018,.017,.012);
   E('ha'+L+':fist',mir([.1,.09,.06],s),[.026,.026,.026],null,.012);C('ha'+L+':thumb',mir([.09,.1,.078],s),mir([.084,.094,.084],s),.009,.007,.006);
   E('th'+L+':haunch',mir([.045,.08,-.01],s),[.036,.04,.036],null,.03);C('kn'+L+':shin',mir([.048,.064,0],s),mir([.05,.028,.012],s),.024,.022,.016);
   E('ft'+L+':foot',mir([.05,.014,.03],s),[.028,.016,.04],null,.012);E('ft'+L+':toe',mir([.05,.012,.062],s),[.02,.012,.014],null,.008);}
  // whip tail with a spade
  C('tail:t1',[0,.11,-.07],[0,.08,-.14],.018,.012,.02);C('tail:t2',[0,.08,-.14],[0,.1,-.2],.012,.008,.012);E('tail:spade',[0,.11,-.215],[.02,.022,.008],[.4,0,0],.008);},
 disp(x,y,z,d){if(Math.abs(d)>.03)return d;const face=sstep(.02,.004,A0.minD(/^T:(cheeks|chin|brow|mouthcut)/,x,y,z))*sstep(.06,.12,z);
  return d-(1-face)*crack(x,y,z,24)*.0014+(vnoise(x*110,y*110,z*110)-.5)*.0009;},
 paint(x,y,z,nx,ny,nz,ao,c,A){
  const face=Math.max(sstep(.022,.004,A.minD(/^T:(cheeks|chin|brow)/,x,y,z))*sstep(.05,.12,z),sstep(.03,.004,A.dist('T:head',x,y,z))*sstep(.02,.1,z)*sstep(.46,.4,y));
  c.copy(K.coal).lerp(K.coalL,sstep(.2,.95,ny)*.35+face*.45).lerp(K.coalD,(1-ao)*.5+sstep(-.1,-.8,ny)*.25);
  // inner furnace glows through the belly and the chest
  const bel=sstep(.03,.0,A.minD(/^T:(belly|body)/,x,y,z))*sstep(.3,.8,nz)*sstep(.22,.1,y);c.lerp(K.belly,bel*.55);c.lerp(K.glowH,bel*sstep(.4,.9,nz)*sstep(.18,.12,y)*.35);
  // glowing cracks everywhere except the face
  const cr=crack(x,y,z,24)*(1-face*.9);c.lerp(K.glow,cr);c.lerp(K.glowH,cr*sstep(.3,.9,ao)*.35);
  // warm cheeks, ashy soles, glowing fists and ear tips
  c.lerp(K.cheek,sstep(.03,0,Math.hypot(Math.abs(x)-.085,y-.32,(z-.13)*1.5))*.6);
  if(A.minD(/^ft[LR]:/,x,y,z)<.003)c.lerp(K.ash,sstep(.2,-.7,ny)*.6);
  if(A.minD(/^ha[LR]:/,x,y,z)<.003)c.lerp(K.glow,sstep(.02,.1,z-.03)*.55);
  if(A.minD(/^ear[LR]:ear2|^tail:spade/,x,y,z)<.003)c.lerp(K.glow,.7);
  if(Math.abs(A.dist('T:mouthcut',x,y,z))<.005&&z>.12)c.copy(K.mouth);
  return 0;},
 accessories(A){const G=new THREE.Group();const P=parts(A,G);const{PB,add,onSurf,irisTex,eye}=P;
  // huge amber eyes with an ember pupil glint
  const tex=irisTex('#140402','#E0600C','#FFC25A','#2A0802',{pup:.34});
  for(const s of[-1,1])eye(s,{r:.056,ctr:[0,.37,.02],dir:[.52,.08,1],off:-.019,tex,lid:COL.coalD,lidCut:.26,yaw:.4,irisK:1.3});
  // the flame crown: layered tongues, hottest inside
  const flame=(h,r)=>{const p=[];for(let i=0;i<=16;i++){const t=i/16;p.push(new THREE.Vector2(Math.pow(Math.sin(Math.PI*t),.7)*r*(1-t*.55),t*h));}return new THREE.LatheGeometry(p,18);};
  const fOut=PB(0xFF3A08,{emissive:0xE0300A,emissiveIntensity:1.3,transparent:true,opacity:.92,roughness:.4,depthWrite:false});
  const fMid=PB(0xFF8A1C,{emissive:0xFF6A10,emissiveIntensity:1.8,transparent:true,opacity:.95,depthWrite:false});
  const fIn=PB(0xFFF0B0,{emissive:0xFFE08A,emissiveIntensity:2.4,depthWrite:false});
  const crown=new THREE.Group();crown.userData.bone='head';crown.position.set(0,.465,-.01);crown.scale.setScalar(1.45);G.add(crown);
  const T=[[0,0,-.02,.2,.07,0],[.055,-.012,-.01,.14,.05,-.35],[-.055,-.012,-.01,.14,.05,.35],[.02,-.01,.05,.11,.045,.2],[-.03,-.01,-.06,.13,.05,-.2]];
  T.forEach(([x,y,z,h,r,rz],k)=>{const g=new THREE.Group();g.position.set(x,y,z);g.rotation.set(-.15+(k>2?.2:0),0,rz);crown.add(g);add(flame(h,r),fOut,null,null,null,g);add(flame(h*.72,r*.66),fMid,[0,.005,.004],null,null,g);add(flame(h*.42,r*.36),fIn,[0,.008,.008],null,null,g);g.children.forEach(m=>m.castShadow=false);});
  for(const s of[-1,1]){const g=new THREE.Group();g.userData.bone=s<0?'earL':'earR';g.position.set(s*.225,.47,-.06);g.rotation.set(-.4,0,-s*.5);G.add(g);add(flame(.06,.018),fMid,null,null,null,g);add(flame(.035,.01),fIn,[0,.003,.002],null,null,g);}
  const pl=new THREE.PointLight(0xFF8A2C,.9,.7,2);pl.position.set(0,.08,0);crown.add(pl);
  // Breaker gear: a riveted iron knuckle band on each fist, Energy bolt on the brow
  const iron=PB(0x3A3440,{metalness:1,roughness:.42}),copper=PB(0xC8703A,{metalness:1,roughness:.32});
  for(const s of[-1,1]){const b=add(new THREE.TorusGeometry(.021,.0045,8,20),iron,mir([.1,.092,.062],s),[0,s*.4,0],[1,1,1.2]);b.userData.bone=s<0?'haL':'haR';for(let k=0;k<3;k++){const r=add(new THREE.SphereGeometry(.0038,8,6),copper,[Math.cos(k*2.1)*.021,Math.sin(k*2.1)*.021,0],null,null,b);r.castShadow=false;}}
  {const g=new THREE.Group();onSurf(g,[0,.62,1],[0,.37,.02],.002,'head');const sh=new THREE.Shape();sh.moveTo(.004,.014);sh.lineTo(-.007,-.001);sh.lineTo(.001,-.001);sh.lineTo(-.004,-.014);sh.lineTo(.008,.002);sh.lineTo(0,.002);sh.closePath();
   add(new THREE.ExtrudeGeometry(sh,{depth:.003,bevelEnabled:true,bevelSize:.0012,bevelThickness:.0012,bevelSegments:1}),PB(0xFFD27A,{emissive:0xFF9A2C,emissiveIntensity:1.4,metalness:.4}),null,null,null,g);}
  // burst (ability): a ring of sparks and a flash shell
  const fx=new THREE.Group();fx.userData.bone='root';fx.userData.fx='split';fx.userData.fxMode='show';fx.position.set(0,.22,0);G.add(fx);
  const sp=PB(0xFFE08A,{emissive:0xFFB040,emissiveIntensity:3});for(let k=0;k<14;k++){const a=k/14*TAU;const m=add(new THREE.OctahedronGeometry(.012+(k%3)*.004,0),sp,[Math.cos(a)*(.2+(k%2)*.06),(k%3)*.05-.02,Math.sin(a)*(.2+(k%2)*.06)],[k,k*2,0],[1,2.2,1],fx);m.castShadow=false;}
  const ring=add(new THREE.TorusGeometry(.2,.012,8,40),PB(0xFF7A1C,{emissive:0xFF6A10,emissiveIntensity:2.2,transparent:true,opacity:.7}),[0,-.2,0],[Math.PI/2,0,0],null,fx);ring.castShadow=false;
  return G;}};
export const S=makeSculpt(def);
const J={root:[null,[0,0,0]],hips:['root',[0,.12,-.01]],chest:['hips',[0,.2,0]],head:['chest',[0,.27,.02]],earL:['head',[-.13,.4,.02]],earR:['head',[.13,.4,.02]],
 shL:['chest',[-.06,.2,.01]],elL:['shL',[-.09,.155,.03]],haL:['elL',[-.098,.11,.05]],shR:['chest',[.06,.2,.01]],elR:['shR',[.09,.155,.03]],haR:['elR',[.098,.11,.05]],
 thL:['hips',[-.045,.08,-.01]],knL:['thL',[-.048,.064,0]],ftL:['knL',[-.05,.028,.012]],thR:['hips',[.045,.08,-.01]],knR:['thR',[.048,.064,0]],ftR:['knR',[.05,.028,.012]],tail:['hips',[0,.11,-.07]]};
const cfg={name:'emberling',J,TIP:{haL:[-.1,.07,.066],haR:[.1,.07,.066],ftL:[-.05,.002,.07],ftR:[.05,.002,.07]},
 TORSO:{hips:[[0,.05,-.02],[0,.18,0],.11],chest:[[0,.17,0],[0,.24,.01],.09],head:[[0,.25,.02],[0,.52,.02],.18]},
 AIM:[],floor:.003,pivot:.12,shMin:-1.8,springs:[['earL','vx',-.5,170,8,0,.4],['earR','vx',-.5,170,8,0,.4],['tail','vy',-.6,120,7,0,.6]]};
const RK=makeRigKit(S,cfg);export const makeRig=RK.makeRig,skinGeo=RK.skinGeo;
export const CLIPS=stdClips({w:.05,arm:.55,x:{
 idle:{label:'Idle',len:2.4,f:t=>{const u=cyc(t,2.4);const b=Math.sin(u*TAU*2)*.5+.5;const fidget=Math.sin(t*11)*bump(u,.55,.85);const shift=Math.sin(u*TAU);return{y:b*.008,sq:b*.03,x:shift*.012,rz:shift*.05,hz:-shift*.08+fidget*.05,hx:-.06,eye:blink(t,2.4,.4),b:{chest:[-b*.05,0,shift*.05],shL:[-.2+fidget*.4,0,-.25],shR:[-.25-fidget*.3,0,.25],elL:[-.7,0,0],elR:[-.7,0,0],thL:[-.15*Math.max(0,shift),0,0],knL:[.25*Math.max(0,shift),0,0],thR:[-.15*Math.max(0,-shift),0,0],knR:[.25*Math.max(0,-shift),0,0],tail:[0,shift*.6,0]}};}},
 idle2:{label:'Idle 2',len:3,f:t=>{const u=cyc(t,3);const pounce=bump(u,.45,.7),crouch=bump(u,.25,.5);const look=Math.sin(u*TAU*2)*bump(u,0,.4);return{y:pounce*.09-crouch*.02,z:pounce*.06,sq:-crouch*.08+pounce*.05,hy:look*.5,hx:-.1*pounce+.1*crouch,eye:1+crouch*.18,eyeW:1+crouch*.06,b:{shL:[-1.4*pounce,0,-.3],shR:[-1.4*pounce,0,.3],elL:[-.4,0,0],elR:[-.4,0,0],thL:[-.8*crouch,0,0],knL:[1.2*crouch,0,0],thR:[-.8*crouch,0,0],knR:[1.2*crouch,0,0],tail:[.4*crouch,0,0]}};}},
 ability:{label:'Burst',len:2.2,f:t=>{const u=cyc(t,2.2);const puff=sstep(0,.45,u)*(1-sstep(.5,.56,u)),boom=bump(u,.5,.9),shake=bump(u,.25,.52);return{y:boom*.06,sq:puff*.14-boom*.06+(u>.5&&u<.6?-.1:0),x:Math.sin(u*140)*.012*shake,rz:Math.sin(u*90)*.05*shake,eye:1+puff*.25-boom*.3,eyeW:1+puff*.1,split:boom,
  b:{shL:[-.3-2*boom,0,-.9*boom-.3*puff],shR:[-.3-2*boom,0,.9*boom+.3*puff],elL:[-1.2*puff,0,0],elR:[-1.2*puff,0,0],thL:[-.4*puff,0,-.25*boom],knL:[.6*puff,0,0],thR:[-.4*puff,0,.25*boom],knR:[.6*puff,0,0],tail:[-.8*boom,0,0]}};}},
 work:{label:'Chases sparks',len:3.6,f:t=>{const u=cyc(t,3.6);const a=u*TAU;const hop=Math.abs(Math.sin(a*3));return{x:Math.sin(a)*.12,z:Math.cos(a)*.12-.12,ry:a+Math.PI/2,y:hop*.05,sq:hop*.03,rz:-.12,hy:-.3,hx:-.15,eye:blink(t,3.6,1.2),b:merge(gait(cyc(t,.4),{leg:.7,knee:1.1,arm:0}),{shL:[-1.6+Math.sin(t*14)*.3,0,-.3],shR:[-1.6-Math.sin(t*14)*.3,0,.3],elL:[-.3,0,0],elR:[-.3,0,0],tail:[0,Math.sin(t*9)*.6,0]})};}},
 nap:{label:'Nap',len:3.2,f:t=>{const b=Math.sin(t*TAU/3.2)*.5+.5;return{y:-.045,sq:-.06+b*.04,rx:.2,hx:.35,hz:.25,eye:.04,b:{thL:[-1.4,0,-.3],knL:[1.9,0,0],thR:[-1.4,0,.3],knR:[1.9,0,0],shL:[-.5,0,.5],elL:[-1.3,0,0],shR:[-.5,0,-.5],elR:[-1.3,0,0],chest:[.25+b*.05,0,0],tail:[.6,.8,0]}};}}}});
export const EXPR={
 happy:{label:'Reckless',hz:-.16,hx:-.08,eye:1.1,b:{shL:[-2,0,-.5],shR:[-.3,0,.4],elL:[-.4,0,0],elR:[-.9,0,0]}},
 focus:{label:'Fired up',hx:.14,eye:.62,eyeW:1.06,b:{shL:[-.6,0,-.1],shR:[-.6,0,.1],elL:[-1.4,0,0],elR:[-1.4,0,0]}},
 startled:{label:'Startled',hx:-.18,eye:1.25,eyeW:1.12,b:{shL:[-.4,0,-1.1],shR:[-.4,0,1.1],elL:[-.3,0,0],elR:[-.3,0,0]}},
 caught:{label:'Fizzled',hx:.35,hz:.14,eye:.5,b:{shL:[.1,0,.2],shR:[.1,0,-.2],chest:[.25,0,0]}}};
export const build=o=>S.build(o),loadBaked=(u,r)=>S.loadBaked(u,r);
export const BIN='emberling.bin?v=1',RES=.0046,GAME_SCALE=1.3;
export const EMBERS=[['earL',[-.2,.45,-.04]],['earR',[.2,.45,-.04]],['tail',[0,.11,-.21]]];
export const ROUTE=[{to:[1.1,-.4],clip:'run',sp:.45},{at:true,clip:'work',dur:7.2,face:[2,1]},{to:[-.7,1],clip:'run',sp:.4},{at:true,clip:'ability',dur:2.2,face:[1,3]},{at:true,clip:'idle',dur:2.4,face:[1,3]},{to:[.2,.2],clip:'carry',sp:.26},{at:true,clip:'nap',dur:3.2,face:[2,2]}];
export const HERO={cam:[1.25,.62,1.5],target:[0,.3,0],clip:'idle'};
