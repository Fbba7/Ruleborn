import * as THREE from 'three';
import {makeSculpt,makeRigKit,stdClips,sstep,vnoise,clamp,ease,bump,blink,cyc,TAU,merge,gait} from './creature-kit.js';
import {parts,hourglass} from './creature-parts.js';
// ============ STILLWATCH · Warden · Time · tall heron-like sentinel, 1.2 m, cyan and slate (GDD 11.4) ============
const COL={slate:0x4E627A,slateL:0x8C9EB2,slateD:0x222C3A,neck:0xDCE4EA,streak:0x3A4658,cap:0x1A2230,cyan:0x2FC0D4,beak:0xD8A838,beakD:0x7A5A20,leg:0x5E584A};
const K=Object.fromEntries(Object.entries(COL).map(([k,v])=>[k,new THREE.Color(v)]));
const mir=(p,s)=>[p[0]*s,p[1],p[2]];let A0=null;
const def={name:'stillwatch',box:[[-.22,0,-.46],[.22,1.2,.42]],res:.0062,warm:0x10202E,aoWarm:.2,sheen:0xE0EEFF,rim:0xBFF4FF,
 bodyMat:{roughness:.66,sheen:.35,sheenRoughness:.5},fur:{shells:0},
 sculpt(A){const{E,C}=A;A0=A;
  // slim teardrop body carried level, an S-curved neck, a dagger beak
  E('T:body',[0,.66,-.06],[.108,.1,.21],[.28,0,0],.06);E('T:breast',[0,.73,.06],[.092,.09,.085],null,.05);E('T:plume',[0,.7,.13],[.06,.07,.04],[.3,0,0],.03);
  C('T:neck1',[0,.76,.1],[0,.88,.055],.052,.038,.04);C('T:neck2',[0,.88,.055],[0,.99,.1],.038,.034,.03);
  E('T:head',[0,1.028,.118],[.048,.046,.068],[-.1,0,0],.03);C('T:beak',[0,1.028,.172],[0,1.0,.37],.019,.004,.012);
  for(const s of[-1,1]){const L=s<0?'L':'R';
   E('T:sock'+L,mir([.034,1.036,.14],s),[.012,.008,.016],null,.005,'s');
   C('ear'+L+':plume',mir([.01,1.066,.08],s),mir([.024,1.09,-.1],s),.011,.004,.01);C('ear'+L+':plume2',mir([.014,1.06,.06],s),mir([.03,1.07,-.06],s),.008,.003,.008);
   E('sh'+L+':wing',mir([.09,.7,-.06],s),[.03,.078,.18],[.3,0,s*-.06],.04);E('el'+L+':wing2',mir([.084,.655,-.2],s),[.024,.05,.12],[.42,0,0],.03);
   for(let k=0;k<4;k++)C('ha'+L+':prim'+k,mir([.08-k*.01,.64-k*.006,-.25],s),mir([.05-k*.008,.62-k*.014,-.43+k*.025],s),.016,.004,.008);
   E('th'+L+':thigh',mir([.055,.55,0],s),[.036,.06,.042],null,.04);C('th'+L+':leg1',mir([.056,.52,0],s),mir([.06,.3,-.01],s),.016,.013,.012);
   E('kn'+L+':knee',mir([.06,.3,-.01],s),[.017,.019,.017],null,.01);C('kn'+L+':leg2',mir([.06,.3,-.01],s),mir([.064,.04,0],s),.013,.011,.01);
   for(let k=0;k<3;k++){const a=(k-1)*.5;C('ft'+L+':toe'+k,mir([.064,.032,.005],s),mir([.064+Math.sin(a)*.1,.012,.005+Math.cos(a)*.1],s),.011,.006,.008);}C('ft'+L+':heel',mir([.064,.03,0],s),mir([.064,.012,-.06],s),.01,.005,.006);}
  E('tail:tail',[0,.63,-.28],[.07,.028,.08],[.4,0,0],.03);},
 disp(x,y,z,d){if(Math.abs(d)>.03)return d;const w=A0.minD(/^(sh|el|ha)[LR]:|^tail:/,x,y,z);const wing=sstep(.01,.002,w);const u=(-z+y*.3)*30;const f=u-Math.floor(u);
  return d+wing*sstep(.2,0,f)*.0008+(vnoise(x*50,y*50,z*50)-.5)*.0003;},
 paint(x,y,z,nx,ny,nz,ao,c,A){const neck=sstep(.018,.002,A.minD(/^T:(neck|head|plume|breast)/,x,y,z))*sstep(.72,.8,y);
  c.copy(K.slate).lerp(K.slateL,sstep(.2,.95,ny)*.3+sstep(.1,-.8,ny)*.35).lerp(K.slateD,(1-ao)*.5+sstep(.2,-.8,ny)*.2).offsetHSL(0,0,(vnoise(x*12,y*12,z*12)-.5)*.05);
  // pale neck with a dark streaked stripe down the front
  c.lerp(K.neck,neck*.9);const st=sstep(.4,.95,nz)*sstep(.018,.004,Math.abs(x))*neck*sstep(.99,.95,y);c.lerp(K.streak,st*(.5+.5*sstep(.3,.8,Math.abs(Math.sin(y*140)))));
  // black cap and the cyan crest
  c.lerp(K.cap,sstep(1.03,1.055,y)*sstep(.02,.004,A.dist('T:head',x,y,z))*.95);
  const cr=A.minD(/^ear[LR]:/,x,y,z);if(cr<.004)c.copy(K.cyan).lerp(K.cap,sstep(.05,-.08,z)*.35);
  const w=A.minD(/^(sh|el|ha)[LR]:/,x,y,z);if(w<.004){const u=(-z+y*.3)*30,f=u-Math.floor(u);c.lerp(K.slateL,sstep(.1,.5,ny)*sstep(-.1,.0,z)*.35);c.lerp(K.slateD,sstep(.8,.97,f)*.28+sstep(-.2,-.34,z)*.7);c.lerp(K.cyan,sstep(.012,.0,Math.abs(y-.66+(-z-.12)*.2))*.25);}
  const bk=A.dist('T:beak',x,y,z);if(bk<.004)c.copy(K.beak).lerp(K.beakD,sstep(.2,.37,z)*.5+sstep(-.2,-.7,ny)*.3);
  const lg=A.minD(/^(th[LR]:leg1|kn|ft)/,x,y,z);if(lg<.004&&y<.53)c.copy(K.leg).lerp(K.slateD,(1-ao)*.4);
  return 0;},
 accessories(A){const G=new THREE.Group();const P=parts(A,G);const{PB,add,hit,onSurf,irisTex,eye}=P;
  const tex=irisTex('#050302','#D8B020','#F8E070','#5A4210',{pup:.4});
  for(const s of[-1,1])eye(s,{r:.0145,ctr:[0,1.036,.12],dir:[1,.08,.55],off:-.004,tex,lid:COL.cap,lidCut:.46,lidTilt:.1,yaw:.95,squash:.62,irisK:1.1});
  // warden's slate gorget and pauldron, the hourglass sigil in cyan
  const stone=PB(0x5A6272,{roughness:.8,flatShading:true}),stoneL=PB(0x8A94A6,{roughness:.7,flatShading:true}),iron=PB(0x2A2E38,{metalness:.8,roughness:.4});
  {const g=new THREE.Group();g.userData.bone='chest';g.position.set(0,.8,.075);g.rotation.set(-.35,0,0);G.add(g);const tor=new THREE.TorusGeometry(.055,.014,6,10);add(tor,stone,null,[Math.PI/2,0,0],[1,1,.8],g);
   const em=new THREE.Group();em.position.set(0,-.02,.052);em.rotation.set(.35,0,0);g.add(em);add(new THREE.CylinderGeometry(.024,.024,.008,6),iron,null,[Math.PI/2,0,0],null,em);const hg=hourglass(P,.03,0x9BEAF3,0xC8963E);hg.position.z=.006;em.add(hg);}
  {const g=new THREE.Group();g.userData.bone='shL';g.position.set(-.115,.75,0);g.rotation.set(0,0,.5);G.add(g);add(new THREE.SphereGeometry(.05,8,5,0,Math.PI*2,0,Math.PI/2),stoneL,null,null,[1,.55,1.2],g);add(new THREE.TorusGeometry(.05,.005,6,10),iron,[0,.002,0],[Math.PI/2,0,0],[1,1.2,1],g);}
  // freeze glyph (ability): cyan rings on the ground and a halo above the target
  const fx=new THREE.Group();fx.userData.bone='root';fx.userData.fx='freeze';fx.userData.fxMode='show';fx.position.set(0,.01,.55);G.add(fx);
  for(let k=0;k<3;k++){const rg=P.ring(0x9BEAF3,.12+k*.07,.135+k*.07);rg.rotation.x=-Math.PI/2;fx.add(rg);}
  for(let k=0;k<6;k++){const sh=new THREE.Mesh(new THREE.OctahedronGeometry(.018,0),new THREE.MeshBasicMaterial({color:0xCFF8FF}));const a=k/6*TAU;sh.position.set(Math.cos(a)*.2,.2+(k%2)*.12,Math.sin(a)*.2);sh.scale.set(.6,1.6,.6);fx.add(sh);}
  return G;}};
export const S=makeSculpt(def);
const J={root:[null,[0,0,0]],hips:['root',[0,.6,-.02]],chest:['hips',[0,.74,.05]],head:['chest',[0,.94,.08]],earL:['head',[-.012,1.068,.07]],earR:['head',[.012,1.068,.07]],
 shL:['chest',[-.105,.75,.03]],elL:['shL',[-.1,.66,-.1]],haL:['elL',[-.085,.63,-.24]],shR:['chest',[.105,.75,.03]],elR:['shR',[.1,.66,-.1]],haR:['elR',[.085,.63,-.24]],
 thL:['hips',[-.055,.56,0]],knL:['thL',[-.06,.3,-.01]],ftL:['knL',[-.064,.04,0]],thR:['hips',[.055,.56,0]],knR:['thR',[.06,.3,-.01]],ftR:['knR',[.064,.04,0]],tail:['hips',[0,.63,-.24]]};
const cfg={name:'stillwatch',J,TIP:{haL:[-.07,.6,-.37],haR:[.07,.6,-.37],ftL:[-.064,.01,.1],ftR:[.064,.01,.1]},
 TORSO:{hips:[[0,.62,-.3],[0,.66,0],.14],chest:[[0,.66,0],[0,.9,.06],.12],head:[[0,.9,.06],[0,1.06,.2],.09]},
 AIM:[],floor:.006,pivot:.6,shMin:-1.2,springs:[['earL','vx',-.5,120,7,0,.4],['earR','vx',-.5,115,7,0,.4],['tail','vx',-.2,140,10,0,.2]]};
const RK=makeRigKit(S,cfg);export const makeRig=RK.makeRig,skinGeo=RK.skinGeo;
// one-legged stance: right leg tucked up under the body
const tuck=(k=1)=>({thR:[.55*k,0,.04*k],knR:[-2.7*k,0,0],ftR:[1.1*k,0,0],thL:[.02*k,0,-.03*k]});
export const CLIPS=stdClips({w:.55,arm:.06,x:{
 idle:{label:'Idle',len:6,f:t=>{const b=Math.sin(t*TAU/6)*.5+.5;return{sq:b*.006,hx:-.04+b*.01,hy:sstep(.6,.7,cyc(t,12))*(1-sstep(.85,.95,cyc(t,12)))*.35,x:-.012,eye:blink(t,6,2),b:merge(tuck(1),{chest:[-b*.02,0,0]})};}},
 idle2:{label:'Idle 2',len:6,f:t=>{const u=cyc(t,6);const strike=bump(u,.45,.6),aim=sstep(.1,.4,u)*(1-sstep(.62,.8,u));return{hx:.3*aim-.2*strike,hy:.2*aim,eye:.55+aim*.3,z:strike*.03,b:{chest:[.25*aim+.3*strike,0,0],hips:[.05*aim,0,0]}};}},
 ability:{label:'Freeze',len:2.8,f:t=>{const u=cyc(t,2.8);const point=sstep(.05,.25,u)*(1-sstep(.85,1,u)),hold=sstep(.25,.3,u)*(1-sstep(.8,.9,u));const q=Math.sin(u*90)*.004*(1-hold);return{hx:.12*point,rx:.05*point,eye:.5+hold*.5,eyeW:1+hold*.05,freeze:hold,x:q,
  b:{chest:[.2*point,0,0],shL:[-.2*point,0,-.5*point],shR:[-.2*point,0,.5*point],elL:[.3*point,0,0],elR:[.3*point,0,0],thR:[-.35*point,0,0],knR:[.6*point,0,0]}};}},
 work:{label:'Stands on one leg',len:8,f:t=>{const b=Math.sin(t*TAU/8)*.5+.5;return{sq:b*.004,hx:.18,x:-.012,eye:.55,b:merge(tuck(1),{chest:[.06+b*.01,0,0]})};}},
 nap:{label:'Rest',len:6,f:t=>{const b=Math.sin(t*TAU/6)*.5+.5;return{sq:-.02+b*.006,hx:.9,hy:1.2,hz:.3,x:-.012,eye:.04,b:merge(tuck(1),{chest:[-.35+b*.02,0,0]})};}},
 celebrate:{label:'Celebrate',len:2.4,f:t=>{const u=cyc(t,2.4);const sp=bump(u,.05,.75),hop=bump(u,.3,.55);return{y:hop*.06,hx:-.3*sp,eye:1,freeze:bump(u,.2,.6)*.4,b:{shL:[-.3*sp,0,-1.5*sp],shR:[-.3*sp,0,1.5*sp],elL:[.4*sp,0,-.4*sp],elR:[.4*sp,0,.4*sp],chest:[-.2*sp,0,0],thL:[-.3*hop,0,0],knL:[.5*hop,0,0],thR:[-.3*hop,0,0],knR:[.5*hop,0,0]}};}}}});
export const EXPR={
 patient:{label:'Patient',hx:.1,eye:.5,b:{}},
 focus:{label:'Watching',hx:.2,hy:.25,eye:.42,eyeW:1.04,b:{chest:[.18,0,0]}},
 startled:{label:'Startled',hx:-.3,eye:1.1,eyeW:1.05,b:{shL:[-.2,0,-.8],shR:[-.2,0,.8],chest:[-.15,0,0]}},
 caught:{label:'Caught',hx:.5,hz:.2,eye:.4,b:{chest:[.35,0,.08],shL:[.1,0,.1],shR:[.1,0,-.1]}}};
export const build=o=>S.build(o),loadBaked=(u,r)=>S.loadBaked(u,r);
export const BIN='stillwatch.bin?v=1',RES=.0062,GAME_SCALE=1.1;
export const EMBERS=[['earL',[-.024,1.09,-.1]],['earR',[.024,1.09,-.1]],['tail',[0,.63,-.33]]];
export const ROUTE=[{to:[1.2,-.4],clip:'walk',sp:.2},{at:true,clip:'work',dur:8,face:[2,-1]},{to:[-.8,1],clip:'walk',sp:.2},{at:true,clip:'ability',dur:2.8,face:[1,3]},{at:true,clip:'idle',dur:6,face:[1,3]},{to:[.2,.2],clip:'carry',sp:.18},{at:true,clip:'nap',dur:6,face:[2,2]}];
export const HERO={cam:[1.8,1.15,2.1],target:[0,.6,0],clip:'idle'};
