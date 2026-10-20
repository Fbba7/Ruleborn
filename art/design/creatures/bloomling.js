import * as THREE from 'three';
import {makeSculpt,makeRigKit,stdClips,sstep,vnoise,clamp,ease,bump,blink,cyc,TAU,merge,gait} from './creature-kit.js';
import {parts} from './creature-parts.js';
// ============ BLOOMLING · Mender · Life · flower-headed sprite, 0.6 m, green and pink (GDD 11.4) ============
const COL={leaf:0x5FB85A,leafL:0xA8E08A,leafD:0x2E7A3A,face:0xEEF6D8,faceD:0xC8DCA8,blush:0xFF7EA8,vein:0x3E9A48,root:0x8A6A3E,rootD:0x5A4028,mouth:0x7A2A3A};
const K=Object.fromEntries(Object.entries(COL).map(([k,v])=>[k,new THREE.Color(v)]));
const mir=(p,s)=>[p[0]*s,p[1],p[2]];let A0=null;
const def={name:'bloomling',box:[[-.2,0,-.16],[.2,.52,.2]],res:.0042,warm:0x1A3A10,aoWarm:.2,sheen:0xF0FFD8,rim:0xFFD0E4,
 bodyMat:{roughness:.46,sheen:.45,sheenRoughness:.35,clearcoat:.2,clearcoatRoughness:.4},fur:{shells:0},
 sculpt(A){const{E,C}=A;A0=A;
  // a seed-bulb body under a big round face
  E('T:bulb',[0,.1,0],[.07,.075,.066],null,.05);E('T:chest',[0,.17,.0],[.052,.045,.05],null,.04);C('T:neck',[0,.18,0],[0,.24,.01],.034,.036,.03);
  E('T:head',[0,.33,.02],[.132,.12,.116],null,.05);E('T:face',[0,.315,.085],[.11,.092,.05],null,.04);
  for(const s of[-1,1])E('T:cheek'+(s<0?'L':'R'),mir([.068,.29,.085],s),[.04,.034,.036],null,.03);
  E('T:mouthcut',[0,.272,.132],[.018,.0035,.014],[.15,0,0],.003,'s');
  for(const s of[-1,1]){const L=s<0?'L':'R';
   // small leaf-tip ears poking out from under the petals
   C('ear'+L+':ear',mir([.1,.38,.0],s),mir([.15,.41,-.02],s),.022,.006,.015);
   // stem arms ending in leaf mitts
   const sh=mir([.048,.175,.0],s),el=mir([.07,.14,.02],s),wr=mir([.078,.105,.04],s);C('sh'+L+':arm1',sh,el,.015,.013,.012);C('el'+L+':arm2',el,wr,.013,.012,.008);
   E('ha'+L+':leafhand',mir([.08,.088,.05],s),[.02,.024,.01],[.3,s*.3,s*.2],.008);
   // stubby stem legs and rootlet feet
   C('th'+L+':leg',mir([.035,.07,.0],s),mir([.038,.03,.01],s),.022,.018,.016);
   E('ft'+L+':foot',mir([.04,.014,.022],s),[.024,.014,.03],null,.01);for(let k=0;k<3;k++){const a=(k-1)*.5;C('ft'+L+':root'+k,mir([.04,.01,.035],s),mir([.04+Math.sin(a)*.03,.004,.035+Math.cos(a)*.026],s),.008,.003,.004);}}
  E('tail:bud',[0,.1,-.07],[.022,.022,.02],null,.02);},
 disp(x,y,z,d){if(Math.abs(d)>.03)return d;const face=sstep(.02,.004,A0.minD(/^T:(face|cheek)/,x,y,z));const bulb=sstep(.02,.004,A0.dist('T:bulb',x,y,z));
  const ang=Math.atan2(x,z);return d+bulb*(1-face)*Math.pow(Math.abs(Math.sin(ang*4)),6)*-.002+(vnoise(x*90,y*90,z*90)-.5)*.0005;},
 paint(x,y,z,nx,ny,nz,ao,c,A){
  c.copy(K.leaf).lerp(K.leafL,sstep(.2,.95,ny)*.35+sstep(.3,.9,nz)*.12).lerp(K.leafD,(1-ao)*.45+sstep(-.1,-.8,ny)*.2);
  // pale face, pink cheeks
  const fc=sstep(.018,.0,A.minD(/^T:(face|cheek)/,x,y,z))*sstep(.04,.09,z)*sstep(.4,.37,y);c.lerp(K.face,fc);c.lerp(K.faceD,fc*(1-ao)*.35);
  c.lerp(K.blush,sstep(.028,0,Math.hypot(Math.abs(x)-.07,y-.285,(z-.11)*1.4))*.6);
  // leaf veins on the bulb and the hands; rootlet feet
  const bulb=sstep(.012,0,A.dist('T:bulb',x,y,z));const ang=Math.atan2(x,z);c.lerp(K.vein,bulb*sstep(.9,.99,Math.abs(Math.cos(ang*4)))*.45);
  if(A.minD(/^ha[LR]:/,x,y,z)<.003)c.lerp(K.leafL,.25).lerp(K.vein,sstep(.003,0,Math.abs(x)-Math.abs(A.minD(/^ha[LR]:/,x,y,z))*0-.078)*.0);
  if(A.minD(/^ft[LR]:/,x,y,z)<.004){c.copy(K.root).lerp(K.rootD,(1-ao)*.5+sstep(0,-.8,ny)*.3);}
  if(A.minD(/^ear[LR]:/,x,y,z)<.003)c.lerp(K.leafL,sstep(.4,.42,y)*.5);
  if(A.dist('tail:bud',x,y,z)<.003)c.lerp(K.blush,.7);
  if(Math.abs(A.dist('T:mouthcut',x,y,z))<.003&&z>.12)c.copy(K.mouth);
  return 0;},
 accessories(A){const G=new THREE.Group();const P=parts(A,G);const{PB,add,onSurf,irisTex,eye}=P;
  const tex=irisTex('#061808','#1E7A30','#8FE07A','#0A2A10',{pup:.34});
  for(const s of[-1,1])eye(s,{r:.052,ctr:[0,.33,.02],dir:[.46,.06,1],off:-.018,tex,lid:COL.leafD,lidCut:.22,yaw:.36,irisK:1.3});
  // petal crown: a ring of cupped pink petals framing the face
  const petalGeo=(len,wid)=>{const s=new THREE.Shape();s.moveTo(0,0);s.bezierCurveTo(wid*.9,len*.25,wid*.8,len*.85,0,len);s.bezierCurveTo(-wid*.8,len*.85,-wid*.9,len*.25,0,0);const g=new THREE.ShapeGeometry(s,16);const p=g.attributes.position;
   for(let i=0;i<p.count;i++){const px=p.getX(i),py=p.getY(i);p.setZ(i,-Math.pow(px/wid,2)*wid*.55-Math.pow(py/len,2)*len*.18);}g.computeVertexNormals();
   const col=[];for(let i=0;i<p.count;i++){const t=p.getY(i)/len;const c=new THREE.Color(0xB0184E).lerp(new THREE.Color(0xF0508C),Math.pow(t,.6)).lerp(new THREE.Color(0xFFB0CC),Math.pow(t,3)*.5);col.push(c.r,c.g,c.b);}g.setAttribute('color',new THREE.Float32BufferAttribute(col,3));return g;};
  const pm=PB(0xFFFFFF,{vertexColors:true,roughness:.5,sheen:.25,sheenColor:new THREE.Color(0xFF9AC0),side:THREE.DoubleSide,clearcoat:.15});
  const crown=new THREE.Group();crown.userData.bone='head';crown.position.set(0,.33,.075);crown.scale.setScalar(1.12);G.add(crown);
  const N=11;for(let k=0;k<N;k++){const a=k/N*TAU+Math.PI/N;if(Math.sin(a)<-.3)continue;const g=new THREE.Group();g.rotation.set(0,0,a-Math.PI/2);crown.add(g);
   const big=k%2?1:.86;const pt=add(petalGeo(.098*big,.056*big),pm,[0,.118,-.02],[.12,0,0],null,g);}
  // an inner ring of smaller petals, offset
  for(let k=0;k<N;k++){const a=k/N*TAU;const g=new THREE.Group();g.rotation.set(0,0,a-Math.PI/2);crown.add(g);if(Math.sin(a)<-.25)continue;add(petalGeo(.065,.038),pm,[0,.108,-.004],[-.2,0,0],null,g);}
  // two floppy side petals that spring with the ears
  for(const s of[-1,1]){const g=new THREE.Group();g.userData.bone=s<0?'earL':'earR';g.position.set(s*.11,.39,-.01);g.rotation.set(-.5,0,-s*1.05);G.add(g);add(petalGeo(.13,.058),pm,null,null,null,g);}
  // a sprout on top: curled tendril and two leaves
  const lm=PB(0x6FC85A,{roughness:.45,sheen:.4,side:THREE.DoubleSide});
  {const g=new THREE.Group();g.userData.bone='head';g.position.set(0,.445,.0);G.add(g);const cu=new THREE.Curve();cu.getPoint=(t,o=new THREE.Vector3())=>o.set(Math.sin(t*5)*.018*t,t*.07,Math.cos(t*5)*.018*t-.018*t);add(new THREE.TubeGeometry(cu,40,.0045,6),lm,null,null,null,g);
   for(const s of[-1,1]){const sh=new THREE.Shape();sh.moveTo(0,0);sh.quadraticCurveTo(.02,.015,0,.045);sh.quadraticCurveTo(-.02,.015,0,0);const lg=new THREE.ShapeGeometry(sh,10);add(lg,lm,[0,.035,-.006],[-.3,0,s*1.1],null,g);}}
  // leaf skirt round the bulb
  for(let k=0;k<7;k++){const a=k/7*TAU;const sh=new THREE.Shape();sh.moveTo(0,0);sh.quadraticCurveTo(.026,.03,0,.06);sh.quadraticCurveTo(-.026,.03,0,0);const g=new THREE.Group();g.userData.bone='hips';g.position.set(Math.sin(a)*.06,.15,Math.cos(a)*.056);g.rotation.set(0,a,0);G.add(g);add(new THREE.ShapeGeometry(sh,10),lm,null,[Math.PI+.5,0,0],null,g);}
  // Mender charm: glowing Life leaf on a vine necklace, and a dewdrop
  {const g=new THREE.Group();g.userData.bone='chest';g.position.set(0,.185,.052);G.add(g);const sh=new THREE.Shape();sh.moveTo(0,-.014);sh.quadraticCurveTo(.014,0,0,.016);sh.quadraticCurveTo(-.014,0,0,-.014);
   add(new THREE.ExtrudeGeometry(sh,{depth:.003,bevelEnabled:true,bevelSize:.0015,bevelThickness:.0015,bevelSegments:1}),PB(0xC8FFB0,{emissive:0x5CC46A,emissiveIntensity:1.5}),null,null,null,g);
   add(new THREE.TorusGeometry(.05,.0025,6,30),PB(0x3E8A45,{roughness:.6}),[0,.025,-.045],[Math.PI/2-.3,0,0],null,g);}
  // heal (ability): a spiral of glowing petals
  const fx=new THREE.Group();fx.userData.bone='root';fx.userData.fx='split';fx.userData.fxMode='show';fx.position.set(0,.2,0);G.add(fx);
  const gp=PB(0xFFFFFF,{vertexColors:true,emissive:0xFF8AB8,emissiveIntensity:.9,side:THREE.DoubleSide});
  for(let k=0;k<16;k++){const a=k/16*TAU*2;const r=.14+k*.008;const m=add(petalGeo(.03,.016),gp,[Math.cos(a)*r,-.12+k*.022,Math.sin(a)*r],[k,a,k*.5],null,fx);m.castShadow=false;}
  return G;}};
export const S=makeSculpt(def);
const J={root:[null,[0,0,0]],hips:['root',[0,.1,0]],chest:['hips',[0,.17,0]],head:['chest',[0,.23,.01]],earL:['head',[-.1,.38,0]],earR:['head',[.1,.38,0]],
 shL:['chest',[-.048,.175,0]],elL:['shL',[-.07,.14,.02]],haL:['elL',[-.078,.105,.04]],shR:['chest',[.048,.175,0]],elR:['shR',[.07,.14,.02]],haR:['elR',[.078,.105,.04]],
 thL:['hips',[-.035,.07,0]],knL:['thL',[-.037,.045,.005]],ftL:['knL',[-.038,.03,.01]],thR:['hips',[.035,.07,0]],knR:['thR',[.037,.045,.005]],ftR:['knR',[.038,.03,.01]],tail:['hips',[0,.1,-.06]]};
const cfg={name:'bloomling',J,TIP:{haL:[-.08,.066,.056],haR:[.08,.066,.056],ftL:[-.04,.002,.06],ftR:[.04,.002,.06]},
 TORSO:{hips:[[0,.03,0],[0,.15,0],.09],chest:[[0,.14,0],[0,.22,.01],.07],head:[[0,.21,.01],[0,.46,.02],.16]},
 AIM:[],floor:.003,pivot:.1,shMin:-1.9,springs:[['earL','vx',-.5,150,6,0,.5],['earR','vx',-.5,150,6,0,.5],['tail','vy',-.3,130,9,0,.2]]};
const RK=makeRigKit(S,cfg);export const makeRig=RK.makeRig,skinGeo=RK.skinGeo;
export const CLIPS=stdClips({w:.12,arm:.4,x:{
 idle:{label:'Idle',len:3.6,f:t=>{const u=cyc(t,3.6);const b=Math.sin(u*TAU)*.5+.5;const sway=Math.sin(u*TAU);const shy=bump(u,.55,.85);return{sq:b*.02,rz:sway*.04,hz:sway*.12+shy*.12,hx:.06+shy*.12,hy:-shy*.25,eye:blink(t,3.6,.8)*(1-shy*.3),b:{chest:[-b*.03,0,sway*.04],shL:[-.3-shy*.6,0,.2+shy*.3],shR:[-.3-shy*.6,0,-.2-shy*.3],elL:[-.9-shy*.5,0,0],elR:[-.9-shy*.5,0,0]}};}},
 idle2:{label:'Idle 2',len:4,f:t=>{const u=cyc(t,4);const peek=bump(u,.2,.7);const side=Math.sin(u*TAU*2)*peek;return{x:side*.02,rz:side*.12,hz:side*.25,hx:-.05,eye:1+peek*.1,b:{shL:[-1.4*peek,0,.4],shR:[-1.4*peek,0,-.4],elL:[-1.4*peek,0,0],elR:[-1.4*peek,0,0]}};}},
 ability:{label:'Twirl',len:2.4,f:t=>{const u=cyc(t,2.4);const spin=ease(sstep(.1,.8,u)),lift=bump(u,.15,.85);return{ry:spin*TAU*2,y:lift*.05,sq:lift*.03,hx:-.15*lift,eye:1-lift*.5,split:lift,b:{shL:[-.4,0,-1.3*lift],shR:[-.4,0,1.3*lift],elL:[-.2,0,0],elR:[-.2,0,0],thL:[-.3*lift,0,0],knL:[.5*lift,0,0]}};}},
 work:{label:'Waters the stones',len:4.4,f:t=>{const u=cyc(t,4.4);const pour=bump(u,.15,.65),pat=bump(u,.7,.95);return{rx:.15*pour,hx:.3*pour+.2*pat,hz:.1*pour,y:-pat*.02,sq:-pat*.04,eye:1-pour*.35,b:{chest:[.25*pour+.3*pat,0,0],shL:[-1*pour-1.2*pat,0,.25],shR:[-1*pour-1.2*pat,0,-.25],elL:[-.6,0,0],elR:[-.6,0,0],haL:[.5*pour,0,0],haR:[.5*pour,0,0]}};}},
 nap:{label:'Nap',len:4.4,f:t=>{const b=Math.sin(t*TAU/4.4)*.5+.5;return{y:-.035,sq:-.05+b*.03,rx:.05,hx:.38,hz:.25,eye:.04,b:{thL:[-1.4,0,-.3],knL:[1.6,0,0],thR:[-1.4,0,.3],knR:[1.6,0,0],shL:[-.7,0,.4],elL:[-1.3,0,0],shR:[-.7,0,-.4],elR:[-1.3,0,0],chest:[.25+b*.04,0,0]}};}}}});
export const EXPR={
 happy:{label:'Sweet',hz:-.14,hx:.04,eye:.9,b:{shL:[-.9,0,.3],shR:[-.9,0,-.3],elL:[-1.3,0,0],elR:[-1.3,0,0]}},
 focus:{label:'Shy',hz:.18,hx:.2,hy:-.35,eye:.72,b:{shL:[-1.5,0,.45],shR:[-1.5,0,-.45],elL:[-1.5,0,0],elR:[-1.5,0,0]}},
 startled:{label:'Startled',hx:-.15,eye:1.22,eyeW:1.1,b:{shL:[-.3,0,-.9],shR:[-.3,0,.9]}},
 caught:{label:'Wilted',hx:.38,hz:.15,eye:.5,b:{chest:[.28,0,0],shL:[.15,0,.1],shR:[.15,0,-.1]}}};
export const build=o=>S.build(o),loadBaked=(u,r)=>S.loadBaked(u,r);
export const BIN='bloomling.bin?v=1',RES=.0042,GAME_SCALE=1.3;
export const EMBERS=[['earL',[-.16,.42,-.02]],['earR',[.16,.42,-.02]],['head',[0,.5,.0]]];
export const ROUTE=[{to:[1.1,-.4],clip:'walk',sp:.2},{at:true,clip:'work',dur:4.4,face:[2,-1]},{to:[-.7,1],clip:'walk',sp:.2},{at:true,clip:'ability',dur:2.4,face:[1,3]},{at:true,clip:'idle',dur:3.6,face:[1,3]},{to:[.2,.2],clip:'carry',sp:.18},{at:true,clip:'nap',dur:4.4,face:[2,2]}];
export const HERO={cam:[1.05,.52,1.3],target:[0,.26,0],clip:'idle'};
