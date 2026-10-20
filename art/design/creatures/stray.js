import * as THREE from 'three';
import {makeSculpt,makeRigKit,stdClips,sstep,vnoise,clamp,ease,bump,blink,cyc,TAU,merge,gait} from './creature-kit.js';
import {parts} from './creature-parts.js';
// ============ THE STRAY · Visitor · asks a favour, then joins the roster · a scruffy little creature with a bundle on a stick (GDD 11.7, 21.6) ============
const COL={fur:0x7E6A58,furL:0xA89078,furD:0x3E3026,patch:0x4E3A2C,cream:0xEEE2CC,creamD:0xC8B8A0,ear:0xE8A6A0,nose:0xD8746E,mouth:0x4A2420,scarf:0x3A78C8,scarfD:0x1E4A8A,grime:0x4A3C30};
const K=Object.fromEntries(Object.entries(COL).map(([k,v])=>[k,new THREE.Color(v)]));
const mir=(p,s)=>[p[0]*s,p[1],p[2]];let A0=null;
function ginghamTex(){const c=document.createElement('canvas');c.width=c.height=256;const x=c.getContext('2d');x.fillStyle='#F4ECE0';x.fillRect(0,0,256,256);x.fillStyle='rgba(200,56,56,.55)';for(let i=0;i<256;i+=32){x.fillRect(i,0,16,256);x.fillRect(0,i,256,16);}x.fillStyle='rgba(160,30,30,.35)';for(let i=0;i<256;i+=32)for(let j=0;j<256;j+=32)x.fillRect(i,j,16,16);
 for(let i=0;i<900;i++){x.fillStyle='rgba(90,60,40,'+(Math.random()*.07)+')';x.fillRect(Math.random()*256,Math.random()*256,3,3);}const t=new THREE.CanvasTexture(c);t.colorSpace=THREE.SRGBColorSpace;t.wrapS=t.wrapT=THREE.RepeatWrapping;t.repeat.set(2,1);return t;}
const def={name:'stray',box:[[-.23,0,-.2],[.23,.62,.21]],res:.0046,warm:0x2A1A0A,aoWarm:.22,sheen:0xFFE8D0,rim:0xFFE0B8,
 bodyMat:{roughness:.85,sheen:.3,sheenRoughness:.6},fur:{shells:0},
 sculpt(A){const{E,C}=A;A0=A;
  E('T:body',[0,.2,0],[.1,.11,.09],null,.05);E('T:belly',[0,.19,.04],[.075,.08,.06],null,.04);C('T:neck',[0,.28,0],[0,.32,.01],.06,.066,.04);
  E('T:head',[0,.43,.01],[.15,.13,.125],null,.055);E('T:muzzle',[0,.39,.1],[.058,.04,.045],null,.035);E('T:nose',[0,.404,.142],[.018,.013,.013],null,.01);
  for(const s of[-1,1]){const L=s<0?'L':'R';E('T:cheek'+L,mir([.08,.39,.08],s),[.05,.04,.042],null,.03);
   // scruffy cheek tufts
   for(let k=0;k<3;k++)C('T:tuft'+L+k,mir([.115,.4-k*.025,.035],s),mir([.17+k*.006,.39-k*.035,.02],s),.028,.006,.012);
   const sh=mir([.09,.25,0],s),el=mir([.12,.19,.03],s),wr=mir([.13,.13,.05],s);C('sh'+L+':arm1',sh,el,.03,.025,.02);C('el'+L+':arm2',el,wr,.025,.022,.015);
   E('ha'+L+':paw',mir([.132,.112,.06],s),[.03,.026,.028],null,.012);
   C('th'+L+':leg1',mir([.05,.12,0],s),mir([.055,.065,.01],s),.036,.03,.025);C('kn'+L+':leg2',mir([.055,.065,.01],s),mir([.058,.028,.02],s),.03,.026,.02);
   E('ft'+L+':foot',mir([.058,.02,.035],s),[.034,.02,.046],null,.014);}
  // ears: the left stands up, the right has flopped over
  C('earL:ear1',[-.09,.52,-.01],[-.125,.6,-.02],.048,.016,.02);E('earL:cup',[-.108,.56,.012],[.026,.042,.01],[.2,.3,.35],.004,'s');
  C('earR:ear1',[.09,.52,-.01],[.12,.575,0],.048,.03,.02);C('earR:ear2',[.12,.575,0],[.16,.56,.045],.03,.012,.015);
  for(let k=0;k<3;k++)C('T:crown'+k,[(k-1)*.03,.54,.0],[(k-1)*.05,.6-Math.abs(k-1)*.02,-.02],.025,.005,.012);
  E('tail:root',[0,.15,-.09],[.03,.03,.028],null,.02);},
 disp(x,y,z,d){if(Math.abs(d)>.035)return d;const face=sstep(.028,.006,A0.minD(/^T:(muzzle|nose)/,x,y,z));
  const cl=Math.pow(vnoise(x*38,y*30,z*38),2);return d+(1-face)*(cl*-.0042+(vnoise(x*90,y*90,z*90)-.5)*.0016)+(vnoise(x*150,y*150,z*150)-.5)*.0005;},
 paint(x,y,z,nx,ny,nz,ao,c,A){
  c.copy(K.fur).lerp(K.furL,sstep(.2,.95,ny)*.3+sstep(.3,.9,nz)*.1).lerp(K.furD,(1-ao)*.55+sstep(-.2,-.8,ny)*.18);
  const pv=vnoise(x*9+4,y*9,z*9);c.lerp(K.patch,sstep(.55,.72,pv)*.8);c.lerp(K.furD,Math.pow(vnoise(x*38,y*30,z*38),2)*.45);c.lerp(K.furL,sstep(.5,.2,vnoise(x*38,y*30,z*38))*.2);
  const muz=sstep(.012,0,A.dist('T:muzzle',x,y,z))*sstep(.06,.1,z)*sstep(.42,.4,y);c.lerp(K.cream,muz*.9);c.lerp(K.creamD,sstep(.01,0,A.minD(/^T:cheek/,x,y,z))*sstep(.05,.1,z)*.35);
  c.lerp(K.cream,sstep(.004,-.001,A.dist('T:belly',x,y,z))*sstep(.03,.07,z)*.85);
  c.lerp(K.grime,sstep(.06,.0,y)*.5);c.lerp(K.grime,sstep(.62,.8,vnoise(x*20+9,y*20,z*20))*sstep(.0,.2,nz)*.25);
  if(A.minD(/^ear[LR]:/,x,y,z)<.004){if(x<0){const inn=sstep(.01,0,A.dist('earL:cup',x,y,z)+.004)*sstep(-.01,.01,z);c.lerp(K.ear,inn*.85);}else{c.lerp(K.ear,sstep(-.2,-.7,ny)*.6);}c.lerp(K.furD,sstep(.58,.62,y)*.4);}
  if(A.dist('T:nose',x,y,z)<.004)c.copy(K.nose).lerp(new THREE.Color(0xFFC0B8),sstep(.4,.9,ny)*.4);
  if(z>.12&&Math.abs(x)<.03){const u=x/.03,cy=.368+.006*(1-Math.abs(u)*2)*(Math.abs(u)<.5?1:-1)*.5;const dd=Math.abs(y-cy),w=.0022*(1-u*u*.5);if(dd<w)c.copy(K.mouth);else if(dd<w+.003)c.lerp(K.mouth,.35*(1-(dd-w)/.003));}
  if(A.minD(/^(ha|ft)[LR]:/,x,y,z)<.003)c.lerp(K.creamD,.55).lerp(K.grime,sstep(.03,0,y)*.4);
  for(const s of[-1,1])c.lerp(new THREE.Color(0xE8807A),sstep(.028,0,Math.hypot(x-s*.095,y-.39,(z-.085)*1.4))*.4);
  return 0;},
 accessories(A){const G=new THREE.Group();const P=parts(A,G);const{PB,add,irisTex,eye,glowTex}=P;
  const tex=irisTex('#0A0602','#7A4A0A','#F2B43C','#1A1206',{pup:.3});
  for(const s of[-1,1])eye(s,{r:.05,ctr:[0,.44,.022],dir:[.44,.13,1],off:-.006,tex,lid:COL.furD,lidCut:.24,yaw:.36,irisK:1.35});
  // sticking plaster on the brow
  {const g=new THREE.Group();g.userData.bone='head';g.position.set(-.07,.505,.112);g.rotation.set(-.55,-.35,.4);G.add(g);const pm=PB(0xE8C89A,{roughness:.8});add(new THREE.BoxGeometry(.05,.016,.004),pm,null,null,null,g);add(new THREE.BoxGeometry(.05,.016,.004),pm,null,[0,0,Math.PI/2],null,g);}
  // patched blue scarf
  {const g=new THREE.Group();g.userData.bone='chest';G.add(g);const sm=PB(COL.scarf,{roughness:.85,sheen:.6,sheenColor:new THREE.Color(0xA8C8FF)});add(new THREE.TorusGeometry(.07,.026,12,32),sm,[0,.3,.008],[Math.PI/2+.12,0,0],[1,1,.7],g);
   add(new THREE.SphereGeometry(.024,12,10),sm,[-.035,.29,.07],null,[1,.8,.8],g);const cu=new THREE.CatmullRomCurve3([new THREE.Vector3(-.035,.28,.075),new THREE.Vector3(-.045,.24,.085),new THREE.Vector3(-.04,.2,.08)]);add(new THREE.TubeGeometry(cu,12,.016,8),sm,null,null,[1,1,.5],g);
   add(new THREE.BoxGeometry(.03,.026,.004),PB(0xC8583A,{roughness:.9}),[.045,.305,.07],[0,.55,0],null,g);
   for(const [dx,dy] of [[-.012,-.012],[.012,.012],[-.012,.012]])add(new THREE.BoxGeometry(.008,.0015,.002),PB(0xF4ECE0),[.045+dx*.7,.305+dy*.7,.073],[0,.55,.8],null,g);}
  // bundle on a stick, resting over the right shoulder
  {const g=new THREE.Group();g.userData.bone='chest';G.add(g);const wd=PB(0x7A5230,{roughness:.8});
   const cu=new THREE.CatmullRomCurve3([new THREE.Vector3(.155,.14,.12),new THREE.Vector3(.13,.3,-.02),new THREE.Vector3(.1,.47,-.21)]);add(new THREE.TubeGeometry(cu,24,.009,8),wd,null,null,null,g);
   add(new THREE.SphereGeometry(.008,8,6),PB(0x5A3A20),[.1,.475,-.215],null,null,g);
   const bm=PB(0xFFFFFF,{map:ginghamTex(),roughness:.85,sheen:.4});const bg=new THREE.SphereGeometry(.078,28,20);{const p=bg.attributes.position;for(let i=0;i<p.count;i++){const yy=p.getY(i);const f=1+(yy<0?-yy*1.2:0)*.25+Math.sin(p.getX(i)*60)*.02;p.setXYZ(i,p.getX(i)*f,yy*.92,p.getZ(i)*f);}bg.computeVertexNormals();}
   add(bg,bm,[.1,.39,-.22],null,null,g);add(new THREE.SphereGeometry(.024,14,10),bm,[.085,.465,-.21],null,[1,.8,1],g);add(new THREE.SphereGeometry(.022,14,10),bm,[.118,.46,-.225],null,[1,.8,1],g);
   add(new THREE.ConeGeometry(.02,.05,10),bm,[.07,.47,-.2],[0,0,.9],null,g);add(new THREE.ConeGeometry(.02,.05,10),bm,[.13,.47,-.23],[0,0,-.9],null,g);}
  // scruffy tail
  {const g=new THREE.Group();g.userData.bone='tail';G.add(g);const cu=new THREE.CatmullRomCurve3([new THREE.Vector3(0,.15,-.09),new THREE.Vector3(0,.16,-.17),new THREE.Vector3(.02,.24,-.21),new THREE.Vector3(.04,.31,-.19),new THREE.Vector3(.06,.33,-.15)]);
   const tg=new THREE.TubeGeometry(cu,60,.03,10);{const p=tg.attributes.position,uv=tg.attributes.uv,cen=new THREE.Vector3(),q=new THREE.Vector3(),col=[];for(let i=0;i<p.count;i++){const u=uv.getX(i),v=uv.getY(i);cu.getPoint(u,cen);const tuft=1+Math.pow(vnoise(u*30,v*8,0),2)*.8;q.set(p.getX(i),p.getY(i),p.getZ(i)).sub(cen).multiplyScalar((.75+u*.35)*tuft*(u>.9?1-(u-.9)*6:1)).add(cen);p.setXYZ(i,q.x,q.y,q.z);const c=K.fur.clone().lerp(K.patch,sstep(.3,.6,u)*.6).lerp(K.furL,sstep(.85,1,u)*.6).lerp(K.furD,Math.pow(vnoise(u*30,v*8,0),2)*.5);col.push(c.r,c.g,c.b);}tg.computeVertexNormals();tg.setAttribute('color',new THREE.Float32BufferAttribute(col,3));}
   add(tg,PB(0xFFFFFF,{vertexColors:true,roughness:.85,sheen:.7,sheenColor:new THREE.Color(0xFFE8D0)}),null,null,null,g);}
  // follow home (ability): little hearts rise around it
  const fx=new THREE.Group();fx.userData.bone='root';fx.userData.fx='split';fx.userData.fxMode='show';fx.position.set(0,.45,0);G.add(fx);fx.userData.spin=2.5;fx.userData.spinAx='y';
  {const hs=new THREE.Shape();hs.moveTo(0,-.02);hs.bezierCurveTo(-.03,.005,-.02,.03,0,.015);hs.bezierCurveTo(.02,.03,.03,.005,0,-.02);const hg=new THREE.ExtrudeGeometry(hs,{depth:.008,bevelEnabled:true,bevelSize:.003,bevelThickness:.003,bevelSegments:2});hg.center();
   const hm=PB(0xFF8AB0,{emissive:0xE0406A,emissiveIntensity:.9,roughness:.4});for(let k=0;k<4;k++){const a=k/4*TAU;const h=add(hg,hm,[Math.sin(a)*.2,(k%2)*.07,Math.cos(a)*.2],[0,a,0],[1.4,1.4,1.4],fx);}
   const gl=new THREE.Sprite(new THREE.SpriteMaterial({map:glowTex('rgba(255,150,190,.7)'),transparent:true,depthWrite:false,blending:THREE.AdditiveBlending}));gl.scale.setScalar(.5);fx.add(gl);}
  return G;}};
export const S=makeSculpt(def);
const J={root:[null,[0,0,0]],hips:['root',[0,.16,0]],chest:['hips',[0,.26,0]],head:['chest',[0,.32,.01]],earL:['head',[-.09,.52,-.01]],earR:['head',[.09,.52,-.01]],
 shL:['chest',[-.09,.25,0]],elL:['shL',[-.12,.19,.03]],haL:['elL',[-.13,.13,.05]],shR:['chest',[.09,.25,0]],elR:['shR',[.12,.19,.03]],haR:['elR',[.13,.13,.05]],
 thL:['hips',[-.05,.12,0]],knL:['thL',[-.055,.065,.01]],ftL:['knL',[-.058,.028,.02]],thR:['hips',[.05,.12,0]],knR:['thR',[.055,.065,.01]],ftR:['knR',[.058,.028,.02]],tail:['hips',[0,.15,-.09]]};
const cfg={name:'stray',J,TIP:{haL:[-.135,.088,.07],haR:[.135,.088,.07],ftL:[-.058,.004,.08],ftR:[.058,.004,.08]},
 TORSO:{hips:[[0,.08,0],[0,.26,0],.12],chest:[[0,.22,0],[0,.32,0],.1],head:[[0,.31,.01],[0,.62,.02],.2]},
 AIM:[],floor:.004,pivot:.16,shMin:-2.4,springs:[['earL','vx',-.45,120,6,0,.5],['earR','vx',-.6,90,5,0,.6],['tail','vx',-.5,90,6,0,.45],['tail','t',.25,60,6,2,.3,2.5]]};
const RK=makeRigKit(S,cfg);export const makeRig=RK.makeRig,skinGeo=RK.skinGeo;
export const CLIPS=stdClips({w:.48,arm:.3,x:{
 idle:{label:'Idle',len:4,f:t=>{const u=cyc(t,4);const b=Math.sin(u*TAU)*.5+.5;const look=bump(u,.4,.8);const sh=Math.sin(t*28)*bump(u,.85,.95);return{sq:b*.018,rz:sh*.03,hy:look*.45,hz:Math.sin(u*TAU)*.06+.05,eye:blink(t,3.4,.2)*1.05,b:{chest:[-b*.03,0,0],shL:[-.15,0,.12],shR:[-.15,0,-.12],elL:[-.4,0,0],elR:[-.4,0,0]}};}},
 idle2:{label:'Scratch an ear',len:4,f:t=>{const u=cyc(t,4);const k=bump(u,.1,.8);const sc=Math.sin(t*18)*k;return{hz:.22*k,hx:-.05*k,eye:1-k*.55,b:{shL:[-2.3*k,0,-.45*k],elL:[-1.1*k+sc*.25,0,0],haL:[sc*.3,0,0],shR:[-.15,0,-.12],elR:[-.4,0,0],chest:[0,0,-.08*k]}};}},
 ability:{label:'Follow home',len:2.6,f:t=>{const u=cyc(t,2.6);const k=ease(sstep(.02,.18,u))*(1-sstep(.85,1,u));const h1=bump(u,.15,.42),h2=bump(u,.48,.75);return{split:k,y:(h1+h2)*.07,sq:(h1+h2)*.05-bump(u,.4,.5)*.06,hz:Math.sin(t*6)*.08*k,eye:1.08,b:{shL:[-1.8*(h1+h2),0,-.3],shR:[-1.8*(h1+h2),0,.3],elL:[-.3,0,0],elR:[-.3,0,0]}};}},
 work:{label:'Ask a favour',len:4.2,f:t=>{const u=cyc(t,4.2);const k=ease(sstep(.05,.2,u))*(1-sstep(.86,1,u));const bob=Math.sin(t*5)*k;return{hz:.24*k,hx:-.12*k,eye:1+k*.14,eyeW:1+k*.05,sq:bob*.015,y:bob*.006,b:{shL:[-1.15*k,0,.38*k],shR:[-1.15*k,0,-.38*k],elL:[-1.05*k,0,0],elR:[-1.05*k,0,0],haL:[.4*k,0,0],haR:[.4*k,0,0]}};}},
 nap:{label:'Curl up',len:4.6,f:t=>{const b=Math.sin(t*TAU/4.6)*.5+.5;return{y:-.05,sq:-.06+b*.03,rx:.06,hx:.45,hz:.25,eye:.04,b:{thL:[-1.5,0,-.35],knL:[1.8,0,0],thR:[-1.5,0,.35],knR:[1.8,0,0],shL:[-.7,0,.4],elL:[-1.3,0,0],shR:[-.7,0,-.4],elR:[-1.3,0,0],chest:[.3+b*.04,0,0]}};}}}});
export const EXPR={
 happy:{label:'Hopeful',hz:.14,hx:-.06,eye:1.1,b:{shL:[-.9,0,.35],shR:[-.9,0,-.35],elL:[-1,0,0],elR:[-1,0,0]}},
 focus:{label:'Wary',hx:.12,hy:.25,eye:.72,b:{shL:[-.3,0,.2],shR:[-.3,0,-.2],elL:[-.8,0,0],elR:[-.8,0,0]}},
 startled:{label:'Startled',hx:-.16,eye:1.22,eyeW:1.08,b:{shL:[-.3,0,-.9],shR:[-.3,0,.9]}},
 caught:{label:'Forlorn',hx:.35,hz:.14,eye:.62,b:{chest:[.22,0,0],shL:[.12,0,.1],shR:[.12,0,-.1]}}};
export const build=o=>S.build(o),loadBaked=(u,r)=>S.loadBaked(u,r);
export const BIN='stray.bin?v=1',RES=.0046,GAME_SCALE=.9;
export const EMBERS=[['earL',[-.13,.61,-.02]],['earR',[.16,.56,.05]],['tail',[.06,.34,-.15]]];
export const ROUTE=[{to:[1.1,-.4],clip:'walk',sp:.24},{at:true,clip:'work',dur:4.2,face:[2,-1]},{to:[-.7,1],clip:'walk',sp:.24},{at:true,clip:'ability',dur:2.6,face:[1,3]},{at:true,clip:'idle2',dur:4,face:[1,3]},{to:[.2,.2],clip:'run',sp:.34},{at:true,clip:'nap',dur:4.6,face:[2,2]}];
export const HERO={cam:[1.05,.52,1.45],target:[0,.3,0],clip:'idle'};
