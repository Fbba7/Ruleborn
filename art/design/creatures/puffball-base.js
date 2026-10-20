import * as THREE from 'three';
import {makeSculpt,makeRigKit,stdClips,sstep,vnoise,clamp,ease,bump,blink,cyc,TAU,merge,gait} from './creature-kit.js';
import {parts} from './creature-parts.js';
// ============ PUFFBALL · a cloud of wool on four stubby legs (Verdant wildlife, 5.7 · Flock law creature) ============
const mir=(p,s)=>[p[0]*s,p[1],p[2]];
export function makePuffball(V){
 const COL=Object.assign({wool:0xF6F2EA,woolL:0xFFFFFF,woolD:0xB8AEC6,face:0x3A2E36,faceL:0x5E4A54,inner:0xF2A0B0,nose:0xE88A9A,hoof:0x2A2026},V.col||{});
 const K=Object.fromEntries(Object.entries(COL).map(([k,v])=>[k,new THREE.Color(v)]));let A0=null;
 // the fleece: 42 overlapping puffs on an egg-shaped shell, deterministic
 const PUFFS=[];{let sd=7;const rnd=()=>{sd=(sd*9301+49297)%233280;return sd/233280;};for(let k=0;k<42;k++){const u=(k+.5)/42,th=Math.acos(1-2*u),ph=k*2.39996;const x=Math.sin(th)*Math.cos(ph),y=Math.cos(th),z=Math.sin(th)*Math.sin(ph);if(y<-.55)continue;PUFFS.push([[x*.135,.215+y*.1,z*.15-.005],.05+rnd()*.022]);}}
 const def={name:V.name,box:[[-.22,0,-.24],[.22,.4,.3]],res:.0048,warm:0x3A2A40,aoWarm:.2,sheen:0xFFFFFF,rim:V.rim||0xFFF0DA,
  bodyMat:{roughness:.9,sheen:1,sheenRoughness:.55,sheenColor:new THREE.Color(0xFFFFFF)},fur:{shells:0},
  sculpt(A){const{E,C}=A;A0=A;
   E('T:core',[0,.21,-.005],[.115,.09,.13],null,.03);PUFFS.forEach(([p,r],k)=>E('T:puff'+k,p,[r*1.05,r*.95,r*1.05],null,.012));
   // dark face poking out of the fleece, a wool fringe on the forehead
   E('head:face',[0,.215,.205],[.064,.07,.058],[-.2,0,0],.02);E('head:snout',[0,.188,.252],[.042,.034,.03],null,.022);
   for(let k=0;k<5;k++){const a=(k-2)*.42;E('head:fringe'+k,[Math.sin(a)*.052,.278+Math.cos(a)*.008,.2+Math.cos(a)*.012],[.028,.026,.026],null,.014);}
   for(const s of[-1,1]){const L=s<0?'L':'R';E('ear'+L+':ear',mir([.1,.24,.19],s),[.036,.013,.02],[0,s*.35,s*-.4],.008);
    C('sh'+L+':leg',mir([.06,.13,.08],s),mir([.06,.06,.085],s),.02,.017,.02);C('el'+L+':shin',mir([.06,.06,.085],s),mir([.06,.018,.088],s),.017,.016,.01);E('ha'+L+':hoof',mir([.06,.012,.092],s),[.02,.013,.023],null,.008);
    C('th'+L+':leg',mir([.06,.13,-.08],s),mir([.06,.06,-.08],s),.021,.017,.02);C('kn'+L+':shin',mir([.06,.06,-.08],s),mir([.06,.018,-.078],s),.017,.016,.01);E('ft'+L+':hoof',mir([.06,.012,-.074],s),[.02,.013,.023],null,.008);}
   E('tail:puff',[0,.25,-.165],[.03,.03,.028],null,.02);},
  disp(x,y,z,d){if(Math.abs(d)>.03)return d;const w=sstep(.003,.014,A0.minD(/^head:(face|snout)|:hoof|:shin|:leg|^ear/,x,y,z));
   const curl=vnoise(x*95,y*95,z*95)*.6+vnoise(x*210,y*210,z*210)*.4;return d+w*(curl-.5)*.011;},
  paint(x,y,z,nx,ny,nz,ao,c,A){
   const skin=A.minD(/^head:(face|snout)|:hoof|:shin|:leg|^ear/,x,y,z)<.0035;
   if(skin){c.copy(K.face).lerp(K.faceL,sstep(.2,.9,ny)*.35+sstep(.3,.9,nz)*.1).lerp(K.hoof,(1-ao)*.35);
    if(A.minD(/:hoof/,x,y,z)<.003)c.copy(K.hoof);
    if(A.minD(/^ear/,x,y,z)<.003&&ny>.2)c.lerp(K.inner,.55);
    if(A.dist('head:snout',x,y,z)<.004&&z>.272){const r=Math.hypot(x,(y-.196)*1.2);c.lerp(K.nose,sstep(.016,.01,r));if(Math.abs(x)<.0015&&y<.194&&y>.182)c.copy(K.face);}
    for(const s of[-1,1])c.lerp(K.inner,sstep(.02,0,Math.hypot(x-s*.042,y-.2,(z-.24)*1.4))*.4);return 0;}
   c.copy(K.wool).lerp(K.woolL,sstep(.2,.95,ny)*.4).lerp(K.woolD,(1-ao)*.6+sstep(-.2,-.9,ny)*.15);
   const curl=vnoise(x*95,y*95,z*95);c.lerp(K.woolD,sstep(.35,.2,curl)*.35).lerp(K.woolL,sstep(.7,.85,curl)*.3);
   if(V.paint)V.paint(x,y,z,nx,ny,nz,ao,c,A,K);return 0;},
  accessories(A){const G=new THREE.Group();const P=parts(A,G);const{PB,add,irisTex,eye,glowTex}=P;
   const tex=irisTex('#0A0608','#3A2418','#8A5A2A','#140C0A',{pup:.45});
   for(const s of[-1,1])eye(s,{r:.022,ctr:[0,.222,.2],dir:[.55,.05,1],off:-.009,tex,lid:COL.face,lidCut:.18,yaw:.5,irisK:1.1});
   // a little brass bell on a ribbon collar: it bleats and rings
   {const g=new THREE.Group();g.userData.bone='chest';G.add(g);const cu=new THREE.CatmullRomCurve3([...Array(13)].map((_,i)=>{const a=i/12*TAU;return new THREE.Vector3(Math.sin(a)*.068,.156+Math.cos(a)*.008,.19+Math.cos(a)*.04);}),true);
    {const _c=add(new THREE.TubeGeometry(cu,48,.008,8,true),PB(V.ribbon||0x5CC46A,{roughness:.6,sheen:.5}),null,null,null,g);if(_c)_c.visible=false;}
    const b=new THREE.Group();b.position.set(0,.146,.228);b.userData.spin=[3.1,.35];b.userData.spinAx='z';g.add(b);
    const bell=new THREE.LatheGeometry([[.001,.012],[.01,.01],[.014,.0],[.017,-.012],[.019,-.016],[.001,-.016]].map(([r,y])=>new THREE.Vector2(r,y)),20);
    add(bell,PB(0xE9B65C,{metalness:.95,roughness:.28}),[0,-.006,0],null,null,b);add(new THREE.SphereGeometry(.005,10,8),PB(0x6A4A1A,{metalness:.8,roughness:.4}),[0,-.022,0],null,null,b);}
   if(V.acc)V.acc(A,G,P,COL);
   // bleat (ability): three soft sound rings
   const fx=new THREE.Group();fx.userData.bone='head';fx.userData.fx='split';fx.userData.fxMode='show';fx.position.set(0,.22,.25);G.add(fx);
   const rm=new THREE.MeshBasicMaterial({color:V.ring||0xFFFFFF,transparent:true,opacity:.7,side:THREE.DoubleSide,depthWrite:false});
   for(let k=0;k<3;k++){const m=add(new THREE.TorusGeometry(.04+k*.03,.004,6,32,Math.PI*.9),rm,[0,0,k*.028],[0,0,Math.PI*.55],null,fx);m.castShadow=false;}
   return G;}};
 const S=makeSculpt(def);
 const J={root:[null,[0,0,0]],hips:['root',[0,.18,-.05]],chest:['hips',[0,.2,.06]],head:['chest',[0,.22,.15]],earL:['head',[-.08,.24,.18]],earR:['head',[.08,.24,.18]],
  shL:['chest',[-.06,.13,.08]],elL:['shL',[-.06,.06,.085]],haL:['elL',[-.06,.018,.088]],shR:['chest',[.06,.13,.08]],elR:['shR',[.06,.06,.085]],haR:['elR',[.06,.018,.088]],
  thL:['hips',[-.06,.13,-.08]],knL:['thL',[-.06,.06,-.08]],ftL:['knL',[-.06,.018,-.078]],thR:['hips',[.06,.13,-.08]],knR:['thR',[.06,.06,-.08]],ftR:['knR',[.06,.018,-.078]],tail:['hips',[0,.25,-.16]]};
 const cfg={name:V.name,J,TIP:{haL:[-.06,.0,.092],haR:[.06,.0,.092],ftL:[-.06,.0,-.074],ftR:[.06,.0,-.074]},
  TORSO:{hips:[[0,.2,-.2],[0,.2,-.02],.12],chest:[[0,.2,-.02],[0,.2,.14],.12],head:[[0,.21,.19],[0,.21,.27],.07]},
  AIM:[],floor:.001,pivot:.18,shMin:-1.2,shMax:1.2,springs:[['tail','vx',-.6,140,7,0,.5],['tail','t',.25,90,6,1,.2,5],['earL','vx',.5,110,6,2,.4],['earR','vx',-.5,110,6,2,.4]]};
 const RK=makeRigKit(S,cfg);
 const legs=(ph,k=1)=>{const s=Math.sin(ph*TAU)*k;return{shL:[s*.5,0,0],shR:[-s*.5,0,0],elL:[Math.max(0,s)*.5,0,0],elR:[Math.max(0,-s)*.5,0,0],thL:[-s*.5,0,0],thR:[s*.5,0,0],knL:[Math.max(0,-s)*.6,0,0],knR:[Math.max(0,s)*.6,0,0]};};
 const CLIPS=stdClips({w:.6,arm:0,x:{
  idle:{label:'Idle',len:4,f:t=>{const u=cyc(t,4);const b=Math.sin(u*TAU)*.5+.5;const flick=bump(u,.62,.7);return{sq:b*.03,hx:Math.sin(t*1.2)*.05,hz:Math.sin(u*TAU)*.06,elx:flick*.6,eye:blink(t,4,.5),b:{chest:[-b*.02,0,0]}};}},
  idle2:{label:'Shake',len:3.4,f:t=>{const u=cyc(t,3.4);const sh=bump(u,.3,.62);const w=Math.sin(t*38)*sh;return{rz:w*.14,sq:sh*.05,hz:-w*.25,elx:w*.6,eye:1-sh*.6,b:{chest:[0,w*.2,0],hips:[0,-w*.2,0]}};}},
  walk:{label:'Trot',len:.7,f:t=>{const ph=cyc(t,.7);const bob=Math.abs(Math.cos(ph*TAU));return{y:bob*.014,sq:bob*.02,rz:Math.sin(ph*TAU)*.03,hx:Math.sin(ph*TAU*2)*.03,eye:blink(t,3),b:legs(ph,1)};}},
  run:{label:'Bound',len:.45,f:t=>{const ph=cyc(t,.45);const air=Math.max(0,Math.sin(ph*TAU));return{y:air*.06,sq:air*.07-(1-air)*.04,rx:Math.cos(ph*TAU)*.12,hx:-.05,b:{shL:[-.6*air,0,0],shR:[-.6*air,0,0],thL:[.6*air,0,0],thR:[.6*air,0,0],knL:[.6*(1-air),0,0],knR:[.6*(1-air),0,0]}};}},
  leap:{label:'Hop',len:1.2,f:t=>{const u=cyc(t,1.2);const cr=bump(u,0,.2)+bump(u,.78,.98),air=bump(u,.16,.82);return{y:air*.2-cr*.02,sq:-cr*.1+air*.08,rx:-air*.15,eye:1-cr*.3,b:{shL:[-.8*air,0,0],shR:[-.8*air,0,0],thL:[.8*air,0,0],thR:[.8*air,0,0],knL:[1*cr,0,0],knR:[1*cr,0,0]}};}},
  ability:{label:'Bleat',len:2,f:t=>{const u=cyc(t,2);const b=bump(u,.15,.65);const w=Math.sin(t*30)*b;return{hx:-.35*b,y:b*.02,sq:b*.06+w*.01,split:sstep(.15,.25,u)*(1-sstep(.6,.72,u)),eye:1-b*.5,b:{chest:[-.1*b,0,0]}};}},
  work:{label:'Graze',len:4,f:t=>{const u=cyc(t,4);const d=ease(sstep(.05,.2,u))*(1-ease(sstep(.8,.95,u)));const ch=Math.sin(t*12)*d;return{hx:.9*d+ch*.05,rx:.12*d,y:-.01*d,eye:1-d*.5,b:{chest:[.2*d,0,0],shL:[.15*d,0,0],shR:[.15*d,0,0]}};}},
  nap:{label:'Nap',len:4.6,f:t=>{const b=Math.sin(t*TAU/4.6)*.5+.5;return{y:-.07,sq:-.1+b*.04,hx:.3,hz:.2,eye:.05,elx:.4,b:{shL:[-1.4,0,.1],shR:[-1.4,0,-.1],elL:[1.8,0,0],elR:[1.8,0,0],thL:[1.4,0,.1],thR:[1.4,0,-.1],knL:[-1.8,0,0],knR:[-1.8,0,0]}};}},
  celebrate:{label:'Spring',len:1.4,f:t=>{const u=cyc(t,1.4);const j=bump(u,.05,.55)+bump(u,.55,.98)*.6;return{y:j*.16,ry:ease(sstep(.05,.55,u))*TAU,sq:j*.08,eye:1,elx:j*.4,b:legs(t*3,.6)};}},
  hit:{label:'Startle',len:1.2,f:t=>{const u=cyc(t,1.2);const k=bump(u,0,.25),r=1-ease(sstep(.25,.9,u));return{z:-k*.04,y:k*.04,sq:-k*.1,rz:Math.sin(u*40)*.06*r,eye:1+k*.3,eyeW:1+k*.2,elx:k,b:legs(0,0)};}}}});
 const EXPR={happy:{label:'Content',hz:-.12,eye:.6,elx:.3},focus:{label:'Curious',hx:-.1,hy:.3,eye:1.1},startled:{label:'Startled',hx:-.12,eye:1.25,eyeW:1.15,elx:.8,sq:.04},caught:{label:'Sulky',hx:.3,hz:.15,eye:.55,elx:-.3}};
 return {S,makeRig:RK.makeRig,skinGeo:RK.skinGeo,CLIPS,EXPR,build:o=>S.build(o),loadBaked:(u,r)=>S.loadBaked(u,r)};}
