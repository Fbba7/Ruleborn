import * as THREE from 'three';
import {makeSculpt,makeRigKit,stdClips,sstep,vnoise,clamp,ease,bump,blink,cyc,TAU,merge,gait} from './creature-kit.js';
import {parts} from './creature-parts.js?v=8';
import {sageFrame,sageBody,nearest,region,paintFace,clothShade,mir,sageBrows} from './sage-kit.js?v=8';
// ============ THE WANDERER · Sage · Keeper level 20 · cloaked traveller, cloak lining a starry map, walking stick topped by a compass; indigo and silver (GDD 11.7) ============
const COL={indigo:0x24245E,indigoL:0x42448A,indigoD:0x10102E,navy:0x0E1030,silver:0xA4AABC,silverL:0xD8DCE8,silverD:0x62687C,star:0xFFF4D0,skin:0xD8A07A,skinD:0x9A6444,
 hair:0xD8DCE6,hairD:0x8A90A0,boot:0x3A3040,sole:0x1A1420,mouth:0x5A2A22,blush:0xD88A78,brass:0xC8A860,wood:0x4A3226};
const K=Object.fromEntries(Object.entries(COL).map(([k,v])=>[k,new THREE.Color(v)]));
const F=sageFrame({k:1.02,head:1.02,leg:1,shW:.175});const{P,HP}=F;const HR=r=>r*F.H*F.k;let A0=null;
const hood={c:HP(0,1.07,-.02),r:[HR(.168),HR(.172),HR(.17)]},cut={c:HP(0,1.02,.135),r:[HR(.132),HR(.15),HR(.105)]};
const starry=(c,x,y,z,ao)=>{c.copy(K.navy).lerp(new THREE.Color(0x3A3A90),sstep(.5,.8,vnoise(x*7,y*7,z*7))*.35);
 const st=sstep(.9,.93,vnoise(x*70,y*70,z*70));c.lerp(K.star,st*.9);const big=sstep(.93,.95,vnoise(x*28+9,y*28,z*28));c.lerp(K.star,big);c.multiplyScalar(.78+.22*ao);};
const def={name:'wanderer',box:[[-.36,0,-.34],[.36,1.3,.3]],res:.0058,warm:0x0A0A20,aoWarm:.14,sheen:0xE8ECFF,rim:0xB8C8FF,
 bodyMat:{roughness:.72,specularIntensity:.45,sheen:0.3,sheenRoughness:.45},fur:{shells:0},
 sculpt(A){A0=A;const{E,C}=A;
  // the hood first, so its opening only cuts the hood
  E('T:hood',hood.c,hood.r,[-.12,0,0],.05);E('T:hoodTip',HP(0,1.1,-.17),[HR(.08),HR(.1),HR(.07)],[-.6,0,0],.05);E('T:hoodcut',cut.c,cut.r,[-.1,0,0],.02,'s');
  sageBody(A,F,{robeHem:.19,flare:1.12,sleeveFlare:1.15,bootH:.13,noseLen:1.15,belly:.95,belt:false});
  // shoulder mantle, silver scarf, satchel strap
  E('T:mantle',P(0,.84,-.012),[.215,.085,.15],null,.05);E('T:mantleB',P(0,.74,-.1),[.19,.12,.05],[-.1,0,0],.05);
  C('T:scarf',P(-.06,.9,.07),P(.06,.9,.07),.035,.035,.03);C('T:scarfEnd',P(.05,.88,.1),P(.07,.72,.12),.025,.018,.02);
  E('T:stache',HP(0,.965,.12),[HR(.042),HR(.012),HR(.018)],null,.01);E('T:beard',HP(0,.935,.1),[HR(.07),HR(.05),HR(.05)],null,.03);
  for(const s of[-1,1])E('T:hairSide'+(s<0?'L':'R'),HP(s*.112,1.0,-.01),[HR(.024),HR(.055),HR(.04)],[0,0,s*-.12],.03);},
 disp(x,y,z,d){if(Math.abs(d)>.03)return d;const n=nearest(A0,x,y,z);
  if(/^T:(robe|fold|mantle|hood)/.test(n))return d+(vnoise(x*40,y*12,z*40)-.5)*.0018;
  if(/^T:(hair|beard|stache)/.test(n))return d-Math.pow(Math.abs(Math.sin(x*140+y*30)),6)*.0008;
  return d+(vnoise(x*70,y*70,z*70)-.5)*.0005;},
 paint(x,y,z,nx,ny,nz,ao,c,A){let n=nearest(A,x,y,z);
  if(/^T:(hood|hoodTip)/.test(n)){const e0=Math.hypot((x-cut.c[0])/cut.r[0],(y-cut.c[1])/cut.r[1],(z-cut.c[2])/cut.r[2]);if(e0<1.02){const ds=A.minD(/^T:(skull|jaw|cheek|brow|nose|ear|lip|alar|chin|socket)/,x,y,z),dh=A.minD(/^T:(beard|stache|hairSide)/,x,y,z);if(Math.min(ds,dh)<.02)n=dh<ds?'T:beard':'T:skull';}}
  const r=region(n);
  if(r==='skin'||r==='neck'||r==='hand'){c.copy(K.skin).lerp(new THREE.Color(0x8A3A2E),(1-ao)*.45+sstep(.2,-.6,ny)*.12);if(r==='skin')paintFace(x,y,z,c,K,F,{ao,smile:.004,blush:.2});{const __bb=A.minD(/^T:(beard|stache)/,x,y,z);if(__bb<.008&&r==='skin')c.lerp(K.hair,sstep(.008,0,__bb)*.85);}c.lerp(K.skinD,sstep(.75,.82,vnoise(x*110,y*110,z*110))*.15);return 0;}
  if(r==='hair'){c.copy(K.hair).lerp(K.hairD,(1-ao)*.5+Math.pow(Math.abs(Math.sin(x*140+y*30)),6)*.15);return 0;}
  if(r==='boot'){c.copy(K.boot).lerp(new THREE.Color(0x0A0810),(1-ao)*.6).lerp(K.silverD,sstep(.6,1,ny)*.2);return 0;}if(r==='sole'){c.copy(K.sole);return 0;}
  if(/scarf/.test(n)){clothShade(c,K,K.silver,K.silverL,K.silverD,ny,nz,ao,x,y,z,.06);return 0;}
  if(/^T:(hood|hoodTip)/.test(n)){// starry lining shows round the face opening
   const e=Math.hypot((x-cut.c[0])/cut.r[0],(y-cut.c[1])/cut.r[1],(z-cut.c[2])/cut.r[2]);if(e<1.16&&nz>-.2){c.copy(K.navy).multiplyScalar(.7+.3*ao);c.lerp(K.silver,sstep(1.08,1.12,e)*.9);return 0;}
   clothShade(c,K,K.indigo,K.indigoL,K.indigoD,ny,nz,ao,x,y,z,.05);return 0;}
  if(/mantle/.test(n)){clothShade(c,K,K.indigo,K.indigoL,K.indigoD,ny,nz,ao,x,y,z,.05);const hb=F.P(0,.78,0)[1];c.lerp(K.silver,sstep(.006,0,Math.abs(y-hb+Math.abs(Math.sin(Math.atan2(x,z)*5))*.02))*.7);return 0;}
  if(r==='robe'){// cloak: open at the front over a silver tunic; the turned-back edges show the star map
   const ax=Math.abs(x),w=.032+(F.P(0,.62,0)[1]-y)*.14;if(nz>.2&&ax<w){clothShade(c,K,K.silver,K.silverL,K.silverD,ny,nz,ao,x,y,z,.05);return 0;}
   if(nz>.1&&ax<w+.03){starry(c,x,y,z,ao);c.lerp(K.silver,sstep(.005,0,Math.abs(ax-w-.03))*.9);return 0;}
   clothShade(c,K,K.indigo,K.indigoL,K.indigoD,ny,nz,ao,x,y,z,.05);const hb=F.P(0,.2,0)[1];c.lerp(K.silver,sstep(hb+.01,hb,y)*sstep(hb-.02,hb-.01,y)*.8);return 0;}
  if(r==='legs'){clothShade(c,K,new THREE.Color(0x3A3A52),new THREE.Color(0x6A6A88),new THREE.Color(0x1A1A2A),ny,nz,ao,x,y,z,.05);return 0;}
  if(r==='sleeve'||r==='cuff'){clothShade(c,K,K.indigo,K.indigoL,K.indigoD,ny,nz,ao,x,y,z,.05);if(r==='cuff')c.lerp(K.silver,.8);return 0;}
  // torso under the cloak: silver tunic at the front, cloak colour at the sides and back
  if(nz>.35&&Math.abs(x)<.07){clothShade(c,K,K.silver,K.silverL,K.silverD,ny,nz,ao,x,y,z,.05);if(Math.abs(x)<.005)c.lerp(K.silverD,.5);return 0;}
  clothShade(c,K,K.indigo,K.indigoL,K.indigoD,ny,nz,ao,x,y,z,.05);return 0;},
 accessories(A){const G=new THREE.Group();const Pt=parts(A,G);const{PB,add,irisTex,eye}=Pt;const T=THREE;
  const tex=irisTex('#060612','#3A4A7A','#9AB0D8','#10142A',{pup:.3,human:true});
  for(const s of[-1,1])eye(s,{human:true,skin:COL.skin,lash:COL.hairD??0x1A0C08,r:HR(.028),ctr:HP(0,1.035,.02),dir:[.46,-.03,1],off:-.009,tex,lid:COL.skinD,lidCut:.28,lidTilt:.32,yaw:.36,irisK:1.35});
  G.add(sageBrows(Pt,F,{col:COL.hairD??COL.hair}));
  const brass=PB(COL.brass,{metalness:1,roughness:.3}),silver=PB(COL.silver,{metalness:1,roughness:.25}),wood=PB(COL.wood,{roughness:.75});
  // walking stick in the right hand, a compass on top with a needle that never settles
  {const w=F.j.wr(1);const g=new T.Group();g.userData.bone='haR';g.position.set(w[0]+.012,w[1]-.05,w[2]+.03);g.rotation.set(.08,0,-.05);G.add(g);
   const pts=[];for(let i=0;i<=12;i++){const u=i/12;pts.push(new T.Vector3(Math.sin(u*9)*.006,-.44+u*.84,Math.cos(u*7)*.006));}add(new T.TubeGeometry(new T.CatmullRomCurve3(pts),40,.011,8),wood,null,null,null,g);
   add(new T.CylinderGeometry(.013,.009,.03,10),silver,[0,-.44,0],null,null,g);for(const y of[.3,.34])add(new T.TorusGeometry(.013,.003,6,16),silver,[0,y,0],[Math.PI/2,0,0],null,g);
   const cp=new T.Group();cp.position.set(0,.43,0);cp.rotation.set(Math.PI/2-.35,0,0);g.add(cp);
   add(new T.CylinderGeometry(.045,.045,.018,32),brass,[0,0,0],[Math.PI/2,0,0],null,cp);add(new T.TorusGeometry(.045,.006,8,32),silver,[0,0,.009],null,null,cp);
   {const fc=document.createElement('canvas');fc.width=fc.height=128;const x=fc.getContext('2d');x.fillStyle='#F4ECD8';x.fillRect(0,0,128,128);x.strokeStyle='#2E2A6A';x.lineWidth=3;x.beginPath();x.arc(64,64,54,0,TAU);x.stroke();x.fillStyle='#2E2A6A';x.font='bold 18px serif';x.textAlign='center';x.textBaseline='middle';['N','E','S','W'].forEach((l,i)=>{const a=i*Math.PI/2-Math.PI/2;x.fillText(l,64+Math.cos(a)*40,64+Math.sin(a)*40);});
    for(let i=0;i<16;i++){const a=i/16*TAU;x.beginPath();x.moveTo(64+Math.cos(a)*50,64+Math.sin(a)*50);x.lineTo(64+Math.cos(a)*(i%4?46:42),64+Math.sin(a)*(i%4?46:42));x.stroke();}const t=new T.CanvasTexture(fc);t.colorSpace=T.SRGBColorSpace;
    add(new T.CircleGeometry(.04,32),new T.MeshStandardMaterial({map:t,roughness:.6}),[0,0,.0095],null,null,cp);}
   const nd=new T.Group();nd.position.z=.012;nd.userData.spin=[1.3,.9];cp.add(nd);add(new T.ConeGeometry(.007,.032,4),PB(0xC03030,{roughness:.4}),[0,.016,0],null,[1,1,.3],nd);add(new T.ConeGeometry(.007,.032,4),silver,[0,-.016,0],[0,0,Math.PI],[1,1,.3],nd);
   add(new T.SphereGeometry(.041,24,10,0,TAU,0,Math.PI/2),PB(0xEAF2FF,{roughness:.02,transmission:.9,thickness:.01,transparent:true,opacity:.35,clearcoat:1}),[0,0,.009],[Math.PI/2,0,0],[1,1,.25],cp);
   add(new T.TorusGeometry(.012,.004,8,16),brass,[0,.052,0],null,null,cp);}
  // small silver clasp at the scarf
  {const b=add(new T.SphereGeometry(.014,14,10),silver,P(0,.9,.105),null,[1,1,.6],G);b.userData.bone='chest';}
  // Copy (power 1): star glyphs lift off and circle the crew
  {const fx=new T.Group();fx.userData.bone='root';fx.userData.fx='copy';fx.userData.fxMode='show';fx.position.set(0,.02,0);G.add(fx);const m=new T.MeshBasicMaterial({color:0xE8ECFF,transparent:true,opacity:.8,depthWrite:false,blending:T.AdditiveBlending,side:T.DoubleSide});
   add(new T.RingGeometry(.4,.415,64),m,[0,0,0],[-Math.PI/2,0,0],null,fx);const sp=new T.Group();sp.userData.spin=1.2;sp.userData.spinAx='y';fx.add(sp);
   for(let i=0;i<8;i++){const a=i/8*TAU;const s=new T.Shape();for(let k=0;k<10;k++){const r=k%2?.012:.03,b=k/10*TAU;k?s.lineTo(Math.cos(b)*r,Math.sin(b)*r):s.moveTo(Math.cos(b)*r,Math.sin(b)*r);}add(new T.ShapeGeometry(s),m,[Math.cos(a)*.4,.5+Math.sin(i*1.7)*.12,Math.sin(a)*.4],[0,-a,0],null,sp);}}
  // Rift (power 2): a starry doorway opens in front
  {const fx=new T.Group();fx.userData.bone='root';fx.userData.fx='rift';fx.userData.fxMode='show';fx.position.set(0,.55,.6);G.add(fx);
   const rc=document.createElement('canvas');rc.width=rc.height=256;{const x=rc.getContext('2d');const g=x.createRadialGradient(128,128,0,128,128,128);g.addColorStop(0,'#8A7AFF');g.addColorStop(.6,'#2A1A6A');g.addColorStop(1,'rgba(10,8,40,0)');x.fillStyle=g;x.fillRect(0,0,256,256);for(let i=0;i<120;i++){x.fillStyle='rgba(255,248,220,'+(.4+Math.random()*.6)+')';const r=Math.random()*1.8+.4;x.beginPath();x.arc(Math.random()*256,Math.random()*256,r,0,TAU);x.fill();}}
   const rt=new T.CanvasTexture(rc);rt.colorSpace=T.SRGBColorSpace;const d=add(new T.CircleGeometry(.36,48),new T.MeshBasicMaterial({map:rt,transparent:true,depthWrite:false,side:T.DoubleSide}),[0,0,0],null,[.75,1.1,1],fx);d.userData.spin=.4;
   const rim=add(new T.TorusGeometry(.36,.012,8,64),new T.MeshBasicMaterial({color:0xC8D0FF,transparent:true,opacity:.9,blending:T.AdditiveBlending,depthWrite:false}),[0,0,0],null,[.75,1.1,1],fx);}
  // Tailwind (power 3): ribbons of wind spiral round the crew
  {const fx=new T.Group();fx.userData.bone='root';fx.userData.fx='wind';fx.userData.fxMode='show';fx.position.set(0,0,0);G.add(fx);const sp=new T.Group();sp.userData.spin=3;sp.userData.spinAx='y';fx.add(sp);const m=new T.MeshBasicMaterial({color:0xDCE4FF,transparent:true,opacity:.5,depthWrite:false,blending:T.AdditiveBlending,side:T.DoubleSide});
   for(let k=0;k<3;k++){const pts=[];for(let i=0;i<=40;i++){const u=i/40,a=u*TAU*.8+k*TAU/3;pts.push(new T.Vector3(Math.cos(a)*(.38+u*.06),.15+u*.9,Math.sin(a)*(.38+u*.06)));}add(new T.TubeGeometry(new T.CatmullRomCurve3(pts),80,.008,5),m,null,null,null,sp);}}
  return G;}};
export const S=makeSculpt(def);
const cfg={name:'wanderer',J:F.J,TIP:F.TIP,TORSO:F.TORSO,AIM:[],floor:.006,pivot:.5,shMin:-2.2,springs:[['earL','vx',-.3,80,6,0,.3],['tail','vy',-.25,90,8,0,.15]]};
const RK=makeRigKit(S,cfg);export const makeRig=RK.makeRig,skinGeo=RK.skinGeo;
const stick={shR:[-.25,0,.1],elR:[-.5,0,0]};
export const CLIPS=stdClips({w:.12,arm:.3,x:{
 idle:{label:'Idle',len:5,f:t=>{const b=Math.sin(t*TAU/5)*.5+.5;return{sq:b*.01,hx:.04,hy:Math.sin(t*.5)*.2,hz:Math.sin(t*.6)*.03,eye:blink(t,4.2,.5)*.9,b:merge(stick,{chest:[-b*.02,0,0],shL:[-.1,0,-.05],elL:[-.3,0,0]})};}},
 idle2:{label:'Idle 2',len:6,f:t=>{const u=cyc(t,6);const far=bump(u,.15,.75);return{hx:-.12*far,hy:.35*far,eye:1-.35*far,b:merge(stick,{shL:[-1.6*far-.1*(1-far),0,.1*far],elL:[-1.8*far-.3,0,0],haL:[.4*far,0,0],chest:[-.05*far,0,0]})};}},
 p1:{label:'Copy',len:3.4,f:t=>{const u=cyc(t,3.4);const k=ease(sstep(.05,.3,u))*(1-sstep(.86,1,u));return{hx:-.15*k,eye:1+k*.2,copy:sstep(.2,.4,u)*(1-sstep(.9,1,u)),b:merge(stick,{shL:[-2*k-.1*(1-k),0,-.2*k],elL:[-.2*k-.3*(1-k),0,0],haL:[-.4*k,0,0],chest:[-.08*k,0,0]})};}},
 p2:{label:'Rift',len:3.4,f:t=>{const u=cyc(t,3.4);const k=ease(sstep(.05,.25,u))*(1-sstep(.86,1,u));const tap=bump(u,.25,.35);return{y:tap*.02,rift:sstep(.3,.5,u)*(1-sstep(.9,1,u)),b:{shR:[-.9*k-.25*(1-k),0,.1],elR:[-.3*k-.5*(1-k),0,0],shL:[-1.2*k-.1*(1-k),0,-.3*k],elL:[-.3,0,0],chest:[-.05*k,0,0]}};}},
 p3:{label:'Tailwind',len:3.2,f:t=>{const u=cyc(t,3.2);const k=ease(sstep(.05,.3,u))*(1-sstep(.85,1,u));const sw=Math.sin(u*TAU*2)*k;return{hy:sw*.2,rz:sw*.04,wind:k,b:merge(stick,{shL:[-.8*k,.4*sw,-.9*k],elL:[-.3,0,0],hips:[0,sw*.3,0]})};}},
 guard:{label:'On guard',len:5,f:t=>{const u=cyc(t,5);return{hy:Math.sin(u*TAU)*.3,hx:.05,eye:.85,b:{shR:[-.6,0,.02],elR:[-.9,0,0],shL:[-.7,0,.3],elL:[-1.4,0,0],chest:[.06,0,0]}};}},
 work:{label:'Reads the stars',len:5,f:t=>{const u=cyc(t,5);const look=bump(u,.1,.9);return{hx:-.35*look,eye:1-.2*look,b:merge(stick,{shL:[-.9*look-.1,0,-.1],elL:[-1.1*look-.3,0,0],haL:[.3*look,0,0],chest:[-.1*look,0,0]})};}},
 nap:{label:'Rest',len:6,f:t=>{const b=Math.sin(t*TAU/6)*.5+.5;return{y:-.34,sq:-.02,hx:.35,eye:.1,b:{thL:[-1.5,0,-.2],knL:[1.9,0,0],thR:[-1.5,0,.2],knR:[1.9,0,0],shL:[-.5,0,.2],elL:[-1,0,0],shR:[-.5,0,-.2],elR:[-1,0,0],chest:[.28+b*.03,0,0]}};}}}});
{const W=CLIPS.walk.f;CLIPS.walk.f=t=>{const p=W(t);p.b=merge(p.b||{},{shR:[-.2-(p.b.shR?p.b.shR[0]:0),0,.1],elR:[-.4-(p.b.elR?p.b.elR[0]:0),0,0]});return p;};}
export const EXPR={
 happy:{label:'Knowing',hx:-.02,hz:.06,eye:.8,b:stick},
 focus:{label:'Far sight',hx:-.12,hy:.3,eye:.55,b:merge(stick,{shL:[-1.6,0,.1],elL:[-1.8,0,0]})},
 startled:{label:'Wide awake',hx:-.1,eye:1.25,eyeW:1.06,b:stick},
 caught:{label:'Weary',hx:.4,hz:.1,eye:.3,b:{chest:[.25,0,0],shR:[.1,0,-.1],shL:[.15,0,.1]}}};
export const build=o=>S.build(o),loadBaked=(u,r)=>S.loadBaked(u,r);
export const BIN='wanderer.bin?v=1',RES=.0095,GAME_SCALE=1;
export const EMBERS=[['head',HP(0,1.25,-.05)],['haR',P(.2,1,.1)],['tail',P(0,.6,-.2)]];
export const ROUTE=[{to:[1.1,-.4],clip:'walk',sp:.22},{at:true,clip:'work',dur:5,face:[2,-1]},{to:[-.7,1],clip:'walk',sp:.22},{at:true,clip:'idle2',dur:6,face:[1,3]},{at:true,clip:'idle',dur:5,face:[1,3]},{to:[.2,.2],clip:'walk',sp:.2},{at:true,clip:'guard',dur:5,face:[2,2]}];
export const HERO={cam:[2.05,1.2,2.8],target:[0,.7,0],clip:'idle'};
