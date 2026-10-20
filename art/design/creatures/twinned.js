import * as THREE from 'three';
import {makeSculpt,makeRigKit,stdClips,sstep,vnoise,clamp,ease,bump,blink,cyc,TAU,merge,gait} from './creature-kit.js';
import {parts} from './creature-parts.js';
// ============ THE TWINNED · Legendary paradox-born · from Twin suns · two silhouettes moving slightly out of step (GDD 11.8, 21.6) ============
// Two little sun-sprites, one gold and one rose-silver. One sculpt, two rigs: the second copies the first a beat late.
const COL={skin:0xF2A640,skinL:0xFFD27A,skinD:0xB0521E,belly:0xFFE8B8,blush:0xFF7A5A,mouth:0x5A1A10,sole:0xA8502A,ray:0xFFC83A,rayD:0xF28A1C};
const K=Object.fromEntries(Object.entries(COL).map(([k,v])=>[k,new THREE.Color(v)]));
const mir=(p,s)=>[p[0]*s,p[1],p[2]];let A0=null;
const def={name:'twinned',box:[[-.22,0,-.2],[.22,.62,.2]],res:.0046,warm:0x3A1404,aoWarm:.22,sheen:0xFFF0C8,rim:0xFFE6A0,
 bodyMat:{roughness:.55,sheen:.6,sheenRoughness:.4,clearcoat:.15},fur:{shells:0},
 sculpt(A){const{E,C}=A;A0=A;
  E('T:body',[0,.2,0],[.095,.1,.085],null,.05);E('T:belly',[0,.19,.04],[.07,.075,.055],null,.04);C('T:neck',[0,.27,0],[0,.31,.005],.06,.07,.04);
  E('head:skull',[0,.405,.005],[.145,.132,.128],null,.05);E('head:face',[0,.39,.075],[.118,.098,.07],null,.045);
  for(const s of[-1,1]){const L=s<0?'L':'R';E('head:cheek'+L,mir([.08,.355,.085],s),[.05,.042,.045],null,.03);
   const sh=mir([.085,.25,0],s),el=mir([.13,.2,.02],s),wr=mir([.145,.15,.04],s);C('sh'+L+':arm1',sh,el,.028,.024,.02);C('el'+L+':arm2',el,wr,.024,.021,.015);
   E('ha'+L+':hand',mir([.15,.13,.045],s),[.03,.032,.026],null,.014);C('ha'+L+':thumb',mir([.135,.14,.065],s),mir([.128,.155,.075],s),.011,.009,.006);
   C('th'+L+':leg1',mir([.05,.13,0],s),mir([.055,.07,.005],s),.04,.034,.03);C('kn'+L+':leg2',mir([.055,.07,.005],s),mir([.057,.03,.012],s),.034,.03,.02);
   E('ft'+L+':foot',mir([.058,.022,.035],s),[.036,.022,.05],null,.016);}
  E('tail:nub',[0,.15,-.08],[.022,.02,.02],null,.015);},
 disp(x,y,z,d){if(Math.abs(d)>.03)return d;return d+(vnoise(x*110,y*110,z*110)-.5)*.0004;},
 paint(x,y,z,nx,ny,nz,ao,c,A){
  c.copy(K.skin).lerp(K.skinL,sstep(.2,.95,ny)*.35+sstep(.3,.9,nz)*.15).lerp(K.skinD,(1-ao)*.5+sstep(-.2,-.8,ny)*.2);
  // sun-glow freckles
  c.lerp(K.skinL,sstep(.72,.8,vnoise(x*38,y*38,z*38))*sstep(.3,.36,y)*.5);
  const bel=sstep(.004,-.002,A.dist('T:belly',x,y,z))*sstep(.05,.08,z);c.lerp(K.belly,bel*.85);
  const fc=sstep(.006,-.001,A.minD(/^head:(face|cheek)/,x,y,z))*sstep(.06,.1,z);c.lerp(K.belly,fc*.7);
  for(const s of[-1,1])c.lerp(K.blush,sstep(.03,0,Math.hypot(x-s*.085,y-.345,(z-.12)*1.5))*.5);
  if(z>.12&&Math.abs(x)<.034){const u=x/.034,cy=.33-.01*(1-u*u);const dd=Math.abs(y-cy),w=.003*(1-u*u*.5);if(dd<w)c.copy(K.mouth);else if(dd<w+.003)c.lerp(K.mouth,.35*(1-(dd-w)/.003));}
  if(A.minD(/^ft[LR]:/,x,y,z)<.004&&ny<-.4)c.lerp(K.sole,.7);
  return 0;},
 accessories(A){const G=new THREE.Group();const P=parts(A,G);const{PB,add,irisTex,eye,glowTex}=P;
  const tex=irisTex('#140804','#8A4A12','#E8A83A','#2A1206',{pup:.34});
  for(const s of[-1,1])eye(s,{r:.042,ctr:[0,.405,.005],dir:[.42,-.1,1],off:-.015,tex,lid:COL.skinD,lidCut:.24,yaw:.38,irisK:1.3});
  // a crown of sun rays round the head: short flame petals, alternating long and short, and a soft halo disc behind
  const rayM=PB(COL.ray,{roughness:.35,emissive:0xF28A1C,emissiveIntensity:.55,clearcoat:.4});rayM.name='ray';
  const crown=new THREE.Group();crown.userData.bone='head';crown.position.set(0,.405,-.035);crown.userData.spin=[1.3,.06];G.add(crown);
  const sh=new THREE.Shape();sh.moveTo(-.026,0);sh.quadraticCurveTo(-.02,.05,0,.085);sh.quadraticCurveTo(.02,.05,.026,0);sh.lineTo(-.026,0);
  const rg=new THREE.ExtrudeGeometry(sh,{depth:.012,bevelEnabled:true,bevelSize:.007,bevelThickness:.007,bevelSegments:3,curveSegments:10});rg.translate(0,0,-.006);
  const N=12;for(let k=0;k<N;k++){const a=k/N*TAU;if(Math.abs(Math.sin(a))<.3&&Math.cos(a)<0)continue;const long=k%2===0;const m=add(rg,rayM,[Math.sin(a)*.14,Math.cos(a)*.13,0],[0,0,-a],long?[1,1.05,1]:[.8,.72,1],crown);}
  const halo=new THREE.Sprite(new THREE.SpriteMaterial({map:glowTex('rgba(255,210,110,.75)'),transparent:true,depthWrite:false,blending:THREE.AdditiveBlending}));halo.name='halo';halo.position.set(0,0,-.03);halo.scale.setScalar(.5);halo.visible=false;crown.add(halo);
  // a tiny sun pendant on a cord
  {const g=new THREE.Group();g.userData.bone='chest';G.add(g);const cu=new THREE.CatmullRomCurve3([...Array(13)].map((_,i)=>{const a=i/12*TAU;return new THREE.Vector3(Math.sin(a)*.068,.285-Math.max(0,Math.cos(a))*.03,Math.cos(a)*.062);}),true);
   add(new THREE.TubeGeometry(cu,48,.004,6,true),PB(0x6A2A10,{roughness:.7}),null,null,null,g);
   const pm=PB(0xFFE08A,{metalness:.9,roughness:.25,emissive:0x8A4A08,emissiveIntensity:.3});pm.name='ray';add(new THREE.CylinderGeometry(.018,.018,.007,24),pm,[0,.252,.066],[Math.PI/2,0,0],null,g);}
  // twin suns (ability): a second, bright echo-sun that flares over its head
  const fx=new THREE.Group();fx.userData.bone='head';fx.userData.fx='split';fx.userData.fxMode='show';fx.position.set(0,.64,0);G.add(fx);fx.userData.spin=4;fx.userData.spinAx='z';
  const sm=new THREE.MeshBasicMaterial({color:0xFFE08A});sm.name='ray';add(new THREE.SphereGeometry(.05,20,14),sm,null,null,null,fx);
  const fl=new THREE.Sprite(new THREE.SpriteMaterial({map:glowTex('rgba(255,200,90,.95)'),transparent:true,depthWrite:false,blending:THREE.AdditiveBlending}));fl.name='halo';fl.scale.setScalar(.32);fx.add(fl);
  for(let k=0;k<8;k++){const a=k/8*TAU;add(new THREE.ConeGeometry(.012,.05,8),sm,[Math.sin(a)*.075,Math.cos(a)*.075,0],[0,0,-a],null,fx);}
  return G;}};
export const S=makeSculpt(def);
const J={root:[null,[0,0,0]],hips:['root',[0,.15,0]],chest:['hips',[0,.24,0]],head:['chest',[0,.3,.005]],earL:['head',[-.06,.5,0]],earR:['head',[.06,.5,0]],
 shL:['chest',[-.085,.25,0]],elL:['shL',[-.13,.2,.02]],haL:['elL',[-.145,.15,.04]],shR:['chest',[.085,.25,0]],elR:['shR',[.13,.2,.02]],haR:['elR',[.145,.15,.04]],
 thL:['hips',[-.05,.13,0]],knL:['thL',[-.055,.07,.005]],ftL:['knL',[-.057,.03,.012]],thR:['hips',[.05,.13,0]],knR:['thR',[.055,.07,.005]],ftR:['knR',[.057,.03,.012]],tail:['hips',[0,.15,-.08]]};
const cfg={name:'twinned',J,TIP:{haL:[-.155,.1,.05],haR:[.155,.1,.05],ftL:[-.058,.002,.08],ftR:[.058,.002,.08]},
 TORSO:{hips:[[0,.1,0],[0,.24,0],.12],chest:[[0,.2,0],[0,.3,0],.1],head:[[0,.3,.005],[0,.54,.005],.16]},
 AIM:[],floor:.003,pivot:.15,shMin:-2.2,springs:[['tail','vx',-.3,120,8,0,.2]]};
const RK=makeRigKit(S,cfg);export const skinGeo=RK.skinGeo;
// the pair: the second twin replays the first's pose 0.16 s late, a little to its right and behind, recoloured rose-silver
export const TWIN={off:[.3,0,-.13],delay:160};
const roseM=new Map();
function recolor(root){root.traverse(o=>{if(!o.isMesh&&!o.isSprite)return;
  if(o.name==='body'&&o.geometry.attributes.color){const g=o.geometry.clone();const c=g.attributes.color,t=new THREE.Color(),hsl={};for(let i=0;i<c.count;i++){t.setRGB(c.getX(i),c.getY(i),c.getZ(i));t.getHSL(hsl);t.setHSL(.1,hsl.s*.28,Math.min(.93,hsl.l*1.02+.05));c.setXYZ(i,t.r,t.g,t.b);}o.geometry=g;return;}
  const m=o.material;const ok=(o.isSprite&&o.name==='halo')||(m&&m.name&&m.name.indexOf('ray')>=0);if(!ok)return;
  let n=roseM.get(m);if(!n){n=m.clone();if(n.onBeforeCompile!==m.onBeforeCompile)n.onBeforeCompile=m.onBeforeCompile;if(n.emissive)n.emissive.set(0xC89A50);if(n.color&&!n.map)n.color.set(n.isMeshBasicMaterial?0xFFF8E8:0xFFF2DC);if(n.isSpriteMaterial)n.color.set(0xFFF4E0);roseM.set(m,n);}o.material=n;});}
export function makeRig(src,o){const a=RK.makeRig(src,o),b=RK.makeRig(src,o);recolor(b.root);
 const root=new THREE.Group();root.add(a.root);root.add(b.root);const buf=[];
 const place=(p,k)=>{const ry=p.ry||0,ox=TWIN.off[0]*k,oz=TWIN.off[2]*k;return Object.assign({},p,{x:(p.x||0)+ox*Math.cos(ry)+oz*Math.sin(ry),z:(p.z||0)-ox*Math.sin(ry)+oz*Math.cos(ry)});};
 const late=()=>{const now=performance.now()-TWIN.delay;let best=buf[0];for(const e of buf){if(e.t<=now)best=e;else break;}return best;};
 const push=(p,clip)=>{buf.push({t:performance.now(),p,clip});while(buf.length>2&&buf[1].t<performance.now()-TWIN.delay-40)buf.shift();};
 const r=Object.assign({},a,{root,twin:b,
  set(p){a.set(place(p,-.5));push(p,null);const e=late();b.set(place(e.p,.5));},
  play(p,clip){a.play(place(p,-.5),clip);push(p,clip);const e=late();b.play(place(e.p,.5),e.clip||clip);}});
 return r;}
export const CLIPS=stdClips({w:.45,arm:.42,x:{
 idle:{label:'Idle',len:3.6,f:t=>{const u=cyc(t,3.6);const b=Math.sin(u*TAU)*.5+.5;const sway=Math.sin(u*TAU);return{sq:b*.02,rz:sway*.05,hz:sway*.08,hy:Math.sin(t*.9)*.2,eye:blink(t,3.6,.4),b:{chest:[-b*.03,0,sway*.04],shL:[-.2,0,.35+b*.08],shR:[-.2,0,-.35-b*.08],elL:[-.4,0,0],elR:[-.4,0,0]}};}},
 idle2:{label:'Idle 2',len:4,f:t=>{const u=cyc(t,4);const wave=bump(u,.15,.75);const w=Math.sin(t*12)*wave;return{hz:-.15*wave,hy:.25*wave,eye:blink(t,2,.2),b:{shR:[-2.2*wave,0,-.5*wave],elR:[-.3+w*.35,0,0],haR:[w*.3,0,0],shL:[-.15,0,.3],elL:[-.4,0,0]}};}},
 ability:{label:'Twin suns',len:2.4,f:t=>{const u=cyc(t,2.4);const up=bump(u,.08,.9),jump=bump(u,.3,.62);return{y:jump*.14,sq:jump*.06-bump(u,.6,.72)*.08,hx:-.25*up,split:sstep(.15,.3,u)*(1-sstep(.82,.95,u)),eye:1+up*.1,
  b:{shL:[-2.6*up,0,-.3*up],shR:[-2.6*up,0,.3*up],elL:[-.2,0,0],elR:[-.2,0,0],thL:[-.6*jump,0,0],knL:[1*jump,0,0],thR:[-.6*jump,0,0],knR:[1*jump,0,0]}};}},
 work:{label:'Twin dance',len:3.2,f:t=>{const u=cyc(t,3.2);const s=Math.sin(u*TAU*2);const hop=Math.abs(Math.sin(u*TAU*2));return{y:hop*.04,ry:u*TAU,sq:hop*.03,rz:s*.08,hz:-s*.1,eye:blink(t,3.2,.6),b:merge(gait(u*2%1,{leg:.4,knee:.7,arm:0}),{shL:[-1.3,0,-.6+s*.3],shR:[-1.3,0,.6+s*.3],elL:[-.5,0,0],elR:[-.5,0,0]})};}},
 nap:{label:'Nap',len:4.4,f:t=>{const b=Math.sin(t*TAU/4.4)*.5+.5;return{y:-.05,sq:-.05+b*.03,rx:.08,hx:.35,hz:.25,eye:.05,b:{thL:[-1.45,0,-.3],knL:[1.6,0,0],thR:[-1.45,0,.3],knR:[1.6,0,0],shL:[-.5,0,.3],elL:[-1.4,0,0],shR:[-.5,0,-.3],elR:[-1.4,0,0],chest:[.3+b*.04,0,0]}};}}}});
export const EXPR={
 happy:{label:'Beaming',hz:-.14,hx:-.05,eye:.8,b:{shL:[-.5,0,.6],shR:[-.5,0,-.6],elL:[-.6,0,0],elR:[-.6,0,0]}},
 focus:{label:'In step',hx:.12,eye:.72,b:{shL:[-1.2,0,.2],shR:[-1.2,0,-.2],elL:[-1,0,0],elR:[-1,0,0]}},
 startled:{label:'Startled',hx:-.15,eye:1.2,eyeW:1.1,b:{shL:[-.3,0,-1],shR:[-.3,0,1]}},
 caught:{label:'Out of step',hx:.35,hz:.14,eye:.55,b:{chest:[.2,0,0],shL:[.15,0,.1],shR:[.15,0,-.1]}}};
export const build=o=>S.build(o),loadBaked=(u,r)=>S.loadBaked(u,r);
export const BIN='twinned.bin?v=1',RES=.0046,GAME_SCALE=1.2;
export const EMBERS=[['head',[-.1,.55,-.03]],['head',[.1,.55,-.03]],['head',[0,.57,-.03]]];
export const ROUTE=[{to:[1.1,-.4],clip:'walk',sp:.24},{at:true,clip:'work',dur:3.2,face:[2,-1]},{to:[-.7,1],clip:'walk',sp:.26},{at:true,clip:'ability',dur:2.4,face:[1,3]},{at:true,clip:'idle',dur:3.6,face:[1,3]},{to:[.2,.2],clip:'run',sp:.34},{at:true,clip:'nap',dur:4.4,face:[2,2]}];
export const HERO={cam:[1.05,.52,1.85],target:[0,.3,-.02],clip:'idle'};
