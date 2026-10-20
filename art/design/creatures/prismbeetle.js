import * as THREE from 'three';
import {makeSculpt,makeRigKit,stdClips,sstep,vnoise,clamp,ease,bump,blink,cyc,TAU,merge} from './creature-kit.js';
import {parts} from './creature-parts.js';
// ============ PRISM BEETLE (Crystalline wildlife, 5.7) ============
// A round lilac beetle whose wing cases have grown into a cluster of clear, rainbow-edged prisms; one prism horn on its head.
const COL={shell:0x4A3A8A,shellL:0x7A68C0,shellD:0x1E1640,belly:0xB8A8E8,face:0x6A5AB0,faceL:0x9A8AD8,leg:0x2A2048,legL:0x4A3E78,blush:0xFF9AD0,mouth:0x1A1030};
const K=Object.fromEntries(Object.entries(COL).map(([k,v])=>[k,new THREE.Color(v)]));
const mir=(p,s)=>[p[0]*s,p[1],p[2]];let A0=null;
const def={name:'prismbeetle',box:[[-.16,0,-.18],[.16,.26,.2]],res:.0036,warm:0x1A1040,aoWarm:.25,sheen:0xE8E0FF,rim:0xC8B8FF,
 bodyMat:{roughness:.32,clearcoat:.8,clearcoatRoughness:.2,sheen:.3,iridescence:.4,iridescenceIOR:1.5},fur:{shells:0},
 sculpt(A){const{E,C}=A;A0=A;
  E('T:body',[0,.11,-.02],[.1,.07,.12],null,.03);E('T:belly',[0,.085,0],[.085,.045,.1],null,.03);
  E('head:head',[0,.105,.11],[.065,.055,.05],null,.03);E('head:snout',[0,.09,.15],[.038,.028,.022],null,.02);
  for(const s of[-1,1]){const L=s<0?'L':'R';E('head:cheek'+L,mir([.04,.088,.135],s),[.024,.02,.02],null,.015);
   // front legs on the shoulder bones, back legs on the hip bones, three segments each
   C('sh'+L+':leg1',mir([.07,.08,.06],s),mir([.1,.06,.08],s),.014,.011,.01);C('el'+L+':leg2',mir([.1,.06,.08],s),mir([.11,.018,.095],s),.011,.009,.008);E('ha'+L+':foot',mir([.112,.01,.1],s),[.012,.008,.014],null,.006);
   C('th'+L+':leg1',mir([.07,.08,-.07],s),mir([.1,.06,-.09],s),.014,.011,.01);C('kn'+L+':leg2',mir([.1,.06,-.09],s),mir([.11,.018,-.1],s),.011,.009,.008);E('ft'+L+':foot',mir([.112,.01,-.1],s),[.012,.008,.014],null,.006);}},
 disp(x,y,z,d){if(Math.abs(d)>.02)return d;return d+(vnoise(x*120,y*120,z*120)-.5)*.0006;},
 paint(x,y,z,nx,ny,nz,ao,c,A){
  c.copy(K.shell).lerp(K.shellL,sstep(.2,.95,ny)*.35+sstep(.3,.9,nz)*.1).lerp(K.shellD,(1-ao)*.5+sstep(-.2,-.8,ny)*.25);
  if(A.dist('T:belly',x,y,z)<.004&&ny<.1)c.lerp(K.belly,.5);
  const hd=A.minD(/^head:/,x,y,z)<.004;if(hd){c.copy(K.face).lerp(K.faceL,sstep(.2,.9,ny)*.35+sstep(.3,.9,nz)*.25).lerp(K.shellD,(1-ao)*.45);
   for(const s of[-1,1])c.lerp(K.blush,sstep(.022,0,Math.hypot(x-s*.042,y-.085,(z-.14)*1.2))*.6);
   if(z>.16&&Math.abs(x)<.016){const u=x/.016,cy=.08-.005*(1-u*u);if(Math.abs(y-cy)<.0018)c.copy(K.mouth);}}
  if(A.minD(/:(leg1|leg2|foot)/,x,y,z)<.003)c.copy(K.leg).lerp(K.legL,sstep(.2,.9,ny)*.4).lerp(K.shellD,(1-ao)*.4);
  return 0;},
 accessories(A){const G=new THREE.Group();const P=parts(A,G);const{PB,add,irisTex,eye,glowTex}=P;
  const tex=irisTex('#0A0418','#3A2A8A','#9A8AF0','#0A0418',{pup:.42});
  for(const s of[-1,1])eye(s,{r:.02,ctr:[0,.108,.11],dir:[.5,.12,1],off:-.008,tex,lid:COL.face,lidCut:.22,yaw:.5,irisK:1.2});
  // the prism cluster: clear hexagonal crystals with iridescent faces, bound to the chest
  const pm=new THREE.MeshPhysicalMaterial({color:0xB89CFF,emissive:0x3A1A8A,emissiveIntensity:.25,roughness:.08,metalness:0,transmission:.42,thickness:.08,ior:1.55,iridescence:1,iridescenceIOR:1.8,iridescenceThicknessRange:[200,700],clearcoat:1,flatShading:true,attenuationColor:new THREE.Color(0x8A5AFF),attenuationDistance:.06});
  const tip=new THREE.MeshPhysicalMaterial({color:0xFFB8E8,emissive:0x8A2A6A,emissiveIntensity:.25,roughness:.08,transmission:.35,thickness:.03,ior:1.6,iridescence:1,flatShading:true});
  const g=new THREE.Group();g.userData.bone='chest';G.add(g);
  const prism=(p,h,r,tilt,m=pm)=>{const q=new THREE.Group();q.position.set(...p);q.rotation.set(tilt[0],tilt[1],tilt[2]);g.add(q);add(new THREE.CylinderGeometry(r,r*1.05,h,6),m,[0,h/2,0],null,null,q);add(new THREE.ConeGeometry(r,r*1.5,6),m,[0,h+r*.75,0],null,null,q);return q;};
  const C=[[[0,.16,-.03],.07,.03,[-.25,0,0]],[[-.045,.15,-.04],.055,.024,[-.3,0,.45]],[[.045,.15,-.04],.055,.024,[-.3,0,-.45]],[[-.03,.15,.03],.04,.02,[.2,0,.5]],[[.03,.15,.03],.04,.02,[.2,0,-.5]],[[0,.145,-.1],.045,.022,[-.8,0,0]],[[-.06,.13,-.09],.035,.018,[-.7,0,.7]],[[.06,.13,-.09],.035,.018,[-.7,0,-.7]]];
  for(const [p,h,r,t] of C)prism(p,h,r,t);
  // a single prism horn on the head
  {const h=new THREE.Group();h.userData.bone='head';G.add(h);const q=new THREE.Group();q.position.set(0,.14,.118);q.rotation.set(.45,0,0);h.add(q);add(new THREE.CylinderGeometry(.015,.017,.045,6),tip,[0,.022,0],null,null,q);add(new THREE.ConeGeometry(.015,.028,6),tip,[0,.058,0],null,null,q);}
  // two short antennae with bead tips
  for(const s of[-1,1]){const L=s<0?'L':'R';const a=new THREE.Group();a.userData.bone='ear'+L;G.add(a);const b=new THREE.Vector3(s*.03,.14,.13);const cu=new THREE.CatmullRomCurve3([b,b.clone().add(new THREE.Vector3(s*.02,.03,.01)),b.clone().add(new THREE.Vector3(s*.04,.045,-.005))]);
   add(new THREE.TubeGeometry(cu,12,.0028,6),PB(COL.leg,{roughness:.5}),null,null,null,a);const e=cu.getPoint(1);add(new THREE.IcosahedronGeometry(.008,0),tip,[e.x,e.y,e.z],null,null,a);}

  // ability: prisms split light into a fan of rainbow beams
  const fx=new THREE.Group();fx.userData.bone='chest';fx.userData.fx='split';fx.userData.fxMode='show';fx.position.set(0,.22,-.03);fx.userData.spin=1.4;fx.userData.spinAx='y';G.add(fx);
  ['#FF6A8A','#FFB84A','#FFF06A','#6AE88A','#6AC8FF','#9A7AFF'].forEach((c,k)=>{const m=new THREE.MeshBasicMaterial({color:c,transparent:true,opacity:.45,blending:THREE.AdditiveBlending,depthWrite:false,side:THREE.DoubleSide});const b=add(new THREE.PlaneGeometry(.02,.3),m,[0,.15,0],null,null,fx);b.geometry.translate(0,.15,0);b.rotation.set(0,k/6*TAU,.5);b.castShadow=false;});
  return G;}};
export const S=makeSculpt(def);
const J={root:[null,[0,0,0]],hips:['root',[0,.1,-.05]],chest:['hips',[0,.11,.02]],head:['chest',[0,.105,.1]],earL:['head',[-.03,.14,.13]],earR:['head',[.03,.14,.13]],
 shL:['chest',[-.07,.08,.06]],elL:['shL',[-.1,.06,.08]],haL:['elL',[-.11,.018,.095]],shR:['chest',[.07,.08,.06]],elR:['shR',[.1,.06,.08]],haR:['elR',[.11,.018,.095]],
 thL:['hips',[-.07,.08,-.07]],knL:['thL',[-.1,.06,-.09]],ftL:['knL',[-.11,.018,-.1]],thR:['hips',[.07,.08,-.07]],knR:['thR',[.1,.06,-.09]],ftR:['knR',[.11,.018,-.1]]};
const cfg={name:'prismbeetle',J,TIP:{haL:[-.112,.002,.1],haR:[.112,.002,.1],ftL:[-.112,.002,-.1],ftR:[.112,.002,-.1]},
 TORSO:{hips:[[0,.1,-.14],[0,.1,-.02],.1],chest:[[0,.1,-.02],[0,.1,.08],.1],head:[[0,.1,.09],[0,.1,.17],.06]},AIM:[],floor:.002,pivot:.1,springs:[['earL','vx',.6,120,6,0,.4],['earR','vx',.6,120,6,0,.4]]};
const RK=makeRigKit(S,cfg);export const makeRig=RK.makeRig,skinGeo=RK.skinGeo;
// six-leg scuttle: front-left and back-right step together (the middle pair is implied by the fast cycle)
const scut=(ph,k=1)=>{const s=Math.sin(ph*TAU)*k,c=Math.cos(ph*TAU)*k;return{shL:[0,s*.45,-Math.max(0,c)*.3],haL:[0,0,0],thR:[0,s*.45,Math.max(0,c)*.3],shR:[0,-s*.45,Math.max(0,-c)*.3],thL:[0,-s*.45,-Math.max(0,-c)*.3]};};
export const CLIPS=stdClips({w:.2,arm:0,x:{
 idle:{label:'Idle',len:4,f:t=>{const u=cyc(t,4);const b=Math.sin(u*TAU)*.5+.5;return{sq:b*.015,hx:Math.sin(t*1.2)*.04,hz:Math.sin(u*TAU)*.05,elx:Math.sin(t*2)*.2,eye:blink(t,4,.5),glow:b};}},
 idle2:{label:'Preen',len:4.4,f:t=>{const u=cyc(t,4.4);const p=bump(u,.2,.75);const w=Math.sin(t*14)*p;return{hx:.2*p,eye:blink(t,2.2,.3),b:{shL:[-.9*p+w*.2,0,-.2*p],elL:[-.8*p,0,0],shR:[-.9*p-w*.2,0,.2*p],elR:[-.8*p,0,0]}};}},
 walk:{label:'Scuttle',len:.5,f:t=>{const ph=cyc(t,.5);return{y:Math.abs(Math.sin(ph*TAU*2))*.005,rz:Math.sin(ph*TAU)*.03,eye:blink(t,3),b:scut(ph)};}},
 run:{label:'Skitter',len:.3,f:t=>{const ph=cyc(t,.3);return{y:Math.abs(Math.sin(ph*TAU*2))*.008,rx:.05,b:scut(ph,1.2)};}},
 ability:{label:'Rainbow split',len:2.6,f:t=>{const u=cyc(t,2.6);const b=bump(u,.1,.85);return{rx:-.25*b,y:b*.02,split:sstep(.12,.25,u)*(1-sstep(.8,.92,u)),glow:1+b,eye:1-b*.2,b:{thL:[.3*b,0,0],thR:[.3*b,0,0]}};}},
 work:{label:'Polish a crystal',len:3.6,f:t=>{const u=cyc(t,3.6);const r=Math.sin(t*9);return{hx:.25,eye:blink(t,3.6,.4),b:{shL:[-.6+r*.15,0,-.1],elL:[-.9,0,0],shR:[-.6-r*.15,0,.1],elR:[-.9,0,0]}};}},
 leap:{label:'Hop',len:1,f:t=>{const u=cyc(t,1);const a=bump(u,.15,.8);return{y:a*.08,sq:a*.06-bump(u,0,.15)*.06,rx:-a*.15,b:scut(0,0)};}},
 nap:{label:'Tuck in',len:5,f:t=>{const b=Math.sin(t*TAU/5)*.5+.5;return{y:-.02,sq:-.05+b*.02,hx:.2,eye:.05,glow:.4+b*.3,b:{shL:[0,0,-.9],shR:[0,0,.9],thL:[0,0,-.9],thR:[0,0,.9],elL:[1,0,0],elR:[1,0,0],knL:[1,0,0],knR:[1,0,0]}};}},
 hit:{label:'Flip over',len:2,f:t=>{const u=cyc(t,2);const f=ease(sstep(0,.25,u))*(1-ease(sstep(.6,.9,u)));const w=Math.sin(t*30)*f;return{rz:f*Math.PI,y:f*.1,eye:1+f*.3,b:{shL:[w*.4,0,0],shR:[-w*.4,0,0],thL:[-w*.4,0,0],thR:[w*.4,0,0]}};}},
 celebrate:{label:'Spin',len:1.4,f:t=>{const u=cyc(t,1.4);return{ry:ease(u)*TAU,y:bump(u,.1,.9)*.04,glow:1.4,b:scut(u*4,.8)};}}}});
export const EXPR={happy:{label:'Content',hz:-.12,eye:.65},focus:{label:'Curious',hx:-.1,eye:1.1,elx:.3},startled:{label:'Startled',eye:1.25,eyeW:1.1},caught:{label:'Grumpy',hx:.25,eye:.55}};
export const build=o=>S.build(o),loadBaked=(u,r)=>S.loadBaked(u,r);
export const BIN='prismbeetle.bin?v=1',RES=.0036,GAME_SCALE=1.35;
export const EMBERS=[['chest',[0,.26,-.03]],['head',[0,.2,.15]],['chest',[-.06,.2,-.08]]];
export const ROUTE=[{to:[1.1,-.4],clip:'walk',sp:.16},{at:true,clip:'work',dur:3.6,face:[2,-1]},{to:[-.7,1],clip:'walk',sp:.18},{at:true,clip:'ability',dur:2.6,face:[1,3]},{at:true,clip:'idle',dur:4,face:[1,3]},{to:[.2,.2],clip:'run',sp:.3},{at:true,clip:'nap',dur:5,face:[2,2]}];
export const HERO={cam:[.6,.38,.72],target:[0,.11,0],clip:'idle'};
