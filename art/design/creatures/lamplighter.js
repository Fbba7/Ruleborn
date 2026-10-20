import * as THREE from 'three';
import {makeSculpt,makeRigKit,stdClips,sstep,vnoise,clamp,ease,bump,blink,cyc,TAU,merge,gait} from './creature-kit.js';
import {parts} from './creature-parts.js?v=8';
import {sageFrame,sageBody,nearest,region,paintFace,clothShade,mir,sageBrows} from './sage-kit.js?v=8';
// ============ THE LAMPLIGHTER · Sage · Energy · after launch (GDD 11.7 names it; the look is a proposal) ============
// a wiry lamplighter in a long charcoal greatcoat with ember-orange trim, a peaked cap, soot on the cheeks, a lighting pole with a glowing wick and a lantern at the belt
const COL={coat:0x34303A,coatL:0x5A5664,coatD:0x141218,ember:0xE8662A,emberL:0xFFA05A,emberD:0x8A2E10,skin:0xD89C74,skinD:0x9A5E40,soot:0x3A2A26,hair:0x3A2418,hairD:0x160C08,
 boot:0x3A2A1E,sole:0x140E0A,mouth:0x5A2418,blush:0xE0806A,brass:0xD0A048,flame:0xFFB84A,shirt:0xE8D8B8};
const K=Object.fromEntries(Object.entries(COL).map(([k,v])=>[k,new THREE.Color(v)]));
const F=sageFrame({k:.98,head:1.06,leg:1.04,shW:.165});const{P,HP}=F;const HR=r=>r*F.H*F.k;let A0=null;
const def={name:'lamplighter',box:[[-.32,0,-.3],[.32,1.26,.3]],res:.0056,warm:0x1A0A06,aoWarm:.2,sheen:0xFFE8D0,rim:0xFFB070,
 bodyMat:{roughness:.74,specularIntensity:.45,sheen:0.3,sheenRoughness:.5},fur:{shells:0},
 sculpt(A){A0=A;const{E,C}=A;
  sageBody(A,F,{coat:.24,sleeveFlare:1.15,bootH:.13,noseLen:1.1,belly:.9});
  // turned-up collar, thick scarf, messy dark hair under the cap
  E('T:collar',P(0,.88,-.03),[.13,.07,.11],null,.03);E('T:collarcut',P(0,.885,.08),[.075,.055,.07],null,.015,'s');E('T:cravat',P(0,0.878,.055),[.058,.048,.05],null,.03);C('T:cravatTail',P(0,0.858,.085),P(0,0.803,.09),.018,.012,.015);
  C('T:scarf',P(-.07,.868,.05),P(.07,.868,.05),.034,.034,.03);C('T:scarfEnd',P(-.05,.85,.09),P(-.08,.68,.1),.026,.02,.02);
  E('T:hairCap',HP(0,1.07,-.025),[HR(.134),HR(.1),HR(.134)],null,.04);for(let i=0;i<6;i++){const a=(i-2.5)*.32;E('T:hairTuft'+i,HP(Math.sin(a)*.12,1.02,Math.cos(a)*.1-.02),[HR(.028),HR(.05),HR(.028)],[0,a,Math.sin(a)*.6],.02);}},
 disp(x,y,z,d){if(Math.abs(d)>.03)return d;const n=nearest(A0,x,y,z);if(/^T:hair/.test(n))return d-Math.pow(Math.abs(Math.sin(Math.atan2(x,z)*16+y*40)),5)*.0022;
  if(/^T:(coat|cfold|collar)/.test(n))return d+(vnoise(x*40,y*12,z*40)-.5)*.0016;return d+(vnoise(x*70,y*70,z*70)-.5)*.0005;},
 paint(x,y,z,nx,ny,nz,ao,c,A){const n=nearest(A,x,y,z);const r=region(n);
  if(/cravat/.test(n)){clothShade(c,K,new THREE.Color(0xC8503A),new THREE.Color(0xE8806A),new THREE.Color(0x6A2418),ny,nz,ao,x,y,z,.05);return 0;}
  if(r==='skin'||r==='neck'||r==='hand'){c.copy(K.skin).lerp(new THREE.Color(0x8A3A2E),(1-ao)*.45+sstep(.2,-.6,ny)*.1);if(r==='skin'){paintFace(x,y,z,c,K,F,{ao,smile:.009,blush:.3});
    // soot smudges on the cheek and nose tip
    c.lerp(K.soot,sstep(.66,.74,vnoise(x*50,y*50,z*50))*sstep(.03,.06,Math.abs(x))*sstep(.07,.1,z)*sstep(F.hyW-.02,F.hyW-.05,y)*.3);}
   if(r==='hand')c.lerp(K.soot,sstep(.55,.7,vnoise(x*60,y*60,z*60))*.4);return 0;}
  if(r==='hair'){c.copy(K.hair).lerp(K.hairD,(1-ao)*.6+Math.pow(Math.abs(Math.sin(Math.atan2(x,z)*16+y*40)),5)*.2);return 0;}
  if(r==='boot'){c.copy(K.boot).lerp(new THREE.Color(0x080404),(1-ao)*.6).lerp(new THREE.Color(0x7A5A3A),sstep(.6,1,ny)*.2);return 0;}if(r==='sole'){c.copy(K.sole);return 0;}
  if(/scarf/.test(n)){clothShade(c,K,K.ember,K.emberL,K.emberD,ny,nz,ao,x,y,z,.08);if(Math.abs(Math.sin(y*160+x*20))>.94)c.lerp(K.emberD,.4);return 0;}
  if(r==='legs'){clothShade(c,K,new THREE.Color(0x4A3A32),new THREE.Color(0x7A6454),new THREE.Color(0x1A120E),ny,nz,ao,x,y,z,.05);return 0;}
  if(r==='cuff'){c.copy(K.ember).lerp(K.emberD,(1-ao)*.5);return 0;}
  // coat, double-breasted with ember piping; shirt at the throat; a leather belt
  const ax=Math.abs(x);if(nz>.3&&ax<.028&&y>F.P(0,.78,0)[1]&&!/collar/.test(n)){c.copy(K.shirt).lerp(new THREE.Color(0xA8906A),(1-ao)*.5);return 0;}
  clothShade(c,K,K.coat,K.coatL,K.coatD,ny,nz,ao,x,y,z,.05);
  if(nz>.25&&Math.abs(ax-.045)<.004&&y>F.P(0,.5,0)[1]&&y<F.P(0,.84,0)[1])c.lerp(K.ember,.8);
  {const hb=F.P(0,.24,0)[1];if(y<hb+.016)c.lerp(K.ember,sstep(hb+.016,hb+.01,y)*.85);}
  if(/collar/.test(n)&&y>F.P(0,.93,0)[1])c.lerp(K.ember,.6);
  if(r==='belt'){c.copy(new THREE.Color(0x4A2E1A)).lerp(new THREE.Color(0x1A0E06),(1-ao)*.6);}
  return 0;},
 accessories(A){const G=new THREE.Group();const Pt=parts(A,G);const{PB,add,irisTex,eye}=Pt;const T=THREE;
  const tex=irisTex('#0A0604','#6A3A12','#E8A04A','#1A0A04',{pup:.3,human:true});
  for(const s of[-1,1])eye(s,{human:true,skin:COL.skin,lash:COL.hairD??0x1A0C08,r:HR(.028),ctr:HP(0,1.035,.02),dir:[.46,-.03,1],off:-.009,tex,lid:COL.skinD,lidCut:.28,lidTilt:.3,yaw:.36,irisK:1.35});
  G.add(sageBrows(Pt,F,{col:COL.hairD??COL.hair}));
  const brass=PB(COL.brass,{metalness:1,roughness:.3}),iron=PB(0x2A2A30,{metalness:.8,roughness:.45}),glassM=PB(0xFFF0D8,{roughness:.05,transmission:.8,thickness:.01,transparent:true,opacity:.45});
  const flameM=new T.MeshBasicMaterial({color:COL.flame}),haloM=new T.MeshBasicMaterial({color:0xFF8A3A,transparent:true,opacity:.28,depthWrite:false,blending:T.AdditiveBlending});
  const flame=(par,sc)=>{const f=new T.Group();f.userData.spin=[9,.18];par.add(f);add(new T.ConeGeometry(.018*sc,.06*sc,12),flameM,[0,.03*sc,0],null,null,f);add(new T.SphereGeometry(.02*sc,12,10),flameM,[0,.008*sc,0],null,null,f);add(new T.SphereGeometry(.05*sc,12,10),haloM,[0,.02*sc,0],null,null,f);return f;};
  // peaked cap with a brass flame badge
  {const h=new T.Group();h.userData.bone='head';h.position.set(...HP(0,1.105,-.005));h.rotation.set(-.08,0,.04);G.add(h);const cm=PB(0x2A2630,{roughness:.7,sheen:.3});
   add(new T.SphereGeometry(.142,28,14,0,TAU,0,Math.PI/2),cm,[0,0,-.01],null,[1,.62,1.02],h);add(new T.CylinderGeometry(.142,.144,.03,32),cm,[0,.004,-.01],null,null,h);add(new T.TorusGeometry(.142,.006,8,40),PB(COL.ember,{roughness:.6}),[0,.012,-.01],[Math.PI/2,0,0],null,h);
   add(new T.CylinderGeometry(.11,.11,.01,28,1,false,-Math.PI*.35,Math.PI*.7),PB(0x141218,{roughness:.4,clearcoat:.6}),[0,-.006,.08],[.18,0,0],[1,1,.8],h);
   const b=new T.Shape();b.moveTo(0,.02);b.quadraticCurveTo(.014,0,0,-.016);b.quadraticCurveTo(-.014,0,0,.02);add(new T.ExtrudeGeometry(b,{depth:.003,bevelEnabled:false}),brass,[0,.03,.137],null,null,h);}
  // lighting pole in the right hand: a tall brass-tipped pole with a hook and a live wick
  {const w=F.j.wr(1);const g=new T.Group();g.userData.bone='haR';g.position.set(w[0]+.012,w[1]-.05,w[2]+.03);g.rotation.set(.06,0,-.04);G.add(g);
   add(new T.CylinderGeometry(.01,.011,1.2,10),PB(0x5A3A24,{roughness:.7}),[0,.12,0],null,null,g);add(new T.CylinderGeometry(.013,.013,.05,10),brass,[0,.72,0],null,null,g);
   const hook=[];for(let i=0;i<=16;i++){const u=i/16,a=u*Math.PI*1.2;hook.push(new T.Vector3(Math.sin(a)*.05,.75+Math.sin(a*.5)*.06+u*.02,0));}add(new T.TubeGeometry(new T.CatmullRomCurve3(hook),24,.005,6),brass,null,null,null,g);
   const wk=new T.Group();wk.position.set(0,.76,0);g.add(wk);add(new T.CylinderGeometry(.009,.013,.03,10),brass,[0,0,0],null,null,wk);const fl=flame(wk,1);fl.position.y=.015;
   const l=new T.PointLight(0xFFA040,1.1,1.4,2);l.position.set(0,.8,0);g.add(l);
   // sparks drifting off the wick
   const sp=new T.Group();sp.userData.spin=1.2;sp.userData.spinAx='y';sp.position.set(0,.8,0);g.add(sp);for(let i=0;i<8;i++)add(new T.SphereGeometry(.004,6,4),flameM,[Math.cos(i*2.4)*.04,.02+i*.018,Math.sin(i*2.4)*.04],null,null,sp);}
  // small lantern on the belt
  {const g=new T.Group();g.userData.bone='hips';g.position.set(...P(-.15,.53,.06));G.add(g);add(new T.TorusGeometry(.015,.003,6,14),brass,[0,.05,0],null,null,g);
   add(new T.CylinderGeometry(.022,.026,.012,6),iron,[0,.032,0],null,null,g);add(new T.CylinderGeometry(.02,.02,.045,6,1,true),glassM,[0,.005,0],null,null,g);add(new T.CylinderGeometry(.026,.022,.01,6),iron,[0,-.02,0],null,null,g);
   const fl=flame(g,.45);fl.position.y=-.008;const l=new T.PointLight(0xFFA040,.35,.5,2);l.position.set(0,0,.02);g.add(l);}
  // brass buttons, two rows
  for(const s of[-1,1])for(let i=0;i<3;i++){const b=add(new T.CylinderGeometry(.0085,.0085,.004,14),brass,P(s*.062,.8-i*.08,.102),[Math.PI/2,0,0],null,G);b.userData.bone='chest';}
  // Flare (proposal 1): the wick blazes and a ring of light rolls outward
  {const fx=new T.Group();fx.userData.bone='root';fx.userData.fx='flare';fx.userData.fxMode='show';fx.position.set(0,.02,0);G.add(fx);const m=new T.MeshBasicMaterial({color:0xFFB050,transparent:true,opacity:.6,depthWrite:false,blending:T.AdditiveBlending,side:T.DoubleSide});
   for(let k=0;k<3;k++)add(new T.RingGeometry(.3+k*.16,.33+k*.16,64),m,[0,k*.004,0],[-Math.PI/2,0,0],null,fx);add(new T.SphereGeometry(.22,20,14),new T.MeshBasicMaterial({color:0xFFC870,transparent:true,opacity:.2,depthWrite:false,blending:T.AdditiveBlending}),[F.j.wr(1)[0],1.35,.1],null,null,fx);}
  // Snuff (proposal 2): a puff of dark smoke where a lamp went out
  {const fx=new T.Group();fx.userData.bone='root';fx.userData.fx='snuff';fx.userData.fxMode='show';fx.position.set(0,.2,.6);G.add(fx);const m=new T.MeshStandardMaterial({color:0x2A2430,transparent:true,opacity:.6,roughness:1,depthWrite:false});
   for(let i=0;i<9;i++)add(new T.SphereGeometry(.07+(i%3)*.02,12,10),m,[Math.sin(i*2.3)*.1,i*.05,Math.cos(i*1.7)*.08],null,null,fx);}
  // Spark trail (proposal 3): embers streak along the ground ahead of the crew
  {const fx=new T.Group();fx.userData.bone='root';fx.userData.fx='trail';fx.userData.fxMode='show';fx.position.set(0,.02,.2);G.add(fx);
   for(let i=0;i<22;i++){const u=i/22;add(new T.SphereGeometry(.012*(1-u*.5),8,6),flameM,[Math.sin(u*9)*.08,.01+Math.abs(Math.sin(u*20))*.04,u*1.1],null,null,fx);}
   const m=new T.MeshBasicMaterial({color:0xFF8A3A,transparent:true,opacity:.35,depthWrite:false,blending:T.AdditiveBlending,side:T.DoubleSide});add(new T.PlaneGeometry(.16,1.1),m,[0,.005,.55],[-Math.PI/2,0,0],null,fx);}
  return G;}};
export const S=makeSculpt(def);
const cfg={name:'lamplighter',J:F.J,TIP:F.TIP,TORSO:F.TORSO,AIM:[],floor:.006,pivot:.5,shMin:-2.2,springs:[['earL','vx',-.3,110,8,0,.25],['tail','vy',-.25,90,8,0,.15]]};
const RK=makeRigKit(S,cfg);export const makeRig=RK.makeRig,skinGeo=RK.skinGeo;
const pole={shR:[-.25,0,.08],elR:[-.55,0,0]};
export const CLIPS=stdClips({w:.12,arm:.3,x:{
 idle:{label:'Idle',len:4.4,f:t=>{const b=Math.sin(t*TAU/4.4)*.5+.5;return{sq:b*.01,hx:.04,hy:Math.sin(t*.5)*.18,hz:Math.sin(t*.6)*.04,eye:blink(t,3.6,.5)*.95,b:merge(pole,{chest:[-b*.02,0,0],shL:[-.1,0,-.05],elL:[-.4,0,0]})};}},
 idle2:{label:'Idle 2',len:5,f:t=>{const u=cyc(t,5);const warm=bump(u,.15,.75);return{hx:.1*warm,eye:1-.4*warm,b:merge(pole,{shL:[-1.1*warm-.1,0,.3*warm],elL:[-1.2*warm-.4,0,0],haL:[.4*warm,0,0]})};}},
 p1:{label:'Flare',len:3,f:t=>{const u=cyc(t,3);const k=ease(sstep(.05,.28,u))*(1-sstep(.86,1,u));return{hx:-.25*k,eye:1-.5*k,flare:sstep(.25,.35,u)*(1-sstep(.9,1,u)),b:{shR:[-2.2*k-.25*(1-k),0,.1],elR:[-.2*k-.55*(1-k),0,0],shL:[-.4*k,0,-.6*k],elL:[-.5,0,0],chest:[-.1*k,0,0]}};}},
 p2:{label:'Snuff',len:3,f:t=>{const u=cyc(t,3);const k=ease(sstep(.05,.3,u))*(1-sstep(.86,1,u));const dip=bump(u,.28,.42);return{hx:.12*k,snuff:sstep(.35,.45,u)*(1-sstep(.9,1,u)),b:{shR:[-1.4*k-.25*(1-k),0,.02],elR:[-.3*k-.55*(1-k)+dip*.3,0,0],shL:[-.1,0,-.05],elL:[-.4,0,0],chest:[.1*k,0,0]}};}},
 p3:{label:'Spark trail',len:3.2,f:t=>{const u=cyc(t,3.2);const k=ease(sstep(.05,.28,u))*(1-sstep(.86,1,u));const sw=Math.sin(u*TAU)*k;return{hy:sw*.2,trail:sstep(.25,.4,u)*(1-sstep(.9,1,u)),b:{shR:[-1*k-.25*(1-k),.4*sw,.2*k],elR:[-.3,0,0],shL:[-.2,0,-.2*k],elL:[-.5,0,0],hips:[0,sw*.25,0]}};}},
 guard:{label:'On guard',len:5,f:t=>{const u=cyc(t,5);return{hy:Math.sin(u*TAU)*.35,eye:.85,b:{shR:[-.3,0,.02],elR:[-.6,0,0],shL:[-.4,0,.25],elL:[-1.3,0,0],chest:[.04,0,0]}};}},
 work:{label:'Lights the lamps',len:4,f:t=>{const u=cyc(t,4);const up=ease(sstep(.1,.35,u))*(1-sstep(.7,.9,u));return{hx:-.35*up,eye:1-.2*up,b:{shR:[-2.4*up-.25*(1-up),0,.05],elR:[-.1*up-.55*(1-up),0,0],haR:[-.2*up,0,0],shL:[-.1,0,-.05],elL:[-.4,0,0],chest:[-.12*up,0,0]}};}},
 nap:{label:'Rest',len:6,f:t=>{const b=Math.sin(t*TAU/6)*.5+.5;return{y:-.34,sq:-.02,hx:.35,eye:.1,b:{thL:[-1.5,0,-.2],knL:[1.9,0,0],thR:[-1.5,0,.2],knR:[1.9,0,0],shL:[-.5,0,.2],elL:[-1,0,0],shR:[-.5,0,-.2],elR:[-1,0,0],chest:[.28+b*.03,0,0]}};}}}});
{const W=CLIPS.walk.f;CLIPS.walk.f=t=>{const p=W(t);p.b=merge(p.b||{},{shR:[-.2-(p.b.shR?p.b.shR[0]:0),0,.08],elR:[-.45-(p.b.elR?p.b.elR[0]:0),0,0]});return p;};}
export const EXPR={
 happy:{label:'Cheerful',hx:-.03,hz:.07,eye:.9,b:pole},
 focus:{label:'Aiming the wick',hx:-.2,eye:.6,b:{shR:[-1.8,0,.1],elR:[-.3,0,0]}},
 startled:{label:'Burnt',hx:-.12,eye:1.3,eyeW:1.06,b:{shL:[-.5,0,-.6],shR:[-.5,0,.6]}},
 caught:{label:'Burnt out',hx:.4,hz:.1,eye:.3,b:{chest:[.25,0,0],shR:[.1,0,-.1],shL:[.15,0,.1]}}};
export const build=o=>S.build(o),loadBaked=(u,r)=>S.loadBaked(u,r);
export const BIN='lamplighter.bin?v=1',RES=.0095,GAME_SCALE=1;
export const EMBERS=[['haR',P(.2,1.45,.1)],['head',HP(0,1.25,0)],['hips',P(-.15,.5,.1)]];
export const ROUTE=[{to:[1.1,-.4],clip:'walk',sp:.24},{at:true,clip:'work',dur:4,face:[2,-1]},{to:[-.7,1],clip:'walk',sp:.24},{at:true,clip:'idle2',dur:5,face:[1,3]},{at:true,clip:'idle',dur:4.4,face:[1,3]},{to:[.2,.2],clip:'walk',sp:.22},{at:true,clip:'guard',dur:5,face:[2,2]}];
export const HERO={cam:[2.2,1.3,3],target:[0,.78,0],clip:'idle'};
