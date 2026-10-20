import * as THREE from 'three';
import {makeSculpt,makeRigKit,stdClips,sstep,vnoise,clamp,ease,bump,blink,cyc,TAU,merge,gait} from './creature-kit.js';
import {parts} from './creature-parts.js';
// ============ THE REVERSER · Legendary paradox-born · from Reversal · walks on its hands in inverted colours (GDD 11.8, 21.6) ============
// A handstanding lemur-acrobat: hands on the ground, legs to the sky, an upside-down face and photo-negative colours.
const COL={fur:0xB4ECF2,furL:0xE6FCFF,furD:0x4E86B0,mask:0x1C2438,maskL:0x34405A,paw:0x2A3450,pawL:0x4A5878,mag:0xE05CB4,magL:0xFF9AD8,mouth:0xF4FBFF,nose:0xF4FBFF,band:0x1C2438};
const K=Object.fromEntries(Object.entries(COL).map(([k,v])=>[k,new THREE.Color(v)]));
const mir=(p,s)=>[p[0]*s,p[1],p[2]];let A0=null;
const def={name:'reverser',box:[[-.26,0,-.2],[.26,.86,.26]],res:.0052,warm:0x0A1830,aoWarm:.18,sheen:0xE8F8FF,rim:0xFF9AD8,
 bodyMat:{roughness:.66,sheen:.55,sheenRoughness:.45},fur:{shells:0},
 sculpt(A){const{E,C}=A;A0=A;
  // shoulder girdle low, torso rising to a small pelvis, legs to the sky
  E('T:shoulders',[0,.29,0],[.115,.06,.075],null,.05);E('T:torso',[0,.4,-.01],[.085,.1,.07],null,.06);E('T:pelvis',[0,.5,-.015],[.07,.05,.058],null,.04);
  E('T:belly',[0,.4,.04],[.065,.085,.04],null,.04);
  // head hangs forward between the arms, upside down (crown towards the ground)
  C('T:neck',[0,.29,.04],[0,.25,.09],.05,.055,.04);
  E('head:skull',[0,.19,.12],[.118,.106,.1],null,.05);E('head:face',[0,.195,.19],[.09,.08,.045],null,.035);
  E('head:muzzle',[0,.232,.205],[.042,.03,.03],null,.022);// muzzle sits above the eyes: the face is inverted
  for(const s of[-1,1]){const L=s<0?'L':'R';
   E('head:cheek'+L,mir([.075,.2,.16],s),[.045,.04,.04],null,.03);
   // tufted ears on the crown (now the bottom), swept back
   C('head:ear'+L,mir([.07,.12,.08],s),mir([.12,.085,.04],s),.03,.012,.02);E('head:earcup'+L,mir([.095,.105,.07],s),[.026,.03,.012],[0,s*.5,s*.6],.006,'s');
   // arms are its legs: shoulder, elbow, broad hand planted on the ground
   const sh=mir([.12,.28,.01],s),el=mir([.14,.15,.04],s),wr=mir([.145,.045,.05],s);
   C('th'+L+':arm1',sh,el,.034,.027,.02);C('kn'+L+':arm2',el,wr,.027,.022,.015);
   E('ft'+L+':palm',mir([.147,.024,.07],s),[.036,.019,.046],null,.014);
   for(let k=0;k<4;k++){const a=(k-1.5)*.34;C('ft'+L+':finger'+k,mir([.147+Math.sin(a)*.018,.016,.1],s),mir([.147+Math.sin(a)*.03,.01,.125],s),.0095,.008,.005);}
   C('ft'+L+':thumb',mir([.12,.02,.07],s),mir([.108,.012,.09],s),.009,.007,.005);
   // legs point up: thigh, shin, and a padded foot with its sole to the sky
   const hp=mir([.05,.52,-.01],s),kn=mir([.075,.64,.015],s),an=mir([.082,.75,0],s);
   C('sh'+L+':thigh',hp,kn,.036,.028,.025);C('el'+L+':shin',kn,an,.026,.02,.015);
   E('ha'+L+':foot',mir([.084,.775,.018],s),[.03,.022,.05],[-.25,0,0],.014);
   for(let k=0;k<3;k++){const a=(k-1)*.4;E('ha'+L+':toe'+k,mir([.084+Math.sin(a)*.02,.795,.055+Math.cos(a)*.004],s),[.011,.011,.013],null,.006);}}
  E('tail:root',[0,.52,-.07],[.03,.03,.03],null,.02);},
 disp(x,y,z,d){if(Math.abs(d)>.03)return d;const face=sstep(.03,.006,A0.minD(/^head:(face|muzzle|cheek)/,x,y,z));
  const fl=Math.pow(vnoise(x*70,y*26,z*70),2)*-.0016;return d+(1-face)*fl+(vnoise(x*140,y*140,z*140)-.5)*.0005;},
 paint(x,y,z,nx,ny,nz,ao,c,A){
  // photo-negative fur: pale ice where it would be dark, with ink shadows turned blue
  c.copy(K.fur).lerp(K.furL,sstep(.1,.9,-ny)*.35+sstep(.3,.9,nz)*.1).lerp(K.furD,(1-ao)*.5+sstep(-.1,-.8,-ny)*.12);
  c.lerp(K.furD,Math.pow(vnoise(x*60,y*22,z*60),3)*.3);
  // dark belly and inner limbs (inverted cream)
  const bel=sstep(.003,-.001,A.dist('T:belly',x,y,z))*sstep(.05,.06,z);c.lerp(K.maskL,bel*.85);
  // lemur mask: dark face with pale rings round the eyes
  const fr=Math.hypot(x*.95,(y-.178)*1.05);const fc=sstep(.108,.09,fr)*sstep(.12,.155,z);c.lerp(K.mask,fc).lerp(K.maskL,fc*sstep(.5,.9,ny)*.3);
  for(const s of[-1,1]){const r=Math.hypot(x-s*.042,(y-.168)*1.1);c.lerp(K.furL,sstep(.052,.047,r)*sstep(.034,.039,r)*fc*.95);}
  // magenta paradox bands on the forearms and shins
  if(A.minD(/^(kn[LR]|el[LR]):/,x,y,z)<.004){const yy=A.minD(/^kn[LR]:/,x,y,z)<.004?y:y;const b=Math.sin(yy*80)*.5+.5;c.lerp(K.mag,sstep(.6,.72,b)*.9);}
  if(A.minD(/^(ft[LR]|ha[LR]):/,x,y,z)<.003)c.copy(K.paw).lerp(K.pawL,sstep(.2,.9,ny)*.3+sstep(.2,.9,-ny)*.2).lerp(K.mask,(1-ao)*.4);
  if(A.minD(/^head:earcup/,x,y,z)<.003)c.lerp(K.mag,.7);
  // pale nose and an upside-down grin above it
  if(A.dist('head:muzzle',x,y,z)<.004&&z>.225){const r=Math.hypot(x,(y-.222)*1.3);c.lerp(K.nose,sstep(.014,.009,r));}
  if(z>.19&&Math.abs(x)<.032){const u=x/.032,cy=.252+.009*(1-u*u);const dd=Math.abs(y-cy),w=.0024*(1-u*u*.5);if(dd<w)c.copy(K.mouth);else if(dd<w+.003)c.lerp(K.mouth,.4*(1-(dd-w)/.003));}
  // magenta blush under the eyes (above them, from our side)
  for(const s of[-1,1])c.lerp(K.mag,sstep(.026,0,Math.hypot(x-s*.07,y-.2,(z-.17)*1.4))*.35);
  return 0;},
 accessories(A){const G=new THREE.Group();const P=parts(A,G);const{PB,add,irisTex,eye,glowTex}=P;
  // inverted eyes: glowing white pupils in ink-dark irises; catch-lights turned black
  const tex=irisTex('#F4FBFF','#1A6A7A','#0A2436','#03060C',{pup:.3});
  for(const s of[-1,1]){const e=eye(s,{r:.036,ctr:[0,.19,.12],dir:[.42,-.24,1],off:-.012,tex,lid:COL.mask,lidCut:.2,lidTilt:.1,yaw:.4,irisK:1.25,roll:Math.PI});
   e.traverse(o=>{if(o.material&&o.material.isMeshBasicMaterial)o.material.color.set(0x0A0A18);});}
  // lemur tail: sweeps back and away from the body, then rolls into a wide flat spiral like a question mark
  {const g=new THREE.Group();g.userData.bone='tail';g.position.set(0,.53,-.07);G.add(g);
   const cu=new THREE.Curve();cu.getPoint=(t,o=new THREE.Vector3())=>{if(t<.4){const u=t/.4;return o.set(u*.07,-.01+u*.1,-.02-u*.2);}const u=(t-.4)/.6;const a=u*TAU*.95,r=.12*(1-u*.72);return o.set(.07+Math.sin(a)*r*.25,.09+r-Math.cos(a)*r+u*.05,-.22-Math.sin(a)*r);};
   const tg=new THREE.TubeGeometry(cu,120,.034,12);{const p=tg.attributes.position,uv=tg.attributes.uv,col=[],cen=new THREE.Vector3(),q=new THREE.Vector3();for(let i=0;i<p.count;i++){const u=uv.getX(i);cu.getPoint(u,cen);q.set(p.getX(i),p.getY(i),p.getZ(i)).sub(cen).multiplyScalar((1.05-u*.55)*(1-sstep(.9,1,u)*.7)).add(cen);p.setXYZ(i,q.x,q.y,q.z);const s=Math.sin(u*TAU*7.5)*.5+.5;const w=sstep(.35,.65,s);const c=K.furL.clone().lerp(K.maskL,w);col.push(c.r,c.g,c.b);}tg.computeVertexNormals();tg.setAttribute('color',new THREE.Float32BufferAttribute(col,3));}
   add(tg,PB(0xffffff,{vertexColors:true,roughness:.75,sheen:.8,sheenColor:new THREE.Color(0xE8F8FF)}),null,null,null,g);add(new THREE.SphereGeometry(.045,16,12),PB(COL.fur,{roughness:.7,sheen:.6}),[0,-.012,-.005],null,[1,.8,1.1],g);
   const tip=cu.getPoint(1),tg2=cu.getTangent(1);const tf=add(new THREE.ConeGeometry(.02,.05,12),PB(COL.mag,{roughness:.6,sheen:.9,sheenColor:new THREE.Color(0xFFC8EA),emissive:0x5A1040,emissiveIntensity:.3}),[tip.x,tip.y,tip.z],null,null,g);tf.quaternion.setFromUnitVectors(new THREE.Vector3(0,1,0),tg2.normalize());
   }
  // a belt sash in magenta with a swap-arrows buckle
  {const g=new THREE.Group();g.userData.bone='chest';G.add(g);const cu=new THREE.CatmullRomCurve3([...Array(17)].map((_,i)=>{const a=i/16*TAU;return new THREE.Vector3(Math.sin(a)*.082,.45+Math.sin(a*2)*.003,-.012+Math.cos(a)*.07);}),true);
   add(new THREE.TubeGeometry(cu,64,.011,8,true),PB(COL.mag,{roughness:.5,sheen:.6}),null,null,[1,.5,1],g);
   const bk=new THREE.Group();bk.position.set(0,.45,.06);g.add(bk);add(new THREE.TorusGeometry(.018,.005,8,24),PB(0xF4FBFF,{metalness:.6,roughness:.25}),null,null,null,bk);
   for(const s of[-1,1]){add(new THREE.ConeGeometry(.007,.012,8),PB(0xF4FBFF,{metalness:.6,roughness:.25}),[s*.018,s*.004,.004],[0,0,s*Math.PI/2],null,bk);}}
  // wrist wraps
  for(const s of[-1,1]){const L=s<0?'L':'R';const g=new THREE.Group();g.userData.bone='kn'+L;G.add(g);add(new THREE.TorusGeometry(.025,.008,8,24),PB(0xF4FBFF,{roughness:.7}),mir([.145,.065,.05],s),[Math.PI/2,0,0],null,g);}
  // reversal (ability): two magenta swap arrows chasing each other round it
  const fx=new THREE.Group();fx.userData.bone='root';fx.userData.fx='split';fx.userData.fxMode='show';fx.position.set(0,.4,0);G.add(fx);fx.userData.spin=6;fx.userData.spinAx='y';
  const am=new THREE.MeshBasicMaterial({color:0xFF7ACC,transparent:true,opacity:.85,blending:THREE.AdditiveBlending,depthWrite:false,side:THREE.DoubleSide});
  for(let k=0;k<2;k++){const g=new THREE.Group();g.rotation.y=k*Math.PI;fx.add(g);const cu=new THREE.Curve();cu.getPoint=(t,o=new THREE.Vector3())=>{const a=t*Math.PI*.8;return o.set(Math.sin(a)*.3,Math.sin(t*Math.PI)*.05-.02,Math.cos(a)*.3);};
   add(new THREE.TubeGeometry(cu,40,.012,6),am,null,null,null,g);const e=cu.getPoint(1);add(new THREE.ConeGeometry(.03,.07,10),am,[e.x,e.y,e.z],[Math.PI/2,0,Math.PI*.8+Math.PI/2],null,g).lookAt(0,e.y,0);}
  return G;}};
export const S=makeSculpt(def);
const J={root:[null,[0,0,0]],hips:['root',[0,.28,0]],chest:['hips',[0,.4,-.01]],head:['hips',[0,.27,.06]],earL:['head',[-.07,.12,.08]],earR:['head',[.07,.12,.08]],
 shL:['chest',[-.05,.52,-.01]],elL:['shL',[-.075,.64,.015]],haL:['elL',[-.082,.75,0]],shR:['chest',[.05,.52,-.01]],elR:['shR',[.075,.64,.015]],haR:['elR',[.082,.75,0]],
 thL:['hips',[-.12,.28,.01]],knL:['thL',[-.14,.15,.04]],ftL:['knL',[-.145,.045,.05]],thR:['hips',[.12,.28,.01]],knR:['thR',[.14,.15,.04]],ftR:['knR',[.145,.045,.05]],tail:['chest',[0,.52,-.07]]};
const cfg={name:'reverser',J,TIP:{haL:[-.084,.8,.03],haR:[.084,.8,.03],ftL:[-.147,.008,.12],ftR:[.147,.008,.12]},
 TORSO:{hips:[[0,.26,0],[0,.32,0],.12],chest:[[0,.36,0],[0,.55,0],.1],head:[[0,.14,.13],[0,.22,.13],.06]},
 AIM:[],floor:.004,pivot:.3,shMin:-1.2,shMax:1.2,springs:[['tail','vx',-.5,90,6,0,.4],['tail','vz',.4,90,6,2,.3],['earL','vx',.3,120,8,0,.3],['earR','vx',.3,120,8,0,.3]]};
const RK=makeRigKit(S,cfg);export const makeRig=RK.makeRig,skinGeo=RK.skinGeo;
// legs to the sky: a balancing sway replaces the arm swing of the standard set
const LEGS=(t,k=1,kick=0)=>{const w=Math.sin(t*2.1)*.12*k,v=Math.sin(t*1.3+1)*.08*k;return{shL:[w+kick,0,.2+v],shR:[-w-kick,0,-.2-v],elL:[-.35-Math.max(0,w)*.6,0,0],elR:[-.35-Math.max(0,-w)*.6,0,0],haL:[.35,0,0],haR:[.35,0,0]};};
const base=stdClips({w:.4,arm:0,x:{
 idle:{label:'Idle',len:4,f:t=>{const u=cyc(t,4);const b=Math.sin(u*TAU)*.5+.5;const look=bump(u,.45,.85);return{legs:1,sq:b*.012,rz:Math.sin(t*1.1)*.03,hy:look*.25,hz:Math.sin(u*TAU)*.05,eye:blink(t,4,.3),b:merge(LEGS(t,1),{chest:[Math.sin(t*1.1)*.05,0,-Math.sin(t*1.1)*.05]})};}},
 idle2:{label:'Idle 2',len:4.6,f:t=>{const u=cyc(t,4.6);const one=bump(u,.12,.8);const w=Math.sin(t*3)*one;return{legs:1,rz:.18*one,x:-.02*one,hx:-.1*one,eye:blink(t,2.3,.5),b:merge(LEGS(t,1+one),{thR:[-.3*one,0,-.9*one],knR:[.6*one,0,0],ftR:[.4*one,0,0],shL:[.4*one+w*.2,0,.5*one],elL:[-.9*one,0,0]})};}},
 ability:{label:'Reversal',len:2.4,f:t=>{const u=cyc(t,2.4);const cr=bump(u,0,.22)+bump(u,.78,.98),air=bump(u,.18,.82);const sp=ease(sstep(.22,.74,u));return{legs:1,y:air*.3-cr*.04,sq:-cr*.08+air*.05,rz:-sp*TAU,ry:sp*Math.PI*.5,split:sstep(.12,.3,u)*(1-sstep(.8,.95,u)),eye:1-cr*.3,hx:cr*.2,
  b:{thL:[-.3*cr,0,.2*air],thR:[-.3*cr,0,-.2*air],knL:[.8*cr,0,0],knR:[.8*cr,0,0],shL:[-.2,0,.6*air],shR:[-.2,0,-.6*air],elL:[-.9*air,0,0],elR:[-.9*air,0,0]}};}},
 work:{label:'One-hand spin',len:4.4,f:t=>{const u=cyc(t,4.4);const one=ease(sstep(.05,.2,u))*(1-sstep(.85,1,u));const sp=ease(sstep(.2,.8,u));return{legs:1,ry:sp*TAU,rz:.14*one,x:-.035*one,eye:1-one*.2,hz:.1*one,b:merge(LEGS(t,1.4),{thR:[-.2*one,0,-1.1*one],knR:[.5*one,0,0],shL:[-.4*one,0,.7*one],shR:[.5*one,0,-.3*one],elL:[-.5,0,0]})};}},
 nap:{label:'Nap',len:4.8,f:t=>{const b=Math.sin(t*TAU/4.8)*.5+.5;return{legs:1,y:-.03,sq:-.035+b*.02,rz:Math.sin(t*.9)*.025,hx:.12,hz:.12,eye:.05,b:{chest:[b*.03,0,0],thL:[0,0,.12],thR:[0,0,-.12],knL:[.35,0,0],knR:[.35,0,0],shL:[.35,0,.5],shR:[.35,0,-.5],elL:[-1.7,0,0],elR:[-1.7,0,0],haL:[.5,0,0],haR:[.5,0,0]}};}},
 celebrate:{label:'Celebrate',len:1.8,f:t=>{const u=cyc(t,1.8);const j=bump(u,.05,.6);return{legs:1,y:j*.28,rz:-ease(sstep(.1,.55,u))*TAU,sq:j*.05-bump(u,.6,.75)*.08,eye:1,b:merge(LEGS(t*3,2),{shL:[0,0,.9*j],shR:[0,0,-.9*j]})};}},
 carry:{label:'Carry',len:1.1,f:t=>{const ph=cyc(t,1.1);const bob=Math.abs(Math.cos(ph*TAU));return{legs:1,y:bob*.012,rx:.05,hx:.05,eye:blink(t,2.6,.4),b:merge(gait(ph,{leg:.35,knee:.5,arm:0}),{shL:[.55,0,.05],shR:[.55,0,-.05],elL:[-1.3,0,0],elR:[-1.3,0,0],haL:[.9,0,0],haR:[.9,0,0]})};}},
 climb:{label:'Climb',len:1.4,f:t=>{const ph=cyc(t,1.4);const s=Math.sin(ph*TAU);return{legs:1,y:.04+ph*.05,rx:-.25,hx:-.15,b:merge({thL:[-1.2-.4*s,0,.1],thR:[-1.2+.4*s,0,-.1],knL:[.6+.3*s,0,0],knR:[.6-.3*s,0,0]},LEGS(t*2,1.5))};}}}});
export const CLIPS={};for(const k in base){const c=base[k];CLIPS[k]={...c,f:t=>{const q=c.f(t);if(!q.legs){const amp=k==='run'?2.4:k==='walk'?1.3:k==='hit'?2.5:k==='leap'?2:1;q.b=Object.assign({},q.b||{},LEGS(t*(k==='run'?2.4:1),amp));}return q;}};}
export const EXPR={
 happy:{label:'Cheeky',hz:-.14,hx:.04,eye:.85,b:LEGS(0,1.4,.3)},
 focus:{label:'Balancing',hx:.15,hz:.08,eye:.7,rz:.05,b:LEGS(1,.6)},
 startled:{label:'Startled',hx:-.12,eye:1.2,eyeW:1.1,b:{shL:[0,0,.8],shR:[0,0,-.8],elL:[-.1,0,0],elR:[-.1,0,0]}},
 caught:{label:'Topsy-turvy',hx:.3,hz:.18,eye:.5,rz:.12,b:LEGS(2,.4,-.2)}};
export const build=o=>S.build(o),loadBaked=(u,r)=>S.loadBaked(u,r);
export const BIN='reverser.bin?v=1',RES=.0052,GAME_SCALE=1.1;
export const EMBERS=[['haL',[-.084,.82,.03]],['haR',[.084,.82,.03]],['tail',[.07,.3,-.3]]];
export const ROUTE=[{to:[1.1,-.4],clip:'walk',sp:.22},{at:true,clip:'work',dur:4.4,face:[2,-1]},{to:[-.7,1],clip:'walk',sp:.24},{at:true,clip:'ability',dur:2.4,face:[1,3]},{at:true,clip:'idle',dur:4,face:[1,3]},{to:[.2,.2],clip:'run',sp:.34},{at:true,clip:'nap',dur:4.8,face:[2,2]}];
export const HERO={cam:[1.25,.62,2.15],target:[0,.44,0],clip:'idle'};
