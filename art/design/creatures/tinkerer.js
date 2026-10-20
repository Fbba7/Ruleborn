import * as THREE from 'three';
import {makeSculpt,makeRigKit,stdClips,sstep,vnoise,clamp,ease,bump,blink,cyc,TAU,merge,gait} from './creature-kit.js';
import {parts} from './creature-parts.js?v=8';
import {sageFrame,sageBody,nearest,region,paintFace,clothShade,mir,sageBrows} from './sage-kit.js?v=8';
// ============ THE TINKERER · Sage · Keeper level 7 · small goggled inventor, wind-up mechanical arm, belt of tools; copper and teal (GDD 11.7) ============
const COL={teal:0x1E6A70,tealL:0x3A9E98,tealD:0x0C3036,shirt:0xF0E2C4,shirtD:0xB8A07A,skin:0xE0A07A,skinD:0xA2603E,hair:0xC4541E,hairL:0xF08A40,hairD:0x6A2410,
 leather:0x6A4024,leatherD:0x2E180C,boot:0x5A3420,sole:0x2A1810,mouth:0x6A2A1A,blush:0xF08A78,brass:0xD8A850,copper:0xC8703A};
const K=Object.fromEntries(Object.entries(COL).map(([k,v])=>[k,new THREE.Color(v)]));
const F=sageFrame({k:.8,head:1.38,leg:.78});const{P,HP}=F;const HR=r=>r*F.H*F.k;let A0=null;
const def={name:'tinkerer',box:[[-.3,0,-.26],[.3,1.08,.26]],res:.0052,warm:0x2A140A,aoWarm:.2,sheen:0xFFF0D8,rim:0x9FF0E8,
 bodyMat:{roughness:.74,specularIntensity:.45,sheen:0.3,sheenRoughness:.55},fur:{shells:0},
 sculpt(A){A0=A;const{E,C}=A;
  sageBody(A,F,{skipArmR:true,belly:1.12,bootH:.1,noseLen:1.25});
  // bib of the overalls, rolled left sleeve, big tool pouches and a chunky belt
  E('T:bib',P(0,.74,.075),[.1,.09,.035],null,.03);for(const s of[-1,1])C('T:strap'+(s<0?'L':'R'),P(s*.075,.8,.09),P(s*.09,.86,-.02),.016,.016,.012);
  E('elL:roll',[F.j.el(-1)[0],F.j.el(-1)[1]-.02*.8,F.j.el(-1)[2]],[.05*.8,.022*.8,.05*.8],null,.012);
  for(const[x,z,r] of[[.1,.05,.042],[-.11,.04,.036],[.02,-.1,.04]])E('T:pouch'+x,P(x,.585,z),[r,r*1.05,r*.7],[0,Math.atan2(x,z),0],.015);
  // messy ginger hair bursting out around the goggle strap
  E('T:hairCap',HP(0,1.1,-.02),[HR(.128),HR(.095),HR(.128)],null,.04);
  const tufts=[[0,1.23,.02,.05,.5],[.07,1.21,.0,.045,-.4],[-.07,1.215,-.01,.045,.5],[.12,1.14,-.04,.04,-1],[-.12,1.13,-.05,.04,1],[0,1.19,-.12,.05,.1],[.05,1.19,-.1,.04,-.5],[-.06,1.18,-.11,.042,.6],[.13,1.06,-.03,.03,-1.2],[-.13,1.06,-.03,.03,1.2]];
  tufts.forEach(([x,y,z,r,rz],i)=>{E('T:hair'+i,HP(x,y-.02,z),[HR(r*.7),HR(r*1.1),HR(r*.7)],[0,0,rz],.025);});
  E('T:hairFringe',HP(0,1.13,.085),[HR(.09),HR(.028),HR(.04)],[.3,0,0],.025);},
 disp(x,y,z,d){if(Math.abs(d)>.03)return d;const n=nearest(A0,x,y,z);
  if(/^T:hair/.test(n))return d-Math.pow(Math.abs(Math.sin(Math.atan2(x,z)*9+y*28+vnoise(x*14,y*14,z*14)*4)),4)*.004;
  return d+(vnoise(x*70,y*70,z*70)-.5)*.0005;},
 paint(x,y,z,nx,ny,nz,ao,c,A){const n=nearest(A,x,y,z);const r=region(n);
  if(r==='skin'||r==='neck'||r==='hand'){c.copy(K.skin).lerp(new THREE.Color(0x8A3A2E),(1-ao)*.45+sstep(.2,-.6,ny)*.1);if(r==='skin')paintFace(x,y,z,c,K,F,{ao,smile:.009,blush:.45});if(/nose/.test(n))c.lerp(K.blush,.25);
   c.lerp(K.skinD,sstep(.72,.8,vnoise(x*120,y*120,z*120))*.18);return 0;}
  if(r==='hair'){c.copy(K.hair).lerp(K.hairL,sstep(.4,1,ny)*.45).lerp(K.hairD,(1-ao)*.7);return 0;}
  if(r==='boot'){c.copy(K.boot).lerp(K.leatherD,(1-ao)*.6).lerp(new THREE.Color(0xA87048),sstep(.5,1,ny)*.25);return 0;}
  if(r==='sole'){c.copy(K.sole);return 0;}
  if(r==='belt'||/pouch|strap/.test(n)&&!/strap/.test(n)){c.copy(K.leather).lerp(K.leatherD,(1-ao)*.6).lerp(new THREE.Color(0xA87048),sstep(.4,1,ny)*.3);return 0;}
  if(/strap/.test(n)){clothShade(c,K,K.teal,K.tealL,K.tealD,ny,nz,ao,x,y,z);return 0;}
  if(r==='sleeve'||r==='cuff'||/roll/.test(n)){if(/elL:arm2/.test(n)&&y<F.j.el(-1)[1]-.03){c.copy(K.skin).lerp(K.skinD,(1-ao)*.5);return 0;}clothShade(c,K,K.shirt,new THREE.Color(0xFFF8E8),K.shirtD,ny,nz,ao,x,y,z,.04);return 0;}
  if(r==='legs'){clothShade(c,K,K.teal,K.tealL,K.tealD,ny,nz,ao,x,y,z,.06);c.lerp(K.tealD,sstep(.004,0,Math.abs(x)-.0)*0);return 0;}
  // torso: teal overalls below the bib line, cream shirt above and on the back
  const bibTop=F.P(0,.8,0)[1],front=nz>-.2;const onBib=/bib/.test(n)||(y<bibTop&&front)||y<F.P(0,.66,0)[1];
  if(onBib){clothShade(c,K,K.teal,K.tealL,K.tealD,ny,nz,ao,x,y,z,.06);if(/bib/.test(n)&&Math.abs(Math.hypot(x,(y-F.P(0,.74,0)[1])*1.2)-.06)<.003)c.lerp(K.tealD,.4);}
  else clothShade(c,K,K.shirt,new THREE.Color(0xFFF8E8),K.shirtD,ny,nz,ao,x,y,z,.04);
  return 0;},
 accessories(A){const G=new THREE.Group();const Pt=parts(A,G);const{PB,add,irisTex,eye}=Pt;const T=THREE;
  const tex=irisTex('#0A0602','#6A3A12','#C8903A','#1A0E06',{pup:.34,human:true});
  for(const s of[-1,1])eye(s,{human:true,skin:COL.skin,lash:COL.hairD??0x1A0C08,r:HR(.031),ctr:HP(0,1.035,.02),dir:[.44,-.04,1],off:-.011,tex,lid:COL.skinD,lidCut:.3,yaw:.36,irisK:1.35});
  // eyebrows: thick ginger tufts
  G.add(sageBrows(Pt,F,{col:COL.hairD??COL.hair}));
  const brass=PB(COL.brass,{metalness:1,roughness:.3}),copper=PB(COL.copper,{metalness:1,roughness:.34}),steel=PB(0x5A6470,{metalness:1,roughness:.4}),lens=PB(0x5CE0D0,{roughness:.05,metalness:.2,clearcoat:1,emissive:0x1A8A80,emissiveIntensity:.5});
  // goggles pushed up on the forehead, strap round the head
  {const g=new T.Group();g.userData.bone='head';g.position.set(...HP(0,1.13,.122));g.rotation.x=-.42;g.scale.setScalar(F.H*F.k);G.add(g);
   for(const s of[-1,1]){add(new T.TorusGeometry(.036,.011,10,28),brass,[s*.043,0,0],null,null,g);add(new T.CylinderGeometry(.034,.034,.012,24),lens,[s*.043,0,.006],[Math.PI/2,0,0],null,g);add(new T.CylinderGeometry(.04,.036,.026,24,1,true),PB(0x3A2418,{roughness:.8,side:T.DoubleSide}),[s*.043,0,-.012],[Math.PI/2,0,0],null,g);
    for(let k=0;k<6;k++){const a=k/6*TAU;add(new T.SphereGeometry(.004,6,4),brass,[s*.043+Math.cos(a)*.036,Math.sin(a)*.036,.008],null,null,g);}}
   add(new T.BoxGeometry(.02,.012,.012),brass,[0,0,0],null,null,g);
   }
  {const st=add(new T.TorusGeometry(.132,.011,8,56),PB(0x3A2418,{roughness:.8}),HP(0,1.105,-.005),[Math.PI/2-.32,0,0],[F.H*F.k,F.H*F.k*1.06,F.H*F.k],G);st.userData.bone='head';}
  // brass bib buttons
  for(const s of[-1,1]){const b=add(new T.CylinderGeometry(.011,.011,.006,14),brass,P(s*.075,.8,.106),[Math.PI/2,0,0],null,G);b.userData.bone='chest';}
  // wind-up mechanical right arm: copper shells, brass joints, steel claw
  {const sh=F.j.sh(1),el=F.j.el(1),wr=F.j.wr(1);const V=a=>new T.Vector3(...a);
   const seg=(a,b,r0,r1,m,bone,bands)=>{const A_=V(a),B_=V(b),d=B_.clone().sub(A_),L=d.length();const g=new T.Group();g.position.copy(A_);g.quaternion.setFromUnitVectors(new T.Vector3(0,-1,0),d.clone().normalize());g.userData.bone=bone;G.add(g);
    add(new T.CylinderGeometry(r0,r1,L,22),m,[0,-L/2,0],null,null,g);for(const u of bands){add(new T.TorusGeometry(r0+(r1-r0)*u+.002,.004,8,26),brass,[0,-L*u,0],[Math.PI/2,0,0],null,g);for(let k=0;k<8;k++){const a=k/8*TAU;add(new T.SphereGeometry(.0032,6,4),brass,[Math.cos(a)*(r0+(r1-r0)*u+.005),-L*u,Math.sin(a)*(r0+(r1-r0)*u+.005)],null,null,g);}}return g;};
   {const g=new T.Group();g.userData.bone='shR';g.position.set(...sh);G.add(g);add(new T.SphereGeometry(.048,20,14),copper,[0,0,0],null,[1,.92,1],g);add(new T.TorusGeometry(.046,.006,8,28),brass,[0,-.01,0],[Math.PI/2,0,0],null,g);}
   seg(sh,el,.03,.027,copper,'shR',[.35,.8]);
   {const g=new T.Group();g.userData.bone='elR';g.position.set(...el);G.add(g);add(new T.SphereGeometry(.03,18,12),brass,[0,0,0],null,null,g);add(new T.CylinderGeometry(.012,.012,.07,12),steel,[0,0,0],[0,0,Math.PI/2],null,g);}
   seg(el,[wr[0],wr[1]+.01,wr[2]],.028,.034,copper,'elR',[.2,.75]);
   // gauge on the forearm with a twitching needle
   {const g=new T.Group();g.userData.bone='elR';g.position.set(el[0]+.02,el[1]-.07,el[2]+.03);g.rotation.set(0,.9,0);G.add(g);add(new T.CylinderGeometry(.016,.016,.006,20),brass,[0,0,0],[Math.PI/2,0,0],null,g);add(new T.CylinderGeometry(.013,.013,.007,20),PB(0xF4ECD8,{roughness:.5}),[0,0,.001],[Math.PI/2,0,0],null,g);const nd=add(new T.BoxGeometry(.002,.011,.002),PB(0xC03020),[0,.004,.006],null,null,g);nd.userData.spin=[3.1,.6];}
   // claw hand: palm block, three jointed fingers and a thumb
   {const g=new T.Group();g.userData.bone='haR';g.position.set(wr[0],wr[1]-.01,wr[2]);G.add(g);add(new T.CylinderGeometry(.026,.026,.02,18),brass,[0,0,0],null,null,g);add(new T.BoxGeometry(.036,.044,.05),steel,[.002,-.03,.004],null,null,g);
    for(let f=0;f<3;f++){const z=(-.016+f*.016);const a=add(new T.CylinderGeometry(.0075,.0075,.03,10),steel,[-.004,-.066,z],[0,0,.18],null,g);add(new T.SphereGeometry(.009,10,8),brass,[-.001,-.052,z],null,null,g);add(new T.ConeGeometry(.0075,.024,10),steel,[-.012,-.092,z],[0,0,.5],null,g);}
    add(new T.CylinderGeometry(.008,.007,.03,10),steel,[-.018,-.04,.03],[.6,0,.4],null,g);}
   // big brass wind-up key on the back, always turning
   {const g=new T.Group();g.userData.bone='chest';g.position.set(...P(0,.8,-.14));G.add(g);add(new T.CylinderGeometry(.009,.009,.06,12),brass,[0,0,-.03],[Math.PI/2,0,0],null,g);const kk=new T.Group();kk.position.z=-.065;kk.userData.spin=1.4;g.add(kk);
    for(const s of[-1,1])add(new T.TorusGeometry(.03,.009,10,24),brass,[s*.034,0,0],null,[1,.8,1],kk);add(new T.SphereGeometry(.013,12,8),brass,[0,0,0],null,null,kk);}}
  // tools on the belt: spanner, screwdriver, hammer
  {const g=new T.Group();g.userData.bone='hips';g.position.set(...P(-.155,.53,.02));g.rotation.set(0,0,-.1);G.add(g);add(new T.BoxGeometry(.012,.12,.006),steel,[0,-.03,0],null,null,g);add(new T.TorusGeometry(.016,.007,8,16,Math.PI*1.4),steel,[0,.035,0],[0,0,-.9],null,g);}
  {const g=new T.Group();g.userData.bone='hips';g.position.set(...P(.13,.54,.09));g.rotation.set(.1,0,.12);G.add(g);add(new T.CylinderGeometry(.012,.012,.05,10),PB(0xC03A2A,{roughness:.4,clearcoat:.6}),[0,.02,0],null,null,g);add(new T.CylinderGeometry(.003,.003,.06,8),steel,[0,-.03,0],null,null,g);}
  {const g=new T.Group();g.userData.bone='hips';g.position.set(...P(.02,.55,-.14));g.rotation.set(-.2,0,.4);G.add(g);add(new T.CylinderGeometry(.007,.008,.1,10),PB(0x8A5A30,{roughness:.7}),[0,-.02,0],null,null,g);add(new T.BoxGeometry(.05,.022,.022),steel,[0,.035,0],null,null,g);}
  // a little cog in the left hand, always being fiddled with
  {const g=new T.Group();g.userData.bone='haL';const w=F.j.wr(-1);g.position.set(w[0]+.012,w[1]-.07,w[2]+.04);g.rotation.set(0,1.2,0);G.add(g);const cg=new T.Group();cg.userData.spin=2.2;g.add(cg);
   const sh=new T.Shape();const N=10;for(let i=0;i<N*2;i++){const a=i/(N*2)*TAU,r=i%2?.022:.027;const a2=a+TAU/(N*4);if(i===0)sh.moveTo(Math.cos(a)*r,Math.sin(a)*r);else sh.lineTo(Math.cos(a)*r,Math.sin(a)*r);sh.lineTo(Math.cos(a2)*r,Math.sin(a2)*r);}sh.closePath();const hole=new T.Path();hole.absarc(0,0,.008,0,TAU,true);sh.holes.push(hole);
   add(new T.ExtrudeGeometry(sh,{depth:.006,bevelEnabled:true,bevelSize:.0015,bevelThickness:.0015,bevelSegments:1}),brass,[0,0,-.003],null,null,cg);}
  // Invert (power 1): a double arrow ring spinning over the claw
  {const fx=new T.Group();fx.userData.bone='root';fx.userData.fx='inv';fx.userData.fxMode='show';fx.position.set(...P(.08,1.35,.18));G.add(fx);const m=new T.MeshBasicMaterial({color:0x7AF0E0,transparent:true,opacity:.8,depthWrite:false,blending:T.AdditiveBlending,side:T.DoubleSide});
   const sp=new T.Group();sp.userData.spin=4;fx.add(sp);for(const s of[0,1]){const r=add(new T.TorusGeometry(.12,.012,8,40,Math.PI*.8),m,[0,0,0],[0,0,s*Math.PI],null,sp);const h=add(new T.ConeGeometry(.03,.06,12),m,[Math.cos(s*Math.PI+Math.PI*.8)*.12,Math.sin(s*Math.PI+Math.PI*.8)*.12,0],[0,0,s*Math.PI+Math.PI*.8],null,sp);}}
  // Jam (power 2): a crackling teal jammer field on the ground ahead
  {const fx=new T.Group();fx.userData.bone='root';fx.userData.fx='jam';fx.userData.fxMode='show';fx.position.set(0,.02,.7);G.add(fx);const m=new T.MeshBasicMaterial({color:0x5CE0D0,transparent:true,opacity:.7,depthWrite:false,blending:T.AdditiveBlending,side:T.DoubleSide});
   for(let k=0;k<3;k++){const r=add(new T.RingGeometry(.16+k*.1,.175+k*.1,6),m,[0,k*.004,0],[-Math.PI/2,0,k*.4],null,fx);r.userData.spin=k%2?-1.5:1.5;}
   const zz=[];for(let i=0;i<9;i++){const a=i/9*TAU;zz.push(new T.Vector3(Math.cos(a)*.3,.05+(i%2)*.06,Math.sin(a)*.3));}zz.push(zz[0].clone());add(new T.TubeGeometry(new T.CatmullRomCurve3(zz,false,'catmullrom',0),60,.006,5),m,[0,0,0],null,null,fx);}
  // Plank (power 3): a wooden plank that unfolds across the gap in front
  {const fx=new T.Group();fx.userData.bone='root';fx.userData.fx='plank';fx.userData.fxMode='show';fx.position.set(0,.03,.25);G.add(fx);const wood=PB(0xB88048,{roughness:.8});
   for(let i=0;i<4;i++){add(new T.BoxGeometry(.3,.025,.2),wood,[0,0,.12+i*.21],null,null,fx);add(new T.BoxGeometry(.31,.028,.02),PB(0x6A4024,{roughness:.8}),[0,.002,.03+i*.21],null,null,fx);for(const s of[-1,1])add(new T.CylinderGeometry(.008,.008,.03,8),brass,[s*.12,.012,.12+i*.21],null,null,fx);}}
  return G;}};
export const S=makeSculpt(def);
const cfg={name:'tinkerer',J:F.J,TIP:F.TIP,TORSO:F.TORSO,AIM:[],floor:.006,pivot:.5,shMin:-2.2,springs:[['earL','vx',-.4,120,9,0,.3],['tail','vy',-.2,140,12,0,.1]]};
const RK=makeRigKit(S,cfg);export const makeRig=RK.makeRig,skinGeo=RK.skinGeo;
// arms: L = flesh hand holding the cog, R = claw
const fid=t=>({shL:[-.55,.1,.15],elL:[-1.25,0,0],haL:[.2+Math.sin(t*5)*.1,0,0],shR:[-.5,-.1,-.2],elR:[-1.2+Math.sin(t*7)*.08,0,0],haR:[Math.sin(t*7)*.2,0,0]});
export const CLIPS=stdClips({w:.2,arm:.4,x:{
 idle:{label:'Idle',len:4,f:t=>{const b=Math.sin(t*Math.PI*.9)*.5+.5;return{sq:b*.012,hx:.22+Math.sin(t*1.2)*.03,hz:Math.sin(t*.8)*.05,elx:-.1,eye:blink(t,3.4,.5)*.95,b:merge(fid(t),{chest:[.06-b*.02,0,0]})};}},
 idle2:{label:'Idle 2',len:5,f:t=>{const u=cyc(t,5);const idea=bump(u,.35,.75);const look=Math.sin(u*TAU)*(1-idea);return{hy:look*.45,hx:.15-idea*.3,y:idea*.03,eye:1+idea*.25,b:merge(fid(t),{shL:[-.55-idea*1.4,.1,.15],elL:[-1.25+idea*.6,0,0],haL:[-idea*.5,0,0]})};}},
 p1:{label:'Invert',len:3,f:t=>{const u=cyc(t,3);const up=ease(sstep(.05,.3,u))*(1-sstep(.85,1,u));const tw=Math.sin(t*14)*up;return{hx:-.25*up,hz:.08*up,eye:1+up*.2,inv:up,b:{shR:[-2.4*up-.4*(1-up),.1,.15*up],elR:[-.3*up-1.1*(1-up),tw*.2,0],haR:[tw*.4,0,0],shL:[-.3,0,-.25*up],elL:[-.6,0,0],chest:[-.1*up,0,0]}};}},
 p2:{label:'Jam',len:3,f:t=>{const u=cyc(t,3);const aim=ease(sstep(.1,.3,u))*(1-sstep(.85,1,u));const kick=bump(u,.3,.42);return{hx:.05*aim,z:-kick*.03,jam:sstep(.32,.4,u)*(1-sstep(.88,1,u)),b:{shR:[-1.45*aim,0,.05],elR:[-.2*aim,0,0],shL:[-.9*aim,0,-.1],elL:[-.9*aim,0,0],chest:[-.05*aim+kick*.1,0,0],thL:[-.2*aim,0,0],thR:[.2*aim,0,0]}};}},
 p3:{label:'Plank',len:3.4,f:t=>{const u=cyc(t,3.4);const k=ease(sstep(.05,.3,u))*(1-sstep(.85,1,u));const lay=sstep(.3,.6,u)*(1-sstep(.88,1,u));return{y:-k*.12,hx:.25*k,plank:lay,b:{chest:[.5*k,0,0],thL:[-1.2*k,0,-.1],knL:[1.6*k,0,0],ftL:[-.3*k,0,0],thR:[-.3*k,0,.1],knR:[1.4*k,0,0],ftR:[.5*k,0,0],shL:[-1.1*k,0,.1],elL:[-.4*k,0,0],shR:[-1.1*k,0,-.1],elR:[-.4*k,0,0]}};}},
 guard:{label:'On guard',len:4,f:t=>{const u=cyc(t,4);const sc=Math.sin(u*TAU);return{hy:sc*.35,hx:.02,eye:.9,b:{shR:[-.9,0,.15],elR:[-1.6,0,0],haR:[.3,0,0],shL:[-.2,0,-.1],elL:[-.3,0,0],chest:[-.04,0,0]}};}},
 work:{label:'Tinkers at the bench',len:2,f:t=>{const u=cyc(t,.5);const hit=Math.pow(Math.sin(u*Math.PI),2);return{hx:.35,y:-.01,eye:.8,b:merge(fid(t),{shR:[-1.2+hit*.5,0,-.05],elR:[-1.4+hit*.5,0,0],chest:[.14,0,0]})};}},
 nap:{label:'Rest',len:5,f:t=>{const b=Math.sin(t*TAU/5)*.5+.5;return{y:-.24,sq:-.02,hx:.42,eye:.12,b:{thL:[-1.5,0,-.3],knL:[1.9,0,0],thR:[-1.5,0,.3],knR:[1.9,0,0],shL:[-.4,0,.2],elL:[-1.1,0,0],shR:[-.4,0,-.2],elR:[-1.1,0,0],chest:[.35+b*.03,0,0]}};}}}});
export const EXPR={
 happy:{label:'Eureka',hx:-.1,hz:.06,eye:1.1,b:{shL:[-2,0,.2],elL:[-.3,0,0],shR:[-.5,0,-.2],elR:[-1.1,0,0]}},
 focus:{label:'Fiddling',hx:.3,eye:.8,b:{shL:[-.55,.1,.15],elL:[-1.25,0,0],shR:[-.5,-.1,-.2],elR:[-1.2,0,0]}},
 startled:{label:'Kaboom',hx:-.15,eye:1.35,eyeW:1.1,b:{shL:[-.4,0,-.9],shR:[-.4,0,.9],elL:[-.5,0,0],elR:[-.5,0,0]}},
 caught:{label:'Out of gears',hx:.4,hz:.12,eye:.35,b:{chest:[.25,0,0],shL:[.15,0,.1],shR:[.15,0,-.1]}}};
export const build=o=>S.build(o),loadBaked=(u,r)=>S.loadBaked(u,r);
export const BIN='tinkerer.bin?v=1',RES=.0095,GAME_SCALE=1;
export const EMBERS=[['head',HP(0,1.22,0)],['haR',P(.25,.36,.05)],['tail',P(0,.8,-.2)]];
export const ROUTE=[{to:[1.1,-.4],clip:'walk',sp:.26},{at:true,clip:'work',dur:4,face:[2,-1]},{to:[-.7,1],clip:'walk',sp:.26},{at:true,clip:'idle2',dur:5,face:[1,3]},{at:true,clip:'idle',dur:4,face:[1,3]},{to:[.2,.2],clip:'walk',sp:.24},{at:true,clip:'guard',dur:4,face:[2,2]}];
export const HERO={cam:[1.3,.8,1.8],target:[0,.48,0],clip:'idle'};
