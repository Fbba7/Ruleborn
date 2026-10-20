import * as THREE from 'three';
import {makeSculpt,makeRigKit,sstep,vnoise,clamp,ease,bump,blink,cyc,TAU,merge} from './creature-kit.js';
import {parts} from './creature-parts.js';
// ============ THE HOURGLASS STORM · Anomaly · scrambles time · runs Tidemark and Haste (GDD 11.8, 17.3) ============
// A little thundercloud with a brass hourglass for a heart, clock-hand horns, a funnel tail and a ring of numerals
// that spins the wrong way round it.
const COL={cloud:0x34304F,cloudL:0x6E6A92,cloudD:0x0E0C1E,glow:0xFFE8A0,gold:0xE9B65C,sand:0xF2C46A,cheek:0xE88AB0,mouth:0x2A1A3A};
const K=Object.fromEntries(Object.entries(COL).map(([k,v])=>[k,new THREE.Color(v)]));
const mir=(p,s)=>[p[0]*s,p[1],p[2]];let A0=null;
let sd=23;const rnd=()=>(sd=(sd*16807)%2147483647)/2147483647;
function numeralTex(){const S=1024,c=document.createElement('canvas');c.width=c.height=S;const x=c.getContext('2d');const C=S/2;x.translate(C,C);
 x.strokeStyle='rgba(255,228,160,.9)';x.lineWidth=6;x.beginPath();x.arc(0,0,C*.97,0,TAU);x.stroke();x.lineWidth=3;x.beginPath();x.arc(0,0,C*.72,0,TAU);x.stroke();
 for(let i=0;i<60;i++){const a=i/60*TAU;const l=i%5?.03:.07;x.lineWidth=i%5?3:7;x.beginPath();x.moveTo(Math.cos(a)*C*.95,Math.sin(a)*C*.95);x.lineTo(Math.cos(a)*C*(.95-l),Math.sin(a)*C*(.95-l));x.stroke();}
 const N=['XII','I','II','III','IV','V','VI','VII','VIII','IX','X','XI'];x.fillStyle='rgba(255,236,180,.95)';x.font='700 70px Georgia,serif';x.textAlign='center';x.textBaseline='middle';
 for(let i=0;i<12;i++){const a=i/12*TAU-Math.PI/2;x.save();x.translate(Math.cos(a)*C*.81,Math.sin(a)*C*.81);x.rotate(a+Math.PI/2);x.fillText(N[(i*5)%12],0,0);x.restore();}
 const t=new THREE.CanvasTexture(c);t.colorSpace=THREE.SRGBColorSpace;return t;}
const def={name:'hourglassstorm',box:[[-.34,.04,-.3],[.34,.84,.3]],res:.0056,warm:0x14102A,aoWarm:.14,sheen:0xFFFFFF,rim:0xFFE8B0,
 bodyMat:{roughness:.85,sheen:.8,sheenRoughness:.6},fur:{shells:0},
 sculpt(A){const{E,C}=A;A0=A;
  // a round cloud head-and-body, lumpy puffs all round, smooth face
  E('T:core',[0,.5,0],[.2,.19,.18],null,.07);E('T:face',[0,.49,.1],[.16,.13,.1],null,.06);
  const puffs=[[0,.66,-.02,.1],[.12,.64,-.04,.085],[-.12,.64,-.04,.085],[.2,.54,-.06,.08],[-.2,.54,-.06,.08],[.16,.42,-.08,.08],[-.16,.42,-.08,.08],[0,.6,-.14,.1],[.07,.72,-.08,.07],[-.07,.72,-.08,.07],[.21,.44,.04,.06],[-.21,.44,.04,.06],[0,.36,-.1,.085]];
  puffs.forEach(([x,y,z,r],k)=>E('T:puff'+k,[x,y,z],[r,r*.92,r],null,.05));
  // funnel tail: a little tornado spiralling to a point
  C('tail:f1',[0,.36,-.02],[.02,.24,-.04],.12,.07,.05);C('tail:f2',[.02,.24,-.04],[-.02,.15,-.03],.07,.035,.04);C('tail:f3',[-.02,.15,-.03],[.02,.08,-.01],.035,.008,.025);
  for(const s of[-1,1]){const L=s<0?'L':'R';E('T:cheek'+L,mir([.11,.44,.13],s),[.06,.05,.05],null,.035);
   const sh=mir([.2,.47,.03],s),el=mir([.27,.4,.07],s),wr=mir([.29,.34,.1],s);C('sh'+L+':arm1',sh,el,.05,.04,.04);C('el'+L+':arm2',el,wr,.04,.035,.03);
   E('ha'+L+':mitt',mir([.295,.32,.11],s),[.042,.038,.04],null,.025);for(let k=0;k<3;k++){const a=(k-1)*.7;E('ha'+L+':puff'+k,mir([.3+Math.sin(a)*.03,.3,.12+Math.cos(a)*.015],s),[.02,.02,.02],null,.015);}}},
 disp(x,y,z,d){if(Math.abs(d)>.03)return d;const face=sstep(.03,.008,A0.minD(/^T:(face|cheek)/,x,y,z));return d+(1-face)*(Math.pow(vnoise(x*24,y*24,z*24),2)*-.004)+(vnoise(x*80,y*80,z*80)-.5)*.0008;},
 paint(x,y,z,nx,ny,nz,ao,c,A){
  c.copy(K.cloud).lerp(K.cloudL,sstep(.1,.95,ny)*.5+sstep(.4,.9,nz)*.1).lerp(K.cloudD,(1-ao)*.7+sstep(-.05,-.9,ny)*.6);
  c.lerp(K.cloudL,sstep(.4,.2,vnoise(x*24,y*24,z*24))*.25);
  // a warm lightning glow from inside the lower cloud
  c.lerp(new THREE.Color(0xC8B8FF),sstep(.62,.8,vnoise(x*8,y*8+3,z*8))*.5);{const nf=1-sstep(.2,.14,Math.abs(x))*sstep(.3,.36,y)*sstep(.66,.6,y)*sstep(.02,.1,z);const v=Math.abs(vnoise(x*18,y*18,z*18)-.5);c.lerp(new THREE.Color(0xFFF0A0),sstep(.02,0,v)*sstep(.5,.7,vnoise(x*5,y*5,z*5))*.75*nf);}
  const fc=sstep(.012,0,A.minD(/^T:(face|cheek)/,x,y,z))*sstep(.08,.14,z);c.lerp(K.cloudL,fc*.18);
  
  if(A.minD(/^tail:/,x,y,z)<.004){const sw=Math.sin(Math.atan2(x,z)*3+y*60)*.5+.5;c.lerp(K.cloudD,sstep(.6,.9,sw)*.35).lerp(K.cloudL,sstep(.3,.1,sw)*.25);}
  // a wobbly little mouth
  if(z>.15&&Math.abs(x)<.07){const u=x/.07,cy=.41+.018*u*u,h=.015*(1-u*u)+.0015,dy=y-cy;if(Math.abs(dy)<h+.0018){if(Math.abs(dy)>=h)c.copy(K.cloudD);else{const tt=1-Math.abs(((u*4+10)%1)-.5)*2,bt=1-Math.abs(((u*4+10.5)%1)-.5)*2;if(dy>h-tt*h*.9||dy<-h+bt*h*.7)c.set(0xF4F0E0).lerp(K.cloudD,(1-ao)*.3);else c.set(0x0A0616).lerp(new THREE.Color(0x6A5AFF),sstep(h*.6,0,Math.abs(dy))*.35);}}}
  return 0;},
 accessories(A){const G=new THREE.Group();const P=parts(A,G);const{PB,add,irisTex,eye,glowTex,hit}=P;
  const tex=irisTex('#1A1400','#FFE23A','#FFFFFF','#000000',{pup:.12});
  for(const s of[-1,1]){const e=eye(s,{r:.054,ctr:[0,.5,.02],dir:[.42,.08,1],off:-.018,tex,lid:COL.cloudD,lidCut:.36,lidTilt:.22,yaw:.4,irisK:1.25});{const ld=e.getObjectByName('lid');if(ld){ld.rotation.z=0;}const bw=new THREE.Mesh(new THREE.CapsuleGeometry(.011,.066,4,12),ld?ld.material:new THREE.MeshStandardMaterial({color:0x111111}));bw.rotation.set(0,0,Math.PI/2+s*.5);bw.scale.set(1,1,.6);bw.position.set(-s*.006,.05,.036);bw.castShadow=true;e.add(bw);const gs=new THREE.Sprite(new THREE.SpriteMaterial({map:glowTex('rgba(255,240,120,.6)'),transparent:true,depthWrite:false,blending:THREE.AdditiveBlending}));gs.position.z=.012;gs.scale.setScalar(.09);e.add(gs);}}
  const gold=PB(COL.gold,{metalness:.9,roughness:.25}),goldD=PB(0x9A6A2A,{metalness:.8,roughness:.35});
  // clock-hand horns: an hour hand and a minute hand
  {const g=new THREE.Group();g.userData.bone='head';G.add(g);
   const hand=(len,w)=>{const s=new THREE.Shape();s.moveTo(-w*.35,0);s.lineTo(w*.35,0);s.lineTo(w*.35,len*.55);s.quadraticCurveTo(w,len*.7,0,len);s.quadraticCurveTo(-w,len*.7,-w*.35,len*.55);s.closePath();const h=new THREE.Path();h.absarc(0,len*.72,w*.3,0,TAU,true);s.holes.push(h);
    return new THREE.ExtrudeGeometry(s,{depth:.008,bevelEnabled:true,bevelSize:.003,bevelThickness:.003,bevelSegments:2});};
   add(hand(.16,.05),gold,[-.1,.66,-.03],[-.15,.2,.55],null,g);add(hand(.22,.042),gold,[.1,.66,-.03],[-.15,-.2,-.4],null,g);
   for(const s of[-1,1])add(new THREE.CylinderGeometry(.018,.022,.02,16),goldD,[s*.1,.66,-.03],[Math.PI/2,0,0],null,g);}
  // the hourglass heart, set into its chest
  {const h=hit([0,-.05,1],[0,.29,0],.0);const g=new THREE.Group();g.userData.bone='chest';g.position.set(0,.225,h.p.z+.045);g.scale.setScalar(1.2);g.rotation.x=.12;G.add(g);
   const gm=new THREE.MeshPhysicalMaterial({color:0xE8F6FF,roughness:.04,transmission:.5,thickness:.02,transparent:true,opacity:.42,clearcoat:1,depthWrite:false});
   const bulb=[];for(let i=0;i<=16;i++){const t=i/16;bulb.push(new THREE.Vector2(.006+Math.sin(t*Math.PI)*.05*(t<.5?1:1),t*.085));}
   const bg=new THREE.LatheGeometry(bulb,32);add(bg,gm,[0,.004,0],null,null,g);add(bg,gm,[0,-.004,0],[Math.PI,0,0],null,g);
   const sm=PB(COL.sand,{roughness:.7,emissive:0xE09A20,emissiveIntensity:.9});
   add(new THREE.ConeGeometry(.042,.045,24),sm,[0,.035,0],[Math.PI,0,0],null,g);add(new THREE.ConeGeometry(.05,.04,24),sm,[0,-.065,0],null,null,g);
   const st=add(new THREE.CylinderGeometry(.0025,.0025,.07,6),PB(COL.sand,{emissive:0xC88A20,emissiveIntensity:.8}),[0,-.03,0],null,null,g);
   for(const y of[.09,-.09])add(new THREE.CylinderGeometry(.062,.062,.012,28),gold,[0,y,0],null,null,g);
   for(let k=0;k<3;k++){const a=k/3*TAU+.5;add(new THREE.CylinderGeometry(.005,.005,.18,8),goldD,[Math.sin(a)*.055,0,Math.cos(a)*.055],null,null,g);}
   const gl=new THREE.Sprite(new THREE.SpriteMaterial({map:glowTex('rgba(255,220,140,.55)'),transparent:true,depthWrite:false,blending:THREE.AdditiveBlending}));gl.scale.setScalar(.2);g.add(gl);}
  // the ring of numerals, turning backwards round it
  {const g=new THREE.Group();g.userData.bone='chest';g.position.set(0,.47,0);g.rotation.set(-1.2,0,-.2);G.add(g);
   const m=new THREE.MeshBasicMaterial({map:numeralTex(),transparent:true,side:THREE.DoubleSide,depthWrite:false,blending:THREE.NormalBlending,opacity:.95});
   const r=add(new THREE.RingGeometry(.38,.52,96,1),m,null,null,null,g);r.castShadow=false;r.userData.spin=-.35;r.userData.spinAx='z';}
  // drifting grains of sand and tiny lightning sparks
  {const pos=[];for(let i=0;i<70;i++){const a=rnd()*TAU,r=.3+rnd()*.28;pos.push(Math.sin(a)*r,.2+rnd()*.6,Math.cos(a)*r);}const g=new THREE.BufferGeometry();g.setAttribute('position',new THREE.Float32BufferAttribute(pos,3));
   const pts=new THREE.Points(g,new THREE.PointsMaterial({size:.012,color:0xFFD878,transparent:true,opacity:.85,depthWrite:false,blending:THREE.AdditiveBlending}));const w=new THREE.Group();w.userData.bone='root';w.userData.spin=.5;w.userData.spinAx='y';w.add(pts);G.add(w);}
  // time scramble (ability): lightning forks and a second, faster ring spinning the other way
  const fx=new THREE.Group();fx.userData.bone='root';fx.userData.fx='split';fx.userData.fxMode='show';fx.position.set(0,.47,0);G.add(fx);
  {const lm=new THREE.MeshBasicMaterial({color:0xFFF3B0,transparent:true,opacity:.9,blending:THREE.AdditiveBlending,depthWrite:false});
   for(let k=0;k<5;k++){const a=k/5*TAU+.3;const pts=[];let p=new THREE.Vector3(Math.sin(a)*.24,.1,Math.cos(a)*.24);for(let i=0;i<7;i++){pts.push(p.clone());p=p.clone().add(new THREE.Vector3(Math.sin(a)*.05+(rnd()-.5)*.06,-.08,Math.cos(a)*.05+(rnd()-.5)*.06));}
    add(new THREE.TubeGeometry(new THREE.CatmullRomCurve3(pts,false,'catmullrom',0),24,.006,5),lm,null,null,null,fx);}
   const r2=new THREE.Group();r2.rotation.set(-1.4,0,.3);fx.add(r2);const rr=add(new THREE.RingGeometry(.3,.4,96,1),new THREE.MeshBasicMaterial({map:numeralTex(),transparent:true,side:THREE.DoubleSide,depthWrite:false,blending:THREE.AdditiveBlending,opacity:.8}),null,null,null,r2);rr.userData.spin=3;rr.userData.spinAx='z';
   const gl=new THREE.Sprite(new THREE.SpriteMaterial({map:glowTex('rgba(255,236,160,.6)'),transparent:true,depthWrite:false,blending:THREE.AdditiveBlending}));gl.scale.setScalar(.7);fx.add(gl);}
  return G;}};
export const S=makeSculpt(def);
const J={root:[null,[0,0,0]],hips:['root',[0,.36,0]],chest:['hips',[0,.47,0]],head:['chest',[0,.52,.02]],earL:['head',[-.1,.66,-.03]],earR:['head',[.1,.66,-.03]],
 shL:['chest',[-.2,.47,.03]],elL:['shL',[-.27,.4,.07]],haL:['elL',[-.29,.34,.1]],shR:['chest',[.2,.47,.03]],elR:['shR',[.27,.4,.07]],haR:['elR',[.29,.34,.1]],tail:['hips',[0,.36,-.02]]};
const cfg={name:'hourglassstorm',J,TIP:{haL:[-.3,.29,.13],haR:[.3,.29,.13]},feet:['hips'],
 TORSO:{hips:[[0,.3,0],[0,.4,0],.2],chest:[[0,.38,0],[0,.6,0],.24],head:[[0,.52,.02],[0,.8,0],.12]},AIM:[],floor:.5,pivot:.47,shMin:-2,
 springs:[['tail','vx',-.6,70,5,0,.5],['tail','t',.35,50,5,2,.35,2.2]]};
const RK=makeRigKit(S,cfg);export const makeRig=RK.makeRig,skinGeo=RK.skinGeo;
const ARMS=(t,k=1)=>({shL:[Math.sin(t*1.5)*.14*k,0,.12],shR:[Math.sin(t*1.5+1)*.14*k,0,-.12],elL:[-.35,0,0],elR:[-.35,0,0]});
export const CLIPS={
 idle:{label:'Brew',len:4,f:t=>{return{y:Math.sin(t*1.1)*.03,rz:Math.sin(t*.7)*.05,hy:Math.sin(t*.5)*.25,sq:Math.sin(t*2.2)*.012,eye:blink(t,3.8,.3),b:ARMS(t)};}},
 idle2:{label:'Tick-tock',len:3,f:t=>{const u=cyc(t,3);const tk=Math.sign(Math.sin(u*TAU*2));return{y:Math.sin(t*1.1)*.02,hz:tk*.16,rz:tk*.04,eye:blink(t,3,.6),b:merge(ARMS(t),{shL:[-.4,0,.3+tk*.15],shR:[-.4,0,-.3+tk*.15]})};}},
 walk:{label:'Roll in',len:2.6,f:t=>{const u=cyc(t,2.6);return{y:Math.sin(u*TAU)*.04,rx:.14,rz:Math.sin(u*TAU)*.08,ry:Math.sin(u*TAU)*.1,eye:blink(t,3.5),b:ARMS(t,1.8)};}},
 run:{label:'Haste',len:.9,f:t=>{const u=cyc(t,.9);return{y:.03+Math.sin(u*TAU*2)*.03,rx:.35,rz:Math.sin(u*TAU)*.1,eye:.95,b:{shL:[.6,0,.4],shR:[.6,0,-.4],elL:[-.2,0,0],elR:[-.2,0,0]}};}},
 ability:{label:'Scramble time',len:2.6,f:t=>{const u=cyc(t,2.6);const k=ease(sstep(.05,.25,u))*(1-sstep(.85,1,u));return{split:k,ry:-ease(sstep(.1,.8,u))*TAU,sq:Math.sin(t*20)*.02*k,y:k*.05,eye:1+k*.12,b:{shL:[-2.2*k,0,.4*k],shR:[-2.2*k,0,-.4*k],elL:[-.3,0,0],elR:[-.3,0,0]}};}},
 work:{label:'Turn the glass',len:4.2,f:t=>{const u=cyc(t,4.2);const k=bump(u,.1,.9);const fl=ease(sstep(.35,.65,u));return{rx:fl*TAU*.5*(u<.9?1:0),y:k*.08,hx:.15*k,eye:u>.35&&u<.65?.3:1,sq:-k*.03,b:{shL:[-1*k,0,.6*k],shR:[-1*k,0,-.6*k],elL:[-.8*k,0,0],elR:[-.8*k,0,0]}};}},
 nap:{label:'Rain out',len:5,f:t=>{const b=Math.sin(t*TAU/5)*.5+.5;return{y:-.06,sq:-.07+b*.03,hx:.25,hz:.14,eye:.05,b:{shL:[.1,0,.5],shR:[.1,0,-.5],elL:[-.6,0,0],elR:[-.6,0,0]}};}},
 celebrate:{label:'Thunderclap',len:1.6,f:t=>{const u=cyc(t,1.6);const c=bump(u,.3,.5);const j=bump(u,.05,.7);return{y:j*.12,sq:c*.1-bump(u,.5,.65)*.06,eye:1-c*.6,b:{shL:[-2.4*j+.8*c,0,-.2],shR:[-2.4*j+.8*c,0,.2],elL:[-.2,0,0],elR:[-.2,0,0]}};}},
 hit:{label:'Scattered',len:1.2,f:t=>{const u=cyc(t,1.2);const k=bump(u,0,.3),r=1-ease(sstep(.3,1,u));return{z:-k*.05,sq:k*.12,rz:Math.sin(u*40)*.12*r,eye:1+k*.3,eyeW:1+k*.12,b:{shL:[-.3,0,1*k],shR:[-.3,0,-1*k]}};}},
 leap:{label:'Skip ahead',len:1.4,f:t=>{const u=cyc(t,1.4);const a=bump(u,.15,.85);return{y:a*.22,sq:-bump(u,0,.2)*.08+a*.05,ry:ease(u)*Math.PI*2,eye:1,b:{shL:[-1.6*a,0,.3],shR:[-1.6*a,0,-.3]}};}}};
export const EXPR={
 happy:{label:'Brewing',hz:-.1,eye:.86,b:ARMS(0,1)},
 focus:{label:'Winding up',hx:.1,eye:.7,b:{shL:[-1,0,.6],shR:[-1,0,-.6],elL:[-.8,0,0],elR:[-.8,0,0]}},
 startled:{label:'Startled',hx:-.14,eye:1.2,eyeW:1.1,b:{shL:[-.3,0,1],shR:[-.3,0,-1]}},
 caught:{label:'Run down',hx:.3,hz:.12,eye:.5,sq:-.06,b:{shL:[.2,0,.1],shR:[.2,0,-.1]}}};
export const build=o=>S.build(o),loadBaked=(u,r)=>S.loadBaked(u,r);
export const BIN='hourglassstorm.bin?v=1',RES=.0056,GAME_SCALE=2.4;
export const EMBERS=[['earL',[-.16,.8,-.03]],['earR',[.18,.84,-.03]],['tail',[.02,.08,-.01]]];
export const ROUTE=[{to:[1.1,-.4],clip:'walk',sp:.2},{at:true,clip:'work',dur:4.2,face:[2,-1]},{to:[-.7,1],clip:'walk',sp:.2},{at:true,clip:'ability',dur:2.6,face:[1,3]},{at:true,clip:'idle2',dur:3,face:[1,3]},{to:[.2,.2],clip:'run',sp:.36},{at:true,clip:'nap',dur:5,face:[2,2]}];
export const HERO={cam:[1.3,.3,2.3],target:[0,.66,0],clip:'idle'};
