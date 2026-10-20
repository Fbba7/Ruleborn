import * as THREE from 'three';
import {makeSculpt,makeRigKit,stdClips,sstep,vnoise,clamp,ease,bump,blink,cyc,TAU,merge,gait} from './creature-kit.js';
import {parts} from './creature-parts.js';
// ============ SOULMENDER · Mender · Spirit · hooded moth-like spirit, 0.9 m, magenta and lilac (GDD 11.4) ============
const COL={fuzz:0xD4B4E8,fuzzL:0xF6E8FF,fuzzD:0x6E4E90,hood:0xA8388A,hoodL:0xD86AB8,hoodD:0x5A1450,face:0x3A1A40,faceL:0x6A3A70,lilac:0xC8A8F0,mouth:0x1A0818};
const K=Object.fromEntries(Object.entries(COL).map(([k,v])=>[k,new THREE.Color(v)]));
const mir=(p,s)=>[p[0]*s,p[1],p[2]];let A0=null;
const HOV=.06;
const def={name:'soulmender',box:[[-.24,0,-.22],[.24,.92,.22]],res:.0054,warm:0x2A0A30,aoWarm:.18,sheen:0xFFF0FF,rim:0xE0B8FF,
 bodyMat:{roughness:.7,sheen:.7,sheenRoughness:.35},fur:{len:.011,dens:[1300,1000,1300],shells:7,strand:[0,-1,-.3]},
 sculpt(A){const{E,C}=A;A0=A;
  // plump furry body with a big lilac ruff; a soft round head deep inside a hood
  E('T:body',[0,.3,0],[.12,.15,.11],null,.06);E('T:abdomen',[0,.18,-.03],[.09,.1,.085],null,.05);for(let k=0;k<3;k++)E('T:band'+k,[0,.14+k*.06,-.035],[.095-k*.006,.012,.088-k*.006],null,.015);
  E('T:ruff',[0,.44,.02],[.15,.075,.13],null,.05);
  // the hood: a soft cowl whose rim frames the face; the head is added after the cut so it sits in the opening
  E('T:hood',[0,.6,-.02],[.165,.17,.155],null,.05);E('T:hoodcut',[0,.565,.12],[.118,.118,.1],null,.025,'s');E('T:hoodtip',[0,.75,-.08],[.05,.06,.05],[-.6,0,0],.04);
  E('T:head',[0,.57,.02],[.12,.12,.11],null,.03);E('T:face',[0,.555,.07],[.1,.095,.055],null,.03);E('T:mouthcut',[0,.495,.118],[.012,.003,.012],[.15,0,0],.002,'s');
  for(const s of[-1,1]){const L=s<0?'L':'R';
   // small furry arms folded in front, four legs tucked
   const sh=mir([.1,.38,.03],s),el=mir([.12,.3,.08],s),wr=mir([.08,.27,.12],s);C('sh'+L+':arm1',sh,el,.03,.026,.02);C('el'+L+':arm2',el,wr,.026,.022,.015);E('ha'+L+':paw',mir([.065,.27,.13],s),[.022,.02,.02],null,.012);
   C('th'+L+':leg1',mir([.05,.18,.02],s),mir([.06,.08,.04],s),.035,.026,.02);C('kn'+L+':leg2',mir([.06,.08,.04],s),mir([.065,.02,.05],s),.026,.02,.015);E('ft'+L+':foot',mir([.065,.012,.07],s),[.026,.012,.032],null,.01);}},
 disp(x,y,z,d){if(Math.abs(d)>.03)return d;const hood=sstep(.012,0,A0.dist('T:hood',x,y,z));const fold=Math.pow(Math.abs(Math.sin(Math.atan2(x,z-.02)*5)),3);return d+hood*fold*-.003*sstep(.7,.5,y)+(vnoise(x*70,y*70,z*70)-.5)*.0006;},
 paint(x,y,z,nx,ny,nz,ao,c,A){
  c.copy(K.fuzz).lerp(K.fuzzL,sstep(.2,.95,ny)*.3+sstep(.3,.9,nz)*.1).lerp(K.fuzzD,(1-ao)*.5+sstep(-.2,-.8,ny)*.25);
  {const st=vnoise(x*420,y*46,z*420);c.lerp(st>.5?K.fuzzL:K.fuzzD,Math.abs(st-.5)*.3);}
  // lilac ruff tips, dark abdomen bands
  if(A.dist('T:ruff',x,y,z)<.006)c.lerp(K.lilac,sstep(.44,.49,y)*.6+sstep(.3,.9,nz)*.2);
  if(A.minD(/^T:band/,x,y,z)<.004)c.lerp(K.fuzzD,.6).lerp(K.hoodD,.3);
  // hood: magenta velvet with a pale lining at the rim
  const hd=A.minD(/^T:(hood|hoodtip)/,x,y,z);let fur=1;
  if(hd<.004){const lin=sstep(.02,.004,Math.abs(A.dist('T:hoodcut',x,y,z)));c.copy(K.hood).lerp(K.hoodL,sstep(.2,.95,ny)*.35+sstep(.3,.9,nz)*.15).lerp(K.hoodD,(1-ao)*.55+sstep(-.2,-.8,ny)*.3);c.lerp(K.lilac,lin*.7);
   c.lerp(K.hoodD,Math.pow(Math.abs(Math.sin(Math.atan2(x,z-.02)*5)),3)*.25*sstep(.7,.5,y));fur=0;}
  // dark soft face inside the hood
  const fc=sstep(.02,-.004,A.dist('T:face',x,y,z))*sstep(.05,.1,z);if(fc>.01&&hd>.003){c.lerp(K.face,fc).lerp(K.faceL,fc*sstep(.3,.95,ny)*.25);fur*=1-fc;}
  if(Math.abs(A.dist('T:mouthcut',x,y,z))<.0025&&z>.12)c.copy(K.mouth);
  if(A.minD(/^(ha|ft)[LR]:/,x,y,z)<.003)c.lerp(K.fuzzD,.4);
  return clamp(fur*(.6+sstep(.004,-.004,A.dist('T:ruff',x,y,z))*.4),0,1);},
 accessories(A){const G=new THREE.Group();const P=parts(A,G);const{PB,add,irisTex,eye}=P;
  const tex=irisTex('#040008','#1A0A2A','#5A3A8A','#08000E',{pup:.55});
  for(const s of[-1,1])eye(s,{r:.05,ctr:[0,.57,.02],dir:[.42,.03,1],off:-.02,tex,lid:COL.face,lidCut:.18,yaw:.32,irisK:1.1});
  // feathery antennae curling out of the hood
  const am=PB(0xE8D0FF,{roughness:.6,sheen:.6,sheenColor:new THREE.Color(0xFFE0FF)});
  for(const s of[-1,1]){const g=new THREE.Group();g.userData.bone=s<0?'earL':'earR';g.position.set(s*.06,.7,.07);G.add(g);
   const cu=new THREE.Curve();cu.getPoint=(t,o=new THREE.Vector3())=>o.set(s*(t*.09+Math.sin(t*2.2)*.02),t*.14-t*t*.04,t*.04);add(new THREE.TubeGeometry(cu,24,.004,6),am,null,null,null,g);
   for(let k=1;k<14;k++){const t=k/14;const p=cu.getPoint(t);for(const q of[-1,1]){const b=new THREE.Mesh(new THREE.CylinderGeometry(.0006,.0018,.05*Math.sin(t*Math.PI)+.01,4),am);b.position.copy(p);b.rotation.set(q*1.1,0,s*.6+q*.3);g.add(b);}}}
  // soft wings: two pairs, lilac with magenta eyespots and pale fringe
  const wingTex=(()=>{const c=document.createElement('canvas');c.width=c.height=512;const x=c.getContext('2d');const g=x.createLinearGradient(0,0,512,0);g.addColorStop(0,'#4A1A88');g.addColorStop(.35,'#7A3AC0');g.addColorStop(.75,'#A858C8');g.addColorStop(1,'#D878C8');x.fillStyle=g;x.fillRect(0,0,512,512);
   x.globalAlpha=.25;x.strokeStyle='#3A1A6A';x.lineWidth=3;for(let i=0;i<7;i++){x.beginPath();x.moveTo(0,256);x.quadraticCurveTo(200,256+(i-3)*50,512,256+(i-3)*110);x.stroke();}x.globalAlpha=1;
   const spot=(cx,cy,r)=>{for(const[f,col]of[[1.35,'#F8E8FF'],[1,'#B8388A'],[.62,'#E86AC0'],[.36,'#1E0A2A'],[.12,'#FFFFFF']]){x.fillStyle=col;x.beginPath();x.ellipse(cx,cy,r*f,r*f*.9,0,0,TAU);x.fill();}};spot(300,190,60);spot(250,360,34);
   x.fillStyle='#F8ECFF';for(let i=0;i<40;i++){const t=i/40;x.beginPath();x.arc(496+Math.sin(t*9)*4,t*512,7,0,TAU);x.fill();}
   const t=new THREE.CanvasTexture(c);t.colorSpace=THREE.SRGBColorSpace;return t;})();
  const wingGeo=(w,h,up)=>{const s=new THREE.Shape();s.moveTo(0,0);s.bezierCurveTo(w*.4,h*up,w*1.05,h*up*.9,w,h*up*.2);s.bezierCurveTo(w*.9,-h*.3*up,w*.4,-h*.25*up,0,0);const g=new THREE.ShapeGeometry(s,32);const p=g.attributes.position,uv=g.attributes.uv;
   for(let i=0;i<p.count;i++){const px=p.getX(i),py=p.getY(i);p.setZ(i,-Math.pow(px/w,2)*.03);uv.setXY(i,px/w,.5+py/(h*1.4)*(up>0?1:-1));}g.computeVertexNormals();return g;};
  const wm=PB(0xFFFFFF,{map:wingTex,roughness:.5,sheen:.8,sheenColor:new THREE.Color(0xFFD8FF),side:THREE.DoubleSide});
  for(const s of[-1,1]){const g=new THREE.Group();g.userData.bone=s<0?'shL':'shR';g.position.set(s*.05,.44,-.1);g.rotation.set(-.35,s*-.5,s*.25);G.add(g);
   const up=add(wingGeo(.32,.28,1),wm,null,null,[s,1,1],g);up.name='wing';const lo=add(wingGeo(.22,.18,-1),wm,[0,-.02,-.01],null,[s,1,1],g);lo.name='wing';}
  // Mender charm: a glowing Spirit spiral pendant on a thread
  {const g=new THREE.Group();g.userData.bone='chest';g.position.set(0,.4,.13);G.add(g);const sp=new THREE.Curve();sp.getPoint=(t,o=new THREE.Vector3())=>{const a=t*TAU*2,r=.002+t*.016;return o.set(Math.cos(a)*r,Math.sin(a)*r,0);};
   add(new THREE.TubeGeometry(sp,48,.0035,6),PB(0xFFD8FF,{emissive:0xE05CB4,emissiveIntensity:1.6}),null,null,null,g);}
  // link (ability): glowing threads spiralling out from its wings
  const fx=new THREE.Group();fx.userData.bone='root';fx.userData.fx='split';fx.userData.fxMode='show';fx.position.set(0,.4,0);G.add(fx);
  const tm=new THREE.MeshBasicMaterial({color:0xFF9AE8,transparent:true,opacity:.7,depthWrite:false,blending:THREE.AdditiveBlending});
  for(let k=0;k<5;k++){const a0=k/5*TAU;const cu=new THREE.Curve();cu.getPoint=(t,o=new THREE.Vector3())=>{const a=a0+t*2.5,r=.08+t*.5;return o.set(Math.cos(a)*r,Math.sin(t*6+k)*.04-t*.3,Math.sin(a)*r);};const m=new THREE.Mesh(new THREE.TubeGeometry(cu,40,.004,5),tm);fx.add(m);
   const b=new THREE.Mesh(new THREE.SphereGeometry(.018,10,8),tm);b.position.copy(cu.getPoint(1));fx.add(b);}
  return G;}};
export const S=makeSculpt(def);
const J={root:[null,[0,0,0]],hips:['root',[0,.2,0]],chest:['hips',[0,.36,0]],head:['chest',[0,.47,.01]],earL:['head',[-.06,.7,.07]],earR:['head',[.06,.7,.07]],
 shL:['chest',[-.1,.38,.03]],elL:['shL',[-.12,.3,.08]],haL:['elL',[-.08,.27,.12]],shR:['chest',[.1,.38,.03]],elR:['shR',[.12,.3,.08]],haR:['elR',[.08,.27,.12]],
 thL:['hips',[-.05,.18,.02]],knL:['thL',[-.06,.08,.04]],ftL:['knL',[-.065,.02,.05]],thR:['hips',[.05,.18,.02]],knR:['thR',[.06,.08,.04]],ftR:['knR',[.065,.02,.05]],tail:['hips',[0,.16,-.06]]};
const cfg={name:'soulmender',J,TIP:{haL:[-.06,.265,.14],haR:[.06,.265,.14],ftL:[-.065,.004,.09],ftR:[.065,.004,.09]},
 TORSO:{hips:[[0,.08,0],[0,.3,0],.13],chest:[[0,.26,0],[0,.48,.01],.16],head:[[0,.44,.01],[0,.8,.02],.18]},
 AIM:[],floor:.004,pivot:.26,shMin:-1.9,springs:[['earL','vx',-.4,110,6,0,.45],['earR','vx',-.4,110,6,0,.45],['tail','vy',-.2,120,10,0,.1]]};
const RK=makeRigKit(S,cfg);export const makeRig=RK.makeRig,skinGeo=RK.skinGeo;
const C0=stdClips({w:.25,arm:.3,x:{
 idle:{label:'Idle',len:4.4,f:t=>{const u=cyc(t,4.4);const b=Math.sin(u*TAU)*.5+.5;const watch=bump(u,.45,.85);return{sq:b*.014,hz:Math.sin(u*TAU)*.04,hy:watch*.3,hx:.08-watch*.05,eye:blink(t,4.4,.9),b:{chest:[-b*.02,0,0],shL:[-.5,0,.35],shR:[-.5,0,-.35],elL:[-1.2,0,0],elR:[-1.2,0,0]}};}},
 idle2:{label:'Idle 2',len:4.8,f:t=>{const u=cyc(t,4.8);const fan=bump(u,.2,.7);const beat=Math.sin(t*6)*fan;return{y:fan*.02,hx:-.05*fan,eye:1-fan*.15,b:{shL:[-.5,-.35*fan+beat*.12,.35],shR:[-.5,.35*fan-beat*.12,-.35],elL:[-1.2,0,0],elR:[-1.2,0,0]}};}},
 ability:{label:'Link the crew',len:3,f:t=>{const u=cyc(t,3);const open=ease(sstep(.05,.3,u))*(1-sstep(.85,1,u));const beat=Math.sin(t*10)*open;return{y:open*.14,sq:open*.05,hx:-.2*open,eye:1+open*.2,split:open,b:{shL:[-.6-.3*open,-.8*open+beat*.2,.35-.9*open],shR:[-.6-.3*open,.8*open-beat*.2,-.35+.9*open],elL:[-1.2+.8*open,0,0],elR:[-1.2+.8*open,0,0]}};}},
 work:{label:'Sits with the loser',len:5,f:t=>{const u=cyc(t,5);const lean=bump(u,.1,.9),pat=Math.sin(t*3)*bump(u,.35,.65);return{y:-.07,rz:-.12*lean,hx:.2*lean,hz:-.22*lean,eye:.75,b:{thL:[-1.3,0,-.3],knL:[1.6,0,0],thR:[-1.3,0,.3],knR:[1.6,0,0],shL:[-.5,0,.35],elL:[-1.2,0,0],shR:[-.9-pat*.1,0,-.6],elR:[-.8,0,0],chest:[.12,0,-.08*lean]}};}},
 nap:{label:'Nap',len:5,f:t=>{const b=Math.sin(t*TAU/5)*.5+.5;return{y:-.1,sq:-.06+b*.03,hx:.45,hz:.15,eye:.04,b:{thL:[-1.45,0,-.3],knL:[1.7,0,0],thR:[-1.45,0,.3],knR:[1.7,0,0],shL:[-.6,0,.4],elL:[-1.3,0,0],shR:[-.6,0,-.4],elR:[-1.3,0,0],chest:[.3+b*.04,0,0]}};}}}});
// it flies (GDD 12.x: Featherkin, Lantern Wisp and Soulmender fly), so moving clips hover a little
export const CLIPS=Object.fromEntries(Object.entries(C0).map(([k,c])=>[k,{...c,f:t=>{const p=c.f(t);const fly=['walk','run','carry','leap','slide','wade','climb'].includes(k);if(!fly)return p;const beat=Math.sin(t*12);const b={...(p.b||{})};const sl=b.shL||[0,0,0],sr=b.shR||[0,0,0];b.shL=[sl[0],sl[1]-.3+beat*.25,sl[2]];b.shR=[sr[0],sr[1]+.3-beat*.25,sr[2]];b.thL=[-.4,0,0];b.thR=[-.4,0,0];b.knL=[.6,0,0];b.knR=[.6,0,0];return{...p,b,y:(p.y||0)+HOV+Math.sin(t*3)*.012};}}]));
export const EXPR={
 happy:{label:'Gentle',hz:-.12,hx:.06,eye:.85,b:{shL:[-.5,0,.35],shR:[-.5,0,-.35],elL:[-1.2,0,0],elR:[-1.2,0,0]}},
 focus:{label:'Watchful',hx:.12,hy:.25,eye:.8,b:{shL:[-.5,-.2,.35],shR:[-.5,.2,-.35],elL:[-1.2,0,0],elR:[-1.2,0,0]}},
 startled:{label:'Startled',hx:-.15,eye:1.2,eyeW:1.08,b:{shL:[-.3,-.6,-.4],shR:[-.3,.6,.4]}},
 caught:{label:'Sorrowful',hx:.38,hz:.12,eye:.55,b:{chest:[.25,0,0],shL:[.1,0,.2],shR:[.1,0,-.2]}}};
export const build=o=>S.build(o),loadBaked=(u,r)=>S.loadBaked(u,r);
export const BIN='soulmender.bin?v=1',RES=.0054,GAME_SCALE=1.15;
export const EMBERS=[['earL',[-.14,.86,.1]],['earR',[.14,.86,.1]],['head',[0,.8,-.06]]];
export const ROUTE=[{to:[1.1,-.4],clip:'walk',sp:.24},{at:true,clip:'work',dur:5,face:[2,-1]},{to:[-.7,1],clip:'walk',sp:.26},{at:true,clip:'ability',dur:3,face:[1,3]},{at:true,clip:'idle',dur:4.4,face:[1,3]},{to:[.2,.2],clip:'carry',sp:.22},{at:true,clip:'nap',dur:5,face:[2,2]}];
export const HERO={cam:[1.45,.8,1.85],target:[0,.44,0],clip:'idle'};
