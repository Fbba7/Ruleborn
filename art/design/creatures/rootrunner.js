import * as THREE from 'three';
import {makeSculpt,makeRigKit,stdClips,sstep,vnoise,clamp,ease,bump,blink,cyc,TAU,merge,gait} from './creature-kit.js';
import {parts} from './creature-parts.js';
// ============ ROOTRUNNER · Carrier · Life · root-legged sprout with a basket, 0.8 m, green and brown (GDD 11.4) ============
const COL={bark:0x6E4228,barkL:0x9A6440,barkD:0x33190A,face:0xF0DCB0,faceD:0xC8A070,leaf:0x5CAE4A,leafD:0x2E6A2A,moss:0x7AB84A,blush:0xE8886A,root:0x6A4226,rootD:0x3A2210,mouth:0x3A1A0E,nose:0x5A3018};
const K=Object.fromEntries(Object.entries(COL).map(([k,v])=>[k,new THREE.Color(v)]));
const mir=(p,s)=>[p[0]*s,p[1],p[2]];let A0=null;
const def={name:'rootrunner',box:[[-.26,0,-.26],[.26,.86,.24]],res:.0052,warm:0x2A1406,aoWarm:.24,sheen:0xFFE4B8,rim:0xFFE0B0,
 bodyMat:{roughness:.72,sheen:.25,sheenRoughness:.5},fur:{shells:0},
 sculpt(A){const{E,C}=A;A0=A;
  // acorn-shaped trunk body, wide round head with a broad flat face
  E('T:body',[0,.3,0],[.13,.14,.12],null,.06);E('T:belly',[0,.27,.05],[.1,.1,.08],null,.05);C('T:neck',[0,.38,0],[0,.43,.01],.075,.085,.05);
  E('T:head',[0,.57,.01],[.19,.165,.16],null,.06);E('T:face',[0,.54,.09],[.16,.12,.08],null,.05);E('T:brow',[0,.62,.1],[.15,.04,.06],null,.035);
  for(const s of[-1,1])E('T:cheek'+(s<0?'L':'R'),mir([.1,.5,.1],s),[.06,.05,.05],null,.035);
  E('T:nose',[0,.525,.165],[.024,.018,.018],null,.012);
  // bark ridges down the back and a knot on the belly
  for(let k=0;k<5;k++){const a=Math.PI+(k-2)*.38;C('T:ridge'+k,[Math.sin(a)*.12,.2,Math.cos(a)*.11],[Math.sin(a)*.1,.4,Math.cos(a)*.1],.012,.009,.02);}
  E('T:knot',[.03,.26,.12],[.02,.018,.012],null,.012);
  for(const s of[-1,1]){const L=s<0?'L':'R';
   // twig arms with three-twig hands
   const sh=mir([.11,.36,.0],s),el=mir([.17,.28,.03],s),wr=mir([.19,.2,.07],s);C('sh'+L+':arm1',sh,el,.03,.024,.02);C('el'+L+':arm2',el,wr,.024,.02,.015);
   E('ha'+L+':palm',mir([.195,.18,.08],s),[.026,.022,.02],null,.012);for(let k=0;k<3;k++){const a=(k-1)*.55;C('ha'+L+':twig'+k,mir([.198,.17,.085],s),mir([.2+Math.sin(a)*.025*s,.125,.095+Math.cos(a)*.02],s),.009,.005,.006);}
   // root legs: thick at the hip, splitting into rootlet toes
   C('th'+L+':leg1',mir([.06,.2,0],s),mir([.075,.1,.01],s),.045,.035,.03);C('kn'+L+':leg2',mir([.075,.1,.01],s),mir([.08,.03,.02],s),.035,.03,.02);
   E('ft'+L+':foot',mir([.08,.022,.04],s),[.045,.02,.05],null,.015);for(let k=0;k<4;k++){const a=(k-1.5)*.45;C('ft'+L+':root'+k,mir([.08,.016,.06],s),mir([.08+Math.sin(a)*.06,.006,.06+Math.cos(a)*.05],s),.013,.004,.006);}}
  E('tail:stub',[0,.2,-.12],[.03,.028,.025],null,.02);},
 disp(x,y,z,d){if(Math.abs(d)>.035)return d;const face=sstep(.03,.006,A0.minD(/^T:(face|cheek|nose|brow)/,x,y,z));
  const grain=Math.sin(Math.atan2(x,z)*15+vnoise(x*9,y*5,z*9)*7+y*6)*.5+.5;return d+(1-face)*(Math.pow(grain,6)*-.0016+(vnoise(x*60,y*20,z*60)-.5)*.0016)+(vnoise(x*120,y*120,z*120)-.5)*.0005;},
 paint(x,y,z,nx,ny,nz,ao,c,A){
  c.copy(K.bark).lerp(K.barkL,sstep(.2,.95,ny)*.28+sstep(.3,.9,nz)*.08).lerp(K.barkD,(1-ao)*.55+sstep(-.1,-.8,ny)*.2);
  let grv=0;{const g=Math.sin(Math.atan2(x,z)*13+vnoise(x*9,y*5,z*9)*6+y*5)*.5+.5;grv=sstep(.8,.95,g);c.lerp(K.barkD,grv*.55).lerp(K.barkL,sstep(.3,.05,g)*.18).lerp(K.barkD,vnoise(x*40,y*12,z*40)*.1);}
  // pale heartwood face and cheeks
  const fc=sstep(.02,.002,A.minD(/^T:(face|cheek)/,x,y,z))*sstep(.07,.12,z)*sstep(.63,.6,y);c.lerp(K.face,fc);c.lerp(K.faceD,fc*(1-ao)*.4);
  c.lerp(K.blush,sstep(.03,0,Math.hypot(Math.abs(x)-.11,y-.495,(z-.13)*1.4))*.45);
  // moss patches on shoulders and the top of the head
  const MS=new THREE.Color(0x4E7A2E),MSL=new THREE.Color(0x86A84A);const mv=vnoise(x*14,y*14,z*14);const ms=sstep(.55,.72,mv)*sstep(.45,.9,ny)*sstep(.64,.7,y)*(1-fc);c.lerp(MS,ms*.9).lerp(MSL,ms*sstep(.7,.85,mv)*.5);{const ms2=sstep(.58,.72,vnoise(x*18+3,y*18,z*18))*sstep(.4,.85,ny)*sstep(.36,.4,y)*sstep(.46,.43,y);c.lerp(MS,ms2*.85);}
  if(A.minD(/^(th|kn|ft)[LR]:/,x,y,z)<.004)c.copy(K.root).lerp(K.rootD,(1-ao)*.55+sstep(0,-.8,ny)*.3).lerp(K.barkL,vnoise(x*80,y*30,z*80)*.18);
  if(A.dist('T:nose',x,y,z)<.004)c.lerp(K.nose,.75);
  if(z>.13&&Math.abs(x)<.03){const u=x/.03,cy=.483-.008*(1-u*u);const d=Math.abs(y-cy);const w=.0026*(1-u*u*.6);if(d<w)c.copy(K.mouth);else if(d<w+.003)c.lerp(K.mouth,.35*(1-(d-w)/.003));}
  if(A.dist('T:knot',x,y,z)<.004)c.lerp(K.barkD,.6);
  return 0;},
 accessories(A){const G=new THREE.Group();const P=parts(A,G);const{PB,add,onSurf,irisTex,eye}=P;
  const tex=irisTex('#0A0602','#3A5A1A','#8AB84A','#1A1206',{pup:.34});
  for(const s of[-1,1])eye(s,{r:.05,ctr:[0,.53,.02],dir:[.5,-.02,1],off:-.016,tex,lid:COL.barkD,lidCut:.26,yaw:.4,irisK:1.3});
  // sprout on top: two big leaves on a curled stem
  const lm=PB(0x5CAE4A,{roughness:.45,sheen:.5,sheenColor:new THREE.Color(0xC8F0A0),side:THREE.DoubleSide});
  const leafGeo=(len,wid)=>{const s=new THREE.Shape();s.moveTo(0,0);s.bezierCurveTo(wid,len*.25,wid*.8,len*.8,0,len);s.bezierCurveTo(-wid*.8,len*.8,-wid,len*.25,0,0);const g=new THREE.ShapeGeometry(s,18);const p=g.attributes.position;
   for(let i=0;i<p.count;i++){const px=p.getX(i),py=p.getY(i);p.setZ(i,-Math.pow(px/wid,2)*wid*.4+Math.sin(py/len*3)*len*.05);}g.computeVertexNormals();
   const col=[];for(let i=0;i<p.count;i++){const t=p.getY(i)/len,e=Math.abs(p.getX(i))/wid;const c=new THREE.Color(0x2E6A2A).lerp(new THREE.Color(0x7ACB5A),Math.pow(t,.7)).lerp(new THREE.Color(0x2E6A2A),sstep(.06,0,Math.abs(p.getX(i)))*.6).lerp(new THREE.Color(0xA8E07A),e*.25);col.push(c.r,c.g,c.b);}g.setAttribute('color',new THREE.Float32BufferAttribute(col,3));return g;};
  const lv=PB(0xB8FF9A,{vertexColors:true,roughness:.38,sheen:.5,sheenColor:new THREE.Color(0xC8F0A0),side:THREE.DoubleSide,clearcoat:.2});
  for(const s of[-1,1]){const g=new THREE.Group();g.userData.bone=s<0?'earL':'earR';g.position.set(s*.02,.72,-.01);g.rotation.set(-.35,0,-s*.85);G.add(g);add(leafGeo(.2,.075),lv,null,null,null,g);}
  {const g=new THREE.Group();g.userData.bone='head';g.position.set(0,.715,0);G.add(g);const cu=new THREE.Curve();cu.getPoint=(t,o=new THREE.Vector3())=>o.set(Math.sin(t*4)*.012*t,t*.05,-t*.01);add(new THREE.TubeGeometry(cu,24,.009,8),PB(0x4A8A32,{roughness:.5}),[0,-.03,0],null,null,g);}
  // woven basket on the back, with straps and a spare seed pod
  const wick=PB(0xC8964E,{roughness:.8}),wickD=PB(0x8A5A2A,{roughness:.85}),lea=PB(0x5A3218,{roughness:.75});
  {const g=new THREE.Group();g.userData.bone='chest';g.position.set(0,.34,-.2);g.rotation.set(-.1,0,0);G.add(g);
   const pts=[];for(let i=0;i<=10;i++){const t=i/10;pts.push(new THREE.Vector2(.07+Math.sin(t*1.5)*.055,t*.2));}const lat=new THREE.LatheGeometry(pts,32);
   {const p=lat.attributes.position;const col=[];for(let i=0;i<p.count;i++){const a=Math.atan2(p.getX(i),p.getZ(i)),y=p.getY(i);const w=(Math.sin(a*18+Math.floor(y*60)%2*Math.PI)>0)?1:0;const c=new THREE.Color(0xC8964E).lerp(new THREE.Color(0x8A5A2A),w*.55+sstep(.04,0,y)*.3);col.push(c.r,c.g,c.b);}lat.setAttribute('color',new THREE.Float32BufferAttribute(col,3));}
   const bm=PB(0xFFFFFF,{vertexColors:true,roughness:.85,side:THREE.DoubleSide});add(lat,bm,[0,-.1,0],null,null,g);
   add(new THREE.TorusGeometry(.124,.008,8,40),wickD,[0,.1,0],[Math.PI/2,0,0],null,g);add(new THREE.TorusGeometry(.072,.007,8,32),wickD,[0,-.1,0],[Math.PI/2,0,0],null,g);
   add(new THREE.SphereGeometry(.05,16,12),PB(0x8AC84A,{roughness:.5,sheen:.4}),[.03,.1,.02],null,[1,1.2,1],g);add(new THREE.SphereGeometry(.035,14,10),PB(0xE8A84A,{roughness:.55}),[-.04,.09,-.02],null,null,g);
   add(new THREE.SphereGeometry(.03,14,10),PB(0xD84A3A,{roughness:.4,clearcoat:.5}),[.0,.1,-.05],null,null,g);}
  for(const s of[-1,1]){const g=new THREE.Group();g.userData.bone='chest';G.add(g);const cu=new THREE.CatmullRomCurve3([new THREE.Vector3(s*.06,.44,-.12),new THREE.Vector3(s*.1,.44,.02),new THREE.Vector3(s*.11,.36,.1),new THREE.Vector3(s*.1,.26,.08),new THREE.Vector3(s*.08,.22,-.1)]);add(new THREE.TubeGeometry(cu,30,.008,6),lea,null,null,[1,1,1],g);}
  // Life leaf badge on the chest strap
  {const g=new THREE.Group();g.userData.bone='chest';g.position.set(-.1,.36,.105);g.rotation.set(0,-.4,.3);G.add(g);const sh=new THREE.Shape();sh.moveTo(0,-.018);sh.quadraticCurveTo(.018,0,0,.02);sh.quadraticCurveTo(-.018,0,0,-.018);
   add(new THREE.ExtrudeGeometry(sh,{depth:.004,bevelEnabled:true,bevelSize:.002,bevelThickness:.002,bevelSegments:1}),PB(0xC8FFB0,{emissive:0x5CC46A,emissiveIntensity:1.4}),null,null,null,g);}
  // root bridge (ability): roots that grow forward from its feet
  const fx=new THREE.Group();fx.userData.bone='root';fx.userData.fx='split';fx.userData.fxMode='grow';fx.userData.fxBase=0;fx.userData.fxGain=1;fx.position.set(0,.01,.08);G.add(fx);
  const rm=PB(0x6A4226,{roughness:.8}),gm=PB(0x7AB84A,{emissive:0x3A8A2A,emissiveIntensity:.35});
  for(let k=0;k<5;k++){const x=(k-2)*.05;const cu=new THREE.CatmullRomCurve3([new THREE.Vector3(x,0,0),new THREE.Vector3(x*1.3,.03,.18),new THREE.Vector3(x*1.1,.02,.38),new THREE.Vector3(x*.8,0,.58)]);add(new THREE.TubeGeometry(cu,24,.018-.002*Math.abs(k-2),6),rm,null,null,null,fx);
   add(new THREE.SphereGeometry(.018,8,6),gm,[x*1.2,.04,.2+k*.07],null,[1,.6,1.4],fx);}
  return G;}};
export const S=makeSculpt(def);
const J={root:[null,[0,0,0]],hips:['root',[0,.24,0]],chest:['hips',[0,.36,0]],head:['chest',[0,.44,.01]],earL:['head',[-.02,.72,0]],earR:['head',[.02,.72,0]],
 shL:['chest',[-.11,.36,0]],elL:['shL',[-.17,.28,.03]],haL:['elL',[-.19,.2,.07]],shR:['chest',[.11,.36,0]],elR:['shR',[.17,.28,.03]],haR:['elR',[.19,.2,.07]],
 thL:['hips',[-.06,.2,0]],knL:['thL',[-.075,.1,.01]],ftL:['knL',[-.08,.03,.02]],thR:['hips',[.06,.2,0]],knR:['thR',[.075,.1,.01]],ftR:['knR',[.08,.03,.02]],tail:['hips',[0,.2,-.11]]};
const cfg={name:'rootrunner',J,TIP:{haL:[-.2,.125,.095],haR:[.2,.125,.095],ftL:[-.08,.006,.1],ftR:[.08,.006,.1]},
 TORSO:{hips:[[0,.14,0],[0,.36,0],.15],chest:[[0,.3,0],[0,.44,0],.13],head:[[0,.42,.01],[0,.76,.02],.21]},
 AIM:[],floor:.004,pivot:.24,shMin:-1.9,springs:[['earL','vx',-.4,120,6,0,.45],['earR','vx',-.4,120,6,0,.45],['tail','vy',-.2,130,10,0,.1]]};
const RK=makeRigKit(S,cfg);export const makeRig=RK.makeRig,skinGeo=RK.skinGeo;
export const CLIPS=stdClips({w:.45,arm:.36,x:{
 idle:{label:'Idle',len:4,f:t=>{const u=cyc(t,4);const b=Math.sin(u*TAU)*.5+.5;const look=bump(u,.5,.85);return{sq:b*.016,hz:Math.sin(u*TAU)*.05,hy:look*.35,hx:.04,eye:blink(t,4,.7),b:{chest:[-b*.03,0,0],shL:[-.25,0,.12],shR:[-.25,0,-.12],elL:[-.55,0,0],elR:[-.55,0,0]}};}},
 idle2:{label:'Idle 2',len:4.4,f:t=>{const u=cyc(t,4.4);const tidy=bump(u,.15,.75);const brush=Math.sin(t*14)*tidy;return{hx:.2*tidy,hz:.08*tidy,eye:1-tidy*.2,b:{chest:[.12*tidy,0,0],shR:[-1.2*tidy,0,-.4*tidy],elR:[-1.1*tidy+brush*.3,0,0],haR:[brush*.4,0,0],shL:[-.2,0,.1],elL:[-.5,0,0]}};}},
 ability:{label:'Root bridge',len:2.8,f:t=>{const u=cyc(t,2.8);const plant=ease(sstep(.05,.3,u))*(1-sstep(.85,1,u)),grow=sstep(.25,.7,u)*(1-sstep(.88,1,u));return{y:-plant*.03,sq:-plant*.05,rx:.1*plant,hx:.25*plant,eye:1-plant*.35,split:grow,b:{thL:[-.35*plant,0,-.25*plant],knL:[.5*plant,0,0],thR:[-.35*plant,0,.25*plant],knR:[.5*plant,0,0],shL:[-.9*plant,0,.5*plant],shR:[-.9*plant,0,-.5*plant],elL:[-.3,0,0],elR:[-.3,0,0]}};}},
 work:{label:'Rearranges the garden',len:4.4,f:t=>{const u=cyc(t,4.4);const dig=bump(u,.08,.45),place=bump(u,.5,.9);const w=Math.sin(t*9)*dig;return{rx:.25*dig+.15*place,hx:.3*dig+.35*place,y:-(dig+place)*.02,eye:1-place*.2,b:{chest:[.35*dig+.3*place,0,0],shL:[-1.1*dig-.9*place,0,.2],shR:[-1.1*dig-.9*place,0,-.2],elL:[-.4+w*.25,0,0],elR:[-.4-w*.25,0,0],haL:[.4*place,0,0],haR:[.4*place,0,0]}};}},
 nap:{label:'Nap',len:4.6,f:t=>{const b=Math.sin(t*TAU/4.6)*.5+.5;return{y:-.07,sq:-.06+b*.03,rx:.06,hx:.4,hz:.2,eye:.04,b:{thL:[-1.45,0,-.35],knL:[1.7,0,0],thR:[-1.45,0,.35],knR:[1.7,0,0],shL:[-.6,0,.35],elL:[-1.3,0,0],shR:[-.6,0,-.35],elR:[-1.3,0,0],chest:[.28+b*.04,0,0]}};}}}});
export const EXPR={
 happy:{label:'Pleased',hz:-.12,hx:.04,eye:.88,b:{shL:[-.4,0,.3],shR:[-.4,0,-.3],elL:[-.9,0,0],elR:[-.9,0,0]}},
 focus:{label:'Busy',hx:.22,hz:.06,eye:.7,b:{shL:[-1.1,0,.35],shR:[-1.1,0,-.35],elL:[-1.1,0,0],elR:[-1.1,0,0],chest:[.12,0,0]}},
 startled:{label:'Startled',hx:-.15,eye:1.2,eyeW:1.08,b:{shL:[-.3,0,-.9],shR:[-.3,0,.9]}},
 caught:{label:'Droopy',hx:.36,hz:.12,eye:.55,b:{chest:[.25,0,0],shL:[.15,0,.1],shR:[.15,0,-.1]}}};
export const build=o=>S.build(o),loadBaked=(u,r)=>S.loadBaked(u,r);
export const BIN='rootrunner.bin?v=1',RES=.0052,GAME_SCALE=1.15;
export const EMBERS=[['earL',[-.14,.86,-.04]],['earR',[.14,.86,-.04]],['head',[0,.8,.0]]];
export const ROUTE=[{to:[1.1,-.4],clip:'carry',sp:.24},{at:true,clip:'work',dur:4.4,face:[2,-1]},{to:[-.7,1],clip:'walk',sp:.26},{at:true,clip:'ability',dur:2.8,face:[1,3]},{at:true,clip:'idle',dur:4,face:[1,3]},{to:[.2,.2],clip:'carry',sp:.22},{at:true,clip:'nap',dur:4.6,face:[2,2]}];
export const HERO={cam:[1.35,.72,1.7],target:[0,.42,0],clip:'idle'};
