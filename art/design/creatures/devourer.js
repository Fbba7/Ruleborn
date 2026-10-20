import * as THREE from 'three';
import {makeSculpt,makeRigKit,sstep,vnoise,clamp,ease,bump,blink,cyc,TAU,merge} from './creature-kit.js';
import {parts} from './creature-parts.js';
// ============ THE DEVOURER · Anomaly · a drifting black hole · runs Inward pull and Heavy ground (GDD 11.8, 17.3) ============
// A round, hungry little void: a body of starry black, huge glowing eyes, a swirling mouth, and a blazing accretion disc
// with bits of stolen islands tumbling round it.
const COL={void:0x0A0718,voidL:0x2A1A4A,voidD:0x020106,rim:0x9A6AFF,mouth:0x000000,cheek:0x8A3AC8,hand:0x140C26};
const K=Object.fromEntries(Object.entries(COL).map(([k,v])=>[k,new THREE.Color(v)]));
const mir=(p,s)=>[p[0]*s,p[1],p[2]];let A0=null;
let sd=11;const rnd=()=>(sd=(sd*16807)%2147483647)/2147483647;
function discTex(){const S=1024,c=document.createElement('canvas');c.width=c.height=S;const x=c.getContext('2d');const C=S/2;x.translate(C,C);
 const pal=['255,236,180','255,190,90','255,130,60','240,90,120','190,110,255'];
 for(let i=0;i<900;i++){const r=(.6+Math.pow(rnd(),.8)*.4)*C*.98,a0=rnd()*TAU,len=.3+rnd()*1.6;const k=Math.min(4,Math.floor((r/C-.6)/.4*5));const al=(1-Math.abs((r/C-.8)/.2))*.55*rnd()+.05;
  x.strokeStyle='rgba('+pal[k]+','+al.toFixed(3)+')';x.lineWidth=1+rnd()*5;x.beginPath();x.arc(0,0,r,a0,a0+len);x.stroke();}
 const g=x.createRadialGradient(0,0,C*.6,0,0,C);g.addColorStop(0,'rgba(255,245,210,.95)');g.addColorStop(.08,'rgba(255,200,110,.7)');g.addColorStop(.5,'rgba(240,110,90,.25)');g.addColorStop(1,'rgba(160,90,255,0)');
 x.globalCompositeOperation='lighter';x.fillStyle=g;x.beginPath();x.arc(0,0,C,0,TAU);x.arc(0,0,C*.6,0,TAU,true);x.fill();
 const t=new THREE.CanvasTexture(c);t.colorSpace=THREE.SRGBColorSpace;return t;}
function vortexTex(){const S=512,c=document.createElement('canvas');c.width=c.height=S;const x=c.getContext('2d');const C=S/2;x.fillStyle='#000';x.fillRect(0,0,S,S);x.translate(C,C);
 for(let k=0;k<5;k++){x.beginPath();for(let i=0;i<=200;i++){const t=i/200;const r=t*C*.98,a=k/5*TAU+t*7;x.lineTo(Math.cos(a)*r,Math.sin(a)*r);}x.strokeStyle='rgba(170,110,255,'+(.55)+')';x.lineWidth=10;x.stroke();x.strokeStyle='rgba(255,170,230,.35)';x.lineWidth=3;x.stroke();}
 const g=x.createRadialGradient(0,0,0,0,0,C);g.addColorStop(0,'rgba(0,0,0,1)');g.addColorStop(.25,'rgba(0,0,0,.9)');g.addColorStop(1,'rgba(40,10,80,0)');x.fillStyle=g;x.fillRect(-C,-C,S,S);
 const t=new THREE.CanvasTexture(c);t.colorSpace=THREE.SRGBColorSpace;return t;}
const def={name:'devourer',box:[[-.36,.12,-.3],[.36,.84,.34]],res:.0058,warm:0x0A0418,aoWarm:.1,sheen:0xC8A8FF,rim:0xB08AFF,
 bodyMat:{roughness:.45,sheen:.9,sheenRoughness:.35,clearcoat:.4,clearcoatRoughness:.3},fur:{shells:0},
 sculpt(A){const{E,C}=A;A0=A;
  E('T:body',[0,.47,0],[.27,.25,.25],null,.08);E('T:belly',[0,.41,.06],[.21,.18,.18],null,.06);
  for(const s of[-1,1]){const L=s<0?'L':'R';E('T:cheek'+L,mir([.15,.44,.14],s),[.1,.085,.085],null,.05);
   // stubby void arms with three soft nubs
   const sh=mir([.23,.47,.03],s),el=mir([.3,.41,.08],s),wr=mir([.325,.36,.12],s);C('sh'+L+':arm1',sh,el,.055,.042,.04);C('el'+L+':arm2',el,wr,.042,.036,.03);
   E('ha'+L+':paw',mir([.33,.345,.13],s),[.042,.036,.04],null,.02);for(let k=0;k<3;k++){const a=(k-1)*.6;E('ha'+L+':nub'+k,mir([.34+Math.sin(a)*.025,.315,.15+Math.cos(a)*.01],s),[.015,.015,.017],null,.012);}
   // two curling void-wisp horns on top
   C('T:horn'+L+'1',mir([.1,.66,-.02],s),mir([.17,.76,-.04],s),.05,.032,.03);C('T:horn'+L+'2',mir([.17,.76,-.04],s),mir([.21,.86,0],s),.032,.018,.02);C('T:horn'+L+'3',mir([.21,.86,0],s),mir([.18,.94,.06],s),.018,.003,.012);}
  // a wispy tail trailing below and behind
  C('tail:t1',[0,.28,-.12],[0,.22,-.2],.07,.045,.04);C('tail:t2',[0,.22,-.2],[.03,.2,-.28],.045,.018,.03);
  // the mouth: a round open maw
  E('T:maw',[0,.37,.21],[.125,.05,.09],null,.016,'s');},
 disp(x,y,z,d){if(Math.abs(d)>.03)return d;return d+(vnoise(x*40,y*40,z*40)-.5)*.0012;},
 paint(x,y,z,nx,ny,nz,ao,c,A){
  c.copy(K.void).lerp(K.voidL,sstep(.2,.95,ny)*.35+sstep(.4,1,Math.abs(nx))*.12).lerp(K.voidD,(1-ao)*.7+sstep(-.1,-.8,ny)*.4);
  // nebula wisps drifting through the body
  const nb=vnoise(x*6+2,y*6,z*6);c.lerp(new THREE.Color(0x3A1A6A),sstep(.55,.8,nb)*.5).lerp(new THREE.Color(0x1A2A6A),sstep(.6,.85,vnoise(x*7,y*7+5,z*7))*.4);
  
  {const md=A.dist('T:maw',x,y,z)+.0;if(md<.004)c.copy(new THREE.Color(0x030208));else if(md<.012&&z>.16)c.lerp(new THREE.Color(0xB07AFF),(1-(md-.004)/.008)*.55);}
  if(A.minD(/^ha[LR]:/,x,y,z)<.003)c.lerp(K.hand,.4).lerp(K.voidL,sstep(.2,.9,ny)*.3);
  return 0;},
 accessories(A){const G=new THREE.Group();const P=parts(A,G);const{PB,add,irisTex,eye,glowTex,hit}=P;
  const tex=irisTex('#1A0004','#FF2A2A','#FFD080','#000000',{pup:.14});
  for(const s of[-1,1]){const e=eye(s,{r:.062,ctr:[0,.5,.02],dir:[.44,.06,1],off:-.02,tex,lid:COL.void,lidCut:.36,lidTilt:.22,yaw:.42,irisK:1.2});{const ld=e.getObjectByName('lid');if(ld){ld.rotation.z=0;}const bw=new THREE.Mesh(new THREE.CapsuleGeometry(.011,.066,4,12),ld?ld.material:new THREE.MeshStandardMaterial({color:0x111111}));bw.rotation.set(0,0,Math.PI/2+s*.5);bw.scale.set(1,1,.6);bw.position.set(-s*.006,.05,.036);bw.castShadow=true;e.add(bw);const gs=new THREE.Sprite(new THREE.SpriteMaterial({map:glowTex('rgba(255,60,40,.55)'),transparent:true,depthWrite:false,blending:THREE.AdditiveBlending}));gs.position.z=.012;gs.scale.setScalar(.09);e.add(gs);}
   const rg=add(new THREE.TorusGeometry(.07,.005,8,40),new THREE.MeshBasicMaterial({color:0xFF3A2A,transparent:true,opacity:.7,blending:THREE.AdditiveBlending,depthWrite:false}),[0,0,.018],null,null,e);rg.castShadow=false;}
  for(const s of[-1,1]){const L=s<0?'L':'R';const cm=PB(0xEDE4D2,{roughness:.35});for(let k=0;k<3;k++){const a=(k-1)*.6;const c=add(new THREE.ConeGeometry(.009,.04,8),cm,mir([.34+Math.sin(a)*.03,.29,.165+Math.cos(a)*.012],s),null,null,G);c.userData.bone='ha'+L;c.quaternion.setFromUnitVectors(new THREE.Vector3(0,1,0),new THREE.Vector3(s*.2,-.8,.6).normalize());}}
  // starfield sprinkled over its skin
  {const pos=[],col=[];const pal=[[1,1,1],[.7,.9,1],[1,.8,.95],[1,.95,.7]];for(let i=0;i<260;i++){const u=rnd()*2-1,a=rnd()*TAU;const d=[Math.sqrt(1-u*u)*Math.cos(a),u,Math.sqrt(1-u*u)*Math.sin(a)];const h=hit(d,[0,.47,0],.003);if(h.p.z>.13&&Math.abs(h.p.y-.49)<.1&&Math.abs(h.p.x)<.2)continue;pos.push(h.p.x,h.p.y,h.p.z);const p=pal[i%4];col.push(...p);}
   const g=new THREE.BufferGeometry();g.setAttribute('position',new THREE.Float32BufferAttribute(pos,3));g.setAttribute('color',new THREE.Float32BufferAttribute(col,3));
   const pts=new THREE.Points(g,new THREE.PointsMaterial({size:.009,vertexColors:true,transparent:true,opacity:.95,depthWrite:false,blending:THREE.AdditiveBlending,sizeAttenuation:true}));pts.userData.bone='chest';G.add(pts);}
  // the maw: a slowly turning vortex deep inside, rimmed with light
  {const h=hit([0,-.02,1],[0,.375,0],-.045);const g=new THREE.Group();g.userData.bone='head';g.position.copy(h.p);G.add(g);
   {const tm=PB(0xEDE4D2,{roughness:.35,clearcoat:.6});for(const[row,n,yy,dir]of[[0,8,.026,-1],[1,7,-.03,1]]){for(let k=0;k<n;k++){const u=(k+.5)/n*2-1;const L=(k%2?.03:.042)*(1-Math.abs(u)*.45);const x=u*.105,y=yy*Math.sqrt(Math.max(.05,1-u*u*.85));const t=add(new THREE.ConeGeometry(.012,L,8),tm,[x,y+dir*L*.35,.072-Math.abs(u)*.03],null,null,g);t.quaternion.setFromUnitVectors(new THREE.Vector3(0,1,0),new THREE.Vector3(-u*.25,dir,.15).normalize());}}
    const rg=new THREE.Sprite(new THREE.SpriteMaterial({map:glowTex('rgba(255,50,40,.45)'),transparent:true,depthWrite:false,blending:THREE.AdditiveBlending}));rg.position.z=.02;rg.scale.set(.24,.09,1);g.add(rg);}
   const vm=PB(0x000000,{map:vortexTex(),emissive:0xffffff,emissiveMap:null,roughness:1});vm.emissiveIntensity=0;const d=add(new THREE.CircleGeometry(.1,40),new THREE.MeshBasicMaterial({map:vortexTex()}),[0,0,0],null,[1.2,.45,1],g);d.userData.spin=-1.4;d.userData.spinAx='z';
}
  // accretion disc: a blazing tilted ring, turning
  const DT=discTex();
  {const g=new THREE.Group();g.userData.bone='chest';g.position.set(0,.38,0);g.rotation.set(-1.25,0,.16);G.add(g);
   const m=new THREE.MeshBasicMaterial({map:DT,transparent:true,side:THREE.DoubleSide,depthWrite:false,blending:THREE.AdditiveBlending});
   m.opacity=.85;const d=add(new THREE.RingGeometry(.34,.52,96,1),m,null,null,null,g);d.castShadow=false;d.userData.spin=.7;d.userData.spinAx='z';
   const d2=add(new THREE.RingGeometry(.3,.43,96,1),m.clone(),[0,0,.004],[0,0,1.3],null,g);d2.material.opacity=.55;d2.castShadow=false;d2.userData.spin=1.2;d2.userData.spinAx='z';
}
  // stolen scraps tumbling round it: rocks, a coin, a tiny cottage, a tree, a lantern
  {const g=new THREE.Group();g.userData.bone='chest';g.position.set(0,.46,0);g.rotation.set(.42,0,.12);g.userData.spin=.45;g.userData.spinAx='y';G.add(g);
   const rk=PB(0x7A6A8A,{roughness:.8}),gr=PB(0x6AAE4A,{roughness:.7});
   const put=(o,a,r,y,sp)=>{const w=new THREE.Group();w.position.set(Math.sin(a)*r,y,Math.cos(a)*r);w.userData.spin=sp;w.userData.spinAx='x';g.add(w);w.add(o);return w;};
   for(let k=0;k<6;k++){const a=k/6*TAU+.4;const o=new THREE.Group();const s=.03+rnd()*.025;const m=new THREE.Mesh(new THREE.DodecahedronGeometry(s,0),rk);m.castShadow=true;o.add(m);if(k%2){const t=new THREE.Mesh(new THREE.CylinderGeometry(s*.9,s*.9,s*.35,7),gr);t.position.y=s*.55;o.add(t);}put(o,a,.72+rnd()*.08,-.06+(rnd()-.5)*.1,.8+rnd());}
   {const o=new THREE.Group();const wl=new THREE.Mesh(new THREE.BoxGeometry(.05,.04,.045),PB(0xF4E8D8,{roughness:.8}));o.add(wl);const rf=new THREE.Mesh(new THREE.ConeGeometry(.045,.035,4),PB(0xD8583A,{roughness:.7}));rf.position.y=.037;rf.rotation.y=Math.PI/4;o.add(rf);put(o,1.9,.66,.05,.5);}
   {const o=new THREE.Group();const c=new THREE.Mesh(new THREE.CylinderGeometry(.028,.028,.006,24),PB(0xE9B65C,{metalness:.9,roughness:.25}));c.rotation.x=Math.PI/2;o.add(c);put(o,3.3,.6,-.04,2.2);}
   {const o=new THREE.Group();const tr=new THREE.Mesh(new THREE.ConeGeometry(.03,.07,8),PB(0xF2A5CF,{roughness:.7}));tr.position.y=.03;o.add(tr);const tk=new THREE.Mesh(new THREE.CylinderGeometry(.006,.008,.03,6),PB(0x7A4A2A));tk.position.y=-.015;o.add(tk);put(o,4.6,.64,.06,.9);}
   {const o=new THREE.Group();const lm=new THREE.Mesh(new THREE.SphereGeometry(.018,12,10),PB(0xFFE08A,{emissive:0xFFB040,emissiveIntensity:1.5}));o.add(lm);const gl=new THREE.Sprite(new THREE.SpriteMaterial({map:glowTex('rgba(255,210,120,.8)'),transparent:true,depthWrite:false,blending:THREE.AdditiveBlending}));gl.scale.setScalar(.09);o.add(gl);put(o,5.5,.58,-.07,1.5);}}
  // inward pull (ability): spiral streams of light pouring into the maw
  const fx=new THREE.Group();fx.userData.bone='root';fx.userData.fx='split';fx.userData.fxMode='show';fx.position.set(0,.38,.26);G.add(fx);
  {const sg=new THREE.Group();sg.userData.spin=-4;sg.userData.spinAx='z';fx.add(sg);const sm=new THREE.MeshBasicMaterial({color:0xC89AFF,transparent:true,opacity:.75,blending:THREE.AdditiveBlending,depthWrite:false});
   for(let k=0;k<5;k++){const cu=new THREE.Curve();cu.getPoint=(t,o=new THREE.Vector3())=>{const a=k/5*TAU+t*5,r=.04+t*.34;return o.set(Math.cos(a)*r,Math.sin(a)*r,t*.35);};add(new THREE.TubeGeometry(cu,60,.006,5),sm,null,null,null,sg);}
   const gl=new THREE.Sprite(new THREE.SpriteMaterial({map:glowTex('rgba(200,150,255,.7)'),transparent:true,depthWrite:false,blending:THREE.AdditiveBlending}));gl.scale.setScalar(.45);fx.add(gl);}
  return G;}};
export const S=makeSculpt(def);
const J={root:[null,[0,0,0]],hips:['root',[0,.4,0]],chest:['hips',[0,.47,0]],head:['chest',[0,.52,.02]],earL:['head',[-.1,.66,-.02]],earR:['head',[.1,.66,-.02]],
 shL:['chest',[-.23,.47,.03]],elL:['shL',[-.3,.41,.08]],haL:['elL',[-.325,.36,.12]],shR:['chest',[.23,.47,.03]],elR:['shR',[.3,.41,.08]],haR:['elR',[.325,.36,.12]],tail:['hips',[0,.28,-.12]]};
const cfg={name:'devourer',J,TIP:{haL:[-.34,.31,.15],haR:[.34,.31,.15]},feet:['hips'],
 TORSO:{hips:[[0,.2,0],[0,.4,0],.26],chest:[[0,.35,0],[0,.6,0],.28],head:[[0,.52,.02],[0,.84,0],.1]},AIM:[],floor:.62,pivot:.47,shMin:-2,
 springs:[['tail','vx',-.5,80,6,0,.45],['tail','t',.3,50,6,2,.3,1.6]]};
const RK=makeRigKit(S,cfg);export const makeRig=RK.makeRig,skinGeo=RK.skinGeo;
const ARMS=(t,k=1)=>({shL:[Math.sin(t*1.3)*.12*k,0,.1],shR:[Math.sin(t*1.3+1.2)*.12*k,0,-.1],elL:[-.3,0,0],elR:[-.3,0,0]});
export const CLIPS={
 idle:{label:'Drift',len:4,f:t=>{return{y:Math.sin(t*.9)*.03,rz:Math.sin(t*.6)*.05,rx:Math.sin(t*.5)*.03,hy:Math.sin(t*.4)*.2,eye:blink(t,4.4,.4),b:ARMS(t)};}},
 idle2:{label:'Grumble',len:4.2,f:t=>{const u=cyc(t,4.2);const g=bump(u,.3,.7);return{y:Math.sin(t*.9)*.02,sq:Math.sin(t*14)*.02*g-g*.04,hx:.1*g,hz:Math.sin(t*9)*.05*g,eye:1-g*.4,b:merge(ARMS(t),{shL:[-.6*g,0,.5*g],shR:[-.6*g,0,-.5*g],elL:[-.9*g,0,0],elR:[-.9*g,0,0]})};}},
 walk:{label:'Drift along',len:3,f:t=>{const u=cyc(t,3);return{y:Math.sin(u*TAU)*.04,rx:.12,rz:Math.sin(u*TAU)*.07,eye:blink(t,3.5),b:ARMS(t,1.6)};}},
 run:{label:'Lurch',len:1.4,f:t=>{const u=cyc(t,1.4);const l=bump(u,.1,.6);return{y:l*.06,z:l*.05,rx:.25*l,sq:-l*.06+bump(u,.6,.8)*.05,eye:1.05,b:{shL:[-1.4*l,0,.3],shR:[-1.4*l,0,-.3],elL:[-.2,0,0],elR:[-.2,0,0]}};}},
 ability:{label:'Inward pull',len:3,f:t=>{const u=cyc(t,3);const k=ease(sstep(.05,.3,u))*(1-sstep(.85,1,u));return{split:k,sq:Math.sin(t*18)*.018*k-k*.03,hx:-.08*k,rz:Math.sin(t*11)*.03*k,eye:1+k*.15,eyeW:1+k*.08,b:{shL:[-1.2*k,0,.8*k],shR:[-1.2*k,0,-.8*k],elL:[-.4,0,0],elR:[-.4,0,0]}};}},
 work:{label:'Devour',len:3.2,f:t=>{const u=cyc(t,3.2);const open=bump(u,.05,.45),gulp=bump(u,.45,.65),sat=bump(u,.65,1);return{sq:open*.08-gulp*.12+sat*.02,hx:-.14*open+.12*gulp,y:gulp*.03,eye:u>.5&&u<.9?.25:1,b:{shL:[-1.3*open,0,.7*open],shR:[-1.3*open,0,-.7*open],elL:[-.8*open,0,0],elR:[-.8*open,0,0],chest:[0,0,Math.sin(t*6)*.04*sat]}};}},
 nap:{label:'Collapse to a dwarf star',len:5,f:t=>{const b=Math.sin(t*TAU/5)*.5+.5;return{y:-.08,sq:-.08+b*.03,hx:.25,hz:.12,eye:.05,b:{shL:[-.9,0,.6],shR:[-.9,0,-.6],elL:[-1.3,0,0],elR:[-1.3,0,0]}};}},
 celebrate:{label:'Supernova spin',len:1.8,f:t=>{const u=cyc(t,1.8);const j=bump(u,.05,.8);return{y:j*.12,ry:ease(sstep(.1,.8,u))*TAU,sq:j*.05,eye:1,b:{shL:[0,0,1.1*j],shR:[0,0,-1.1*j],elL:[-.1,0,0],elR:[-.1,0,0]}};}},
 hit:{label:'Flicker',len:1.2,f:t=>{const u=cyc(t,1.2);const k=bump(u,0,.3),r=1-ease(sstep(.3,1,u));return{z:-k*.06,sq:k*.12,rz:Math.sin(u*40)*.12*r,eye:1+k*.3,eyeW:1+k*.15,b:{shL:[-.3,0,1*k],shR:[-.3,0,-1*k]}};}},
 leap:{label:'Surge',len:1.6,f:t=>{const u=cyc(t,1.6);const a=bump(u,.15,.85);return{y:a*.2,sq:-bump(u,0,.2)*.08+a*.06,rx:-.1*a,eye:1,b:{shL:[-1.8*a,0,.3],shR:[-1.8*a,0,-.3]}};}}};
export const EXPR={
 happy:{label:'Hungry',hz:-.1,hx:-.05,eye:.85,b:ARMS(0,1)},
 focus:{label:'Pulling',hx:-.12,eye:.7,b:{shL:[-1.2,0,.8],shR:[-1.2,0,-.8],elL:[-.4,0,0],elR:[-.4,0,0]}},
 startled:{label:'Startled',hx:-.14,eye:1.2,eyeW:1.1,b:{shL:[-.3,0,1],shR:[-.3,0,-1]}},
 caught:{label:'Starved',hx:.3,hz:.12,eye:.5,sq:-.06,b:{shL:[.2,0,.1],shR:[.2,0,-.1]}}};
export const build=o=>S.build(o),loadBaked=(u,r)=>S.loadBaked(u,r);
export const BIN='devourer.bin?v=1',RES=.0058,GAME_SCALE=2.6;
export const EMBERS=[['earL',[-.14,.8,-.1]],['earR',[.14,.8,-.1]],['tail',[.03,.2,-.28]]];
export const ROUTE=[{to:[1.1,-.4],clip:'walk',sp:.16},{at:true,clip:'work',dur:3.2,face:[2,-1]},{to:[-.7,1],clip:'walk',sp:.16},{at:true,clip:'ability',dur:3,face:[1,3]},{at:true,clip:'idle',dur:4,face:[1,3]},{to:[.2,.2],clip:'run',sp:.26},{at:true,clip:'nap',dur:5,face:[2,2]}];
export const HERO={cam:[1.3,.3,2.35],target:[0,.72,0],clip:'idle'};
