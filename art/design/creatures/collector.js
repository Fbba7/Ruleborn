import * as THREE from 'three';
import {makeSculpt,makeRigKit,stdClips,sstep,vnoise,clamp,ease,bump,blink,cyc,TAU,merge,gait} from './creature-kit.js';
import {parts} from './creature-parts.js';
// ============ THE COLLECTOR · Visitor · swaps law pages · a magpie merchant in a coat of pockets (GDD 11.7, 21.6) ============
const COL={blk:0x1C2030,blkL:0x3A4258,wht:0xF4F2EC,whtD:0xC8C4C0,sheen:0x2A7A9A,sheen2:0x4A3A9A,coat:0x7A2A38,coatL:0xA8465A,coatD:0x3A1018,gold:0xE9B65C,beak:0x2A2A32,beakL:0x5A5A66,leg:0x3A3A46};
const K=Object.fromEntries(Object.entries(COL).map(([k,v])=>[k,new THREE.Color(v)]));
const mir=(p,s)=>[p[0]*s,p[1],p[2]];let A0=null;
const def={name:'collector',box:[[-.25,0,-.23],[.25,.76,.3]],res:.0052,warm:0x10101A,aoWarm:.16,sheen:0xC8E0FF,rim:0xC8D8FF,
 bodyMat:{roughness:.6,sheen:.6,sheenRoughness:.4},fur:{shells:0},
 sculpt(A){const{E,C}=A;A0=A;
  E('T:body',[0,.34,0],[.12,.16,.11],null,.06);E('T:coat',[0,.22,-.005],[.135,.13,.125],null,.05);E('T:belly',[0,.35,.05],[.085,.12,.068],null,.05);
  C('T:neck',[0,.46,0],[0,.52,.012],.06,.064,.035);E('T:head',[0,.605,.02],[.128,.122,.122],null,.045);
  for(const s of[-1,1])E('T:cheek'+(s<0?'L':'R'),mir([.065,.57,.07],s),[.05,.045,.045],null,.03);
  C('T:beak1',[0,.598,.118],[0,.588,.2],.034,.017,.012);C('T:beak2',[0,.588,.2],[0,.572,.252],.017,.004,.008);E('T:gape',[0,.583,.15],[.03,.0028,.03],null,.003,'s');
  C('T:crest1',[0,.7,-.01],[0,.735,-.05],.022,.006,.012);C('T:crest2',[.018,.7,-.03],[.03,.725,-.075],.016,.004,.01);
  for(const s of[-1,1]){const L=s<0?'L':'R';
   const sh=mir([.11,.44,0],s),el=mir([.16,.35,.04],s),wr=mir([.17,.26,.07],s);C('sh'+L+':arm1',sh,el,.034,.027,.02);C('el'+L+':arm2',el,wr,.027,.022,.015);
   E('ha'+L+':palm',mir([.175,.235,.085],s),[.024,.03,.02],null,.012);for(let k=0;k<3;k++){const a=(k-1)*.34;C('ha'+L+':quill'+k,mir([.176,.22,.09],s),mir([.18+Math.sin(a)*.03,.165,.1+Math.cos(a)*.01],s),.012,.004,.006);}
   C('th'+L+':leg1',mir([.045,.14,0],s),mir([.05,.08,.02],s),.022,.018,.015);C('kn'+L+':leg2',mir([.05,.08,.02],s),mir([.052,.025,.03],s),.017,.014,.01);
   for(let k=0;k<3;k++){const a=(k-1)*.45;C('ft'+L+':toe'+k,mir([.052,.018,.035],s),mir([.052+Math.sin(a)*.04,.008,.035+Math.cos(a)*.05],s),.011,.006,.005);}C('ft'+L+':toeB',mir([.052,.018,.03],s),mir([.05,.008,-.01],s),.01,.006,.005);}
  E('tail:root',[0,.22,-.11],[.03,.03,.028],null,.02);},
 disp(x,y,z,d){if(Math.abs(d)>.03)return d;const face=sstep(.03,.006,A0.minD(/^T:(beak|gape)/,x,y,z));const coat=A0.minD(/^T:(coat|body)/,x,y,z)<.004&&y<.46?1:0;
  const fe=Math.pow(vnoise(x*60,y*30,z*60),2)*-.0012;const fab=(vnoise(x*160,y*160,z*160)-.5)*.0005;return d+(1-face)*(coat?fab:fe)+(vnoise(x*140,y*140,z*140)-.5)*.0004;},
 paint(x,y,z,nx,ny,nz,ao,c,A){
  c.copy(K.blk).lerp(K.blkL,sstep(.2,.95,ny)*.35+sstep(.3,.9,nz)*.12).lerp(new THREE.Color(0x06070C),(1-ao)*.5);
  {const v=vnoise(x*7,y*7,z*7);const sh=sstep(.2,.9,Math.abs(nx)*.6+ny*.4);c.lerp(K.sheen,sh*sstep(.35,.75,v)*.45).lerp(K.sheen2,sh*sstep(.7,.95,v)*.3);}
  {const m=sstep(.035,.02,A.minD(/^T:(body|coat|belly)/,x,y,z))*(A.minD(/^(sh|el|ha|th|kn|ft)[LR]:/,x,y,z)>.004?1:0)*sstep(.468,.44,y)*sstep(.075,.1,y);
   const vw=clamp(.012+(y-.26)*.24,0,.058);const v=sstep(vw+.004,vw-.002,Math.abs(x))*sstep(.055,.085,z)*sstep(.255,.27,y);const lap=sstep(vw+.022,vw+.014,Math.abs(x))*(1-v)*sstep(.055,.085,z)*sstep(.28,.31,y);
   const cc=K.coat.clone().lerp(K.coatL,sstep(.3,.9,ny)*.3+sstep(.2,.8,nz)*.12).lerp(K.coatD,(1-ao)*.6+sstep(-.1,-.8,ny)*.25).lerp(K.coatD,clamp((vnoise(x*26,y*14,z*26)-.5)*.14+.06,0,1));
   cc.lerp(K.coatL,lap*.55);cc.lerp(K.gold,sstep(.0035,.001,Math.abs(Math.abs(x)-vw-.02))*lap*.9);cc.lerp(K.coatD,sstep(.11,.085,y)*.5);cc.lerp(K.coatL,sstep(.43,.455,y)*.4);
   const wc=K.wht.clone().lerp(K.whtD,(1-ao)*.55+sstep(.2,-.7,ny)*.2).lerp(K.whtD,Math.pow(vnoise(x*60,y*30,z*60),3)*.25);
   c.lerp(cc,m*(1-v));c.lerp(wc,m*v);}
  if(A.minD(/^(sh|el)[LR]:/,x,y,z)<.004){c.copy(K.coat).lerp(K.coatL,sstep(.2,.9,ny)*.3).lerp(K.coatD,(1-ao)*.55);if(A.minD(/^ha[LR]:/,x,y,z)<.03)c.lerp(K.gold,.75);}
  if(A.minD(/^T:(beak|gape)/,x,y,z)<.004)c.copy(K.beak).lerp(K.beakL,sstep(.2,.9,ny)*.4+sstep(.23,.25,z)*.3);
  if(A.minD(/^(th|kn|ft)[LR]:/,x,y,z)<.004){c.copy(K.leg).lerp(K.blkL,sstep(.2,.9,ny)*.25).lerp(new THREE.Color(0x10101A),(1-ao)*.4);c.lerp(new THREE.Color(0x10101A),sstep(.6,.9,Math.sin(y*260)*.5+.5)*.3);}
  if(A.minD(/^ha[LR]:/,x,y,z)<.003){c.copy(K.blk).lerp(K.sheen,sstep(.3,.9,ny)*.35);}
  for(const s of[-1,1])c.lerp(new THREE.Color(0xE87A8A),sstep(.022,0,Math.hypot(x-s*.075,y-.56,(z-.08)*1.4))*.25);
  return 0;},
 accessories(A){const G=new THREE.Group();const P=parts(A,G);const{PB,add,irisTex,eye,glowTex,hit}=P;
  const tex=irisTex('#050508','#2A1A08','#D8A040','#050508',{pup:.42});
  for(const s of[-1,1])eye(s,{r:.036,ctr:[0,.6,.02],dir:[.52,.1,.85],off:-.012,tex,lid:COL.blk,lidCut:.2,yaw:.55,irisK:1.25});
  const gold=PB(COL.gold,{metalness:.9,roughness:.25}),coatD=PB(COL.coatD,{roughness:.8,sheen:.4}),coat=PB(COL.coat,{roughness:.75,sheen:.5,sheenColor:new THREE.Color(0xFFB0B8)});
  // monocle on a gold chain
  {const h=hit([.52,.1,.85],[0,.6,.02],.028);const g=new THREE.Group();g.userData.bone='head';g.position.copy(h.p);g.quaternion.setFromUnitVectors(new THREE.Vector3(0,0,1),new THREE.Vector3(.52,.1,.85).normalize());G.add(g);
   add(new THREE.TorusGeometry(.043,.0055,12,40),gold,null,null,null,g);add(new THREE.TorusGeometry(.043,.0022,6,40),PB(0xFFF0C0,{metalness:.9,roughness:.15}),[0,0,.004],null,[1.02,1.02,1],g);
   add(new THREE.CircleGeometry(.042,32),PB(0xE8F6FF,{roughness:.02,transparent:true,opacity:.18,clearcoat:1,clearcoatRoughness:0,depthWrite:false}),[0,0,-.001],null,null,g);
   add(new THREE.SphereGeometry(.006,10,8),gold,[.03,-.03,0],null,null,g);
   const w=new THREE.Vector3();g.updateMatrix();const lp=(x,y,z)=>new THREE.Vector3(x,y,z).applyMatrix4(g.matrix);
   const cg=new THREE.Group();cg.userData.bone='head';G.add(cg);const cu=new THREE.CatmullRomCurve3([lp(.032,-.032,0),new THREE.Vector3(.118,.555,.075),new THREE.Vector3(.1,.49,.085),new THREE.Vector3(.064,.445,.1)]);add(new THREE.TubeGeometry(cu,28,.0018,5),gold,null,null,null,cg);}
  // tilted merchant's top hat with a feather in the band
  {const g=new THREE.Group();g.userData.bone='head';g.position.set(.02,.705,.0);g.rotation.set(-.12,0,-.22);G.add(g);
   add(new THREE.CylinderGeometry(.1,.1,.012,32),coatD,[0,.008,0],null,null,g);add(new THREE.CylinderGeometry(.058,.064,.11,28),PB(0x2A1418,{roughness:.6,sheen:.5}),[0,.068,0],null,null,g);
   add(new THREE.CylinderGeometry(.065,.065,.022,28,1,true),gold,[0,.026,0],null,null,g);
   const sh=new THREE.Shape();sh.moveTo(0,0);sh.quadraticCurveTo(.02,.06,.005,.13);sh.quadraticCurveTo(-.012,.06,0,0);add(new THREE.ShapeGeometry(sh,12),PB(0x9BEAF3,{roughness:.5,side:THREE.DoubleSide,sheen:.6}),[-.058,.03,.02],[0,-.4,.35],null,g);}
  // the coat of pockets: six curved patch pockets on the coat surface, each with something poking out
  {const spots=[[.62,.17,'key'],[-.62,.17,'scroll'],[1.3,.2,'coin'],[-1.3,.2,'page'],[.78,.35,'quill'],[-.78,.34,'page2']];
   const pk=(w,h)=>{const g=new THREE.PlaneGeometry(w,h,8,8);const p=g.attributes.position;for(let i=0;i<p.count;i++){const px=p.getX(i),py=p.getY(i);p.setZ(i,-Math.pow(px/(w*.5),2)*.004+(py<-h*.3?-Math.pow((py+h*.3)/h,2)*.02:0));}g.computeVertexNormals();return g;};
   const pm=PB(0x5A1C28,{roughness:.8,sheen:.5,sheenColor:new THREE.Color(0xFFA0B0),side:THREE.DoubleSide}),fm=PB(COL.coatL,{roughness:.75,sheen:.5,side:THREE.DoubleSide}),st=PB(COL.gold,{roughness:.6});
   for(const [a,y,it] of spots){const d=[Math.sin(a),0,Math.cos(a)];const h=hit(d,[0,y,0],.004);const pg=new THREE.Group();pg.userData.bone='chest';pg.position.copy(h.p);const n=h.n.clone();n.y*=.4;n.normalize();pg.quaternion.setFromUnitVectors(new THREE.Vector3(0,0,1),n);G.add(pg);
    add(pk(.05,.046),pm,[0,-.004,0],null,null,pg);add(pk(.056,.018),fm,[0,.021,.004],[-.25,0,0],null,pg);add(new THREE.SphereGeometry(.005,8,6),PB(COL.gold,{metalness:.9,roughness:.25}),[0,.015,.009],null,null,pg);
    for(let k=0;k<7;k++)add(new THREE.BoxGeometry(.0035,.0012,.001),st,[-.021+k*.007,-.026,.002],null,null,pg);
    if(it==='key'){add(new THREE.TorusGeometry(.009,.0025,6,14),gold,[.012,.04,-.004],null,null,pg);add(new THREE.CylinderGeometry(.0025,.0025,.03,6),gold,[.012,.022,-.004],null,null,pg);}
    if(it==='scroll'){add(new THREE.CylinderGeometry(.008,.008,.05,10),PB(0xEAD6AA,{roughness:.8}),[-.01,.035,-.004],[0,0,.3],null,pg);add(new THREE.TorusGeometry(.0085,.002,6,12),PB(0xC23A40),[-.01,.035,-.004],[Math.PI/2,0,.3],null,pg);}
    if(it==='coin')add(new THREE.CylinderGeometry(.013,.013,.003,20),gold,[.005,.035,-.004],[Math.PI/2,0,.2],null,pg);
    if(it==='quill'){const sh=new THREE.Shape();sh.moveTo(0,0);sh.quadraticCurveTo(.012,.04,0,.075);sh.quadraticCurveTo(-.01,.04,0,0);add(new THREE.ShapeGeometry(sh,10),PB(0xF4F2EC,{roughness:.6,side:THREE.DoubleSide}),[.01,.012,-.004],[0,0,-.25],null,pg);}
    if(it==='page'||it==='page2')add(new THREE.PlaneGeometry(.03,.042),PB(it==='page'?0xC8B8FF:0xFFE08A,{roughness:.6,side:THREE.DoubleSide,emissive:it==='page'?0x5A3AC8:0xC88A1A,emissiveIntensity:.55}),[-.004,.034,-.005],[0,0,.18],null,pg);}
   const bg=new THREE.Group();bg.userData.bone='chest';G.add(bg);for(const yy of[.38,.33,.285]){const vw=.012+(yy-.26)*.24+.024;const h=hit([.25,0,1],[0,yy,0],.003);add(new THREE.SphereGeometry(.0065,10,8),gold,[vw,yy,h.p.z-.004],null,null,bg);add(new THREE.SphereGeometry(.0065,10,8),gold,[-vw,yy,h.p.z-.004],null,null,bg);}}
  // cravat at the collar
  {const h=hit([0,-.15,1],[0,.47,0],.004);const g=new THREE.Group();g.userData.bone='chest';g.position.copy(h.p);G.add(g);const cm=PB(0x2A8AA8,{roughness:.55,sheen:.7,sheenColor:new THREE.Color(0xB0F0FF)});
   add(new THREE.SphereGeometry(.013,14,10),cm,null,null,[1.2,1,.8],g);for(const s of[-1,1])add(new THREE.ConeGeometry(.016,.036,12),cm,[s*.018,-.002,-.003],[0,0,s*Math.PI/2],[1,1,.55],g);
   add(new THREE.ConeGeometry(.013,.05,12),cm,[0,-.032,-.004],[Math.PI,0,0],[1,1,.5],g);add(new THREE.SphereGeometry(.005,8,6),gold,[0,0,.011],null,null,g);}
  // coat tails flaring out behind
  {const g=new THREE.Group();g.userData.bone='hips';G.add(g);const tm=PB(COL.coat,{roughness:.75,sheen:.5,sheenColor:new THREE.Color(0xFFB0B8),side:THREE.DoubleSide});
   for(const s of[-1,1]){const sh=new THREE.Shape();sh.moveTo(0,0);sh.lineTo(.06,0);sh.quadraticCurveTo(.065,-.08,.035,-.13);sh.lineTo(0,-.11);sh.closePath();const geo=new THREE.ShapeGeometry(sh,10);const p=geo.attributes.position;for(let i=0;i<p.count;i++){const px=p.getX(i),py=p.getY(i);p.setZ(i,-Math.pow(px/.06,2)*.02+py*.25);}geo.computeVertexNormals();
    const pv=new THREE.Group();pv.position.set(s*.005,.14,-.118);pv.rotation.set(-.15,Math.PI+s*.28,0);pv.scale.set(s,1,1);g.add(pv);add(geo,tm,null,null,null,pv);}}
  // long iridescent tail feathers
  {const g=new THREE.Group();g.userData.bone='tail';g.position.set(0,.22,-.12);G.add(g);
   const fg=(len,wid)=>{const s=new THREE.Shape();s.moveTo(0,0);s.bezierCurveTo(wid,len*.2,wid*.9,len*.85,0,len);s.bezierCurveTo(-wid*.9,len*.85,-wid,len*.2,0,0);const geo=new THREE.ShapeGeometry(s,20);const p=geo.attributes.position,col=[];for(let i=0;i<p.count;i++){const t=p.getY(i)/len;const c=new THREE.Color(0x10141E).lerp(new THREE.Color(0x2A7A9A),sstep(.15,.6,t)*.7).lerp(new THREE.Color(0x5A3AA0),sstep(.6,.95,t)*.55);col.push(c.r,c.g,c.b);p.setZ(i,Math.sin(t*2.2)*len*.06);}geo.computeVertexNormals();geo.setAttribute('color',new THREE.Float32BufferAttribute(col,3));return geo;};
   const fm=PB(0xFFFFFF,{vertexColors:true,roughness:.35,metalness:.2,clearcoat:.6,sheen:.8,sheenColor:new THREE.Color(0x9BEAF3),side:THREE.DoubleSide});
   for(let k=0;k<5;k++){const a=(k-2)*.16;const pv=new THREE.Group();pv.rotation.set(-2.05+Math.abs(k-2)*.06,0,a);g.add(pv);add(fg(k===2?.3:.26-Math.abs(k-2)*.02,.034),fm,null,null,null,pv);}}
  // swap pages (ability): two law pages orbit and trade places
  const fx=new THREE.Group();fx.userData.bone='root';fx.userData.fx='split';fx.userData.fxMode='show';fx.position.set(0,.46,.05);G.add(fx);fx.userData.spin=5;fx.userData.spinAx='y';
  for(const [k,col,em] of [[0,0xC8B8FF,0x6A4AE0],[1,0xFFE08A,0xE0A020]]){const g=new THREE.Group();g.rotation.y=k*Math.PI;fx.add(g);const pl=add(new THREE.PlaneGeometry(.1,.13),PB(col,{emissive:em,emissiveIntensity:1.1,side:THREE.DoubleSide,roughness:.5}),[0,0,.26],[0,0,.15],null,g);
   const gl=new THREE.Sprite(new THREE.SpriteMaterial({map:glowTex(k?'rgba(255,210,120,.8)':'rgba(170,140,255,.8)'),transparent:true,depthWrite:false,blending:THREE.AdditiveBlending}));gl.position.set(0,0,.26);gl.scale.setScalar(.22);g.add(gl);}
  return G;}};
export const S=makeSculpt(def);
const J={root:[null,[0,0,0]],hips:['root',[0,.22,0]],chest:['hips',[0,.4,0]],head:['chest',[0,.5,.01]],earL:['head',[-.02,.7,-.02]],earR:['head',[.02,.7,-.02]],
 shL:['chest',[-.11,.44,0]],elL:['shL',[-.16,.35,.04]],haL:['elL',[-.17,.26,.07]],shR:['chest',[.11,.44,0]],elR:['shR',[.16,.35,.04]],haR:['elR',[.17,.26,.07]],
 thL:['hips',[-.045,.14,0]],knL:['thL',[-.05,.08,.02]],ftL:['knL',[-.052,.025,.03]],thR:['hips',[.045,.14,0]],knR:['thR',[.05,.08,.02]],ftR:['knR',[.052,.025,.03]],tail:['hips',[0,.22,-.11]]};
const cfg={name:'collector',J,TIP:{haL:[-.18,.165,.1],haR:[.18,.165,.1],ftL:[-.052,.006,.085],ftR:[.052,.006,.085]},
 TORSO:{hips:[[0,.08,0],[0,.32,0],.16],chest:[[0,.3,0],[0,.5,0],.14],head:[[0,.5,.01],[0,.75,.1],.16]},
 AIM:[],floor:.004,pivot:.22,shMin:-2,springs:[['tail','vx',-.5,90,6,0,.4],['tail','vz',.3,90,6,2,.25]]};
const RK=makeRigKit(S,cfg);export const makeRig=RK.makeRig,skinGeo=RK.skinGeo;
const CLASP={shL:[-.6,0,.32],shR:[-.6,0,-.32],elL:[-.95,0,0],elR:[-.95,0,0]};
export const CLIPS=stdClips({w:.38,arm:.28,x:{
 idle:{label:'Idle',len:4,f:t=>{const u=cyc(t,4);const b=Math.sin(u*TAU)*.5+.5;const tilt=bump(u,.35,.7);return{sq:b*.012,hz:tilt*.28,hy:Math.sin(u*TAU)*.15,eye:blink(t,3.2,.4),b:merge(CLASP,{chest:[-b*.03,0,0]})};}},
 idle2:{label:'Pat the pockets',len:4.4,f:t=>{const u=cyc(t,4.4);const k=bump(u,.1,.8);const pat=Math.abs(Math.sin(t*9))*k;return{hx:.22*k,hy:.3*k,hz:.1*k,eye:1-k*.1,b:{shR:[-.25*k,0,-.05+pat*.12],elR:[-.7*k-.2,0,0],haR:[.2*k,0,0],shL:[-.6*k-.1,0,.3*k],elL:[-1.1*k-.2,0,0],chest:[.08*k,.15*k,0]}};}},
 ability:{label:'Swap pages',len:2.8,f:t=>{const u=cyc(t,2.8);const k=ease(sstep(.05,.25,u))*(1-sstep(.85,1,u));const hop=bump(u,.4,.62);return{split:k,y:hop*.05,sq:hop*.04,hx:-.1*k,eye:1+k*.08,b:{shL:[-1.3*k,0,-.35*k],shR:[-1.3*k,0,.35*k],elL:[-.25*k,0,0],elR:[-.25*k,0,0],haL:[-.4*k,0,0],haR:[-.4*k,0,0]}};}},
 work:{label:'Polish a trinket',len:4,f:t=>{const u=cyc(t,4);const k=ease(sstep(.05,.2,u))*(1-sstep(.86,1,u));const r=Math.sin(t*10)*k;return{hx:.3*k,hz:.12*k,eye:1-k*.25,b:{shL:[-.95*k,0,.35*k],shR:[-.95*k,0,-.35*k],elL:[-1.05*k+r*.2,0,0],elR:[-1.05*k-r*.2,0,0],haL:[r*.25,0,0],chest:[.12*k,0,0]}};}},
 nap:{label:'Doze with the head tucked',len:4.8,f:t=>{const b=Math.sin(t*TAU/4.8)*.5+.5;return{sq:-.02+b*.02,hx:.4,hy:.5,hz:.2,eye:.04,b:merge(CLASP,{chest:[.16+b*.03,0,0]})};}}}});
export const EXPR={
 happy:{label:'Delighted',hz:-.15,hx:-.02,eye:.86,b:CLASP},
 focus:{label:'Appraising',hx:.12,hz:.22,eye:.7,b:{shR:[-1.2,0,-.3],elR:[-1.3,0,0],shL:[-.6,0,.3],elL:[-.95,0,0]}},
 startled:{label:'Startled',hx:-.18,eye:1.2,eyeW:1.06,b:{shL:[-.3,0,-.9],shR:[-.3,0,.9]}},
 caught:{label:'Affronted',hx:-.1,hz:.1,eye:.6,b:{shL:[-.2,0,-.4],shR:[-.2,0,.4],elL:[-1.4,0,0],elR:[-1.4,0,0]}}};
export const build=o=>S.build(o),loadBaked=(u,r)=>S.loadBaked(u,r);
export const BIN='collector.bin?v=1',RES=.0052,GAME_SCALE=1.1;
export const EMBERS=[['head',[-.04,.84,0]],['head',[.08,.82,.02]],['tail',[0,.12,-.38]]];
export const ROUTE=[{to:[1.1,-.4],clip:'walk',sp:.22},{at:true,clip:'work',dur:4,face:[2,-1]},{to:[-.7,1],clip:'walk',sp:.22},{at:true,clip:'ability',dur:2.8,face:[1,3]},{at:true,clip:'idle2',dur:4.4,face:[1,3]},{to:[.2,.2],clip:'walk',sp:.22},{at:true,clip:'nap',dur:4.8,face:[2,2]}];
export const HERO={cam:[1.45,.78,1.95],target:[0,.44,0],clip:'idle'};
