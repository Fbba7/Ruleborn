import * as THREE from 'three';
import {makeSculpt,makeRigKit,stdClips,sstep,vnoise,clamp,ease,bump,blink,cyc,TAU,merge,gait} from './creature-kit.js';
// ============ MOSSBEAR · Warden · Life · big mossy stone bear, 1.4 m, green and stone (GDD 11.4) ============
const COL={grassO:0x8A9A3A,lichen:0xB8C27A,lichenO:0xD49A4A,grassY:0xB8C060,flowerW:0xF4F0E4,flowerY:0xF2D05A,clawT:0x4A3E36,stone:0x6C7288,stoneW:0x958A78,stoneD:0x383C4E,pale:0xB9B1A0,moss:0x4A8A3E,mossD:0x24502A,mossL:0x8AB050,nose:0x3A3040,claw:0xECE4D0,pad:0x5A5064,ear:0x6A6E80};
const K=Object.fromEntries(Object.entries(COL).map(([k,v])=>[k,new THREE.Color(v)]));
const mir=(p,s)=>[p[0]*s,p[1],p[2]];
const h3=(x,y,z,s)=>{const v=Math.sin(x*127.1+y*311.7+z*74.7+s*19.19)*43758.5453;return v-Math.floor(v);};
const cell=(x,y,z)=>{const xi=Math.floor(x),yi=Math.floor(y),zi=Math.floor(z);let d1=9,d2=9,id=0;for(let i=-1;i<=1;i++)for(let j=-1;j<=1;j++)for(let k=-1;k<=1;k++){const cx=xi+i,cy=yi+j,cz=zi+k;const px=cx+h3(cx,cy,cz,1)-x,py=cy+h3(cx,cy,cz,2)-y,pz=cz+h3(cx,cy,cz,3)-z;const d=px*px+py*py+pz*pz;if(d<d1){d2=d1;d1=d;id=h3(cx,cy,cz,4);}else if(d<d2)d2=d;}return[Math.sqrt(d1),Math.sqrt(d2),id];};
const mossF=(x,y,z)=>{const f=y-z*.55+(vnoise(x*5+7,y*5,z*5)-.5)*.34+(vnoise(x*19,y*19+3,z*19)-.5)*.11+Math.max(0,.3-Math.abs(x))*.04;const arm=Math.abs(x)>.34?sstep(.58,.7,y+(vnoise(x*6,y*6,z*6)-.5)*.2)*sstep(-.05,.08,-z+.12)*.9:0;return Math.max(sstep(.7,.84,f)*(1-sstep(.2,.3,z)*sstep(1.01,.97,y)),arm);};
const def={name:'mossbear',box:[[-.74,0,-.44],[.74,1.22,.5]],res:.009,warm:0x3A3050,aoWarm:.14,sheen:0xD8F0C0,rim:0xC8F0B0,bodyMat:{roughness:.9,sheen:.35},fur:{len:.013,dens:[980,760,980],shells:6},
 sculpt({E,C,along}){
  E('T:belly',[0,.4,.02],[.27,.26,.25],null,.08);E('T:chest',[0,.66,.04],[.33,.23,.27],[.15,0,0],.09);E('T:hump',[0,.82,-.1],[.27,.17,.21],null,.08);
  E('T:skull',[0,.95,.2],[.17,.155,.16],null,.07);E('T:crown',[0,1.04,.16],[.13,.06,.11],null,.06);E('T:brow',[0,.995,.3],[.13,.035,.05],null,.04);
  E('T:muzzle',[0,.885,.335],[.1,.078,.09],null,.045);E('T:chin',[0,.845,.3],[.07,.04,.06],null,.04);E('T:nose',[0,.918,.418],[.044,.03,.026],[-.2,0,0],.015);
  for(const s of[-1,1]){const L=s<0?'L':'R';
   E('T:shoulder'+L,[s*.27,.75,0],[.17,.16,.18],null,.08);E('T:cheek'+L,[s*.11,.9,.27],[.07,.06,.06],null,.04);
   E('T:sock'+L,[s*.066,.952,.352],[.034,.03,.026],null,.015,'s');
   E('ear'+L+':ear',[s*.13,1.07,.15],[.058,.058,.03],[-.2,-s*.3,s*.3],.03);E('T:earcut'+L,[s*.13,1.072,.172],[.034,.034,.014],[-.2,-s*.3,s*.3],.012,'s');
   const sh=mir([.3,.72,.03],s),el=mir([.45,.5,.07],s),wr=mir([.52,.28,.1],s);C('sh'+L+':arm1',sh,el,.12,.1,.07);C('el'+L+':arm2',el,wr,.1,.088,.05);
   E('ha'+L+':paw',mir([.54,.22,.13],s),[.1,.075,.11],null,.04);for(let k=0;k<4;k++){const o=(k-1.5)*.044,yy=.205-Math.abs(k-1.5)*.006;E('ha'+L+':knuck'+k,mir([.54+o,yy,.205],s),[.034,.032,.036],null,.022);C('ha'+L+':claw'+k,mir([.54+o*1.05,yy-.004,.232],s),mir([.54+o*1.12,yy-.05,.262],s),.016,.0045,.012);}E('ha'+L+':palm',mir([.54,.172,.14],s),[.07,.03,.07],null,.03);
   E('th'+L+':haunch',mir([.16,.3,-.02],s),[.15,.15,.16],null,.07);C('kn'+L+':shin',mir([.16,.22,.02],s),mir([.17,.1,.05],s),.11,.1,.05);
   E('ft'+L+':foot',mir([.17,.065,.1],s),[.11,.06,.15],null,.04);for(let k=0;k<4;k++){const o=(k-1.5)*.05,yy=.058-Math.abs(k-1.5)*.004;E('ft'+L+':toe'+k,mir([.17+o,yy,.226],s),[.034,.032,.036],null,.02);C('ft'+L+':claw'+k,mir([.17+o*1.05,yy+.004,.256],s),mir([.17+o*1.1,.012,.284],s),.015,.004,.01);}}
  E('tail:tail',[0,.36,-.26],[.07,.065,.06],null,.04);},
 disp(x,y,z,d){if(Math.abs(d)>.03)return d;const m=mossF(x,y,z);const[c1,c2]=cell(x*11,y*11,z*11);const crk=sstep(.1,0,c2-c1),dome=(.55-c1)*.006,chip=sstep(.6,.85,vnoise(x*38,y*38,z*38))*.0018;const facR=sstep(.2,.3,z)*sstep(.82,.9,y);d+=(crk*.011-dome+chip+(vnoise(x*120,y*120,z*120)-.5)*.0007)*(1-m)*(1-facR*.85)-m*(sstep(.55,.85,vnoise(x*34,y*34,z*34))*.007);const r=Math.abs(vnoise(x*7,y*7,z*7)-.5),r2=Math.abs(vnoise(x*15+3,y*15,z*15)-.5);const face=sstep(.2,.3,z)*sstep(.82,.9,y);
  return d+(sstep(.035,0,r)*.006+sstep(.022,0,r2)*.0015)*(1-m)*(1-face*.8)-(vnoise(x*6,y*6,z*6)-.5)*.007*(1-m)-m*(.006+(vnoise(x*46,y*46,z*46)-.5)*.006);},
 paint(x,y,z,nx,ny,nz,ao,c,A){const m=mossF(x,y,z);const r=Math.abs(vnoise(x*7,y*7,z*7)-.5);const face=sstep(.2,.3,z)*sstep(.82,.9,y);
  const[q1,q2,qid]=cell(x*11,y*11,z*11);const crk=sstep(.09,0,q2-q1);c.copy(K.stone).lerp(K.stoneW,sstep(.35,.75,vnoise(x*3.5,y*3.5,z*3.5))*.5+qid*.3).offsetHSL((qid-.5)*.03,0,(qid-.5)*.07);c.lerp(K.stoneD,crk*.9*(1-face*.8));c.lerp(K.mossD,crk*sstep(.55,.8,vnoise(x*5+2,y*5,z*5))*.85*(1-face));const gr=vnoise(x*160,y*160,z*160);c.offsetHSL(0,0,(gr-.5)*.06*(1-face));c.lerp(K.pale,sstep(.07,.1,q2-q1)*sstep(.12,.1,q2-q1)*.3);c.lerp(K.pale,sstep(.13,.2,q2-q1)*sstep(.3,.95,ny)*.22);const lic=vnoise(x*26+5,y*26,z*26),lic2=vnoise(x*80,y*80,z*80);c.lerp(K.lichen,sstep(.72,.8,lic)*sstep(.35,.6,lic2)*.7*(1-face));c.lerp(K.lichenO,sstep(.82,.88,vnoise(x*17+9,y*17,z*17))*sstep(.4,.6,lic2)*.55*(1-face));c.lerp(K.stoneD,sstep(.035,0,r)*.8*(1-face*.8));c.lerp(K.stoneD,(1-ao)*.25);c.lerp(K.pale,sstep(.2,.8,ny)*.12);
  const bel=Math.hypot(x/.2,(y-.45)/.24,(z-.22)/.12);c.lerp(K.pale,sstep(1.1,.8,bel)*sstep(0,.4,nz)*.8);
  c.lerp(K.pale,sstep(.012,-.006,Math.min(A.dist('T:muzzle',x,y,z),A.dist('T:chin',x,y,z)))*.9);
  c.lerp(K.nose,sstep(.006,-.002,A.dist('T:nose',x,y,z)));
  const er=A.minD(/^ear[LR]:/,x,y,z);if(er<.006)c.lerp(K.ear,sstep(.1,.5,nz)*sstep(.03,.01,Math.abs(x)-.1)*.8);
  const cl=A.minD(/:claw/,x,y,z);c.lerp(K.claw,sstep(.004,-.002,cl));c.lerp(K.clawT,sstep(.004,-.002,cl)*.72);const pd=A.minD(/:paw|:toe|:foot|:knuck|:palm/,x,y,z);c.lerp(K.pad,sstep(.004,-.002,pd)*sstep(-.05,-.55,ny)*.9);c.lerp(K.pad,sstep(.004,-.002,A.minD(/:knuck|:toe/,x,y,z))*sstep(.1,.5,nz)*sstep(-.1,-.4,ny)*.6);
  const mn=vnoise(x*22,y*22,z*22),mn2=vnoise(x*70,y*70,z*70),bl=vnoise(x*140,y*60,z*140);const pat=vnoise(x*9+1,y*9,z*9);const gC=K.moss.clone().lerp(K.mossD,.22+sstep(.55,.15,mn)*.55+(1-ao)*.4+sstep(.4,.2,pat)*.25).lerp(K.grassO,sstep(.62,.85,pat)*.35).lerp(K.mossL,sstep(.68,.95,mn)*.35*sstep(.2,.9,ny)).lerp(K.grassY,sstep(.7,.92,bl)*.25*sstep(0,.8,ny)).offsetHSL((mn2-.5)*.03,0,(mn2-.5)*.08);const fl=sstep(.9,.95,vnoise(x*95+2,y*95,z*95))*sstep(.3,.8,ny);gC.lerp(fl>0&&vnoise(x*9,y*9,z*9)>.5?K.flowerW:K.flowerY,fl*.9);c.lerp(gC,sstep(0,.3,m));c.lerp(K.mossD,sstep(.3,0,m)*sstep(0,.08,m)*.5);
  const clump=sstep(.25,.8,vnoise(x*28+4,y*28,z*28));return m>.2?Math.min(1,m*1.2)*(.45+.55*clump):0;},
 accessories(A){const G=new THREE.Group();const PB=(c,o={})=>new THREE.MeshPhysicalMaterial(Object.assign({color:c,roughness:.5},o));const add=(geo,m,p,r,s,par=G,bone)=>{const o=new THREE.Mesh(geo,m);if(p)o.position.set(...p);if(r)o.rotation.set(...r);if(s)o.scale.set(...s);o.castShadow=o.receiveShadow=true;if(bone)o.userData.bone=bone;par.add(o);return o;};
  const hit=(dir,ctr,off=0)=>{const d=new THREE.Vector3(...dir).normalize(),c=new THREE.Vector3(...ctr);let t=1.2;for(let i=0;i<220;i++){const p=c.clone().addScaledVector(d,t);const s=A.sdf(p.x,p.y,p.z);if(s<.0008)break;t-=Math.max(s*.8,.0008);}const p=c.clone().addScaledVector(d,t);const e=.002;const n=new THREE.Vector3(A.sdf(p.x+e,p.y,p.z)-A.sdf(p.x-e,p.y,p.z),A.sdf(p.x,p.y+e,p.z)-A.sdf(p.x,p.y-e,p.z),A.sdf(p.x,p.y,p.z+e)-A.sdf(p.x,p.y,p.z-e)).normalize();return{p:p.addScaledVector(n,off),n};};
  // kind eyes: warm brown, soft heavy lids
  const ic=document.createElement('canvas');ic.width=ic.height=128;{const x=ic.getContext('2d');const g=x.createRadialGradient(64,64,0,64,64,64);g.addColorStop(0,'#120806');g.addColorStop(.42,'#120806');g.addColorStop(.5,'#5A3014');g.addColorStop(.85,'#A8682A');g.addColorStop(1,'#3A1E0C');x.fillStyle=g;x.fillRect(0,0,128,128);}
  const it=new THREE.CanvasTexture(ic);it.colorSpace=THREE.SRGBColorSpace;const irisM=PB(0xffffff,{map:it,roughness:.15,clearcoat:1,clearcoatRoughness:.05});const lidM=PB(COL.stone,{roughness:.9});
  for(const s of[-1,1]){const e=new THREE.Group();e.name=s<0?'eye_L':'eye_R';e.userData.bone='head';e.position.set(s*.066,.952,.336);e.rotation.set(0,s*.3,0);G.add(e);
   const eg=new THREE.SphereGeometry(.03,32,20);{const uv=eg.attributes.uv,p=eg.attributes.position;for(let i=0;i<p.count;i++)uv.setXY(i,.5+p.getX(i)/.05,.5+p.getY(i)/.05);}add(eg,irisM,null,null,[1,1,.8],e);
   const lid=add(new THREE.SphereGeometry(.033,28,12,0,Math.PI*2,0,Math.PI*.36),lidM,[0,.001,0],[-.5,0,s*.12],null,e);lid.name='lid';
   for(const[r,x,y]of[[.0075,-.009,.011],[.0035,.01,-.008]]){const sp=new THREE.Mesh(new THREE.SphereGeometry(r,10,8),new THREE.MeshBasicMaterial({color:0xffffff}));sp.position.set(x,y,.026);e.add(sp);}}
  // Life leaf on the forehead
  const leafG=(l,w)=>{const sh=new THREE.Shape();sh.moveTo(0,0);sh.bezierCurveTo(w*.8,l*.2,w*.6,l*.8,0,l);sh.bezierCurveTo(-w*.6,l*.8,-w*.8,l*.2,0,0);const g=new THREE.ExtrudeGeometry(sh,{depth:.003,bevelEnabled:true,bevelThickness:.003,bevelSize:.003,bevelSegments:2,curveSegments:10});g.translate(0,-l*.5,0);return g;};
  const leafM=PB(0x7CD66A,{roughness:.35,clearcoat:.6,sheen:.4,sheenColor:new THREE.Color(0xD8FFB0)});{const h=hit([0,.3,1],[0,.99,.2],.005);const lf=add(leafG(.095,.044),leafM,h.p.toArray(),null,null,G,'head');lf.lookAt(h.p.clone().add(h.n));lf.rotateZ(.35);lf.name='life_leaf';add(new THREE.BoxGeometry(.003,.06,.004),PB(0x2F7A3C),[0,0,.006],null,null,lf);}
  // flowers, sprouts and mushrooms growing in the moss; they swell and bloom when it roots
  const petal=new THREE.SphereGeometry(.02,12,8);const FC=[0xF7A6DA,0xFFFFFF,0xFFE08F,0xF7A6DA,0xC8B8FF];let seed=3;const rnd=()=>{seed=(seed*9301+49297)%233280;return seed/233280;};
  const flower=(pos,n,col,sc,bone,extra)=>{const f=new THREE.Group();f.position.copy(pos);f.lookAt(pos.clone().add(n));f.rotateX(Math.PI/2);f.scale.setScalar(sc);f.userData.bone=bone;f.userData.fx='bloom';f.userData.fxBase=extra?0:1;f.userData.fxGain=extra?1.2:.55;if(extra)f.userData.fxMode='grow';
   const pm=PB(col,{roughness:.55,sheen:.6,sheenColor:new THREE.Color(0xFFFFFF)});for(let k=0;k<5;k++){const a=k/5*TAU;add(petal,pm,[Math.cos(a)*.022,.012,Math.sin(a)*.022],[0,-a,.35],[1.1,.35,.6],f);}add(new THREE.SphereGeometry(.013,12,8),PB(0xF2B43C,{roughness:.6}),[0,.016,0],null,[1,.7,1],f);add(new THREE.CylinderGeometry(.004,.005,.03,6),PB(0x3E8A45),[0,-.004,0],null,null,f);G.add(f);return f;};
  const spots=[];for(let i=0;i<140&&spots.length<30;i++){const th=rnd()*TAU,ph=.25+rnd()*1.05;const dir=[Math.sin(th)*Math.sin(ph)*1.1,Math.cos(ph),Math.cos(th)*Math.sin(ph)*.9-.35];const h=hit(dir,[0,.78,-.02],-.002);if(mossF(h.p.x,h.p.y,h.p.z)<.65)continue;if(spots.some(s=>s.p.distanceTo(h.p)<.075))continue;spots.push(h);}
  spots.forEach((h,i)=>{const bone=h.p.y>.9&&h.p.z>.05?'head':'chest';if(i%6===5){const m=new THREE.Group();m.position.copy(h.p);m.lookAt(h.p.clone().add(h.n));m.rotateX(Math.PI/2);m.userData.bone=bone;m.userData.fx='bloom';m.userData.fxGain=.4;add(new THREE.CylinderGeometry(.008,.01,.035,8),PB(0xF1E3C4),[0,.017,0],null,null,m);add(new THREE.SphereGeometry(.026,16,10,0,TAU,0,Math.PI*.5),PB(0xE2536B,{roughness:.5}),[0,.03,0],null,[1,.7,1],m);for(let k=0;k<3;k++)add(new THREE.SphereGeometry(.004,6,4),PB(0xffffff),[Math.cos(k*2)*.013,.046,Math.sin(k*2)*.013],null,null,m);G.add(m);}
   else if(i%6===2){const s=new THREE.Group();s.position.copy(h.p);s.lookAt(h.p.clone().add(h.n));s.rotateX(Math.PI/2);s.userData.bone=bone;s.userData.fx='bloom';s.userData.fxGain=.7;for(let k=0;k<3;k++){const cu=new THREE.CatmullRomCurve3([[0,0,0],[.006,.03,0],[.02,.055,0],[.028,.05,0],[.024,.04,0]].map(p=>new THREE.Vector3(...p)));const t=add(new THREE.TubeGeometry(cu,16,.0045,6),PB(0x6FC05A,{roughness:.5}),null,[0,k*2.1,0],null,s);}G.add(s);}
   else flower(h.p,h.n,FC[i%5],.9+rnd()*.5,bone,i%3===1);});
  // warden's bark pauldron on the left shoulder (modelled on the out-held arm)
  // warden's bark bracers with a leaf badge
  for(const s of[-1,1]){const el=new THREE.Vector3(s*.45,.5,.07),wr=new THREE.Vector3(s*.52,.28,.1);const br=new THREE.Group();br.userData.bone='el'+(s<0?'L':'R');br.position.copy(el.clone().lerp(wr,.55));br.quaternion.setFromUnitVectors(new THREE.Vector3(0,1,0),wr.clone().sub(el).normalize());G.add(br);
   const bark=PB(0x7A5236,{roughness:.85}),barkD=PB(0x553520,{roughness:.9}),gold=PB(0xD9B86A,{metalness:1,roughness:.3});
   add(new THREE.CylinderGeometry(.102,.108,.1,28,1,true),bark,null,null,null,br).material.side=THREE.DoubleSide;for(const y of[-.05,.05])add(new THREE.TorusGeometry(.105,.009,8,32),gold,[0,y,0],[Math.PI/2,0,0],null,br);
   for(let k=0;k<10;k++){const a2=k/10*TAU;add(new THREE.BoxGeometry(.008,.085,.006),barkD,[Math.cos(a2)*.108,0,Math.sin(a2)*.108],[0,-a2,0],null,br);}
   const bd=new THREE.Group();bd.position.set(s*.1,0,.04);bd.rotation.set(0,s*1.2,0);br.add(bd);add(new THREE.CylinderGeometry(.035,.035,.012,24),gold,null,[Math.PI/2,0,0],null,bd);add(leafG(.045,.034),leafM,[0,0,.008],null,null,bd);}
  // roots that grow from the feet when it plants itself (ability)
  for(const s of[-1,1]){const rg=new THREE.Group();rg.userData.bone='ft'+(s<0?'L':'R');rg.userData.fx='roots';rg.userData.fxMode='show';rg.position.set(s*.17,.03,.1);G.add(rg);const rm=PB(0x7A5236,{roughness:.85});
   for(let k=0;k<6;k++){const a=k/6*TAU+s*.3;const L=.16+((k*37)%5)*.02;const cu=new THREE.CatmullRomCurve3([[0,.03,0],[Math.cos(a)*L*.4,.0,Math.sin(a)*L*.4],[Math.cos(a+.3)*L*.8,-.01,Math.sin(a+.3)*L*.8],[Math.cos(a+.5)*L,-.02,Math.sin(a+.5)*L]].map(p=>new THREE.Vector3(...p)));add(new THREE.TubeGeometry(cu,20,.016,7),rm,null,null,null,rg);}}
  return G;}};
export const S=makeSculpt(def);
const J={root:[null,[0,0,0]],hips:['root',[0,.42,0]],chest:['hips',[0,.66,.03]],head:['chest',[0,.86,.14]],earL:['head',[-.13,1.04,.14]],earR:['head',[.13,1.04,.14]],
 shL:['chest',[-.3,.72,.03]],elL:['shL',[-.45,.5,.07]],haL:['elL',[-.52,.28,.1]],shR:['chest',[.3,.72,.03]],elR:['shR',[.45,.5,.07]],haR:['elR',[.52,.28,.1]],
 thL:['hips',[-.15,.34,0]],knL:['thL',[-.165,.2,.03]],ftL:['knL',[-.17,.09,.06]],thR:['hips',[.15,.34,0]],knR:['thR',[.165,.2,.03]],ftR:['knR',[.17,.09,.06]],tail:['hips',[0,.36,-.24]]};
const cfg={name:'mossbear',J,TIP:{haL:[-.55,.14,.2],haR:[.55,.14,.2],ftL:[-.17,.02,.24],ftR:[.17,.02,.24]},
 TORSO:{hips:[[0,.2,0],[0,.52,.02],.26],chest:[[0,.56,.03],[0,.82,-.02],.26],head:[[0,.88,.17],[0,1.03,.2],.16]},
 AIM:[['shL','elL',[-.2,-1,.1]],['elL','haL',[-.06,-1,.2]],['shR','elR',[.2,-1,.1]],['elR','haR',[.06,-1,.2]]],floor:.008,pivot:.35,shMin:-1.7,
 springs:[['earL','vy',-.4,160,12,0,.3],['earR','vy',-.4,150,12,0,.3],['tail','vy',-.5,200,12,0,.4]]};
const RK=makeRigKit(S,cfg);export const makeRig=RK.makeRig,skinGeo=RK.skinGeo;
export const CLIPS=stdClips({w:.9,arm:.3,x:{
 idle:{label:'Idle',len:5,f:t=>{const b=Math.sin(t*TAU/5)*.5+.5;return{sq:b*.012,hx:.06+Math.sin(t*.9)*.03,hz:Math.sin(t*.5)*.05,elx:-bump(t%5,3.4,3.8)*.4,eye:blink(t,5,.5),bloom:b*.08,b:{chest:[-b*.04,0,0],shL:[Math.sin(t*1.1)*.03,0,-.02-b*.03],shR:[Math.sin(t*1.1+1)*.03,0,.02+b*.03],elL:[-.18,0,0],elR:[-.18,0,0]}};}},
 ability:{label:'Root',len:3.2,f:t=>{const u=cyc(t,3.2);const r=sstep(.05,.3,u)*(1-sstep(.85,1,u)),g=sstep(.2,.55,u)*(1-sstep(.88,1,u));const pulse=Math.sin(t*5)*.5+.5;return{y:-.04*r,sq:-.05*r+pulse*.008*g,hx:-.12*r,elx:-.2,eye:1-.85*g*(1-bump(u,.6,.66)),roots:r,bloom:g*(1+pulse*.15),
  b:{thL:[-.35*r,0,-.15*r],knL:[.5*r,0,0],ftL:[-.15*r,0,0],thR:[-.35*r,0,.15*r],knR:[.5*r,0,0],ftR:[-.15*r,0,0],shL:[-.45*r,0,-.5*r],shR:[-.45*r,0,.5*r],elL:[-.5*r,0,0],elR:[-.5*r,0,0],chest:[-.12*r,0,0],hips:[.1*r,0,0]}};}},
 nap:{label:'Nap',len:5,f:t=>{const b=Math.sin(t*TAU/5)*.5+.5;return{y:-.12,sq:-.05+b*.03,rx:.06,hx:.35+b*.04,hz:.12,elx:.3,eye:.1,bloom:.5+b*.2,b:{thL:[-1.45,0,-.3],knL:[1.9,0,0],ftL:[-.3,0,0],thR:[-1.45,0,.3],knR:[1.9,0,0],ftR:[-.3,0,0],shL:[-.5,0,.3],elL:[-.9,0,0],shR:[-.5,0,-.3],elR:[-.9,0,0],chest:[.3+b*.04,0,0]}};}},
 work:{label:'Work loop',len:2.4,f:t=>{const u=cyc(t,2.4);const dip=sstep(.0,.25,u)*(1-sstep(.75,1,u));const pat=Math.max(0,Math.sin(t*7))*dip;return{y:-dip*.06,hx:dip*.35,elx:-.1,eye:u>.82&&u<.88?.15:1,bloom:dip*.2,b:{chest:[.55*dip,0,0],hips:[.25*dip,0,0],shL:[-1*dip-.2*pat,0,-.15],shR:[-1*dip-.2*Math.max(0,Math.sin(t*7+Math.PI))*dip,0,.15],elL:[-.35,0,0],elR:[-.35,0,0],thL:[-.55*dip,0,0],knL:[.9*dip,0,0],thR:[-.55*dip,0,0],knR:[.9*dip,0,0]}};}},
 celebrate:{label:'Celebrate',len:2.2,f:t=>{const u=cyc(t,2.2);const j=bump(u,.1,.45);const st=bump(u,.5,.95);return{y:j*.08,sq:j*.05-bump(u,.43,.52)*.12,hz:Math.sin(t*4)*.12*st,hx:-.15*j,elx:.2,eye:u>.2&&u<.3?.2:1,bloom:j+st*.5,b:{shL:[-1.3*j-.4*st,0,-.7*j-.2*st],shR:[-1.3*j-.4*st,0,.7*j+.2*st],elL:[-.6,0,0],elR:[-.6,0,0],thL:[-.4*j,0,0],knL:[.6*j,0,0],thR:[-.4*j,0,0],knR:[.6*j,0,0],hips:[0,Math.sin(t*4)*.15*st,0]}};}}}});
export const EXPR={
 gentle:{label:'Gentle',hz:-.12,hx:.1,eye:.8,bloom:.2,b:{shL:[0,0,-.08],shR:[0,0,.08]}},
 focus:{label:'Focused',hx:.2,elx:.2,eye:.55,eyeW:1.02,b:{shL:[-.25,0,-.2],shR:[-.25,0,.2],elL:[-.5,0,0],elR:[-.5,0,0]}},
 startled:{label:'Startled',hx:-.14,elx:-.4,eye:1.25,eyeW:1.08,b:{shL:[-.35,0,-.5],shR:[-.35,0,.5],elL:[-.4,0,0],elR:[-.4,0,0]}},
 caught:{label:'Caught',hx:.34,hz:.08,elx:.3,elz:.3,eye:.65,b:{shL:[.1,0,.12],shR:[.1,0,-.12],chest:[.18,0,0]}}};
export const build=o=>S.build(o),loadBaked=(u,r)=>S.loadBaked(u,r);
export const BIN='mossbear.bin?v=4',RES=.009,GAME_SCALE=1.2;
export const EMBERS=[['earL',[-.13,1.1,.15]],['earR',[.13,1.1,.15]],['tail',[0,.36,-.32]]];
export const ROUTE=[{to:[1.5,-.6],clip:'walk',sp:.22},{at:true,clip:'work',dur:4.8,face:[1.9,-1.5]},{to:[-.4,1.3],clip:'walk',sp:.22},{at:true,clip:'ability',dur:3.2,face:[1,4]},{at:true,clip:'idle',dur:3,face:[1,4]},{to:[.3,.3],clip:'carry',sp:.18},{at:true,clip:'nap',dur:5,face:[2,3]}];
export const HERO={cam:[1.7,1.1,3.8],target:[0,.62,0],clip:'idle'};
