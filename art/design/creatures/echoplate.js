import * as THREE from 'three';
import {makeSculpt,makeRigKit,stdClips,sstep,vnoise,clamp,ease,bump,blink,cyc,TAU,merge,gait} from './creature-kit.js';
import {parts} from './creature-parts.js';
// ============ ECHOPLATE · Warden · Spirit · hollow armour with a wisp inside, 1.2 m, magenta and silver (GDD 11.4) ============
const COL={steel:0xB4BCCC,steelL:0xEEF2F8,steelD:0x4A5068,trim:0xC08AD8,gold:0xD8B060,leather:0x3A2430,gap:0x2A0A26,glow:0xFF5ACD};
const K=Object.fromEntries(Object.entries(COL).map(([k,v])=>[k,new THREE.Color(v)]));
const mir=(p,s)=>[p[0]*s,p[1],p[2]];let A0=null;
const def={name:'echoplate',box:[[-.36,0,-.3],[.36,1.28,.3]],res:.0066,warm:0x1A0A20,aoWarm:.14,sheen:0xF4E8FF,rim:0xFF8AE0,
 noiseAmt:0,bodyMat:{roughness:.26,metalness:1,clearcoat:.6,clearcoatRoughness:.12,sheen:0},fur:{shells:0},
 sculpt(A){const{E,C}=A;A0=A;
  // broad breastplate and plackart, a waist and fauld
  E('T:chest',[0,.76,.01],[.2,.17,.15],null,.06);E('T:plastron',[0,.78,.08],[.17,.13,.09],null,.05);E('T:waist',[0,.58,0],[.14,.08,.11],null,.05);
  E('T:fauld',[0,.5,0],[.17,.07,.13],null,.04);for(const k of[0,2])E('T:tasset'+k,[(k-1)*.1,.44,.08],[.07,.06,.025],[.25,0,(k-1)*.25],.02);
  // helm: tall rounded great-helm with a narrow visor slit and a crest ridge
  C('T:gorget',[0,.9,0],[0,.97,.01],.1,.09,.04);E('T:helm',[0,1.07,.01],[.14,.16,.14],null,.05);E('T:helmface',[0,1.05,.08],[.12,.13,.07],null,.04);
  C('T:crest',[0,1.2,.08],[0,1.19,-.12],.02,.015,.02);E('T:visor',[0,1.06,.14],[.09,.011,.05],null,.004,'s');
  for(let k=0;k<5;k++)E('T:breath'+k,[(k-2)*.022,.99,.14],[.004,.012,.03],null,.002,'s');
  for(const s of[-1,1]){const L=s<0?'L':'R';
   // pauldrons (big rounded shoulder plates), vambraces and gauntlets
   E('sh'+L+':pauldron',mir([.22,.86,0],s),[.1,.08,.1],[0,0,s*.35],.04);E('sh'+L+':pauldron2',mir([.25,.8,0],s),[.09,.05,.09],[0,0,s*.5],.03);
   const sh=mir([.22,.82,0],s),el=mir([.28,.62,.02],s),wr=mir([.3,.44,.06],s);C('sh'+L+':arm1',sh,el,.05,.045,.03);E('el'+L+':cop',el,[.05,.05,.05],null,.02);C('el'+L+':arm2',el,wr,.045,.052,.03);
   E('ha'+L+':gauntlet',mir([.305,.4,.075],s),[.055,.055,.05],null,.025);for(let k=0;k<4;k++)C('ha'+L+':fg'+k,mir([.29+k*.01*s*0,.37,.1+ (k-1.5)*.0],s).map((v,i)=>i===0?v+(k-1.5)*.02*s:v),mir([.3+(k-1.5)*.02,.33,.11],s),.013,.012,.006);
   // cuisses, poleyns, greaves, sabatons
   C('th'+L+':leg1',mir([.09,.48,0],s),mir([.1,.27,.02],s),.07,.06,.04);E('kn'+L+':poleyn',mir([.1,.26,.05],s),[.055,.055,.04],null,.02);C('kn'+L+':leg2',mir([.1,.26,.02],s),mir([.105,.07,.0],s),.058,.05,.03);
   E('ft'+L+':sabaton',mir([.105,.04,.05],s),[.06,.04,.1],null,.025);for(let k=0;k<3;k++)E('ft'+L+':lame'+k,mir([.105,.05,.08+k*.03],s),[.058,.012,.018],null,.006);}
  E('tail:plate',[0,.5,-.12],[.1,.06,.03],null,.03);},
 disp(x,y,z,d){if(Math.abs(d)>.03)return d;
  // plate seams: shallow grooves where the lames overlap
  const seam=A0.minD(/^T:(tasset|breath)|^ft[LR]:lame/,x,y,z);const ring=Math.abs(((y*14)%1+1)%1-.5);const arm=sstep(.01,0,A0.minD(/^(el|th|kn)[LR]:(arm2|leg1|leg2)/,x,y,z));
  return d+sstep(.004,0,Math.abs(seam))*.0025+arm*sstep(.06,.0,ring-.44)*.0022+(vnoise(x*50,y*50,z*50)-.5)*.0004;},
 paint(x,y,z,nx,ny,nz,ao,c,A){
  c.copy(K.steel).lerp(K.steelL,sstep(.35,.95,ny)*.45+sstep(.5,.95,nz)*.15).lerp(K.steelD,(1-ao)*.8+sstep(-.2,-.8,ny)*.35);
  c.lerp(K.steelL,Math.pow(vnoise(x*160,y*6,z*160),3)*.25);c.lerp(K.steelD,sstep(.66,.8,vnoise(x*36,y*36,z*36))*.18);
  // magenta trim bands on the plate edges, gold rivets
  let tr=0;if(A.dist('T:plastron',x,y,z)<.004&&nz>.3){const e=Math.hypot(x/.17,(y-.78)/.13);tr=sstep(.8,.86,e)*sstep(1,.94,e);}if(A.minD(/^sh[LR]:pauldron2/,x,y,z)<.004)tr=Math.max(tr,sstep(.79,.77,y)*.9);if(A.dist('T:fauld',x,y,z)<.004)tr=Math.max(tr,sstep(.475,.465,y)*.9);c.lerp(K.trim,tr*.85);
  const rv=[[.12,.84],[-.12,.84],[.15,.7],[-.15,.7]].some(([rx,ry])=>Math.hypot(x-rx,y-ry)<.012&&z>.08);if(rv)c.copy(K.gold);
  // the wisp shows through every gap: visor, breaths, elbow and knee joints, waist
  const gapD=Math.min(A.dist('T:visor',x,y,z),A.minD(/^T:breath/,x,y,z));if(gapD<.006)c.copy(K.gap).lerp(K.glow,sstep(.006,-.004,gapD));
  const jt=Math.abs(y-.58)<.02&&nz>-.3?sstep(.02,0,Math.abs(y-.58))*.4:0;c.lerp(K.gap,jt);
  // Spirit spiral etched on the breastplate
  if(A.dist('T:plastron',x,y,z)<.004&&nz>.5){const rx=x,ry=y-.78,r=Math.hypot(rx,ry),a=Math.atan2(ry,rx);const sp=Math.abs(((r*120-a*1.6/Math.PI*2)%4+4)%4-2);c.lerp(K.trim,sstep(.05,.035,r)*sstep(.6,.2,sp)*.9);}
  if(A.minD(/^T:(waist)/,x,y,z)<.004)c.lerp(K.leather,.75);
  return 0;},
 accessories(A){const G=new THREE.Group();const P=parts(A,G);const{PB,add,onSurf}=P;
  const glowM=new THREE.MeshBasicMaterial({color:0xFFB8EE});
  // eyes: two soft magenta lights inside the visor slit
  for(const s of[-1,1]){const g=new THREE.Group();g.name=s<0?'eye_L':'eye_R';g.userData.bone='head';g.position.set(s*.04,1.06,.13);G.add(g);const e=new THREE.Mesh(new THREE.SphereGeometry(.016,16,10),glowM);e.scale.set(1.6,.55,.6);g.add(e);
   const h=new THREE.Mesh(new THREE.SphereGeometry(.03,16,10),new THREE.MeshBasicMaterial({color:0xFF5ACD,transparent:true,opacity:.35,depthWrite:false}));h.scale.set(1.6,.5,.4);g.add(h);}
  {const l=new THREE.PointLight(0xFF5ACD,.9,.6,2);l.position.set(0,1.05,.05);const g=new THREE.Group();g.userData.bone='head';G.add(g);g.add(l);}
  // wisp plume rising from the helm instead of a horsehair crest
  const plume=new THREE.Group();plume.userData.bone='earL';plume.position.set(0,1.2,-.03);G.add(plume);
  const pm=new THREE.MeshBasicMaterial({color:0xFF7ADA,transparent:true,opacity:.55,depthWrite:false,blending:THREE.AdditiveBlending,side:THREE.DoubleSide});
  for(let k=0;k<6;k++){const s=new THREE.Shape();const h=.18-k*.018,w=.035;s.moveTo(-w,0);s.quadraticCurveTo(-w*1.2,h*.5,0,h);s.quadraticCurveTo(w*1.2,h*.5,w,0);s.lineTo(-w,0);const m=new THREE.Mesh(new THREE.ShapeGeometry(s,10),pm);m.position.set(0,0,-k*.02);m.rotation.set(-.5-k*.12,k*.5,0);plume.add(m);}
  // gold helm band and a magenta cape hanging from the shoulders
  add(new THREE.TorusGeometry(.146,.013,10,40),PB(0xD8B060,{metalness:1,roughness:.3}),[0,.985,.0],[Math.PI/2,0,0],[1,1.02,1],G,'head');
  {const g=new THREE.Group();g.userData.bone='chest';g.position.set(0,.9,-.14);G.add(g);const cg=new THREE.PlaneGeometry(.4,.62,10,16);const p=cg.attributes.position;const col=[];
   for(let i=0;i<p.count;i++){const px=p.getX(i),py=p.getY(i);const t=(.31-py)/.62;p.setZ(i,-Math.cos(px*9)*.018-t*t*.06);p.setX(i,px*(1+t*.35));p.setY(i,py-.31);const c=new THREE.Color(0xA83A8C).lerp(new THREE.Color(0x5A1450),t*.8).lerp(new THREE.Color(0xE8B060),sstep(.94,1,t)*.7);col.push(c.r,c.g,c.b);}
   cg.computeVertexNormals();cg.setAttribute('color',new THREE.Float32BufferAttribute(col,3));add(cg,PB(0xFFFFFF,{vertexColors:true,roughness:.8,sheen:.6,sheenColor:new THREE.Color(0xFF9AE0),side:THREE.DoubleSide}),null,[.12,0,0],null,g);}
  // Warden shield: a tall kite shield on the left arm, silver with a magenta spiral
  const shield=new THREE.Group();shield.userData.bone='chest';shield.position.set(-.31,.57,.4);shield.rotation.set(-.06,-.28,.05);G.add(shield);
  {const strap=new THREE.Mesh(new THREE.BoxGeometry(.05,.14,.03),PB(0x5A3A2A,{roughness:.8}));strap.position.set(0,0,-.05);shield.add(strap);}
  {const s=new THREE.Shape();s.moveTo(0,.2);s.quadraticCurveTo(.15,.2,.15,.06);s.quadraticCurveTo(.15,-.12,0,-.26);s.quadraticCurveTo(-.15,-.12,-.15,.06);s.quadraticCurveTo(-.15,.2,0,.2);
   add(new THREE.ExtrudeGeometry(s,{depth:.02,bevelEnabled:true,bevelSize:.012,bevelThickness:.01,bevelSegments:3,curveSegments:24}),PB(0xC8CCDA,{metalness:.9,roughness:.25,clearcoat:.5}),[0,0,-.02],null,null,shield);
   const e=new THREE.Shape();e.moveTo(0,.17);e.quadraticCurveTo(.12,.17,.12,.05);e.quadraticCurveTo(.12,-.1,0,-.22);e.quadraticCurveTo(-.12,-.1,-.12,.05);e.quadraticCurveTo(-.12,.17,0,.17);
   add(new THREE.ShapeGeometry(e,24),PB(0x7A2A6E,{roughness:.6}),[0,0,.012],null,null,shield);
   const sp=new THREE.Curve();sp.getPoint=(t,o=new THREE.Vector3())=>{const a=t*TAU*2.2,r=.01+t*.08;return o.set(Math.cos(a)*r,Math.sin(a)*r,.014);};add(new THREE.TubeGeometry(sp,80,.006,6),PB(0xFFB8EE,{emissive:0xFF5ACD,emissiveIntensity:1.6}),null,null,null,shield);}
  // revival (ability): the shield flares into a ring of light on the ground
  const fx=new THREE.Group();fx.userData.bone='root';fx.userData.fx='split';fx.userData.fxMode='show';fx.position.set(0,.02,0);G.add(fx);
  const rm=new THREE.MeshBasicMaterial({color:0xFF7ADA,transparent:true,opacity:.6,depthWrite:false,blending:THREE.AdditiveBlending,side:THREE.DoubleSide});
  for(let k=0;k<3;k++){const r=new THREE.Mesh(new THREE.RingGeometry(.3+k*.12,.32+k*.12,64),rm);r.rotation.x=-Math.PI/2;r.position.y=k*.01;fx.add(r);}
  const col=new THREE.Mesh(new THREE.CylinderGeometry(.34,.4,1.1,32,1,true),new THREE.MeshBasicMaterial({color:0xFF9AE8,transparent:true,opacity:.18,depthWrite:false,blending:THREE.AdditiveBlending,side:THREE.DoubleSide}));col.position.y=.55;fx.add(col);
  return G;}};
export const S=makeSculpt(def);
const J={root:[null,[0,0,0]],hips:['root',[0,.5,0]],chest:['hips',[0,.72,0]],head:['chest',[0,.94,.01]],earL:['head',[0,1.2,-.03]],earR:['head',[0,1.2,-.03]],
 shL:['chest',[-.22,.82,0]],elL:['shL',[-.28,.62,.02]],haL:['elL',[-.3,.44,.06]],shR:['chest',[.22,.82,0]],elR:['shR',[.28,.62,.02]],haR:['elR',[.3,.44,.06]],
 thL:['hips',[-.09,.48,0]],knL:['thL',[-.1,.26,.02]],ftL:['knL',[-.105,.07,0]],thR:['hips',[.09,.48,0]],knR:['thR',[.1,.26,.02]],ftR:['knR',[.105,.07,0]],tail:['hips',[0,.5,-.11]]};
const cfg={name:'echoplate',J,TIP:{haL:[-.3,.33,.11],haR:[.3,.33,.11],ftL:[-.105,.01,.15],ftR:[.105,.01,.15]},
 TORSO:{hips:[[0,.42,0],[0,.62,0],.19],chest:[[0,.58,0],[0,.94,0],.24],head:[[0,.9,.01],[0,1.24,.02],.18]},
 AIM:[],floor:.006,pivot:.5,shMin:-1.7,springs:[['earL','vx',-.5,90,5,0,.5],['tail','vy',-.2,140,12,0,.1]]};
const RK=makeRigKit(S,cfg);export const makeRig=RK.makeRig,skinGeo=RK.skinGeo;
export const CLIPS=stdClips({w:.85,arm:.3,x:{
 idle:{label:'Idle',len:4.8,f:t=>{const u=cyc(t,4.8);const b=Math.sin(u*TAU)*.5+.5;return{sq:b*.008,hx:.02,hz:Math.sin(u*TAU)*.02,eye:.92+b*.1,b:{chest:[-b*.02,0,0],shL:[-.35,0,.1],elL:[-.9,0,0],shR:[-.12,0,-.08],elR:[-.3,0,0]}};}},
 idle2:{label:'Idle 2',len:5,f:t=>{const u=cyc(t,5);const look=bump(u,.15,.55),rest=bump(u,.6,.95);return{hy:Math.sin(u*TAU*2)*.4*look,hx:.1*rest,eye:1-rest*.3,b:{shL:[-.35,0,.1],elL:[-.9,0,0],shR:[-.5*rest,0,-.2*rest],elR:[-.3-.8*rest,0,0],chest:[.05*rest,0,0]}};}},
 ability:{label:'Stands over the crew',len:3,f:t=>{const u=cyc(t,3);const raise=ease(sstep(.05,.3,u))*(1-sstep(.85,1,u));return{y:-raise*.02,sq:-raise*.02,hx:-.12*raise,eye:1+raise*.3,split:raise,b:{thL:[-.2*raise,0,-.2*raise],knL:[.3*raise,0,0],thR:[.1*raise,0,.2*raise],shL:[-1.6*raise-.35*(1-raise),0,.3*raise+.1],elL:[-.6*raise-.9*(1-raise),0,0],shR:[-.3*raise,0,-.5*raise],elR:[-.3,0,0]}};}},
 work:{label:'Polishes armour nobody wears',len:4.4,f:t=>{const u=cyc(t,4.4);const rub=Math.sin(t*9)*bump(u,.05,.95);return{hx:.28,hy:-.15,rx:.06,eye:.85,b:{chest:[.12,0,0],shL:[-.9,0,.35],elL:[-1.5,0,0],shR:[-1+rub*.12,0,-.1],elR:[-1.2+rub*.2,0,0],haR:[rub*.3,0,0]}};}},
 nap:{label:'Rest',len:5,f:t=>{const b=Math.sin(t*TAU/5)*.5+.5;return{y:-.2,sq:-.02,hx:.4,eye:.2+b*.15,b:{thL:[-1.5,0,-.2],knL:[1.9,0,0],thR:[-.5,0,.25],knR:[1.2,0,0],shL:[-.5,0,.2],elL:[-1,0,0],shR:[-.4,0,-.2],elR:[-.8,0,0],chest:[.3,0,0]}};}}}});
export const EXPR={
 happy:{label:'Kindly',hz:-.08,hx:.04,eye:1.05,b:{shL:[-.35,0,.1],elL:[-.9,0,0],shR:[-.5,0,-.2],elR:[-.9,0,0]}},
 focus:{label:'On guard',hx:.12,eye:.65,b:{shL:[-1.2,0,.25],elL:[-.8,0,0],shR:[-.6,0,-.3],elR:[-.9,0,0],chest:[.08,0,0]}},
 startled:{label:'Alert',hx:-.12,eye:1.35,eyeW:1.1,b:{shL:[-.6,0,-.4],shR:[-.3,0,.6]}},
 caught:{label:'Dimmed',hx:.4,hz:.1,eye:.25,b:{chest:[.3,0,0],shL:[.2,0,.1],shR:[.2,0,-.1]}}};
export const build=o=>S.build(o),loadBaked=(u,r)=>S.loadBaked(u,r);
export const BIN='echoplate.bin?v=1',RES=.0095,GAME_SCALE=1;
export const EMBERS=[['head',[0,1.3,-.05]],['chest',[.25,.95,0]],['chest',[-.25,.95,0]]];
{const FREE=new Set(['ko','nap']);for(const k in CLIPS){if(FREE.has(k))continue;const f0=CLIPS[k].f;CLIPS[k].f=t=>{const p=f0(t);p.b=p.b||{};const o=p.b.shL||[0,0,0];p.b.shL=[-.5+o[0]*.08,0,.1];p.b.elL=[-1.1,0,0];p.b.haL=[.1,0,0];return p;};}}
export const ROUTE=[{to:[1.1,-.4],clip:'walk',sp:.22},{at:true,clip:'work',dur:4.4,face:[2,-1]},{to:[-.7,1],clip:'walk',sp:.22},{at:true,clip:'ability',dur:3,face:[1,3]},{at:true,clip:'idle',dur:4.8,face:[1,3]},{to:[.2,.2],clip:'walk',sp:.2},{at:true,clip:'nap',dur:5,face:[2,2]}];
export const HERO={cam:[1.9,1.05,2.5],target:[0,.64,0],clip:'idle'};
