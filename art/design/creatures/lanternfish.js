import * as THREE from 'three';
import {makeSculpt,makeRigKit,sstep,vnoise,clamp,ease,bump,blink,cyc,TAU} from './creature-kit.js';
import {parts} from './creature-parts.js';
// ============ SLOW-SWIMMING LANTERNFISH (Tidehold wildlife, 5.7) ============
// A round deep-sea fish that swims through the air of Tidehold: a big head, a glowing lure on a stalk, lights along its flanks.
const COL={skin:0x2A5A8A,skinL:0x5A9AC8,skinD:0x122A48,belly:0xC8E8F0,fin:0x6AC8E8,blush:0xFF9AB0,mouth:0x0A1A2A,photo:0x9BEAF3};
const K=Object.fromEntries(Object.entries(COL).map(([k,v])=>[k,new THREE.Color(v)]));let A0=null;
const def={name:'lanternfish',box:[[-.13,.12,-.26],[.13,.42,.2]],res:.004,warm:0x0A1A30,aoWarm:.25,sheen:0xC8F0FF,rim:0x9BEAF3,
 bodyMat:{roughness:.35,clearcoat:.7,clearcoatRoughness:.25,sheen:.4,iridescence:.35},fur:{shells:0},
 sculpt(A){const{E,C}=A;A0=A;
  E('head:head',[0,.27,.05],[.1,.1,.1],null,.04);E('head:jaw',[0,.235,.1],[.08,.05,.06],null,.035);
  C('T:body',[0,.27,-.02],[0,.27,-.14],.085,.045,.04);C('tail:stem',[0,.27,-.14],[0,.27,-.19],.045,.022,.02);
  E('head:brow',[0,.325,.075],[.07,.03,.04],null,.03);},
 disp(x,y,z,d){if(Math.abs(d)>.02)return d;const sc=Math.sin(z*160+Math.sin(y*160)*1.3)*Math.sin(y*160)*.5;return d+sc*.0006*sstep(.02,-.05,z);},
 paint(x,y,z,nx,ny,nz,ao,c,A){
  c.copy(K.skin).lerp(K.skinL,sstep(.2,.95,ny)*.3+sstep(.4,.9,nz)*.2).lerp(K.skinD,(1-ao)*.5);
  c.lerp(K.belly,sstep(-.3,-.7,ny)*.8);
  // scale shimmer on the flanks
  const sc=Math.sin(z*160+Math.sin(y*160)*1.3)*.5+.5;c.lerp(K.skinL,sstep(.8,.95,sc)*sstep(.05,-.08,z)*.35);
  for(const s of[-1,1])c.lerp(K.blush,sstep(.03,0,Math.hypot(x-s*.07,y-.245,(z-.11)*1.2))*.5);
  if(z>.14&&Math.abs(x)<.03){const u=x/.03,cy=.228+.006*(1-u*u);const dd=Math.abs(y-cy),w=.0034*(1-u*u*.4);if(dd<w)c.copy(K.mouth);else if(dd<w+.002)c.lerp(K.mouth,.4);}
  return 0;},
 accessories(A){const G=new THREE.Group();const P=parts(A,G);const{PB,add,irisTex,eye,glowTex}=P;
  const tex=irisTex('#02060C','#0A2A4A','#2A7AB8','#02060C',{pup:.5});
  for(const s of[-1,1])eye(s,{r:.03,ctr:[0,.285,.05],dir:[.55,.12,1],off:-.01,tex,lid:COL.skinD,lidCut:.2,yaw:.55,irisK:1.15});
  const fm=PB(COL.fin,{transparent:true,opacity:.85,side:THREE.DoubleSide,roughness:.3,sheen:.8,sheenColor:new THREE.Color(0xE8FFFF),iridescence:.7,depthWrite:false});
  const finGeo=(w,h,fan)=>{const sh=new THREE.Shape();sh.moveTo(0,0);sh.quadraticCurveTo(w*.3,h*.9,w,h);for(let k=0;k<5;k++){const t=1-k/5;sh.quadraticCurveTo(w*(t-.1)*1.02,h*t*.8+h*.1,w*(t-.2),h*(t-.2));}sh.lineTo(0,0);const g=new THREE.ShapeGeometry(sh,16);return g;};
  // tail fan, dorsal fin and pectoral fins, each on its own bone so they ripple
  {const g=new THREE.Group();g.userData.bone='tail';g.position.set(0,.27,-.18);G.add(g);const sh=new THREE.Shape();sh.moveTo(0,0);sh.quadraticCurveTo(.05,.03,.1,.075);sh.quadraticCurveTo(.075,.02,.085,0);sh.quadraticCurveTo(.075,-.02,.1,-.075);sh.quadraticCurveTo(.05,-.03,0,0);const tg=new THREE.ShapeGeometry(sh,16);tg.rotateY(Math.PI/2);const f=add(tg,fm,null,null,null,g);f.castShadow=false;}
  {const g=new THREE.Group();g.userData.bone='hips';g.position.set(0,.345,-.02);G.add(g);const sh=new THREE.Shape();sh.moveTo(.04,0);sh.quadraticCurveTo(.02,.05,-.05,.045);sh.quadraticCurveTo(-.08,.03,-.1,-.005);sh.lineTo(.04,-.01);const dg=new THREE.ShapeGeometry(sh,16);dg.rotateY(-Math.PI/2);dg.scale(1,1,-1);const f=add(dg,fm,null,null,null,g);f.castShadow=false;}
  for(const s of[-1,1]){const L=s<0?'L':'R';const g=new THREE.Group();g.userData.bone='ear'+L;g.position.set(s*.08,.24,.0);G.add(g);const f=add(finGeo(.07,.05),fm,null,[.3,s*(Math.PI/2+.5),0],[s,1,1],g);f.castShadow=false;}
  // the lure: a curved stalk from the brow to a glowing bulb
  {const g=new THREE.Group();g.userData.bone='head';G.add(g);const b=new THREE.Vector3(0,.35,.07);const cu=new THREE.CatmullRomCurve3([b,b.clone().add(new THREE.Vector3(0,.07,-.01)),b.clone().add(new THREE.Vector3(0,.1,.05)),b.clone().add(new THREE.Vector3(0,.08,.1))]);
   add(new THREE.TubeGeometry(cu,24,.005,8),PB(COL.skin,{roughness:.4,clearcoat:.5}),null,null,null,g);const e=cu.getPoint(1);const bulb=new THREE.Group();bulb.position.copy(e);bulb.userData.spin=[2.2,.2];bulb.userData.spinAx='x';g.add(bulb);
   add(new THREE.SphereGeometry(.022,20,14),new THREE.MeshPhysicalMaterial({color:0xE8FFFF,emissive:0x8AF0FF,emissiveIntensity:1.6,roughness:.2,clearcoat:1}),[0,-.012,0],null,null,bulb);
   const gl=new THREE.Sprite(new THREE.SpriteMaterial({map:glowTex('rgba(160,240,255,.95)'),transparent:true,depthWrite:false,blending:THREE.AdditiveBlending}));gl.position.set(0,-.012,0);gl.scale.setScalar(.05);gl.userData.fx='glow';gl.userData.fxBase=.9;gl.userData.fxGain=.8;bulb.add(gl);}
  // photophores: a row of little lights along each flank
  const pm=new THREE.MeshPhysicalMaterial({color:0xC8FAFF,emissive:0x6AE8F8,emissiveIntensity:1.3,roughness:.3});
  for(const s of[-1,1])for(let k=0;k<6;k++){const z=.05-k*.035,r=.085-k*.007;const g=new THREE.Group();g.userData.bone=k<2?'chest':'hips';G.add(g);add(new THREE.SphereGeometry(.0085,10,8),pm,[s*(r+.002),.25-k*.002,z],null,[.6,1,1],g);}
  // ability: the lure flares and a ring of light washes outward
  const fx=new THREE.Group();fx.userData.bone='head';fx.userData.fx='split';fx.userData.fxMode='show';fx.position.set(0,.42,.14);G.add(fx);
  const rm=new THREE.MeshBasicMaterial({color:0x9BEAF3,transparent:true,opacity:.6,blending:THREE.AdditiveBlending,depthWrite:false,side:THREE.DoubleSide});for(let k=0;k<3;k++){const m=add(new THREE.RingGeometry(.05+k*.05,.058+k*.05,40),rm,null,[0,0,0],null,fx);m.castShadow=false;}
  return G;}};
export const S=makeSculpt(def);
const J={root:[null,[0,0,0]],hips:['root',[0,.27,-.06]],chest:['hips',[0,.27,.02]],head:['chest',[0,.27,.06]],earL:['chest',[-.08,.24,0]],earR:['chest',[.08,.24,0]],tail:['hips',[0,.27,-.17]]};
const cfg={name:'lanternfish',J,TIP:{},feet:['hips'],TORSO:{hips:[[0,.27,-.2],[0,.27,-.06],.08],chest:[[0,.27,-.06],[0,.27,.02],.09],head:[[0,.27,.03],[0,.27,.16],.1]},AIM:[],floor:.3,pivot:.27,
 springs:[['tail','wy',-.6,80,5,1,.6],['earL','t',.25,70,5,1,.3,4],['earR','t',-.25,70,5,1,.3,4.3]]};
const RK=makeRigKit(S,cfg);export const makeRig=RK.makeRig,skinGeo=RK.skinGeo;
const swim=(t,rate,amp)=>{const s=Math.sin(t*rate);return{chest:[0,s*amp*.3,0],hips:[0,-s*amp*.6,0],tail:[0,s*amp*1.1,0],earL:[0,Math.sin(t*rate*1.3)*.4,0],earR:[0,-Math.sin(t*rate*1.3)*.4,0]};};
export const CLIPS={
 idle:{label:'Hover',len:4,f:t=>{return{y:Math.sin(t*1.1)*.02,rz:Math.sin(t*.7)*.04,rx:Math.sin(t*.5)*.05,glow:Math.sin(t*2)*.5+.5,eye:blink(t,4,.5),b:swim(t,2.4,.25)};}},
 idle2:{label:'Look about',len:5,f:t=>{const u=cyc(t,5);const look=Math.sin(u*TAU);return{ry:look*.6,y:Math.sin(t)*.015,eye:blink(t,2.5,.2),glow:.6,b:swim(t,2,.2)};}},
 walk:{label:'Swim',len:2,f:t=>{return{y:Math.sin(t*2)*.02,rx:.05,rz:Math.sin(t*3.1)*.05,glow:.7,eye:blink(t,3),b:swim(t,6,.5)};}},
 run:{label:'Dash',len:1,f:t=>{return{y:Math.sin(t*4)*.02,rx:.1,glow:1,b:swim(t,12,.7)};}},
 ability:{label:'Lure flare',len:2.4,f:t=>{const u=cyc(t,2.4);const b=bump(u,.1,.85);return{rx:-.25*b,y:b*.03,split:sstep(.15,.3,u)*(1-sstep(.75,.9,u)),glow:1+b*1.5,eye:1-b*.3,b:swim(t,3,.3)};}},
 work:{label:'Patrol the pond',len:6,f:t=>{const u=cyc(t,6);const a=u*TAU;return{x:Math.sin(a)*.14,z:Math.cos(a)*.14-.14,ry:a+Math.PI/2,rz:-.18,glow:.7,eye:blink(t,4),b:swim(t,5,.45)};}},
 nap:{label:'Doze',len:5,f:t=>{return{y:-.08+Math.sin(t*.6)*.01,rz:.2,glow:.25+Math.sin(t*.8)*.1,eye:.05,b:swim(t,.8,.1)};}},
 celebrate:{label:'Barrel roll',len:1.6,f:t=>{const u=cyc(t,1.6);return{rz:ease(u)*TAU,y:bump(u,.1,.9)*.06,glow:1.4,eye:1,b:swim(t,8,.5)};}},
 hit:{label:'Startle',len:1.2,f:t=>{const u=cyc(t,1.2);const k=bump(u,0,.3),r=1-ease(sstep(.3,1,u));return{z:-k*.06,sq:k*.1,rz:Math.sin(u*40)*.1*r,eye:1+k*.3,eyeW:1+k*.2,glow:1-k*.6,b:swim(t,14,.8*r)};}}};
export const EXPR={happy:{label:'Content',hz:-.1,eye:.6},focus:{label:'Curious',hx:-.1,eye:1.1},startled:{label:'Startled',eye:1.25,eyeW:1.1,sq:.06},caught:{label:'Sleepy',eye:.15}};
export const build=o=>S.build(o),loadBaked=(u,r)=>S.loadBaked(u,r);
export const BIN='lanternfish.bin?v=1',RES=.004,GAME_SCALE=1.35;
export const EMBERS=[['head',[0,.44,.17]],['tail',[0,.3,-.3]],['chest',[0,.2,0]]];
export const ROUTE=[{to:[1.1,-.4],clip:'walk',sp:.16},{at:true,clip:'work',dur:6,face:[2,-1]},{to:[-.7,1],clip:'walk',sp:.18},{at:true,clip:'ability',dur:2.4,face:[1,3]},{at:true,clip:'idle',dur:4,face:[1,3]},{to:[.2,.2],clip:'run',sp:.3},{at:true,clip:'nap',dur:5,face:[2,2]}];
export const HERO={cam:[.78,.46,.86],target:[0,.3,-.02],clip:'idle'};
