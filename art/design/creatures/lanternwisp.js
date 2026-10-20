import * as THREE from 'three';
import {makeSculpt,makeRigKit,stdClips,sstep,vnoise,clamp,ease,bump,blink,cyc,TAU,merge,gait} from './creature-kit.js';
import {parts} from './creature-parts.js';
// ============ LANTERN WISP · Scout · Spirit · floating lantern spirit, 0.6 m, magenta with warm light (GDD 11.4) ============
const COL={body:0xD2449A,bodyL:0xF08CC4,bodyD:0x6A1A62,core:0xFFD89A,cheek:0xFF9AC8,mouth:0x5A1440,tail:0xC04AA8};
const K=Object.fromEntries(Object.entries(COL).map(([k,v])=>[k,new THREE.Color(v)]));
const mir=(p,s)=>[p[0]*s,p[1],p[2]];let A0=null;
const HOV=.16;
const def={name:'lanternwisp',box:[[-.22,0,-.2],[.22,.64,.22]],res:.0044,warm:0x3A0A30,aoWarm:.1,sheen:0xFFE8F6,rim:0xFFD08A,
 bodyMat:{roughness:.35,sheen:.6,sheenRoughness:.3,clearcoat:.35,clearcoatRoughness:.3,emissive:0x3A0A30,emissiveIntensity:.3},fur:{shells:0},vcGlow:1.1,
 sculpt(A){const{E,C}=A;A0=A;
  // one big glowing head that is most of the body, a soft skirt, and a curling wisp tail
  E('T:head',[0,.4,.01],[.15,.14,.14],null,.05);E('T:face',[0,.38,.08],[.125,.1,.07],null,.04);for(const s of[-1,1])E('T:cheek'+(s<0?'L':'R'),mir([.08,.35,.1],s),[.04,.034,.035],null,.03);
  
  E('T:skirt',[0,.27,0],[.12,.06,.11],null,.05);for(let k=0;k<8;k++){const a=k/8*TAU;E('T:scallop'+k,[Math.sin(a)*.1,.235,Math.cos(a)*.095],[.035,.03,.03],null,.03);}
  C('tail:w1',[0,.24,-.01],[0,.16,-.04],.07,.05,.05);C('tail:w2',[0,.16,-.04],[.02,.09,-.08],.05,.028,.04);C('tail:w3',[.02,.09,-.08],[.05,.05,-.1],.028,.008,.02);
  for(const s of[-1,1]){const L=s<0?'L':'R';
   // tiny flame-tip arms
   C('sh'+L+':arm1',mir([.1,.28,.02],s),mir([.14,.24,.05],s),.022,.018,.015);E('ha'+L+':paw',mir([.15,.225,.065],s),[.02,.022,.02],null,.012);
   // flame-tip ears
   C('ear'+L+':ear',mir([.085,.5,-.01],s),mir([.12,.575,-.06],s),.034,.005,.03);C('ear'+L+':ear2',mir([.12,.575,-.06],s),mir([.1,.61,-.1],s),.006,.002,.01);}},
 disp(x,y,z,d){if(Math.abs(d)>.03)return d;return d+(vnoise(x*50,y*50,z*50)-.5)*.0006;},
 paint(x,y,z,nx,ny,nz,ao,c,A){
  // warm light from inside: bright at the core, deepening to magenta at the rim
  const r=Math.hypot(x,(y-.34)*1.1,z);c.copy(K.bodyL).lerp(K.body,sstep(.06,.15,r)).lerp(K.bodyD,(1-ao)*.4+sstep(-.3,-.9,ny)*.3);
  c.lerp(K.bodyD,sstep(.2,.6,ny)*.35+sstep(.0,-.6,nz)*.35);{const cg=sstep(.1,.7,nz)*sstep(.42,.3,y)*sstep(.2,.3,y);c.lerp(K.core,cg*.8);c.lerp(new THREE.Color(0xFFF2D0),cg*sstep(.36,.3,y)*.5);}
  const fc=sstep(.02,-.004,A.minD(/^T:(face|cheek)/,x,y,z))*sstep(.04,.1,z);c.lerp(K.bodyL,fc*.7);
  c.lerp(K.cheek,sstep(.026,0,Math.hypot(Math.abs(x)-.08,y-.345,(z-.12)*1.3))*.6);
  if(z>.12&&Math.abs(x)<.024){const u=x/.024,cy=.326-.006*(1-u*u);const d=Math.abs(y-cy),w=.0022*(1-u*u*.6);if(d<w)c.copy(K.mouth);else if(d<w+.0025)c.lerp(K.mouth,.35*(1-(d-w)/.0025));}
  if(A.minD(/^tail:|^T:scallop/,x,y,z)<.004)c.lerp(K.tail,sstep(.24,.08,y)*.7).lerp(K.bodyL,sstep(.1,.04,y)*.5);
  if(A.minD(/^ear[LR]:/,x,y,z)<.004)c.lerp(K.core,sstep(.52,.6,y)*.8);
  if(A.dist('T:mouthcut',x,y,z)<.006&&z>.13)c.copy(K.mouth);
  return 0;},
 accessories(A){const G=new THREE.Group();const P=parts(A,G);const{PB,add,irisTex,eye,hit}=P;
  const tex=irisTex('#12020E','#8A1A6A','#FFB86A','#2A0620',{pup:.36});
  for(const s of[-1,1])eye(s,{r:.06,ctr:[0,.4,.02],dir:[.42,.05,1],off:-.02,tex,lid:COL.bodyD,lidCut:.2,yaw:.33,irisK:1.25});
  // lantern frame: brass cap with a ring handle on the crown, a brass band at the waist and four slim ribs
  const brass=PB(0xD8A84A,{metalness:1,roughness:.3}),brassD=PB(0x8A5A22,{metalness:1,roughness:.42});
  {const g=new THREE.Group();g.userData.bone='head';g.position.set(0,.535,0);G.add(g);
   add(new THREE.CylinderGeometry(.045,.07,.03,24),brass,[0,0,0],null,null,g);add(new THREE.CylinderGeometry(.02,.04,.025,20),brassD,[0,.025,0],null,null,g);
   add(new THREE.TorusGeometry(.03,.006,8,24),brass,[0,.062,0],null,null,g);}
  add(new THREE.TorusGeometry(.125,.009,8,40),brass,[0,.27,0],[Math.PI/2,0,0],null,G,'hips');
  for(const a of[Math.PI/2,Math.PI*.8,Math.PI*1.2,Math.PI*1.5]){const pts=[];for(let i=0;i<=14;i++){const el=-.35+i/14*1.85;pts.push(hit([Math.sin(a)*Math.cos(el),Math.sin(el),Math.cos(a)*Math.cos(el)],[0,.4,.01],.004).p);}
   add(new THREE.TubeGeometry(new THREE.CatmullRomCurve3(pts),40,.005,6),brassD,null,null,null,G,'head');}
  // the flame inside: a bright core and a real light
  {const g=new THREE.Group();g.userData.bone='chest';g.position.set(0,.34,0);G.add(g);g.add(new THREE.PointLight(0xFFB86A,1.2,.9,2));
   const f=new THREE.Mesh(new THREE.SphereGeometry(.05,16,12),new THREE.MeshBasicMaterial({color:0xFFE8B0,transparent:true,opacity:.35,depthWrite:false,blending:THREE.AdditiveBlending}));f.scale.set(1,1.4,1);g.add(f);}
  // floating sparks orbiting it
  const sp=new THREE.Group();sp.userData.bone='root';G.add(sp);const sm=new THREE.MeshBasicMaterial({color:0xFFD08A});
  for(let k=0;k<5;k++){const a=k/5*TAU;const m=new THREE.Mesh(new THREE.SphereGeometry(.007,8,6),sm);m.position.set(Math.cos(a)*.2,.42+Math.sin(a*2)*.05,Math.sin(a)*.2);sp.add(m);}
  // reveal (ability): a widening ring of warm light
  const fx=new THREE.Group();fx.userData.bone='root';fx.userData.fx='split';fx.userData.fxMode='show';fx.position.set(0,.02,0);G.add(fx);
  const rm=new THREE.MeshBasicMaterial({color:0xFFC87A,transparent:true,opacity:.55,depthWrite:false,blending:THREE.AdditiveBlending,side:THREE.DoubleSide});
  for(let k=0;k<3;k++){const r=new THREE.Mesh(new THREE.RingGeometry(.25+k*.18,.27+k*.18,64),rm);r.rotation.x=-Math.PI/2;fx.add(r);}
  const bm=new THREE.Mesh(new THREE.SphereGeometry(.34,32,16,0,TAU,0,Math.PI/2),new THREE.MeshBasicMaterial({color:0xFFB86A,transparent:true,opacity:.12,depthWrite:false,blending:THREE.AdditiveBlending,side:THREE.DoubleSide}));fx.add(bm);
  return G;}};
export const S=makeSculpt(def);
// floating: the leg bones sit in the wisp tail so the standard gait just ripples it
const J={root:[null,[0,0,0]],hips:['root',[0,.26,0]],chest:['hips',[0,.3,0]],head:['chest',[0,.34,.01]],earL:['head',[-.09,.5,0]],earR:['head',[.09,.5,0]],
 shL:['chest',[-.1,.28,.02]],elL:['shL',[-.13,.25,.04]],haL:['elL',[-.15,.225,.065]],shR:['chest',[.1,.28,.02]],elR:['shR',[.13,.25,.04]],haR:['elR',[.15,.225,.065]],
 thL:['hips',[-.01,.2,-.02]],knL:['thL',[-.01,.12,-.05]],ftL:['knL',[-.01,.02,-.08]],thR:['hips',[.01,.2,-.02]],knR:['thR',[.01,.12,-.05]],ftR:['knR',[.01,.02,-.08]],tail:['hips',[0,.2,-.03]]};
const cfg={name:'lanternwisp',J,TIP:{haL:[-.16,.21,.08],haR:[.16,.21,.08],ftL:[-.01,0,-.1],ftR:[.01,0,-.1]},
 TORSO:{hips:[[0,.2,0],[0,.3,0],.13],chest:[[0,.26,0],[0,.36,0],.14],head:[[0,.3,.01],[0,.56,.02],.17]},
 AIM:[],floor:.01,pivot:.3,shMin:-1.9,springs:[['earL','vx',-.6,110,5,0,.6],['earR','vx',-.6,110,5,0,.6],['tail','vy',-.6,70,5,0,.5]]};
const RK=makeRigKit(S,cfg);export const makeRig=RK.makeRig,skinGeo=RK.skinGeo;
const C0=stdClips({w:.05,arm:.5,x:{
 idle:{label:'Idle',len:3.2,f:t=>{const u=cyc(t,3.2);const b=Math.sin(u*TAU);const peek=bump(u,.55,.9);return{rz:b*.05,hz:b*.1+peek*.2,hy:peek*.45,hx:-.05,eye:blink(t,3.2,.6)*(1+peek*.15),b:{shL:[-.3,0,.4+b*.1],shR:[-.3,0,-.4+b*.1]}};}},
 idle2:{label:'Idle 2',len:3.6,f:t=>{const u=cyc(t,3.6);const spin=ease(sstep(.2,.7,u));return{ry:spin*TAU,rz:Math.sin(u*TAU*2)*.1,eye:1+bump(u,.2,.7)*.2,b:{shL:[-1.4*bump(u,.2,.7),0,.6],shR:[-1.4*bump(u,.2,.7),0,-.6]}};}},
 ability:{label:'Reveal',len:2.6,f:t=>{const u=cyc(t,2.6);const flare=ease(sstep(.05,.35,u))*(1-sstep(.8,1,u));return{y:flare*.08,sq:flare*.08,hx:-.12*flare,eye:1+flare*.35,eyeW:1+flare*.1,split:flare,b:{shL:[-.8*flare,0,-1.2*flare],shR:[-.8*flare,0,1.2*flare]}};}},
 work:{label:'Lights every lantern',len:4.2,f:t=>{const u=cyc(t,4.2);const reach=bump(u,.1,.5),glow=bump(u,.5,.9);return{z:reach*.06,rx:.2*reach,hx:.15*reach-.1*glow,sq:glow*.06,eye:1+glow*.2,b:{shR:[-1.6*reach,0,-.3],elR:[-.3,0,0],shL:[-.3,0,.4]}};}},
 nap:{label:'Dims to sleep',len:4.4,f:t=>{const b=Math.sin(t*TAU/4.4)*.5+.5;return{y:-.1,sq:-.06+b*.03,hx:.35,hz:.2,eye:.05,b:{shL:[-.5,0,.6],shR:[-.5,0,-.6]}};}}}});
export const CLIPS=Object.fromEntries(Object.entries(C0).map(([k,c])=>[k,{...c,f:t=>{const p=c.f(t);const nap=k==='nap'||k==='ko';return{...p,y:(p.y||0)+(nap?HOV*.35:HOV)+Math.sin(t*2.4)*.012,sq:(p.sq||0)*.6};}}]));
export const EXPR={
 happy:{label:'Delighted',hz:-.14,eye:.9,b:{shL:[-.9,0,.6],shR:[-.9,0,-.6]}},
 focus:{label:'Nosy',hx:.12,hz:.25,eye:.8,eyeW:1.06,b:{shR:[-1.3,0,-.3],shL:[-.3,0,.4]}},
 startled:{label:'Startled',hx:-.18,eye:1.25,eyeW:1.12,b:{shL:[-.3,0,-.9],shR:[-.3,0,.9]}},
 caught:{label:'Flickering',hx:.35,hz:.15,eye:.45,b:{chest:[.2,0,0]}}};
export const build=o=>S.build(o),loadBaked=(u,r)=>S.loadBaked(u,r);
export const BIN='lanternwisp.bin?v=1',RES=.0044,GAME_SCALE=1.3;
export const EMBERS=[['earL',[-.14,.62,-.03]],['earR',[.14,.62,-.03]],['head',[0,.6,0]]];
export const ROUTE=[{to:[1.1,-.4],clip:'walk',sp:.3},{at:true,clip:'work',dur:4.2,face:[2,-1]},{to:[-.7,1],clip:'run',sp:.5},{at:true,clip:'ability',dur:2.6,face:[1,3]},{at:true,clip:'idle',dur:3.2,face:[1,3]},{to:[.2,.2],clip:'walk',sp:.3},{at:true,clip:'nap',dur:4.4,face:[2,2]}];
export const HERO={cam:[1.2,.7,1.62],target:[0,.44,0],clip:'idle'};
