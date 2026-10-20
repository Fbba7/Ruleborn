import * as THREE from 'three';
import {makeSculpt,makeRigKit,stdClips,sstep,vnoise,clamp,ease,bump,blink,cyc,TAU,merge,gait} from './creature-kit.js';
import {parts} from './creature-parts.js?v=8';
import {sageFrame,sageBody,nearest,region,paintFace,clothShade,mir,sageBrows} from './sage-kit.js?v=8';
// ============ THE GARDENER · Sage · Keeper level 13 · tall, gentle, wide hat woven from vines, glowing watering can; green and cream; flowers open where it walks (GDD 11.7) ============
const COL={cream:0xEEE4C8,creamL:0xFFF8E6,creamD:0xB8A882,green:0x4A8A3C,greenL:0x86BE5A,greenD:0x223F1C,skin:0xB27A54,skinD:0x7A4A30,hair:0x2A1A12,hairL:0x5A3A26,
 vine:0x5A7A30,vineD:0x2E4418,boot:0x6A4A2E,sole:0x2A1A10,mouth:0x5A2418,blush:0xD8806A,glow:0xE8FF9A,can:0x5E9E86,brass:0xC8A050};
const K=Object.fromEntries(Object.entries(COL).map(([k,v])=>[k,new THREE.Color(v)]));
const F=sageFrame({k:1.08,head:1.04,leg:1,shW:.18});const{P,HP}=F;const HR=r=>r*F.H*F.k;let A0=null;
const def={name:'gardener',box:[[-.36,0,-.32],[.36,1.3,.32]],res:.0058,warm:0x1A1406,aoWarm:.18,sheen:0xFFF6DC,rim:0xD8FF9A,
 bodyMat:{roughness:.78,specularIntensity:.45,sheen:0.3,sheenRoughness:.5},fur:{shells:0},
 sculpt(A){A0=A;const{E,C}=A;
  sageBody(A,F,{robeHem:.075,flare:1.05,sleeveFlare:1.3,bootH:.05,noseLen:.95,belly:.95});
  // leaf-green shawl over the shoulders, a knotted sash, low bun of dark hair
  E('T:shawl',P(0,.845,-.005),[.21,.08,.135],null,.05);E('T:shawlB',P(0,.76,-.1),[.17,.1,.04],[-.1,0,0],.04);
  E('T:sash',P(0,.6,.004),[.15,.034,.116],null,.012);E('T:knot',P(.06,.585,.1),[.028,.024,.02],null,.012);for(const s of[-1,1])C('T:tail'+(s<0?'L':'R'),P(.06+s*.012,.575,.108),P(.06+s*.03,.47,.1),.014,.01,.01);
  E('T:hairCap',HP(0,1.075,-.02),[HR(.136),HR(.1),HR(.134)],null,.04);E('T:hairBack',HP(0,1.0,-.07),[HR(.128),HR(.13),HR(.09)],null,.04);for(const s of[-1,1])E('T:hairSide'+(s<0?'L':'R'),HP(s*.112,1.03,.02),[HR(.03),HR(.07),HR(.07)],[0,0,s*-.1],.03);
  E('T:hairBun',HP(0,.97,-.15),[HR(.055),HR(.05),HR(.05)],null,.03);},
 disp(x,y,z,d){if(Math.abs(d)>.03)return d;const n=nearest(A0,x,y,z);
  if(/^T:hair/.test(n))return d-Math.pow(Math.abs(Math.sin(x*120+y*40)),6)*.0018;
  if(/^T:(robe|fold)/.test(n))return d+(vnoise(x*50,y*14,z*50)-.5)*.0016;
  return d+(vnoise(x*70,y*70,z*70)-.5)*.0005;},
 paint(x,y,z,nx,ny,nz,ao,c,A){const n=nearest(A,x,y,z);const r=region(n);
  if(r==='skin'||r==='neck'||r==='hand'){c.copy(K.skin).lerp(K.skinD,(1-ao)*.5+sstep(.2,-.6,ny)*.1);if(r==='skin'){paintFace(x,y,z,c,K,F,{ao,smile:.008,blush:.35});
    // freckles across the nose
    if(z>.08&&Math.abs(y-(F.hyW-.02))<.03&&Math.abs(x)<.06&&vnoise(x*400,y*400,z*400)>.78)c.lerp(K.skinD,.45);}
   return 0;}
  if(r==='hair'){c.copy(K.hair).lerp(K.hairL,sstep(.3,1,ny)*.35+Math.pow(Math.abs(Math.sin(x*120+y*40)),8)*.3).lerp(new THREE.Color(0x0A0604),(1-ao)*.6);return 0;}
  if(r==='boot'){c.copy(K.boot).lerp(new THREE.Color(0x2A1A10),(1-ao)*.6);return 0;}if(r==='sole'){c.copy(K.sole);return 0;}
  if(/shawl|sash|knot|T:tail/.test(n)&&!(/shawl/.test(n)&&y<F.P(0,.745,0)[1]-.04)){clothShade(c,K,K.green,K.greenL,K.greenD,ny,nz,ao,x,y,z,.05);
   // embroidered leaf sprigs along the shawl edge
   const u=Math.atan2(x,z)*6,v=y*40;const lf=Math.abs(Math.sin(u*3+Math.sin(v)))*sstep(.5,.9,Math.sin(v*2+u));if(/shawl/.test(n))c.lerp(K.greenL,sstep(.85,.95,lf)*.6);return 0;}
  // leaf-edged green capelet painted over the shoulders and upper chest
  if(r==='top'||r==='sleeve'){const a=Math.atan2(x,z),yc=F.P(0,.745,0)[1]-Math.abs(Math.sin(a*6))*.035-(r==='sleeve'?.02:0);if(y>yc&&!(r==='sleeve'&&/el[LR]/.test(n))){clothShade(c,K,K.green,K.greenL,K.greenD,ny,nz,ao,x,y,z,.05);c.lerp(K.greenD,sstep(yc+.008,yc,y)*.5);return 0;}}
  // cream robe with a green hem band and rolled grass stains near the ground
  clothShade(c,K,K.cream,K.creamL,K.creamD,ny,nz,ao,x,y,z,.05);
  if(r==='robe'){const hb=F.P(0,.14,0)[1];c.lerp(K.green,sstep(hb+.012,hb,y)*sstep(hb-.03,hb-.018,y)*.9);c.lerp(new THREE.Color(0x8A9A5A),sstep(.1,.02,y)*.35);}
  if(r==='cuff')c.lerp(K.green,.8);
  return 0;},
 accessories(A){const G=new THREE.Group();const Pt=parts(A,G);const{PB,add,irisTex,eye}=Pt;const T=THREE;
  const tex=irisTex('#0A0602','#3A5A1A','#8AA84A','#1A1206',{pup:.3,human:true});
  for(const s of[-1,1])eye(s,{human:true,skin:COL.skin,lash:COL.hairD??0x1A0C08,r:HR(.028),ctr:HP(0,1.035,.02),dir:[.46,-.03,1],off:-.009,tex,lid:COL.skinD,lidCut:.28,lidTilt:.3,yaw:.36,irisK:1.35});
  G.add(sageBrows(Pt,F,{col:COL.hairD??COL.hair}));
  const vine=PB(COL.vine,{roughness:.7,sheen:.4,sheenColor:new T.Color(0xC8E890)}),vineD=PB(COL.vineD,{roughness:.8});
  const leafGeo=(len,wid)=>{const s=new T.Shape();s.moveTo(0,0);s.bezierCurveTo(wid,len*.25,wid*.8,len*.8,0,len);s.bezierCurveTo(-wid*.8,len*.8,-wid,len*.25,0,0);const g=new T.ShapeGeometry(s,10);const p=g.attributes.position;for(let i=0;i<p.count;i++){const px=p.getX(i),py=p.getY(i);p.setZ(i,-Math.pow(px/wid,2)*wid*.5+Math.sin(py/len*3)*len*.06);}g.computeVertexNormals();return g;};
  const leafM=PB(0x6AAE48,{roughness:.5,sheen:.6,sheenColor:new T.Color(0xD8F0A0),side:T.DoubleSide});
  const flower=(col,r)=>{const f=new T.Group();const pm=PB(col,{roughness:.55,sheen:.6,side:T.DoubleSide});for(let i=0;i<5;i++){const p=add(new T.SphereGeometry(r,10,8),pm,[Math.cos(i/5*TAU)*r*1.1,Math.sin(i/5*TAU)*r*1.1,0],null,[1,1,.3],f);}add(new T.SphereGeometry(r*.6,10,8),PB(0xF2C43A,{roughness:.5}),[0,0,r*.2],null,null,f);return f;};
  // wide hat woven from vines: twisted rings for the brim, a dome of loops, leaves and a few flowers
  {const h=new T.Group();h.userData.bone='head';h.position.set(...HP(0,1.1,-.005));h.rotation.set(-.1,0,.06);G.add(h);
   for(let ring=0;ring<6;ring++){const R0=.15+ring*.052;for(let st=0;st<2;st++){const pts=[];for(let i=0;i<=96;i++){const a=i/96*TAU;const w=Math.sin(a*14+st*Math.PI+ring)*.006;pts.push(new T.Vector3(Math.cos(a)*(R0+w),-ring*.008+Math.cos(a*14+st*Math.PI)*.006,Math.sin(a)*(R0+w)));}add(new T.TubeGeometry(new T.CatmullRomCurve3(pts,true),200,.0085,6,true),st?vineD:vine,null,null,null,h);}}
   for(let i=0;i<7;i++){const a=i/7*Math.PI;const pts=[];for(let j=0;j<=24;j++){const u=j/24*Math.PI;pts.push(new T.Vector3(Math.cos(u)*.152*Math.cos(a),Math.sin(u)*.11+.002,Math.cos(u)*.152*Math.sin(a)));}add(new T.TubeGeometry(new T.CatmullRomCurve3(pts),40,.008,6),i%2?vine:vineD,null,null,null,h);}
   add(new T.SphereGeometry(.15,28,14,0,TAU,0,Math.PI/2),PB(0x4A6A2A,{roughness:.85,sheen:.4,sheenColor:new T.Color(0xB8D878)}),[0,.0,0],null,[1,.72,1],h);
   for(let i=0;i<26;i++){const a=i/26*TAU+Math.sin(i*7)*.2,r=.17+(i%4)*.045;const l=add(leafGeo(.05+(i%3)*.012,.02),leafM,[Math.cos(a)*r,.008,Math.sin(a)*r],[-Math.PI/2+.3,0,-a+Math.PI/2+(i%2?.5:-.5)],null,h);}
   [[0xF4A0C0,.3,.2,.022],[0xFFFFFF,1.2,.26,.018],[0xF4D050,2.2,.21,.02],[0xE878A8,3.4,.28,.018],[0xFFF4F8,4.4,.19,.022],[0xF4A0C0,5.4,.25,.018]].forEach(([c,a,r,s])=>{const f=flower(c,s);f.position.set(Math.cos(a)*r,.02,Math.sin(a)*r);f.rotation.set(-Math.PI/2,0,0);h.add(f);});}
  // glowing watering can in the right hand
  {const w=F.j.wr(1);const g=new T.Group();g.userData.bone='haR';g.position.set(w[0]+.01,w[1]-.13,w[2]+.02);g.rotation.set(0,-.2,0);G.add(g);const cm=PB(COL.can,{metalness:.7,roughness:.35}),br=PB(COL.brass,{metalness:1,roughness:.3});
   const pr=[];for(let i=0;i<=12;i++){const u=i/12;pr.push(new T.Vector2(.055+Math.sin(u*Math.PI)*.012,u*.11-.055));}add(new T.LatheGeometry(pr,28),cm,[0,-.02,0],null,null,g);add(new T.CircleGeometry(.056,28),cm,[0,-.075,0],[Math.PI/2,0,0],null,g);
   for(const y of[-.07,.03])add(new T.TorusGeometry(.058,.005,8,32),br,[0,y,0],[Math.PI/2,0,0],null,g);
   {const pts=[new T.Vector3(0,.035,-.03),new T.Vector3(0,.09,-.01),new T.Vector3(0,.09,.03),new T.Vector3(0,.035,.045)];add(new T.TubeGeometry(new T.CatmullRomCurve3(pts),24,.007,8),br,null,null,null,g);}
   {const pts=[new T.Vector3(0,-.03,.05),new T.Vector3(0,.02,.12),new T.Vector3(0,.07,.17)];add(new T.TubeGeometry(new T.CatmullRomCurve3(pts),24,.009,8),cm,null,null,null,g);add(new T.CylinderGeometry(.022,.01,.022,16),br,[0,.078,.18],[-.7,0,0],null,g);}
   const gl=new T.Mesh(new T.CircleGeometry(.05,24),new T.MeshBasicMaterial({color:COL.glow}));gl.position.y=.036;gl.rotation.x=-Math.PI/2;g.add(gl);
   const l=new T.PointLight(COL.glow,.8,.7,2);l.position.set(0,.08,0);g.add(l);
   const halo=new T.Mesh(new T.SphereGeometry(.07,16,10),new T.MeshBasicMaterial({color:COL.glow,transparent:true,opacity:.18,depthWrite:false,blending:T.AdditiveBlending}));halo.position.y=.05;g.add(halo);
   // water falling from the rose (at home)
   const pour=new T.Group();pour.userData.fx='pour';pour.userData.fxMode='show';pour.position.set(0,.078,.19);g.add(pour);const wm=new T.MeshBasicMaterial({color:0xD8FFB0,transparent:true,opacity:.55,depthWrite:false,blending:T.AdditiveBlending});
   for(let i=0;i<14;i++){const d=add(new T.SphereGeometry(.006,6,4),wm,[Math.sin(i*2.3)*.02,-.02-i*.018,.01+i*.004],null,[1,2,1],pour);}}
  // flowers opening at the feet as it walks
  for(const s of[-1,1]){const fx=new T.Group();fx.userData.bone='root';fx.userData.fx=s<0?'bloomL':'bloomR';fx.userData.fxMode='show';fx.position.set(s*.1,.005,-.08);G.add(fx);
   [[0,0,0xF4A0C0],[.04,.03,0xFFF4F8],[-.03,.04,0xF4D050]].forEach(([dx,dz,c],i)=>{const st=add(new T.CylinderGeometry(.003,.003,.03,6),vine,[dx,.015,dz],null,null,fx);const f=flower(c,.012);f.position.set(dx,.032,dz);f.rotation.x=-1.2;fx.add(f);const l=add(leafGeo(.03,.012),leafM,[dx,.004,dz],[-1.3,0,i*2],null,fx);});}
  // Vine bridge (power 1): vines braid forward across a gap
  {const fx=new T.Group();fx.userData.bone='root';fx.userData.fx='vine';fx.userData.fxMode='show';fx.position.set(0,.02,.25);G.add(fx);
   for(let st=0;st<3;st++){const pts=[];for(let i=0;i<=30;i++){const u=i/30;pts.push(new T.Vector3(Math.sin(u*20+st*2.1)*.06,Math.sin(u*Math.PI)*.06+Math.cos(u*20+st*2.1)*.02,u*1.1));}add(new T.TubeGeometry(new T.CatmullRomCurve3(pts),120,.014,6),st%2?vineD:vine,null,null,null,fx);}
   for(let i=0;i<12;i++)add(leafGeo(.05,.02),leafM,[Math.sin(i*1.7)*.07,.05,.08+i*.085],[-.6,i*1.3,0],null,fx);}
  // Renew (power 2): a ring of light with leaves spiralling up
  {const fx=new T.Group();fx.userData.bone='root';fx.userData.fx='renew';fx.userData.fxMode='show';fx.position.set(0,.02,0);G.add(fx);const m=new T.MeshBasicMaterial({color:0xC8FF8A,transparent:true,opacity:.6,depthWrite:false,blending:T.AdditiveBlending,side:T.DoubleSide});
   for(let k=0;k<2;k++)add(new T.RingGeometry(.36+k*.14,.38+k*.14,64),m,[0,k*.004,0],[-Math.PI/2,0,0],null,fx);const sp=new T.Group();sp.userData.spin=1.6;sp.userData.spinAx='y';fx.add(sp);
   for(let i=0;i<14;i++){const a=i/14*TAU*2,y=.1+i*.07;add(leafGeo(.045,.018),new T.MeshBasicMaterial({color:0xB8F07A,side:T.DoubleSide,transparent:true,opacity:.85}),[Math.cos(a)*.35,y,Math.sin(a)*.35],[0,-a,.6],null,sp);}}
  // Decoy (power 3): a sapling springs up in front and waves
  {const fx=new T.Group();fx.userData.bone='root';fx.userData.fx='sapling';fx.userData.fxMode='show';fx.position.set(.1,0,.55);G.add(fx);add(new T.CylinderGeometry(.012,.02,.32,8),PB(0x7A5A34,{roughness:.8}),[0,.16,0],null,null,fx);
   for(let i=0;i<9;i++){const a=i/9*TAU;add(leafGeo(.09,.035),leafM,[Math.cos(a)*.03,.26+(i%3)*.04,Math.sin(a)*.03],[-.4,a,0],null,fx);}add(new T.SphereGeometry(.05,12,10),new T.MeshBasicMaterial({color:0xE8FF9A,transparent:true,opacity:.25,depthWrite:false,blending:T.AdditiveBlending}),[0,.3,0],null,null,fx);}
  return G;}};
export const S=makeSculpt(def);
const cfg={name:'gardener',J:F.J,TIP:F.TIP,TORSO:F.TORSO,AIM:[],floor:.006,pivot:.5,shMin:-2.2,springs:[['earL','vx',-.4,80,6,0,.3],['tail','vy',-.2,120,10,0,.12]]};
const RK=makeRigKit(S,cfg);export const makeRig=RK.makeRig,skinGeo=RK.skinGeo;
const hold=(t)=>({shR:[-.12,0,.12],elR:[-.55,0,0],haR:[.2,0,0]});
export const CLIPS=stdClips({w:.1,arm:.25,x:{
 idle:{label:'Idle',len:5,f:t=>{const b=Math.sin(t*TAU/5)*.5+.5;return{sq:b*.01,hx:.06+Math.sin(t*.8)*.02,hz:Math.sin(t*.6)*.05,eye:blink(t,4.6,.5)*.92,b:merge(hold(t),{chest:[-b*.02,0,0],shL:[-.35,.2,-.1],elL:[-.9,0,0],haL:[.2,0,0]})};}},
 idle2:{label:'Idle 2',len:6,f:t=>{const u=cyc(t,6);const smell=bump(u,.2,.7);return{hx:.25*smell,hy:-.3*smell,eye:1-smell*.5,b:merge(hold(t),{shL:[-1.3*smell-.35*(1-smell),.2,-.1],elL:[-1.6*smell-.9*(1-smell),0,0],chest:[.1*smell,0,0]})};}},
 p1:{label:'Vine bridge',len:3.4,f:t=>{const u=cyc(t,3.4);const k=ease(sstep(.05,.3,u))*(1-sstep(.86,1,u));return{hx:.12*k,vine:sstep(.2,.5,u)*(1-sstep(.9,1,u)),b:{shL:[-1.3*k-.35*(1-k),0,-.05],elL:[-.2*k-.9*(1-k),0,0],haL:[-.5*k,0,0],shR:[-.12,0,.12+.3*k],elR:[-.55,0,0],chest:[.08*k,0,0]}};}},
 p2:{label:'Renew',len:3.4,f:t=>{const u=cyc(t,3.4);const k=ease(sstep(.05,.3,u))*(1-sstep(.86,1,u));return{hx:-.2*k,eye:1-.5*k,renew:k,b:{shL:[-1.9*k-.35*(1-k),0,-.4*k-.1],elL:[-.3*k-.9*(1-k),0,0],shR:[-1.2*k-.12,0,.3*k+.12],elR:[-.3,0,0],chest:[-.08*k,0,0]}};}},
 p3:{label:'Decoy',len:3.4,f:t=>{const u=cyc(t,3.4);const k=ease(sstep(.05,.28,u))*(1-sstep(.86,1,u));const grow=sstep(.3,.55,u)*(1-sstep(.9,1,u));return{y:-.1*k,hx:.3*k,sapling:grow,b:{chest:[.35*k,0,0],thL:[-.9*k,0,-.1],knL:[1.3*k,0,0],thR:[-.2*k,0,.1],knR:[1*k,0,0],shL:[-1*k-.35*(1-k),0,0],elL:[-.4*k-.9*(1-k),0,0],shR:[-.12,0,.12],elR:[-.55,0,0]}};}},
 guard:{label:'On guard',len:5,f:t=>{const u=cyc(t,5);return{hy:Math.sin(u*TAU)*.35,hx:.03,eye:.95,b:merge(hold(t),{shL:[-.35,.2,-.1],elL:[-.9,0,0]})};}},
 work:{label:'Waters the garden',len:4,f:t=>{const u=cyc(t,4);const tip=ease(sstep(.05,.25,u))*(1-sstep(.8,.95,u));return{hx:.22,rx:.05,eye:.8,pour:sstep(.2,.3,u)*(1-sstep(.78,.85,u)),b:{shR:[-.9*tip-.12,0,.12],elR:[-.3*tip-.55*(1-tip),0,0],haR:[.6*tip+.2,0,0],shL:[-.35,.2,-.1],elL:[-.9,0,0],chest:[.1,0,0]}};}},
 nap:{label:'Rest',len:6,f:t=>{const b=Math.sin(t*TAU/6)*.5+.5;return{y:-.34,sq:-.02,hx:.3,eye:.1,b:{thL:[-1.5,0,-.2],knL:[1.9,0,0],thR:[-1.5,0,.2],knR:[1.9,0,0],shL:[-.5,0,.2],elL:[-1,0,0],shR:[-.4,0,-.1],elR:[-.8,0,0],chest:[.25+b*.03,0,0]}};}}}});
{const W=CLIPS.walk.f,L=CLIPS.walk.len;CLIPS.walk.f=t=>{const p=W(t);const ph=cyc(t,L);p.bloomL=bump((ph+.25)%1,0,.55);p.bloomR=bump((ph+.75)%1,0,.55);p.b=merge(p.b||{},{shR:[.1,0,.12],elR:[-.5,0,0]});return p;};}
export const EXPR={
 happy:{label:'Warm',hx:-.04,hz:.08,eye:.85,b:{shL:[-.35,.2,-.1],elL:[-.9,0,0],shR:[-.12,0,.12],elR:[-.55,0,0]}},
 focus:{label:'Listening to the leaves',hx:.2,hy:-.3,eye:.6,b:{shL:[-1.2,.2,-.1],elL:[-1.5,0,0]}},
 startled:{label:'Surprised',hx:-.1,eye:1.25,eyeW:1.08,b:{shL:[-.9,0,-.3],elL:[-1.2,0,0]}},
 caught:{label:'Wilted',hx:.42,hz:.1,eye:.3,b:{chest:[.25,0,0],shL:[.15,0,.1],shR:[.15,0,-.1]}}};
export const build=o=>S.build(o),loadBaked=(u,r)=>S.loadBaked(u,r);
export const BIN='gardener.bin?v=1',RES=.0095,GAME_SCALE=1;
export const EMBERS=[['head',HP(0,1.2,0)],['haR',P(.25,.3,.2)],['chest',P(0,.9,-.1)]];
export const ROUTE=[{to:[1.1,-.4],clip:'walk',sp:.2},{at:true,clip:'work',dur:4,face:[2,-1]},{to:[-.7,1],clip:'walk',sp:.2},{at:true,clip:'idle2',dur:6,face:[1,3]},{at:true,clip:'idle',dur:5,face:[1,3]},{to:[.2,.2],clip:'walk',sp:.2},{at:true,clip:'guard',dur:5,face:[2,2]}];
export const HERO={cam:[2.1,1.2,2.9],target:[0,.7,0],clip:'idle'};
