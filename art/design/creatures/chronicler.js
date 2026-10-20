import * as THREE from 'three';
import {makeSculpt,makeRigKit,stdClips,sstep,vnoise,clamp,ease,bump,blink,cyc,TAU,merge,gait} from './creature-kit.js';
import {parts,hourglass} from './creature-parts.js?v=8';
import {sageFrame,sageBody,nearest,region,paintFace,clothShade,mir,sageBrows} from './sage-kit.js?v=8';
// ============ THE CHRONICLER · Sage · Time · after launch (GDD 11.7 names it; the look is a proposal) ============
// a lanky scribe in a long cyan coat with brass clockwork buttons, an hourglass-waisted hat, a glowing quill and a scroll that unrolls into a floating timeline
const COL={coat:0x1E6E82,coatL:0x44A8B8,coatD:0x0A2E3A,cream:0xEDE2C6,creamD:0xB09A70,brass:0xC8963E,skin:0xE4B494,skinD:0xA06A4A,hair:0x6A6A78,hairD:0x2E2E3A,
 boot:0x2A2230,sole:0x140E18,mouth:0x6A2A22,blush:0xE08A7A,glow:0x9BEAF3,ink:0x1A1A2E,vest:0x2A2A3E};
const K=Object.fromEntries(Object.entries(COL).map(([k,v])=>[k,new THREE.Color(v)]));
const F=sageFrame({k:1.04,head:.98,leg:1.06,shW:.165});const{P,HP}=F;const HR=r=>r*F.H*F.k;let A0=null;
const def={name:'chronicler',box:[[-.34,0,-.3],[.34,1.34,.3]],res:.0058,warm:0x0A1418,aoWarm:.16,sheen:0xE8FCFF,rim:0x9BEAF3,
 bodyMat:{roughness:.7,specularIntensity:.45,sheen:0.3,sheenRoughness:.45},fur:{shells:0},
 sculpt(A){A0=A;const{E,C}=A;
  sageBody(A,F,{coat:.2,sleeveFlare:1.1,bootH:.12,noseLen:1.12,belly:.9});
  // tall stand-up collar and coat tails, neat grey hair tied back
  E('T:collar',P(0,.875,-.03),[.12,.055,.1],null,.03);E('T:collarcut',P(0,.875,.075),[.075,.055,.07],null,.015,'s');E('T:cravat',P(0,0.868,.055),[.058,.048,.05],null,.03);C('T:cravatTail',P(0,0.848,.085),P(0,0.793,.09),.018,.012,.015);
  for(const s of[-1,1])E('T:lapel'+(s<0?'L':'R'),P(s*.06,.78,.1),[.045,.09,.02],[0,0,s*.25],.02);
  E('T:hairCap',HP(0,1.06,-.02),[HR(.132),HR(.11),HR(.132)],null,.04);E('T:hairTail',HP(0,.97,-.14),[HR(.035),HR(.06),HR(.035)],[.4,0,0],.03);
  for(const s of[-1,1])E('T:hairSide'+(s<0?'L':'R'),HP(s*.112,1.05,-.01),[HR(.024),HR(.05),HR(.045)],[0,0,s*-.1],.03);},
 disp(x,y,z,d){if(Math.abs(d)>.03)return d;const n=nearest(A0,x,y,z);if(/^T:hair/.test(n))return d-Math.pow(Math.abs(Math.sin(Math.atan2(x,z)*40+y*10)),6)*.0015;
  if(/^T:(coat|cfold)/.test(n))return d+(vnoise(x*40,y*12,z*40)-.5)*.0014;return d+(vnoise(x*70,y*70,z*70)-.5)*.0005;},
 paint(x,y,z,nx,ny,nz,ao,c,A){const n=nearest(A,x,y,z);const r=region(n);
  if(/cravat/.test(n)){clothShade(c,K,new THREE.Color(0xF2ECDC),new THREE.Color(0xFFFFFF),new THREE.Color(0xB8B0A0),ny,nz,ao,x,y,z,.03);return 0;}
  if(r==='skin'||r==='neck'||r==='hand'){c.copy(K.skin).lerp(new THREE.Color(0x8A3A2E),(1-ao)*.45+sstep(.2,-.6,ny)*.1);if(r==='skin')paintFace(x,y,z,c,K,F,{ao,smile:.005,blush:.25});
   if(r==='hand'&&/fg[01]|ft[01]/.test(n)&&/haR/.test(n))c.lerp(K.ink,.35);return 0;}
  if(r==='hair'){c.copy(K.hair).lerp(K.hairD,(1-ao)*.6+Math.pow(Math.abs(Math.sin(Math.atan2(x,z)*40+y*10)),6)*.3).lerp(new THREE.Color(0x9A9EAC),sstep(.5,1,ny)*.25);return 0;}
  if(r==='boot'){c.copy(K.boot).lerp(new THREE.Color(0x06040A),(1-ao)*.6).lerp(new THREE.Color(0x6A5A7A),sstep(.6,1,ny)*.2);return 0;}if(r==='sole'){c.copy(K.sole);return 0;}
  if(r==='legs'){clothShade(c,K,K.vest,new THREE.Color(0x4A4A62),new THREE.Color(0x10101A),ny,nz,ao,x,y,z,.05);return 0;}
  if(/collar|lapel/.test(n)){clothShade(c,K,K.coat,K.coatL,K.coatD,ny,nz,ao,x,y,z,.04);c.lerp(K.brass,/lapel/.test(n)?sstep(.004,0,A.dist(n,x,y,z)+.0)*0:0);if(/collar/.test(n)&&y>F.P(0,.955,0)[1])c.lerp(K.brass,.7);return 0;}
  if(r==='cuff'){c.copy(K.cream).lerp(K.creamD,(1-ao)*.5);return 0;}
  // coat open at the front over a dark waistcoat and cream shirt; brass clock-dial buttons are separate pieces
  const ax=Math.abs(x);if(nz>.3){if(ax<.03&&y>F.P(0,.72,0)[1]){c.copy(K.cream).lerp(K.creamD,(1-ao)*.5);return 0;}if(ax<.075&&y>F.P(0,.5,0)[1]){clothShade(c,K,K.vest,new THREE.Color(0x4A4A62),new THREE.Color(0x10101A),ny,nz,ao,x,y,z,.04);
   // fine gold pinstripe
   if(Math.abs(((x*120)%1+1)%1-.5)<.06)c.lerp(K.brass,.3);return 0;}}
  clothShade(c,K,K.coat,K.coatL,K.coatD,ny,nz,ao,x,y,z,.05);
  // brass-trimmed hem and a band of tiny clock ticks around it
  {const hb=F.P(0,.2,0)[1];if(y<hb+.02){c.lerp(K.brass,sstep(hb+.012,hb+.006,y)*.85);if(y>hb+.012&&y<hb+.02&&Math.abs(Math.sin(Math.atan2(x,z)*60))>.9)c.lerp(K.brass,.7);}}
  return 0;},
 accessories(A){const G=new THREE.Group();const Pt=parts(A,G);const{PB,add,irisTex,eye}=Pt;const T=THREE;
  const tex=irisTex('#06080C','#1E5A6A','#6AC8D8','#0A1A20',{pup:.3,human:true});
  for(const s of[-1,1])eye(s,{human:true,skin:COL.skin,lash:COL.hairD??0x1A0C08,r:HR(.027),ctr:HP(0,1.035,.02),dir:[.46,-.03,1],off:-.009,tex,lid:COL.skinD,lidCut:.3,lidTilt:.3,yaw:.36,irisK:1.35});
  G.add(sageBrows(Pt,F,{col:COL.hairD??COL.hair}));
  const brass=PB(COL.brass,{metalness:1,roughness:.3}),glass=PB(0xEAF8FF,{roughness:.02,transmission:.9,thickness:.01,transparent:true,opacity:.4,clearcoat:1});
  // hourglass-waisted top hat with a brass band and a tiny ticking dial
  {const h=new T.Group();h.userData.bone='head';h.position.set(...HP(0,1.13,-.01));h.rotation.set(-.06,0,.05);G.add(h);const hm=PB(0x16404C,{roughness:.6,sheen:.4,sheenColor:new T.Color(0x9BEAF3)});
   add(new T.CylinderGeometry(.2,.2,.012,40),hm,[0,0,0],null,null,h);const pr=[];for(let i=0;i<=16;i++){const u=i/16;pr.push(new T.Vector2(.105-Math.sin(u*Math.PI)*.028,u*.22));}add(new T.LatheGeometry(pr,32),hm,[0,.006,0],null,null,h);add(new T.CircleGeometry(.105,32),hm,[0,.226,0],[-Math.PI/2,0,0],null,h);
   add(new T.TorusGeometry(.086,.008,8,40),brass,[0,.11,0],[Math.PI/2,0,0],null,h);add(new T.TorusGeometry(.104,.006,8,40),brass,[0,.02,0],[Math.PI/2,0,0],null,h);
   const d=new T.Group();d.position.set(0,.11,.088);h.add(d);add(new T.CylinderGeometry(.022,.022,.006,24),brass,[0,0,0],[Math.PI/2,0,0],null,d);add(new T.CircleGeometry(.018,24),PB(0xF4ECD8),[0,0,.0035],null,null,d);const nd=add(new T.BoxGeometry(.002,.014,.001),PB(0x1A1A2E),[0,0,.004],null,null,d);nd.userData.spin=-1;}
  // brass clock-dial buttons down the waistcoat, a watch chain across it
  for(let i=0;i<4;i++){const b=add(new T.CylinderGeometry(.0085,.0085,.004,16),brass,P(.045,.76-i*.055,.098),[Math.PI/2,0,0],null,G);b.userData.bone='chest';}
  {const pts=[P(-.05,.66,.1),P(0,.63,.11),P(.05,.66,.1)].map(p=>new T.Vector3(...p));const ch=add(new T.TubeGeometry(new T.CatmullRomCurve3(pts),20,.0028,6),brass,null,null,null,G);ch.userData.bone='chest';}
  // glowing quill in the right hand
  {const w=F.j.wr(1);const g=new T.Group();g.userData.bone='haR';g.position.set(w[0]-.004,w[1]-.07,w[2]+.04);g.rotation.set(.5,0,-.3);G.add(g);add(new T.CylinderGeometry(.003,.0015,.1,8),brass,[0,-.03,0],null,null,g);
   const s=new T.Shape();s.moveTo(0,0);s.bezierCurveTo(.03,.05,.03,.16,0,.24);s.bezierCurveTo(-.012,.16,-.012,.05,0,0);const fg=new T.ShapeGeometry(s,16);add(fg,PB(0xE8FCFF,{roughness:.5,sheen:.8,sheenColor:new T.Color(0x9BEAF3),emissive:0x3AAFC0,emissiveIntensity:.5,side:T.DoubleSide}),[0,.01,0],[0,.4,0],null,g);
   const l=new T.PointLight(COL.glow,.5,.5,2);l.position.set(0,.1,0);g.add(l);}
  // scroll: a roll under the left arm unspooling into a floating ribbon timeline that circles slowly
  {const w=F.j.wr(-1);const g=new T.Group();g.userData.bone='haL';g.position.set(w[0]+.02,w[1]-.05,w[2]+.02);g.rotation.set(0,0,Math.PI/2+.2);G.add(g);add(new T.CylinderGeometry(.022,.022,.12,20),PB(COL.cream,{roughness:.8}),[0,0,0],null,null,g);for(const s of[-1,1])add(new T.CylinderGeometry(.008,.008,.02,10),brass,[0,s*.07,0],null,null,g);}
  {const fx=new T.Group();fx.userData.bone='root';G.add(fx);const sp=new T.Group();sp.userData.spin=.25;sp.userData.spinAx='y';sp.position.y=F.P(0,.5,0)[1];fx.add(sp);
   const rc=document.createElement('canvas');rc.width=1024;rc.height=64;{const x=rc.getContext('2d');x.fillStyle='#EDE2C6';x.fillRect(0,0,1024,64);x.strokeStyle='#1E6E82';x.lineWidth=2;x.beginPath();x.moveTo(0,32);x.lineTo(1024,32);x.stroke();for(let i=0;i<40;i++){const px=i*25.6;x.beginPath();x.moveTo(px,i%5?26:18);x.lineTo(px,i%5?38:46);x.stroke();}
    x.fillStyle='#1A1A2E';for(let i=0;i<16;i++){x.fillRect(i*64+8,8,30+Math.sin(i)*10,3);x.fillRect(i*64+10,52,24+Math.cos(i)*8,3);}x.fillStyle='#9BEAF3';for(let i=0;i<8;i++){x.beginPath();x.arc(i*128+60,32,6,0,TAU);x.fill();}}
   const rt=new T.CanvasTexture(rc);rt.colorSpace=T.SRGBColorSpace;const N=80,pos=[],uv=[],idx=[];for(let i=0;i<=N;i++){const u=i/N,a=-.4+u*TAU*.62,r=.34,y=.02+u*.36+Math.sin(u*9)*.02;for(const v of[0,1]){pos.push(Math.cos(a)*r,y+(v-.5)*.05,Math.sin(a)*r);uv.push(u,v);}if(i<N){const b=i*2;idx.push(b,b+1,b+2,b+1,b+3,b+2);}}
   const gg=new T.BufferGeometry();gg.setIndex(idx);gg.setAttribute('position',new T.Float32BufferAttribute(pos,3));gg.setAttribute('uv',new T.Float32BufferAttribute(uv,2));gg.computeVertexNormals();add(gg,new T.MeshStandardMaterial({map:rt,side:T.DoubleSide,roughness:.8,transparent:true,opacity:.92}),null,null,null,sp);}
  // Rewind (proposal 1): a clock ring on the ground with its hands spinning backwards
  {const fx=new T.Group();fx.userData.bone='root';fx.userData.fx='rewind';fx.userData.fxMode='show';fx.position.set(0,.02,0);G.add(fx);const m=new T.MeshBasicMaterial({color:COL.glow,transparent:true,opacity:.7,depthWrite:false,blending:T.AdditiveBlending,side:T.DoubleSide});
   add(new T.RingGeometry(.44,.46,64),m,[0,0,0],[-Math.PI/2,0,0],null,fx);for(let i=0;i<12;i++){const a=i/12*TAU;add(new T.PlaneGeometry(.015,i%3?.04:.07),m,[Math.cos(a)*.41,0,Math.sin(a)*.41],[-Math.PI/2,0,-a+Math.PI/2],null,fx);}
   const hd=new T.Group();hd.userData.spin=-4;hd.userData.spinAx='y';fx.add(hd);add(new T.PlaneGeometry(.02,.34),m,[0,.01,.15],[-Math.PI/2,0,0],null,hd);add(new T.PlaneGeometry(.02,.24),m,[.1,.01,0],[-Math.PI/2,0,Math.PI/2],null,hd);}
  // Bookmark (proposal 2): a ribbon-marker planted in the ground ahead
  {const fx=new T.Group();fx.userData.bone='root';fx.userData.fx='mark';fx.userData.fxMode='show';fx.position.set(0,0,.55);G.add(fx);add(new T.CylinderGeometry(.006,.006,.36,8),brass,[0,.18,0],null,null,fx);
   const s=new T.Shape();s.moveTo(0,0);s.lineTo(.14,0);s.lineTo(.11,-.04);s.lineTo(.14,-.08);s.lineTo(0,-.08);add(new T.ShapeGeometry(s),PB(COL.glow,{emissive:COL.glow,emissiveIntensity:.8,side:T.DoubleSide}),[0,.36,0],null,null,fx);
   add(new T.RingGeometry(.12,.14,48),new T.MeshBasicMaterial({color:COL.glow,transparent:true,opacity:.6,depthWrite:false,blending:T.AdditiveBlending,side:T.DoubleSide}),[0,.01,0],[-Math.PI/2,0,0],null,fx);}
  // Still frame (proposal 3): a cyan picture frame snaps shut around a spot ahead
  {const fx=new T.Group();fx.userData.bone='root';fx.userData.fx='frame';fx.userData.fxMode='show';fx.position.set(0,.45,.7);G.add(fx);const m=new T.MeshBasicMaterial({color:COL.glow,transparent:true,opacity:.85,depthWrite:false,blending:T.AdditiveBlending});
   for(const[w,h,x,y] of[[.5,.03,0,.3],[.5,.03,0,-.3],[.03,.6,.25,0],[.03,.6,-.25,0]])add(new T.BoxGeometry(w,h,.02),m,[x,y,0],null,null,fx);
   add(new T.PlaneGeometry(.47,.57),new T.MeshBasicMaterial({color:COL.glow,transparent:true,opacity:.12,depthWrite:false,side:T.DoubleSide}),[0,0,0],null,null,fx);}
  return G;}};
export const S=makeSculpt(def);
const cfg={name:'chronicler',J:F.J,TIP:F.TIP,TORSO:F.TORSO,AIM:[],floor:.006,pivot:.5,shMin:-2.2,springs:[['earL','vx',-.3,110,8,0,.25],['tail','vy',-.25,90,8,0,.15]]};
const RK=makeRigKit(S,cfg);export const makeRig=RK.makeRig,skinGeo=RK.skinGeo;
const pose={shR:[-.5,0,.05],elR:[-1.1,0,0],haR:[.1,0,0],shL:[-.2,0,-.1],elL:[-.9,0,0]};
export const CLIPS=stdClips({w:.1,arm:.25,x:{
 idle:{label:'Idle',len:4.4,f:t=>{const b=Math.sin(t*TAU/4.4)*.5+.5;const wr=Math.sin(t*6)*bump(cyc(t,4.4),.2,.7);return{sq:b*.01,hx:.14,hz:Math.sin(t*.7)*.03,eye:blink(t,3.8,.5)*.9,b:merge(pose,{chest:[-b*.02,0,0],haR:[.1+wr*.25,0,wr*.2]})};}},
 idle2:{label:'Idle 2',len:6,f:t=>{const u=cyc(t,6);const chk=bump(u,.2,.7);return{hx:.3*chk,hy:-.1*chk,eye:1-.3*chk,b:merge(pose,{shL:[-.9*chk-.2,0,.2*chk-.1],elL:[-1.5*chk-.9*(1-chk),0,0],haL:[.3*chk,0,0]})};}},
 p1:{label:'Rewind',len:3.2,f:t=>{const u=cyc(t,3.2);const k=ease(sstep(.05,.3,u))*(1-sstep(.86,1,u));const c=Math.sin(u*TAU*3)*k;return{hx:-.1*k,eye:1+.2*k,rewind:k,b:{shR:[-1.8*k-.5*(1-k),0,.1*k+.05],elR:[-.3*k-1.1*(1-k),0,0],haR:[c*.6,0,c*.4],shL:[-.2,0,-.1],elL:[-.9,0,0],chest:[-.06*k,0,0]}};}},
 p2:{label:'Bookmark',len:3.2,f:t=>{const u=cyc(t,3.2);const k=ease(sstep(.05,.3,u))*(1-sstep(.86,1,u));const jab=bump(u,.28,.42);return{hx:.12*k,y:-.03*k,mark:sstep(.34,.45,u)*(1-sstep(.9,1,u)),b:{shR:[-1.3*k-.5*(1-k),0,.05],elR:[-.2*k-1.1*(1-k)+jab*.3,0,0],shL:[-.2,0,-.1],elL:[-.9,0,0],chest:[.12*k+jab*.1,0,0],thR:[-.35*k,0,0],knR:[.3*k,0,0]}};}},
 p3:{label:'Still frame',len:3.2,f:t=>{const u=cyc(t,3.2);const k=ease(sstep(.05,.28,u))*(1-sstep(.86,1,u));const snap=sstep(.3,.36,u)*(1-sstep(.88,1,u));return{hx:-.05*k,eye:1-.4*k,frame:snap,b:{shR:[-1.4*k-.5*(1-k),-.2*k,.25*k],elR:[-.5*k-1.1*(1-k),0,0],shL:[-1.4*k-.2*(1-k),.2*k,-.25*k],elL:[-.5*k-.9*(1-k),0,0]}};}},
 guard:{label:'On guard',len:5,f:t=>{const u=cyc(t,5);return{hy:Math.sin(u*TAU)*.3,hx:.02,eye:.85,b:merge(pose,{chest:[-.03,0,0]})};}},
 work:{label:'Writes the day down',len:4,f:t=>{const w=Math.sin(t*9)*.5+.5;return{hx:.38,eye:.7,b:{shR:[-.9,0,.05],elR:[-1.4+w*.08,0,0],haR:[.3+Math.sin(t*14)*.12,0,Math.sin(t*9)*.15],shL:[-.9,0,.2],elL:[-1.4,0,0],chest:[.15,0,0]}};}},
 nap:{label:'Rest',len:6,f:t=>{const b=Math.sin(t*TAU/6)*.5+.5;return{y:-.36,sq:-.02,hx:.4,eye:.1,b:{thL:[-1.5,0,-.2],knL:[1.9,0,0],thR:[-1.5,0,.2],knR:[1.9,0,0],shL:[-.5,0,.2],elL:[-1,0,0],shR:[-.5,0,-.2],elR:[-1,0,0],chest:[.28+b*.03,0,0]}};}}}});
export const EXPR={
 happy:{label:'Pleased',hx:-.02,hz:.06,eye:.85,b:pose},
 focus:{label:'Noting',hx:.3,eye:.65,b:merge(pose,{elR:[-1.4,0,0]})},
 startled:{label:'Out of time',hx:-.1,eye:1.3,eyeW:1.06,b:{shL:[-.5,0,-.6],shR:[-.5,0,.6]}},
 caught:{label:'Lost the page',hx:.4,hz:.1,eye:.3,b:{chest:[.25,0,0],shR:[.1,0,-.1],shL:[.15,0,.1]}}};
export const build=o=>S.build(o),loadBaked=(u,r)=>S.loadBaked(u,r);
export const BIN='chronicler.bin?v=1',RES=.0095,GAME_SCALE=1;
export const EMBERS=[['head',HP(0,1.4,0)],['haR',P(.24,.5,.1)],['tail',P(0,.6,-.2)]];
export const ROUTE=[{to:[1.1,-.4],clip:'walk',sp:.22},{at:true,clip:'work',dur:4,face:[2,-1]},{to:[-.7,1],clip:'walk',sp:.22},{at:true,clip:'idle2',dur:6,face:[1,3]},{at:true,clip:'idle',dur:4.4,face:[1,3]},{to:[.2,.2],clip:'walk',sp:.2},{at:true,clip:'guard',dur:5,face:[2,2]}];
export const HERO={cam:[2.1,1.25,2.9],target:[0,.74,0],clip:'idle'};
