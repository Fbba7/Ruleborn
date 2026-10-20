import * as THREE from 'three';
import {makeSculpt,makeRigKit,stdClips,sstep,vnoise,clamp,ease,bump,blink,cyc,TAU,merge} from './creature-kit.js';
import {parts} from './creature-parts.js';
// ============ SWARMLINGS · law creature from Swarm birth: two tiny guards pop out of every knocked-out guard ============
// A thumb-sized beetle-guard in an oversized tin helmet, with a pin-spear and a lantern twice too big for it.
const COL={shell:0x7AB84A,shellL:0xB8E07A,shellD:0x2E5A22,belly:0xF2E8B8,face:0xE8D89A,faceL:0xFFF4C8,leg:0x2E4A22,blush:0xFF9A7A,mouth:0x3A1A10,wing:0x4A7A2A};
const K=Object.fromEntries(Object.entries(COL).map(([k,v])=>[k,new THREE.Color(v)]));
const mir=(p,s)=>[p[0]*s,p[1],p[2]];let A0=null;
const def={name:'swarmling',box:[[-.13,0,-.12],[.13,.3,.14]],res:.0034,warm:0x1A2A10,aoWarm:.22,sheen:0xF4FFD8,rim:0xE8FFB0,
 bodyMat:{roughness:.4,clearcoat:.55,clearcoatRoughness:.3,sheen:.4},fur:{shells:0},
 sculpt(A){const{E,C}=A;A0=A;
  E('T:body',[0,.09,-.005],[.052,.055,.048],null,.03);E('T:belly',[0,.085,.03],[.04,.042,.025],null,.02);
  E('head:head',[0,.17,.01],[.062,.056,.056],null,.03);E('head:face',[0,.16,.045],[.048,.038,.026],null,.025);
  for(const s of[-1,1]){const L=s<0?'L':'R';E('head:cheek'+L,mir([.03,.152,.05],s),[.02,.017,.016],null,.012);
   C('sh'+L+':arm1',mir([.045,.11,0],s),mir([.065,.09,.015],s),.012,.01,.01);C('el'+L+':arm2',mir([.065,.09,.015],s),mir([.07,.07,.03],s),.01,.009,.008);E('ha'+L+':hand',mir([.07,.063,.035],s),[.012,.012,.011],null,.006);
   C('th'+L+':leg1',mir([.024,.05,0],s),mir([.027,.028,.004],s),.015,.013,.012);C('kn'+L+':leg2',mir([.027,.028,.004],s),mir([.028,.012,.01],s),.013,.012,.008);E('ft'+L+':foot',mir([.029,.008,.022],s),[.015,.009,.02],null,.006);}},
 disp(x,y,z,d){if(Math.abs(d)>.02)return d;return d+(vnoise(x*140,y*140,z*140)-.5)*.0005;},
 paint(x,y,z,nx,ny,nz,ao,c,A){
  c.copy(K.shell).lerp(K.shellL,sstep(.2,.95,ny)*.35+sstep(.3,.9,nz)*.1).lerp(K.shellD,(1-ao)*.5+sstep(-.2,-.8,ny)*.2);
  // wing-case seam and spots
  if(A.dist('T:body',x,y,z)<.004&&z<.01){if(Math.abs(x)<.003)c.lerp(K.shellD,.7);const sp=Math.hypot(Math.abs(x)-.025,y-.1);c.lerp(K.shellD,sstep(.011,.007,sp)*.8);}
  if(A.dist('T:belly',x,y,z)<.004&&nz>.3)c.lerp(K.belly,.7);
  if(A.minD(/^head:(face|cheek)/,x,y,z)<.004&&nz>.25){c.copy(K.face).lerp(K.faceL,sstep(.2,.9,ny)*.3).lerp(K.shellD,(1-ao)*.3);for(const s of[-1,1])c.lerp(K.blush,sstep(.018,0,Math.hypot(x-s*.03,y-.148,(z-.065)*1.3))*.55);
   if(z>.068&&Math.abs(x)<.013){const u=x/.013,cy=.14-.004*(1-u*u);if(Math.abs(y-cy)<.0018)c.copy(K.mouth);}}
  if(A.minD(/:(arm1|arm2|hand|leg1|leg2|foot)/,x,y,z)<.003)c.lerp(K.leg,.75);
  return 0;},
 accessories(A){const G=new THREE.Group();const P=parts(A,G);const{PB,add,irisTex,eye,glowTex}=P;
  const tex=irisTex('#060A04','#2A3A12','#8AB84A','#060A04',{pup:.46});
  for(const s of[-1,1])eye(s,{r:.017,ctr:[0,.168,.012],dir:[.42,.02,1],off:-.006,tex,lid:COL.shellD,lidCut:.26,lidTilt:-.08,yaw:.4,irisK:1.2});
  const tin=PB(0xB8BCC8,{metalness:.85,roughness:.32}),tinD=PB(0x7A7E8A,{metalness:.8,roughness:.4});
  // an oversized tin helmet, tipped back, with a red feather
  {const g=new THREE.Group();g.userData.bone='head';g.position.set(0,.19,-.005);g.rotation.x=-.15;G.add(g);
   add(new THREE.SphereGeometry(.07,28,16,0,TAU,0,Math.PI/2),tin,null,null,[1,.72,1.02],g);add(new THREE.TorusGeometry(.069,.006,8,40),tinD,[0,.002,0],[Math.PI/2,0,0],null,g);
   add(new THREE.CylinderGeometry(.012,.014,.014,12),tinD,[0,.05,0],null,null,g);
   const cu=new THREE.CatmullRomCurve3([new THREE.Vector3(0,.055,0),new THREE.Vector3(0,.09,-.02),new THREE.Vector3(0,.1,-.06)]);const pl=new THREE.Group();pl.userData.spin=[3,.12];pl.userData.spinAx='x';g.add(pl);
   const tg=new THREE.TubeGeometry(cu,20,.012,8);const p=tg.attributes.position,uv=tg.attributes.uv;for(let i=0;i<p.count;i++){const u=uv.getX(i);const c=cu.getPoint(u);const f=Math.sin(u*Math.PI)*.9+.25;p.setX(i,c.x+(p.getX(i)-c.x)*f*.5);p.setY(i,c.y+(p.getY(i)-c.y)*f);p.setZ(i,c.z+(p.getZ(i)-c.z)*f);}tg.computeVertexNormals();
   add(tg,PB(0xE2536B,{roughness:.7,sheen:.8}),null,null,null,pl);}
  // antennae poking out from under the helmet
  for(const s of[-1,1]){const L=s<0?'L':'R';const a=new THREE.Group();a.userData.bone='ear'+L;G.add(a);const b=new THREE.Vector3(s*.05,.2,.03);const cu=new THREE.CatmullRomCurve3([b,b.clone().add(new THREE.Vector3(s*.025,.02,.01)),b.clone().add(new THREE.Vector3(s*.04,.025,-.005))]);
   add(new THREE.TubeGeometry(cu,10,.0025,6),PB(COL.leg,{roughness:.5}),null,null,null,a);const e=cu.getPoint(1);add(new THREE.SphereGeometry(.006,10,8),PB(COL.shellL,{roughness:.4}),[e.x,e.y,e.z],null,null,a);}
  // a pin for a spear in the right hand, a lantern twice too big in the left
  {const g=new THREE.Group();g.userData.bone='haR';G.add(g);add(new THREE.CylinderGeometry(.0028,.0028,.19,6),PB(0x8A6A3A,{roughness:.6}),[.072,.1,.036],null,null,g);add(new THREE.ConeGeometry(.007,.022,8),tin,[.072,.205,.036],null,null,g);add(new THREE.SphereGeometry(.006,10,8),PB(0xE2536B,{roughness:.5}),[.072,.19,.036],null,null,g);}
  {const g=new THREE.Group();g.userData.bone='haL';G.add(g);const l=new THREE.Group();l.position.set(-.072,.03,.04);l.userData.spin=[2.6,.18];l.userData.spinAx='z';g.add(l);
   add(new THREE.TorusGeometry(.009,.002,6,16,Math.PI),tinD,[0,.03,0],null,null,l);add(new THREE.CylinderGeometry(.018,.02,.006,12),tinD,[0,.022,0],null,null,l);add(new THREE.CylinderGeometry(.018,.018,.004,12),tinD,[0,-.018,0],null,null,l);
   add(new THREE.CylinderGeometry(.016,.016,.036,12),new THREE.MeshPhysicalMaterial({color:0xFFE8A8,emissive:0xFFB84A,emissiveIntensity:1.2,transparent:true,opacity:.85,roughness:.2}),[0,.002,0],null,null,l);
   const gl=new THREE.Sprite(new THREE.SpriteMaterial({map:glowTex('rgba(255,200,110,.9)'),transparent:true,depthWrite:false,blending:THREE.AdditiveBlending}));gl.scale.setScalar(.055);l.add(gl);}
  // ability: splits in two — a twin pops out in a puff
  const fx=new THREE.Group();fx.userData.bone='root';fx.userData.fx='split';fx.userData.fxMode='show';fx.position.set(0,.12,0);G.add(fx);
  const pm=new THREE.SpriteMaterial({map:glowTex('rgba(240,255,210,.9)'),transparent:true,depthWrite:false});for(let k=0;k<9;k++){const a=k/9*TAU;const s=new THREE.Sprite(pm);s.position.set(Math.sin(a)*.1,Math.cos(a*2)*.03,Math.cos(a)*.1);s.scale.setScalar(.06+k%3*.015);fx.add(s);}
  return G;}};
export const S=makeSculpt(def);
const J={root:[null,[0,0,0]],hips:['root',[0,.06,0]],chest:['hips',[0,.1,0]],head:['chest',[0,.14,.01]],earL:['head',[-.05,.2,.03]],earR:['head',[.05,.2,.03]],
 shL:['chest',[-.045,.11,0]],elL:['shL',[-.065,.09,.015]],haL:['elL',[-.07,.07,.03]],shR:['chest',[.045,.11,0]],elR:['shR',[.065,.09,.015]],haR:['elR',[.07,.07,.03]],
 thL:['hips',[-.024,.05,0]],knL:['thL',[-.027,.028,.004]],ftL:['knL',[-.028,.012,.01]],thR:['hips',[.024,.05,0]],knR:['thR',[.027,.028,.004]],ftR:['knR',[.028,.012,.01]]};
const cfg={name:'swarmling',J,TIP:{haL:[-.07,.055,.04],haR:[.07,.055,.04],ftL:[-.029,.0,.04],ftR:[.029,.0,.04]},
 TORSO:{hips:[[0,.04,0],[0,.08,0],.06],chest:[[0,.08,0],[0,.13,0],.06],head:[[0,.14,.01],[0,.22,.01],.07]},AIM:[],floor:.001,pivot:.08,shMin:-2.4,springs:[['earL','vx',.6,140,7,0,.5],['earR','vx',.6,140,7,0,.5]]};
const RK=makeRigKit(S,cfg);export const makeRig=RK.makeRig,skinGeo=RK.skinGeo;
export const CLIPS=stdClips({w:.55,arm:.35,x:{
 idle:{label:'On guard',len:3.6,f:t=>{const u=cyc(t,3.6);const b=Math.sin(u*TAU)*.5+.5;return{sq:b*.03,hy:Math.sin(t*1.3)*.35,hz:Math.sin(u*TAU)*.06,elx:Math.sin(t*3)*.25,eye:blink(t,3.6,.4),b:{shR:[-.25,0,.15],elR:[-.8,0,0],shL:[-.3,0,-.2],elL:[-.6,0,0]}};}},
 idle2:{label:'Salute',len:3,f:t=>{const u=cyc(t,3);const s=bump(u,.15,.7);return{sq:s*.04,y:s*.01,hx:-.12*s,eye:blink(t,3,.6),b:{shL:[-2.4*s,0,-.35*s],elL:[-1.4*s,0,0],shR:[-.25,0,.15],elR:[-.8,0,0]}};}},
 ability:{label:'Swarm split',len:2,f:t=>{const u=cyc(t,2);const p=bump(u,.05,.55);return{y:p*.12,sq:-bump(u,0,.1)*.1+p*.1,ry:ease(sstep(.05,.55,u))*TAU,split:sstep(.1,.2,u)*(1-sstep(.55,.75,u)),eye:1+p*.2,b:{shL:[-1.5*p,0,-.4*p],shR:[-1.5*p,0,.4*p]}};}},
 work:{label:'March the post',len:3.2,f:t=>{const ph=cyc(t,.8);const s=Math.sin(ph*TAU);return{y:Math.abs(Math.cos(ph*TAU))*.012,rz:s*.05,eye:blink(t,3.2),b:merge({thL:[-.6*s,0,0],thR:[.6*s,0,0],knL:[.6*Math.max(0,s),0,0],knR:[.6*Math.max(0,-s),0,0]},{shR:[-.25,0,.15],elR:[-.9,0,0],shL:[.35*s,0,-.1],elL:[-.4,0,0]})};}},
 nap:{label:'Nap on duty',len:4.4,f:t=>{const b=Math.sin(t*TAU/4.4)*.5+.5;return{y:-.012,sq:-.05+b*.03,hx:.35+b*.04,hz:.12,eye:.05,b:{thL:[-1.3,0,-.2],knL:[1.6,0,0],thR:[-1.3,0,.2],knR:[1.6,0,0],shR:[-.4,0,.1],elR:[-1.2,0,0],shL:[-.3,0,-.1],elL:[-.9,0,0]}};}}}});
export const EXPR={happy:{label:'Proud',hz:-.12,hx:-.06,eye:.8},focus:{label:'Alert',hx:.1,eye:.7,elx:.4},startled:{label:'Startled',eye:1.25,eyeW:1.1,elx:.8},caught:{label:'Dizzy',hx:.3,hz:.2,eye:.5}};
export const build=o=>S.build(o),loadBaked=(u,r)=>S.loadBaked(u,r);
export const BIN='swarmling.bin?v=1',RES=.0034,GAME_SCALE=1.2;
export const EMBERS=[['head',[0,.3,-.06]],['haL',[-.07,.06,.04]],['earR',[.09,.22,.03]]];
export const ROUTE=[{to:[1.1,-.4],clip:'walk',sp:.2},{at:true,clip:'work',dur:3.2,face:[2,-1]},{to:[-.7,1],clip:'run',sp:.3},{at:true,clip:'ability',dur:2,face:[1,3]},{at:true,clip:'idle',dur:3.6,face:[1,3]},{to:[.2,.2],clip:'walk',sp:.2},{at:true,clip:'nap',dur:4.4,face:[2,2]}];
export const HERO={cam:[.5,.3,.66],target:[0,.14,0],clip:'idle'};
