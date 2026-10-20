import * as THREE from 'three';
import {makeSculpt,makeRigKit,stdClips,sstep,vnoise,clamp,ease,bump,blink,cyc,TAU,merge,gait} from './creature-kit.js';
import {parts} from './creature-parts.js';
// ============ PRISM MITE · Carrier · Matter · tiny prism bug with a backpack, 0.5 m, violet with rainbow edges (GDD 11.4) ============
const COL={shell:0x5A34D0,shellL:0x9A7CFF,shellD:0x1C0E58,belly:0xC8B8FF,bellyD:0x8A76D0,seam:0x1A0E40,foot:0x3A2A7A,cheek:0xF0A0D0};
const K=Object.fromEntries(Object.entries(COL).map(([k,v])=>[k,new THREE.Color(v)]));
const mir=(p,s)=>[p[0]*s,p[1],p[2]];const RB=new THREE.Color();
let A0=null;
const def={name:'prismmite',box:[[-.2,0,-.22],[.2,.6,.2]],res:.0042,warm:0x2A1060,aoWarm:.22,sheen:0xE8DCFF,rim:0xD8C8FF,
 bodyMat:{roughness:.26,sheen:0,clearcoat:1,clearcoatRoughness:.12,iridescence:.22,iridescenceIOR:1.38,iridescenceThicknessRange:[200,700]},fur:{shells:0},
 sculpt(A){const{E,C}=A;A0=A;
  // round segmented abdomen, small thorax, a huge head
  E('T:abdomen',[0,.14,-.07],[.1,.086,.112],[.25,0,0],.04);E('T:thorax',[0,.22,-.005],[.078,.066,.07],null,.04);
  E('T:head',[0,.345,.03],[.128,.116,.112],null,.04);E('T:brow',[0,.4,.07],[.1,.04,.06],null,.03);E('T:jaw',[0,.29,.08],[.075,.045,.05],null,.03);
  E('T:mouthcut',[0,.284,.128],[.03,.005,.016],[.2,0,0],.005,'s');
  for(const s of[-1,1]){const L=s<0?'L':'R';
   E('T:cheek'+L,[s*.07,.3,.08],[.048,.04,.045],null,.03);
   C('ear'+L+':ant1',mir([.04,.44,.05],s),mir([.078,.505,.06],s),.011,.008,.02);C('ear'+L+':ant2',mir([.078,.505,.06],s),mir([.1,.545,.025],s),.008,.006,.008);E('ear'+L+':bulb',mir([.104,.552,.018],s),[.019,.019,.019],null,.008);
   const sh=mir([.072,.235,.02],s),el=mir([.088,.19,.042],s),wr=mir([.09,.148,.06],s);C('sh'+L+':arm1',sh,el,.021,.018,.018);C('el'+L+':arm2',el,wr,.018,.016,.012);
   E('ha'+L+':mitt',mir([.091,.128,.068],s),[.021,.02,.021],null,.012);C('ha'+L+':thumb',mir([.082,.134,.08],s),mir([.076,.13,.087],s),.008,.006,.006);
   E('th'+L+':haunch',mir([.05,.098,-.02],s),[.042,.044,.044],null,.03);C('kn'+L+':shin',mir([.055,.078,-.01],s),mir([.06,.034,.006],s),.025,.022,.018);
   E('ft'+L+':foot',mir([.06,.018,.028],s),[.03,.018,.042],null,.012);for(let k=0;k<2;k++){const o=(k-.5)*.026;E('ft'+L+':toe'+k,mir([.06+o,.014,.066],s),[.012,.011,.013],null,.006);}}
  E('tail:tip',[0,.11,-.17],[.036,.03,.03],null,.03);},
 disp(x,y,z,d){if(Math.abs(d)>.03)return d;const ab=sstep(.02,.004,A0.minD(/^T:abdomen|^tail:/,x,y,z));const u=(-z-.02+y*.25)/.036;const f=u-Math.floor(u);
  const head=sstep(.02,.004,A0.dist('T:head',x,y,z))*sstep(.36,.42,y);const cap=Math.abs(x)<.004?.0012:0;
  return d+ab*(sstep(.14,0,f)*.004-Math.sin(f*Math.PI)*.0015)+head*(sstep(.004,0,Math.abs(x))*.0012)+(vnoise(x*120,y*120,z*120)-.5)*.0005;},
 paint(x,y,z,nx,ny,nz,ao,c,A){const ab=sstep(.02,.004,A.minD(/^T:abdomen|^tail:/,x,y,z));const u=(-z-.02+y*.25)/.036;const f=u-Math.floor(u);
  const under=sstep(.1,-.6,ny)*sstep(-.2,.6,nz)+sstep(.03,.0,A.minD(/^T:(jaw|cheek)/,x,y,z))*.8;
  c.copy(K.shell).lerp(K.shellL,sstep(.2,.95,ny)*.28+sstep(.4,.9,nz)*.1).lerp(K.shellD,(1-ao)*.45+sstep(-.1,-.8,ny)*.25);
  c.lerp(K.belly,clamp(under,0,1)*.55);c.lerp(K.bellyD,clamp(under,0,1)*(1-ao)*.4);
  c.lerp(K.seam,ab*sstep(.12,0,f)*.8);
  // rainbow edge: hue walks around the silhouette-facing normals
  const edge=sstep(.55,.95,Math.abs(nx))*(1-clamp(under,0,1));RB.setHSL(((y*3.2+z*2+nx*.3)%1+1)%1,.85,.6);c.lerp(RB,edge*.3);
  const lm=A.minD(/^(sh|el|ha|th|kn|ft)[LR]:|^ear/,x,y,z);if(lm<.004){c.lerp(K.foot,.35*sstep(.2,-.6,ny));}
  if(A.minD(/^ear[LR]:bulb/,x,y,z)<.003){RB.setHSL(((y*6+x*4)%1+1)%1,.9,.72);c.copy(RB);}
  c.lerp(K.cheek,sstep(.03,0,Math.hypot(Math.abs(x)-.085,y-.29,(z-.105)*1.4)-.0)*.55);
  return 0;},
 accessories(A){const G=new THREE.Group();const P=parts(A,G);const{PB,add,hit,onSurf,irisTex,eye}=P;
  // enormous compound eyes: dark violet with a honeycomb sheen
  const tex=irisTex('#07040F','#2A1A62','#7A5CE8','#120A2A',{pup:.36,hex:true});
  for(const s of[-1,1])eye(s,{r:.05,ctr:[0,.35,.03],dir:[.58,.12,1],off:-.016,tex,lid:COL.shellD,lidCut:.3,yaw:.42,irisK:1.25});
  // Matter hexagon glowing on the brow
  {const g=new THREE.Group();onSurf(g,[0,.55,1],[0,.36,.03],.001,'head');const gm=PB(0xFFFFFF,{emissive:0xC8B4FF,emissiveIntensity:1.8});add(new THREE.TorusGeometry(.014,.0028,6,6),gm,null,[0,0,Math.PI/6],null,g);add(new THREE.CylinderGeometry(.005,.005,.002,6),gm,null,[Math.PI/2,0,0],null,g);}
  // the backpack: a faceted rainbow prism in a leather harness
  const pack=new THREE.Group();pack.userData.bone='chest';pack.position.set(.01,.3,-.095);pack.rotation.set(-.3,0,.18);pack.scale.setScalar(1.35);G.add(pack);
  const pm=PB(0xB898FF,{roughness:.04,transmission:.3,thickness:.08,ior:1.6,iridescence:1,iridescenceIOR:1.5,clearcoat:1,flatShading:true,emissive:0x7A4CF0,emissiveIntensity:.55});
  const body=new THREE.CylinderGeometry(.042,.05,.12,6,1);add(body,pm,[0,.03,0],null,null,pack);add(new THREE.ConeGeometry(.042,.05,6),pm,[0,.115,0],null,null,pack);add(new THREE.ConeGeometry(.05,.04,6),pm,[0,-.05,0],[Math.PI,0,0],null,pack);
  const pl=new THREE.PointLight(0xC8A8FF,.35,.35,2);pl.position.set(0,.03,-.02);pack.add(pl);
  const lea=PB(0x6A4030,{roughness:.75}),brass=PB(0xC89A4A,{metalness:1,roughness:.35});
  for(const y of[-.005,.06])add(new THREE.TorusGeometry(.049,.006,6,18),lea,[0,y,0],[Math.PI/2,0,0],[1,1,1],pack);
  add(new THREE.BoxGeometry(.07,.08,.012),lea,[0,.02,.05],null,null,pack);add(new THREE.SphereGeometry(.007,10,8),brass,[0,.055,.057],null,null,pack);
  for(const s of[-1,1]){const st=new THREE.Mesh(new THREE.TorusGeometry(.062,.005,6,24,Math.PI*1.1),lea);st.position.set(s*.042,.235,.0);st.rotation.set(0,Math.PI/2,-.2);st.userData.bone='chest';st.castShadow=true;G.add(st);}
  // split sparkle (ability): prism shards burst out
  const fx=new THREE.Group();fx.userData.bone='root';fx.userData.fx='split';fx.userData.fxMode='show';fx.position.set(0,.2,0);G.add(fx);
  for(let k=0;k<10;k++){const a=k/10*TAU;const sh=new THREE.Mesh(new THREE.OctahedronGeometry(.012+(k%3)*.005,0),new THREE.MeshBasicMaterial({color:new THREE.Color().setHSL(k/10,.9,.7)}));sh.position.set(Math.cos(a)*(.16+(k%2)*.05),.02+(k%3)*.05,Math.sin(a)*(.16+(k%2)*.05));sh.rotation.set(k,k*2,0);fx.add(sh);}
  return G;}};
export const S=makeSculpt(def);
const J={root:[null,[0,0,0]],hips:['root',[0,.14,-.03]],chest:['hips',[0,.22,0]],head:['chest',[0,.29,.03]],earL:['head',[-.04,.44,.05]],earR:['head',[.04,.44,.05]],
 shL:['chest',[-.072,.235,.02]],elL:['shL',[-.088,.19,.042]],haL:['elL',[-.09,.148,.06]],shR:['chest',[.072,.235,.02]],elR:['shR',[.088,.19,.042]],haR:['elR',[.09,.148,.06]],
 thL:['hips',[-.05,.098,-.02]],knL:['thL',[-.055,.078,-.01]],ftL:['knL',[-.06,.034,.006]],thR:['hips',[.05,.098,-.02]],knR:['thR',[.055,.078,-.01]],ftR:['knR',[.06,.034,.006]],tail:['hips',[0,.12,-.14]]};
const cfg={name:'prismmite',J,TIP:{haL:[-.092,.11,.074],haR:[.092,.11,.074],ftL:[-.06,.004,.07],ftR:[.06,.004,.07]},
 TORSO:{hips:[[0,.06,-.1],[0,.2,-.03],.13],chest:[[0,.18,0],[0,.27,.01],.1],head:[[0,.26,.03],[0,.47,.03],.15]},
 AIM:[],floor:.004,pivot:.14,shMin:-1.7,springs:[['earL','vx',-.6,170,7,0,.5],['earR','vx',-.6,160,7,0,.5],['tail','vy',-.4,130,9,0,.3]]};
const RK=makeRigKit(S,cfg);export const makeRig=RK.makeRig,skinGeo=RK.skinGeo;
export const CLIPS=stdClips({w:.1,arm:.5,x:{
 idle:{label:'Idle',len:3,f:t=>{const b=Math.sin(t*TAU/1.5)*.5+.5;const chat=Math.sin(t*9)*bump(t%3,.6,1.6);const tilt=Math.sin(t*TAU/3);return{y:b*.006,sq:b*.02,hx:-.05+chat*.04,hz:tilt*.14,hy:tilt*.12,elx:-.1,eye:blink(t,3,.3),b:{chest:[-b*.04,0,tilt*.05],shL:[-.15+chat*.3,0,.1],shR:[-.2-chat*.25,0,-.1],elL:[-.45,0,0],elR:[-.55,0,0],tail:[0,tilt*.3,0]}};}},
 idle2:{label:'Idle 2',len:4,f:t=>{const u=cyc(t,4);const peek=bump(u,.1,.5),hop=bump(u,.55,.7);return{y:hop*.05,sq:hop*.04-bump(u,.7,.78)*.05,hy:.7*peek*Math.sin(u*TAU*2),hx:-.15*peek,eye:1+peek*.15,eyeW:1+peek*.05,b:{shL:[-.4*peek,0,-.4*peek],shR:[-.4*peek,0,.4*peek],thL:[-.5*hop,0,0],knL:[.8*hop,0,0],thR:[-.5*hop,0,0],knR:[.8*hop,0,0]}};}},
 ability:{label:'Split',len:2.4,f:t=>{const u=cyc(t,2.4);const crouch=bump(u,0,.3),spin=sstep(.2,.55,u),burst=bump(u,.42,.8),shake=bump(u,.25,.5);return{y:burst*.07-crouch*.03,sq:-crouch*.1+burst*.06,ry:spin*TAU*2,rz:Math.sin(u*80)*.04*shake,x:Math.sin(u*120)*.01*shake,eye:1+burst*.2,eyeW:1+burst*.1,split:burst,
  b:{shL:[-1.8*burst,0,-.6*burst],shR:[-1.8*burst,0,.6*burst],elL:[-.3,0,0],elR:[-.3,0,0],thL:[-.9*crouch,0,-.2*burst],knL:[1.3*crouch,0,0],thR:[-.9*crouch,0,.2*burst],knR:[1.3*crouch,0,0]}};}},
 work:{label:'Plays with itself',len:3.2,f:t=>{const u=cyc(t,3.2);const side=Math.sin(u*TAU);const hop=Math.abs(Math.sin(u*TAU*2));return{x:side*.05,y:hop*.035,sq:hop*.03,ry:side*.9,hz:-side*.15,eye:blink(t,3.2,1),split:bump(u,.4,.6)*.6,b:{shL:[-1.2*hop,0,-.5],shR:[-1.2*(1-hop),0,.5],elL:[-.4,0,0],elR:[-.4,0,0],thL:[-.4*hop,0,0],knL:[.6*hop,0,0],thR:[-.4*(1-hop),0,0],knR:[.6*(1-hop),0,0],tail:[0,side*.5,0]}};}},
 nap:{label:'Nap',len:4,f:t=>{const b=Math.sin(t*TAU/4)*.5+.5;return{y:-.05,sq:-.06+b*.03,rx:.35,hx:.45,hz:.2,eye:.05,b:{thL:[-1.5,0,-.3],knL:[2,0,0],thR:[-1.5,0,.3],knR:[2,0,0],shL:[-.6,0,.5],elL:[-1.2,0,0],shR:[-.6,0,-.5],elR:[-1.2,0,0],chest:[.35+b*.04,0,0],tail:[.2,0,0]}};}}}});
export const EXPR={
 happy:{label:'Chatty',hz:-.14,hx:-.05,eye:1.05,b:{shL:[-.9,0,-.4],shR:[-.4,0,.3],elL:[-.8,0,0],elR:[-.5,0,0]}},
 focus:{label:'Focused',hx:.12,eye:.62,eyeW:1.05,b:{shL:[-.5,0,-.2],shR:[-.5,0,.2],elL:[-1,0,0],elR:[-1,0,0]}},
 startled:{label:'Startled',hx:-.15,eye:1.2,eyeW:1.1,b:{shL:[-.4,0,-1],shR:[-.4,0,1],elL:[-.4,0,0],elR:[-.4,0,0]}},
 caught:{label:'Caught',hx:.3,hz:.1,eye:.55,b:{shL:[.1,0,.2],shR:[.1,0,-.2],chest:[.2,0,0]}}};
export const build=o=>S.build(o),loadBaked=(u,r)=>S.loadBaked(u,r);
export const BIN='prismmite.bin?v=1',RES=.0042,GAME_SCALE=1.35;
export const EMBERS=[['earL',[-.105,.56,.02]],['earR',[.105,.56,.02]],['chest',[0,.37,-.12]]];
export const ROUTE=[{to:[1.1,-.4],clip:'run',sp:.42},{at:true,clip:'work',dur:6.4,face:[2,1]},{to:[-.7,1],clip:'walk',sp:.26},{at:true,clip:'ability',dur:2.4,face:[1,3]},{at:true,clip:'idle',dur:3,face:[1,3]},{to:[.2,.2],clip:'carry',sp:.24},{at:true,clip:'nap',dur:4,face:[2,2]}];
export const HERO={cam:[1.1,.6,1.34],target:[0,.28,0],clip:'idle'};
