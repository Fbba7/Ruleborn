import * as THREE from 'three';
import {makeSculpt,makeRigKit,sstep,vnoise,clamp,ease,bump,blink,cyc,TAU} from './creature-kit.js';
import {parts} from './creature-parts.js';
// ============ SKY-DRIFTING JELLYFISH (Skyfield wildlife, 5.7) ============
// A glassy dome that pulses through the air, a frilled rim, a sleepy face and long ribbon tentacles.
const COL={bell:0xBFE8FF,bellL:0xF0FBFF,bellD:0x6AA8E0,rim:0xFFC8E8,rimD:0xE08AC0,spot:0xFFFFFF,blush:0xFF9AC8,mouth:0x2A3A6A};
const K=Object.fromEntries(Object.entries(COL).map(([k,v])=>[k,new THREE.Color(v)]));let A0=null;
const def={name:'skyjelly',box:[[-.2,.2,-.2],[.2,.52,.2]],res:.0042,warm:0x1A2A5A,aoWarm:.1,sheen:0xFFFFFF,rim:0xFFE0F4,
 bodyMat:{roughness:.18,clearcoat:1,clearcoatRoughness:.1,sheen:.6,sheenRoughness:.3,sheenColor:new THREE.Color(0xE8F8FF),transmission:.28,thickness:.25,ior:1.25,iridescence:.35},fur:{shells:0},
 sculpt(A){const{E,C}=A;A0=A;
  E('T:bell',[0,.38,0],[.16,.13,.16],null,.02);E('T:hollow',[0,.28,0],[.15,.1,.15],null,.035,'s');
  // eight soft lobes around the rim
  for(let k=0;k<8;k++){const a=k/8*TAU;E('T:lobe'+k,[Math.sin(a)*.13,.305,Math.cos(a)*.13],[.045,.03,.045],null,.03);}
  E('T:crown',[0,.49,0],[.07,.03,.07],null,.05);E('head:face',[0,.37,.13],[.09,.07,.04],null,.05);},
 disp(x,y,z,d){if(Math.abs(d)>.02)return d;return d+(vnoise(x*60,y*60,z*60)-.5)*.0012;},
 paint(x,y,z,nx,ny,nz,ao,c,A){
  c.copy(K.bell).lerp(K.bellL,sstep(.2,.95,ny)*.5).lerp(K.bellD,(1-ao)*.35+sstep(-.1,-.8,ny)*.25);
  // soft white freckles on the dome and a pink rim band
  const sp=vnoise(x*26,y*26,z*26);c.lerp(K.spot,sstep(.74,.82,sp)*sstep(.36,.42,y)*.7);
  c.lerp(K.rim,sstep(.335,.315,y)*.75);c.lerp(K.rimD,sstep(.3,.285,y)*.6);
  // radial canals on the dome
  const a=Math.atan2(x,z);const can=Math.abs(Math.sin(a*4));c.lerp(K.bellD,sstep(.06,.0,can)*sstep(.34,.4,y)*.25);
  for(const s of[-1,1])c.lerp(K.blush,sstep(.03,0,Math.hypot(x-s*.07,y-.345,(z-.14)*1.2))*.55);
  if(z>.12&&Math.abs(x)<.018){const u=x/.018,cy=.332-.006*(1-u*u);const dd=Math.abs(y-cy);if(dd<.0022)c.copy(K.mouth);}
  return 0;},
 accessories(A){const G=new THREE.Group();const P=parts(A,G);const{PB,add,irisTex,eye,glowTex}=P;
  const tex=irisTex('#0A1030','#1E3A7A','#5A9AE8','#0A1030',{pup:.4});
  for(const s of[-1,1])eye(s,{r:.028,ctr:[0,.37,.02],dir:[.36,-.02,1],off:-.008,tex,lid:COL.bellD,lidCut:.3,lidTilt:.05,yaw:.35,irisK:1.2});
  // inner glow: the bell lights up from inside when it pulses
  const gl=new THREE.Sprite(new THREE.SpriteMaterial({map:glowTex('rgba(200,240,255,.8)'),transparent:true,depthWrite:false,blending:THREE.AdditiveBlending}));gl.position.set(0,.36,0);gl.scale.setScalar(.34);gl.userData.bone='chest';gl.userData.fx='glow';gl.userData.fxBase=.7;gl.userData.fxGain=.6;G.add(gl);
  // long ribbon tentacles: wavy strips hanging from under the rim, each swaying on its own
  const tm=new THREE.MeshPhysicalMaterial({color:0xFFD0EC,transparent:true,opacity:.85,roughness:.3,sheen:.8,sheenColor:new THREE.Color(0xFFFFFF),side:THREE.DoubleSide,iridescence:.6,depthWrite:false});
  const om=new THREE.MeshPhysicalMaterial({color:0xE8C8FF,transparent:true,opacity:.9,roughness:.3,sheen:.8,side:THREE.DoubleSide,iridescence:.5});
  for(let k=0;k<8;k++){const a=k/8*TAU+.2;const g=new THREE.Group();g.userData.bone='hips';g.position.set(Math.sin(a)*.11,.3,Math.cos(a)*.11);g.userData.spin=[1.3+k*.17,.22];g.userData.spinAx=k%2?'x':'z';G.add(g);
   const L=.16+(k%3)*.05;const geo=new THREE.PlaneGeometry(.024,L,1,24);const p=geo.attributes.position;for(let i=0;i<p.count;i++){const yy=p.getY(i);const u=(L/2-yy)/L;p.setX(i,p.getX(i)*(1-u*.6)+Math.sin(u*9+k)*.014*u);p.setZ(i,Math.cos(u*7+k)*.01*u);}geo.translate(0,-L/2,0);geo.computeVertexNormals();
   const m=add(geo,tm,null,[0,a,0],null,g);m.castShadow=false;}
  // four frilly oral arms in the middle
  for(let k=0;k<4;k++){const a=k/4*TAU;const g=new THREE.Group();g.userData.bone='hips';g.position.set(Math.sin(a)*.03,.3,Math.cos(a)*.03);g.userData.spin=[.9+k*.2,.15];g.userData.spinAx='x';G.add(g);
   const cu=new THREE.CatmullRomCurve3([...Array(8)].map((_,i)=>new THREE.Vector3(Math.sin(i*1.3+k)*.012,-i*.022,Math.cos(i*1.3+k)*.012)));
   const geo=new THREE.TubeGeometry(cu,40,.009,8);const p=geo.attributes.position;for(let i=0;i<p.count;i++){const f=1+Math.sin(i*.9)*.35;p.setX(i,p.getX(i)*f);p.setZ(i,p.getZ(i)*f);}geo.computeVertexNormals();add(geo,om,null,null,null,g);}
  // ability: a ring of static sparkles as it charges the air
  const fx=new THREE.Group();fx.userData.bone='chest';fx.userData.fx='split';fx.userData.fxMode='show';fx.position.set(0,.36,0);fx.userData.spin=2.5;fx.userData.spinAx='y';G.add(fx);
  const sm=new THREE.SpriteMaterial({map:glowTex('rgba(220,245,255,.95)'),transparent:true,depthWrite:false,blending:THREE.AdditiveBlending});for(let k=0;k<12;k++){const a=k/12*TAU;const s=new THREE.Sprite(sm);s.position.set(Math.sin(a)*.24,(k%3-1)*.04,Math.cos(a)*.24);s.scale.setScalar(.05);fx.add(s);}
  return G;}};
export const S=makeSculpt(def);
const J={root:[null,[0,0,0]],hips:['root',[0,.3,0]],chest:['hips',[0,.38,0]],head:['chest',[0,.37,.1]],tail:['hips',[0,.28,0]]};
const cfg={name:'skyjelly',J,TIP:{},feet:['hips'],TORSO:{hips:[[0,.28,0],[0,.33,0],.14],chest:[[0,.34,0],[0,.5,0],.16],head:[[0,.36,.1],[0,.38,.14],.05]},AIM:[],floor:.36,pivot:.36,springs:[]};
const RK=makeRigKit(S,cfg);export const makeRig=RK.makeRig,skinGeo=RK.skinGeo;
const pulse=(t,rate)=>{const u=(t*rate)%1;return u<.35?ease(u/.35):1-ease((u-.35)/.65);};
export const CLIPS={
 idle:{label:'Drift',len:4,f:t=>{const p=pulse(t,.5);return{y:Math.sin(t*.8)*.03+p*.02,sq:-p*.07,rz:Math.sin(t*.6)*.05,rx:Math.sin(t*.45)*.04,ry:Math.sin(t*.3)*.25,glow:p,eye:blink(t,4,.5)};}},
 idle2:{label:'Doze',len:5,f:t=>{const p=pulse(t,.3);return{y:Math.sin(t*.5)*.02-.02,sq:-p*.04,rz:.12,eye:.08,glow:p*.4,hz:.1};}},
 walk:{label:'Pulse along',len:1.6,f:t=>{const p=pulse(t,1/1.6);return{y:p*.05,sq:-p*.12+.03,rx:.12,z:p*.02,glow:p,eye:blink(t,3)};}},
 run:{label:'Jet',len:.8,f:t=>{const p=pulse(t,1/.8);return{y:p*.07,sq:-p*.18+.04,rx:.3,glow:p,eye:.8};}},
 ability:{label:'Static glow',len:2.4,f:t=>{const u=cyc(t,2.4);const b=bump(u,.1,.85);return{y:b*.05,sq:Math.sin(t*20)*.02*b,split:sstep(.12,.25,u)*(1-sstep(.75,.9,u)),glow:.6+b*.8,ry:u*TAU*.5,eye:1+b*.15};}},
 work:{label:'Ride the wind',len:5,f:t=>{const u=cyc(t,5);const a=u*TAU;const p=pulse(t,.6);return{x:Math.sin(a)*.12,z:Math.cos(a)*.08-.08,y:Math.sin(a*2)*.04,rz:-Math.cos(a)*.2,sq:-p*.06,glow:p,eye:blink(t,4)};}},
 nap:{label:'Sink and sleep',len:5,f:t=>{const b=Math.sin(t*TAU/5)*.5+.5;return{y:-.1+b*.01,sq:.05-b*.03,eye:.05,glow:.3,rz:.08};}},
 celebrate:{label:'Somersault',len:1.8,f:t=>{const u=cyc(t,1.8);const a=ease(u)*TAU;return{y:Math.sin(u*Math.PI)*.1,rx:-a,sq:-pulse(t,1.2)*.1,glow:1,eye:1};}},
 hit:{label:'Jolt',len:1.2,f:t=>{const u=cyc(t,1.2);const k=bump(u,0,.3),r=1-ease(sstep(.3,1,u));return{y:-k*.05,sq:k*.15,rz:Math.sin(u*40)*.15*r,eye:1+k*.3,eyeW:1+k*.2,glow:1-k*.5};}}};
export const EXPR={happy:{label:'Content',hz:-.1,eye:.6},focus:{label:'Curious',hx:-.1,eye:1.1},startled:{label:'Startled',eye:1.25,eyeW:1.1,sq:.06},caught:{label:'Sleepy',eye:.1}};
export const build=o=>S.build(o),loadBaked=(u,r)=>S.loadBaked(u,r);
export const BIN='skyjelly.bin?v=1',RES=.0042,GAME_SCALE=1.35;
export const EMBERS=[['chest',[-.1,.46,.05]],['chest',[.1,.46,.05]],['hips',[0,.12,0]]];
export const ROUTE=[{to:[1.1,-.4],clip:'walk',sp:.18},{at:true,clip:'work',dur:5,face:[2,-1]},{to:[-.7,1],clip:'walk',sp:.2},{at:true,clip:'ability',dur:2.4,face:[1,3]},{at:true,clip:'idle',dur:4,face:[1,3]},{to:[.2,.2],clip:'run',sp:.3},{at:true,clip:'nap',dur:5,face:[2,2]}];
export const HERO={cam:[.75,.55,1.05],target:[0,.3,0],clip:'idle'};
