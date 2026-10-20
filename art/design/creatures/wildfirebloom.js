import * as THREE from 'three';
import {makeSculpt,makeRigKit,stdClips,sstep,vnoise,clamp,ease,bump,blink,cyc,TAU,merge,gait} from './creature-kit.js';
import {parts} from './creature-parts.js';
// ============ THE WILDFIRE BLOOM · Anomaly · fire and growth run wild · runs Heat bloom and Regrowth (GDD 11.8, 17.3) ============
// A round leafy bulb on root feet, its face a golden seed-disc framed by a crown of flame petals, with thorny vines,
// burning buds on its shoulders and embers drifting off it.
const COL={leaf:0x2E5A22,leafL:0x5A8A3A,leafD:0x0E200C,face:0xB86A2A,faceD:0x4A1A08,seed:0x2A0A04,cheek:0xFF7A4A,root:0x5A3A20,rootD:0x2A1A0C,mouth:0x4A1A0A,ember:0xFF8A3C};
const K=Object.fromEntries(Object.entries(COL).map(([k,v])=>[k,new THREE.Color(v)]));
const mir=(p,s)=>[p[0]*s,p[1],p[2]];let A0=null;
let sd=37;const rnd=()=>(sd=(sd*16807)%2147483647)/2147483647;
const def={name:'wildfirebloom',box:[[-.3,0,-.26],[.3,.8,.26]],res:.0054,warm:0x2A0A04,aoWarm:.24,sheen:0xFFE0A0,rim:0xFFB060,
 bodyMat:{roughness:.6,sheen:.5,sheenRoughness:.45},fur:{shells:0},
 sculpt(A){const{E,C}=A;A0=A;
  // round leafy bulb body, a wide round head whose front is a flat seed-disc face
  E('T:body',[0,.26,0],[.15,.15,.14],null,.06);E('T:belly',[0,.24,.05],[.11,.11,.09],null,.05);C('T:neck',[0,.36,0],[0,.4,.01],.08,.09,.05);
  E('T:head',[0,.53,0],[.17,.16,.15],null,.06);E('T:face',[0,.52,.095],[.155,.145,.075],null,.05);
  for(const s of[-1,1]){const L=s<0?'L':'R';E('T:cheek'+L,mir([.09,.47,.13],s),[.055,.045,.04],null,.03);
   // leaf-blade arms ending in three leaflet fingers
   const sh=mir([.13,.33,0],s),el=mir([.19,.25,.04],s),wr=mir([.21,.18,.08],s);C('sh'+L+':arm1',sh,el,.034,.026,.02);C('el'+L+':arm2',el,wr,.026,.02,.015);
   E('ha'+L+':palm',mir([.215,.165,.09],s),[.028,.022,.022],null,.012);for(let k=0;k<3;k++){const a=(k-1)*.55;C('ha'+L+':leaflet'+k,mir([.218,.155,.095],s),mir([.225+Math.sin(a)*.03,.115,.105+Math.cos(a)*.015],s),.013,.004,.007);}
   // root legs with splayed rootlet toes
   C('th'+L+':leg1',mir([.07,.16,0],s),mir([.08,.08,.01],s),.048,.038,.03);C('kn'+L+':leg2',mir([.08,.08,.01],s),mir([.085,.025,.02],s),.038,.032,.02);
   E('ft'+L+':foot',mir([.085,.02,.04],s),[.048,.02,.055],null,.015);for(let k=0;k<4;k++){const a=(k-1.5)*.45;C('ft'+L+':root'+k,mir([.085,.014,.06],s),mir([.085+Math.sin(a)*.065,.005,.06+Math.cos(a)*.055],s),.014,.004,.006);}}
  // leaf ridges down the back of the bulb
  for(let k=0;k<6;k++){const a=Math.PI+(k-2.5)*.4;C('T:rib'+k,[Math.sin(a)*.14,.13,Math.cos(a)*.13],[Math.sin(a)*.12,.38,Math.cos(a)*.11],.014,.01,.02);}
  E('tail:stub',[0,.18,-.13],[.035,.03,.03],null,.02);},
 disp(x,y,z,d){if(Math.abs(d)>.03)return d;const face=sstep(.03,.006,A0.minD(/^T:(face|cheek)/,x,y,z));
  const row=y*20,fr=row-Math.floor(row);return d+(1-face)*(sstep(.7,.95,fr)*-.0014+(vnoise(x*60,y*60,z*60)-.5)*.0012);},
 paint(x,y,z,nx,ny,nz,ao,c,A){
  c.copy(K.leaf).lerp(K.leafL,sstep(.2,.95,ny)*.3+sstep(.3,.9,nz)*.12).lerp(K.leafD,(1-ao)*.6+sstep(-.1,-.8,ny)*.25);
  {const row=y*20,ri=Math.floor(row),fr=row-ri;const ang=Math.atan2(x,z)/TAU*9+(ri%2)*.5;const fa=ang-Math.floor(ang);const tip=1-Math.abs(fa-.5)*2;const edge=fr-tip*.35;c.lerp(K.leafD,sstep(.45,.85,edge)*.45).lerp(K.leafL,sstep(.2,-.1,edge)*.3);c.lerp(K.leafD,vnoise(x*30,y*30,z*30)*.12);}
  // scorched ember edges creeping up from the feet
  c.lerp(new THREE.Color(0x2A0E06),sstep(.24,.02,y)*.7);c.lerp(K.ember,sstep(.7,.86,vnoise(x*14,y*14,z*14))*sstep(.46,.2,y)*.75);
  {const hd=sstep(.012,0,A.minD(/^T:(head|face|cheek)/,x,y,z))*sstep(.4,.44,y);if(hd>0){const sp=new THREE.Color(0x7A2E12).lerp(new THREE.Color(0xD8702A),sstep(.2,.95,ny)*.45).lerp(new THREE.Color(0x2A0C04),(1-ao)*.55);sp.lerp(new THREE.Color(0xFF9A3C),sstep(.7,.9,vnoise(x*30,y*30,z*30))*.6);c.lerp(sp,hd);}}
  // golden seed-disc face with a Fibonacci ring of seeds round the edge
  const fr=Math.hypot(x,(y-.515)*1.02);const fc=sstep(.152,.138,fr)*sstep(.09,.13,z);
  if(fc>0){const cf=K.face.clone().lerp(K.faceD,(1-ao)*.4+sstep(.08,.13,fr)*.35);const ring=sstep(.105,.12,fr);if(ring>0){const a=Math.atan2(y-.515,x);const n=Math.floor(fr*380);const ph=(a/TAU*34+n*.618)%1;cf.lerp(K.seed,ring*sstep(.35,.2,Math.abs(ph-.5))*.7);}{const v=Math.abs(vnoise(x*40,y*40,z*40)-.5);cf.lerp(K.ember,sstep(.03,0,v)*.8);}c.lerp(cf,fc);}
  
  if(A.minD(/^(th|kn|ft)[LR]:/,x,y,z)<.004)c.copy(K.root).lerp(K.rootD,(1-ao)*.55+sstep(0,-.8,ny)*.3).lerp(K.ember,sstep(.78,.92,vnoise(x*40,y*40,z*40))*.5);
  if(A.minD(/^ha[LR]:/,x,y,z)<.003)c.copy(K.leafL).lerp(K.leafD,(1-ao)*.4);
  if(z>.14&&Math.abs(x)<.075){const u=x/.075,cy=.448+.02*u*u,h=.014*(1-u*u)+.0015,dy=y-cy;if(Math.abs(dy)<h+.002){if(Math.abs(dy)>=h)c.copy(K.faceD);else{const tt=1-Math.abs(((u*3+10)%1)-.5)*2,bt=1-Math.abs(((u*3+10.5)%1)-.5)*2;if(dy>h-tt*h*.8||dy<-h+bt*h*.6)c.copy(K.face).lerp(K.faceD,.3);else c.set(0xFFD050).lerp(new THREE.Color(0xFF4A0A),sstep(0,h,Math.abs(dy))*.8);}}}
  return 0;},
 accessories(A){const G=new THREE.Group();const P=parts(A,G);const{PB,add,irisTex,eye,glowTex,hit}=P;
  const tex=irisTex('#140200','#FF3A0A','#FFE070','#000000',{pup:.14});
  for(const s of[-1,1]){const e=eye(s,{r:.047,ctr:[0,.53,.02],dir:[.36,.06,1],off:-.016,tex,lid:COL.faceD,lidCut:.36,lidTilt:.22,yaw:.34,irisK:1.3});{const ld=e.getObjectByName('lid');if(ld){ld.rotation.z=0;}const bw=new THREE.Mesh(new THREE.CapsuleGeometry(.0095,.058,4,12),ld?ld.material:new THREE.MeshStandardMaterial({color:0x111111}));bw.rotation.set(0,0,Math.PI/2+s*.5);bw.scale.set(1,1,.6);bw.position.set(-s*.005,.043,.03);bw.castShadow=true;e.add(bw);const gs=new THREE.Sprite(new THREE.SpriteMaterial({map:glowTex('rgba(255,90,20,.6)'),transparent:true,depthWrite:false,blending:THREE.AdditiveBlending}));gs.position.z=.012;gs.scale.setScalar(.09);e.add(gs);}}
  // crown of flame petals round the face: two rows, each petal flickering on its own
  const petal=(len,wid,cols,flame=true)=>{const s=new THREE.Shape();s.moveTo(0,0);if(flame){s.bezierCurveTo(wid*1.1,len*.2,wid*.9,len*.55,wid*.25,len*.72);s.quadraticCurveTo(wid*.45,len*.88,-wid*.15,len);s.quadraticCurveTo(-wid*.05,len*.8,-wid*.35,len*.68);s.bezierCurveTo(-wid*.95,len*.5,-wid*1.05,len*.2,0,0);}else{s.bezierCurveTo(wid,len*.25,wid*.7,len*.7,0,len);s.bezierCurveTo(-wid*.7,len*.7,-wid,len*.25,0,0);}const g=new THREE.ShapeGeometry(s,20);const p=g.attributes.position,col=[];
   for(let i=0;i<p.count;i++){const t=p.getY(i)/len,e=Math.abs(p.getX(i))/wid;p.setZ(i,-Math.pow(e,2)*wid*.35+Math.sin(t*2.6)*len*.08);const c=new THREE.Color(cols[0]).lerp(new THREE.Color(cols[1]),sstep(0,.55,t)).lerp(new THREE.Color(cols[2]),sstep(.55,1,t)).lerp(new THREE.Color(cols[1]),e*.2);col.push(c.r,c.g,c.b);}
   g.computeVertexNormals();g.setAttribute('color',new THREE.Float32BufferAttribute(col,3));return g;};
  const fm=PB(0xFFFFFF,{vertexColors:true,roughness:.4,emissive:0xFF3A08,emissiveIntensity:1.1,side:THREE.DoubleSide,sheen:.6,sheenColor:new THREE.Color(0xFFE0A0)});
  const fm2=PB(0xFFFFFF,{vertexColors:true,roughness:.4,emissive:0xFF8A20,emissiveIntensity:1.1,side:THREE.DoubleSide});
  {const g=new THREE.Group();g.userData.bone='head';g.position.set(0,.515,.07);G.add(g);
   for(let k=0;k<12;k++){const a=k/12*TAU;const pv=new THREE.Group();pv.rotation.z=a;pv.userData.spin=[3+k*.37,.06];pv.userData.spinAx='z';g.add(pv);const q=new THREE.Group();q.position.y=.132;q.rotation.x=.18;pv.add(q);add(petal(.13+(k%2)*.035,.058,[0xFFB020,0xE83A0A,0x7A0A04]),fm,null,null,null,q).castShadow=false;}
   for(let k=0;k<12;k++){const a=(k+.5)/12*TAU;const pv=new THREE.Group();pv.rotation.z=a;pv.userData.spin=[4+k*.41,.08];pv.userData.spinAx='z';g.add(pv);const q=new THREE.Group();q.position.set(0,.128,.012);q.rotation.x=.3;pv.add(q);add(petal(.085,.042,[0xFFE080,0xFF8A18,0xC8200A]),fm2,null,null,null,q).castShadow=false;}
   const gl=new THREE.Sprite(new THREE.SpriteMaterial({map:glowTex('rgba(255,120,40,.5)'),transparent:true,depthWrite:false,blending:THREE.AdditiveBlending}));gl.position.z=-.06;gl.scale.setScalar(.42);g.add(gl);}
  // burning buds on the shoulders
  for(const s of[-1,1]){const h=hit([s*.7,.55,.2],[0,.33,0],.0);const g=new THREE.Group();g.userData.bone='chest';g.position.copy(h.p);G.add(g);
   add(new THREE.SphereGeometry(.03,14,12),PB(0x5AAE4A,{roughness:.5}),null,null,[1,1.25,1],g);
   for(let k=0;k<4;k++){const pv=new THREE.Group();pv.rotation.set(0,k/4*TAU,0);pv.userData.spin=[5+k,.1];pv.userData.spinAx='x';g.add(pv);const q=new THREE.Group();q.position.y=.02;q.rotation.x=-.25;pv.add(q);add(petal(.06,.022,[0xFFE080,0xFF8A20,0xE0301A]),fm2,null,null,null,q).castShadow=false;}}
  // thorny vines wrapping the bulb
  {const g=new THREE.Group();g.userData.bone='chest';G.add(g);const vm=PB(0x2E6A2A,{roughness:.6}),th=PB(0x8A3A1A,{roughness:.5});
   for(let v=0;v<1;v++){const pts=[];for(let i=0;i<=24;i++){const t=i/24;const a=t*TAU*1.6+.6;pts.push(new THREE.Vector3(Math.sin(a),.11+t*.15+Math.sin(t*17)*.01,Math.cos(a)));}
    const cu=new THREE.CatmullRomCurve3(pts.map(p=>{const h=hit([p.x,0,p.z],[0,p.y,0],.004);return h.p;}));add(new THREE.TubeGeometry(cu,90,.0065,6),vm,null,null,null,g);
    for(let k=1;k<14;k++){const t=k/14;const p=cu.getPoint(t),tg=cu.getTangent(t);const n=new THREE.Vector3(p.x,0,p.z).normalize();const tn=add(new THREE.ConeGeometry(.0065,.024,6),th,[p.x+n.x*.006,p.y,p.z+n.z*.006],null,null,g);tn.quaternion.setFromUnitVectors(new THREE.Vector3(0,1,0),n.clone().add(tg.clone().multiplyScalar(.4)).normalize());}
    for(let k=0;k<4;k++){const p=cu.getPoint(.12+k*.24);const n=new THREE.Vector3(p.x,0,p.z).normalize();const lf=add(petal(.04,.02,[0x2E6A2A,0x5AAE4A,0x9AE07A]),PB(0xFFFFFF,{vertexColors:true,roughness:.5,side:THREE.DoubleSide}),[p.x,p.y,p.z],null,null,g);lf.lookAt(p.x+n.x,p.y+.4,p.z+n.z);}}}
  // embers drifting up off it
  {const pos=[];for(let i=0;i<50;i++){const a=rnd()*TAU,r=.12+rnd()*.2;pos.push(Math.sin(a)*r,.3+rnd()*.55,Math.cos(a)*r);}const g=new THREE.BufferGeometry();g.setAttribute('position',new THREE.Float32BufferAttribute(pos,3));
   const pts=new THREE.Points(g,new THREE.PointsMaterial({size:.014,color:0xFFB050,transparent:true,opacity:.9,depthWrite:false,blending:THREE.AdditiveBlending}));const w=new THREE.Group();w.userData.bone='root';w.userData.spin=.8;w.userData.spinAx='y';w.add(pts);G.add(w);}
  // heat bloom (ability): a ring of fire-flowers bursting up from the ground round it
  const fx=new THREE.Group();fx.userData.bone='root';fx.userData.fx='split';fx.userData.fxMode='grow';fx.userData.fxBase=0;fx.userData.fxGain=1;fx.position.set(0,.005,0);G.add(fx);
  for(let k=0;k<7;k++){const a=k/7*TAU;const g=new THREE.Group();g.position.set(Math.sin(a)*.34,0,Math.cos(a)*.34);fx.add(g);
   add(new THREE.CylinderGeometry(.006,.008,.08,6),PB(0x3E8A3A),[0,.04,0],null,null,g);for(let q=0;q<5;q++){const pv=new THREE.Group();pv.position.y=.08;pv.rotation.set(0,q/5*TAU,0);pv.userData.spin=[6+q,.12];pv.userData.spinAx='x';g.add(pv);const w=new THREE.Group();w.rotation.x=-.5;pv.add(w);add(petal(.06,.025,[0xFFE080,0xFF8A20,0xE0301A]),fm2,null,null,null,w).castShadow=false;}
   const gl=new THREE.Sprite(new THREE.SpriteMaterial({map:glowTex('rgba(255,150,60,.6)'),transparent:true,depthWrite:false,blending:THREE.AdditiveBlending}));gl.position.y=.1;gl.scale.setScalar(.16);g.add(gl);}
  return G;}};
export const S=makeSculpt(def);
const J={root:[null,[0,0,0]],hips:['root',[0,.2,0]],chest:['hips',[0,.33,0]],head:['chest',[0,.4,.01]],earL:['head',[-.1,.62,0]],earR:['head',[.1,.62,0]],
 shL:['chest',[-.13,.33,0]],elL:['shL',[-.19,.25,.04]],haL:['elL',[-.21,.18,.08]],shR:['chest',[.13,.33,0]],elR:['shR',[.19,.25,.04]],haR:['elR',[.21,.18,.08]],
 thL:['hips',[-.07,.16,0]],knL:['thL',[-.08,.08,.01]],ftL:['knL',[-.085,.025,.02]],thR:['hips',[.07,.16,0]],knR:['thR',[.08,.08,.01]],ftR:['knR',[.085,.025,.02]],tail:['hips',[0,.18,-.13]]};
const cfg={name:'wildfirebloom',J,TIP:{haL:[-.23,.11,.11],haR:[.23,.11,.11],ftL:[-.085,.006,.1],ftR:[.085,.006,.1]},
 TORSO:{hips:[[0,.1,0],[0,.32,0],.16],chest:[[0,.26,0],[0,.4,0],.14],head:[[0,.38,.01],[0,.72,.02],.2]},AIM:[],floor:.004,pivot:.2,shMin:-2,springs:[['tail','vy',-.2,130,10,0,.1]]};
const RK=makeRigKit(S,cfg);export const makeRig=RK.makeRig,skinGeo=RK.skinGeo;
export const CLIPS=stdClips({w:.55,arm:.34,x:{
 idle:{label:'Smoulder',len:4,f:t=>{const u=cyc(t,4);const b=Math.sin(u*TAU)*.5+.5;const look=bump(u,.45,.85);return{sq:b*.018,hz:Math.sin(u*TAU)*.05,hy:look*.35,eye:blink(t,3.6,.5),b:{chest:[-b*.03,0,0],shL:[-.25,0,.14],shR:[-.25,0,-.14],elL:[-.55,0,0],elR:[-.55,0,0]}};}},
 idle2:{label:'Fan the flames',len:4,f:t=>{const u=cyc(t,4);const k=bump(u,.1,.85);const w=Math.sin(t*10)*k;return{hx:-.12*k,eye:1-k*.3,b:{shL:[-2.1*k,0,-.3*k+w*.2],shR:[-2.1*k,0,.3*k-w*.2],elL:[-.5*k,0,0],elR:[-.5*k,0,0],haL:[w*.4,0,0],haR:[-w*.4,0,0]}};}},
 ability:{label:'Heat bloom',len:2.8,f:t=>{const u=cyc(t,2.8);const st=ease(sstep(.05,.3,u))*(1-sstep(.85,1,u)),gr=sstep(.25,.6,u)*(1-sstep(.85,1,u));return{split:gr,y:-st*.03,sq:-st*.06+gr*.03,hx:-.2*st,eye:1-st*.2,b:{shL:[-1.6*st,0,.7*st],shR:[-1.6*st,0,-.7*st],elL:[-.3,0,0],elR:[-.3,0,0],thL:[-.3*st,0,-.2*st],thR:[-.3*st,0,.2*st],knL:[.5*st,0,0],knR:[.5*st,0,0]}};}},
 work:{label:'Regrow',len:4.4,f:t=>{const u=cyc(t,4.4);const dig=bump(u,.08,.5),rise=bump(u,.5,.95);return{rx:.3*dig,hx:.35*dig-.1*rise,y:-dig*.03+rise*.02,sq:-dig*.05+rise*.04,eye:1-dig*.3,b:{chest:[.35*dig,0,0],shL:[-1.1*dig-2*rise,0,.2],shR:[-1.1*dig-2*rise,0,-.2],elL:[-.4,0,0],elR:[-.4,0,0]}};}},
 nap:{label:'Go to seed',len:4.6,f:t=>{const b=Math.sin(t*TAU/4.6)*.5+.5;return{y:-.07,sq:-.06+b*.03,hx:.4,hz:.18,eye:.04,b:{thL:[-1.45,0,-.35],knL:[1.7,0,0],thR:[-1.45,0,.35],knR:[1.7,0,0],shL:[-.6,0,.35],elL:[-1.3,0,0],shR:[-.6,0,-.35],elR:[-1.3,0,0],chest:[.28+b*.04,0,0]}};}}}});
export const EXPR={
 happy:{label:'Blazing',hz:-.12,eye:.86,b:{shL:[-.4,0,.3],shR:[-.4,0,-.3],elL:[-.9,0,0],elR:[-.9,0,0]}},
 focus:{label:'Spreading',hx:.2,eye:.7,b:{shL:[-1.1,0,.5],shR:[-1.1,0,-.5],elL:[-.6,0,0],elR:[-.6,0,0]}},
 startled:{label:'Startled',hx:-.15,eye:1.2,eyeW:1.08,b:{shL:[-.3,0,-.9],shR:[-.3,0,.9]}},
 caught:{label:'Wilted',hx:.4,hz:.12,eye:.55,b:{chest:[.25,0,0],shL:[.15,0,.1],shR:[.15,0,-.1]}}};
export const build=o=>S.build(o),loadBaked=(u,r)=>S.loadBaked(u,r);
export const BIN='wildfirebloom.bin?v=1',RES=.0054,GAME_SCALE=2.2;
export const EMBERS=[['head',[-.12,.68,.06]],['head',[.12,.68,.06]],['head',[0,.72,.04]]];
export const ROUTE=[{to:[1.1,-.4],clip:'walk',sp:.2},{at:true,clip:'work',dur:4.4,face:[2,-1]},{to:[-.7,1],clip:'walk',sp:.2},{at:true,clip:'ability',dur:2.8,face:[1,3]},{at:true,clip:'idle2',dur:4,face:[1,3]},{to:[.2,.2],clip:'run',sp:.32},{at:true,clip:'nap',dur:4.6,face:[2,2]}];
export const HERO={cam:[1.25,.28,2.2],target:[0,.42,0],clip:'idle'};
