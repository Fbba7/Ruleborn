import * as THREE from 'three';
import {makeSculpt,makeRigKit,stdClips,sstep,vnoise,clamp,ease,bump,blink,cyc,TAU,merge,gait} from './creature-kit.js';
// ============ GLASS GOLEM · Warden · Matter · tall faceted crystal body with an inner light, 1.2 m, violet glass (GDD 11.4) ============
const COL={glass:0x4A2CB8,glassL:0xA48CFA,glassD:0x1C1052,edge:0xF2ECFF,core:0xE6DAFF,stone:0x6E6878,stoneL:0x9A94A6,stoneD:0x3E3A48,iron:0x3A3644};
const K=Object.fromEntries(Object.entries(COL).map(([k,v])=>[k,new THREE.Color(v)]));
const mir=(p,s)=>[p[0]*s,p[1],p[2]];
const h3=(x,y,z,s)=>{const v=Math.sin(x*127.1+y*311.7+z*74.7+s*19.19)*43758.5453;return v-Math.floor(v);};
const cellI=(x,y,z)=>{const xi=Math.floor(x),yi=Math.floor(y),zi=Math.floor(z);let d1=9,d2=9,id=0;for(let i=-1;i<=1;i++)for(let j=-1;j<=1;j++)for(let k=-1;k<=1;k++){const cx=xi+i,cy=yi+j,cz=zi+k;const px=cx+h3(cx,cy,cz,1)-x,py=cy+h3(cx,cy,cz,2)-y,pz=cz+h3(cx,cy,cz,3)-z;const d=px*px+py*py+pz*pz;if(d<d1){d2=d1;d1=d;id=cx*73856093^cy*19349663^cz*83492791;}else if(d<d2)d2=d;}return[Math.sqrt(d1),Math.sqrt(d2),id];};
const F=3.3;const fkey=(x,y,z,nx,ny,nz)=>{const s=(F*(1+.35*sstep(.9,1.1,y)));const[,,id]=cellI(x*s,y*s,z*s);return id+'|'+Math.round(nx*1.6)+','+Math.round(ny*1.6)+','+Math.round(nz*1.6);};
const fhash=k=>{let h=0;for(let i=0;i<k.length;i++)h=(h*31+k.charCodeAt(i))|0;return ((h>>>0)%1000)/1000;};
const def={name:'glassgolem',box:[[-.62,0,-.34],[.62,1.24,.36]],res:.0085,warm:0x2A1060,aoWarm:.2,sheen:0xE0D0FF,rim:0xC8B0FF,bodyMat:{roughness:.14,metalness:.05,sheen:0,clearcoat:1,clearcoatRoughness:.03,ior:1.52,iridescence:.5,iridescenceIOR:1.35,specularIntensity:1,emissive:0x2A1470,emissiveIntensity:.18},fur:{shells:0},
 sculpt({E,C}){
  // heavy wedge of a body: wide shoulders over a narrow waist, neckless blunt head
  E('T:pelvis',[0,.5,0],[.2,.14,.15],null,.07);E('T:waist',[0,.63,0],[.19,.1,.14],null,.07);E('T:torso',[0,.8,0],[.27,.2,.19],null,.08);
  E('T:shoulders',[0,.93,-.015],[.36,.12,.19],null,.07);E('T:back',[0,.9,-.09],[.24,.16,.12],null,.06);
  E('T:head',[0,1.055,.05],[.145,.135,.135],null,.05);E('T:crown',[0,1.15,.03],[.115,.055,.1],null,.04);E('T:brow',[0,1.1,.16],[.13,.035,.05],null,.03);E('T:jaw',[0,.995,.115],[.12,.06,.08],null,.04);
  for(const s of[-1,1]){const L=s<0?'L':'R';
   E('T:sock'+L,[s*.058,1.063,.176],[.042,.017,.024],null,.01,'s');
   E('sh'+L+':pauldron',mir([.34,.94,0],s),[.15,.13,.15],null,.05);
   const sh=mir([.37,.88,0],s),el=mir([.44,.62,.04],s),wr=mir([.46,.41,.08],s);C('sh'+L+':arm1',sh,el,.1,.085,.05);C('el'+L+':arm2',el,wr,.088,.078,.04);
   E('ha'+L+':fist',mir([.47,.33,.1],s),[.09,.085,.095],null,.035);for(let k=0;k<3;k++){const o=(k-1)*.045;C('ha'+L+':finger'+k,mir([.47+o,.31,.17],s),mir([.47+o*1.05,.25,.18],s),.028,.024,.015);}C('ha'+L+':thumb',mir([.42,.34,.15],s),mir([.42,.3,.19],s),.03,.025,.015);
   E('th'+L+':haunch',mir([.13,.44,0],s),[.12,.12,.13],null,.06);C('kn'+L+':shin',mir([.14,.34,.01],s),mir([.15,.12,.02],s),.1,.092,.05);
   E('ft'+L+':foot',mir([.15,.05,.06],s),[.1,.05,.14],null,.03);E('ft'+L+':toe',mir([.15,.045,.16],s),[.085,.04,.05],null,.025);}},
 disp(x,y,z,d){return d+(vnoise(x*40,y*40,z*40)-.5)*.002;},
 paint(x,y,z,nx,ny,nz,ao,c,A){const s=F*(1+.35*sstep(.9,1.1,y));const[c1,c2]=cellI(x*s,y*s,z*s);const k=fhash(fkey(x,y,z,nx,ny,nz));const edge=sstep(.07,0,c2-c1);
  c.copy(K.glass).lerp(K.glassL,sstep(.35,1,k)*.5+sstep(.3,.95,ny)*.3+sstep(.4,.9,nz)*.12).lerp(K.glassD,sstep(.45,0,k)*.5+(1-ao)*.4).offsetHSL((k-.5)*.05,0,0);
  // the inner light shows through the chest and belly
  const core=Math.hypot(x/.2,(y-.78)/.22,z/.18);c.lerp(K.core,sstep(1.25,.45,core)*.7*sstep(-.2,.6,nz));
  c.lerp(K.edge,edge*.35*sstep(.2,.8,ny+nz*.5));const st=A.minD(/:fist|:finger|:thumb|:foot|:toe/,x,y,z);return 0;},
 accessories(A){const G=new THREE.Group();const PB=(c,o={})=>new THREE.MeshPhysicalMaterial(Object.assign({color:c,roughness:.5},o));const add=(geo,m,p,r,s,par=G,bone)=>{const o=new THREE.Mesh(geo,m);if(p)o.position.set(...p);if(r)o.rotation.set(...r);if(s)o.scale.set(...s);o.castShadow=o.receiveShadow=true;if(bone)o.userData.bone=bone;par.add(o);return o;};
  const hit=(dir,ctr,off=0)=>{const d=new THREE.Vector3(...dir).normalize(),c=new THREE.Vector3(...ctr);let t=.7;for(let i=0;i<220;i++){const p=c.clone().addScaledVector(d,t);const s=A.sdf(p.x,p.y,p.z);if(s<.0008)break;t-=Math.max(s*.8,.0008);}const p=c.clone().addScaledVector(d,t);const e=.002;const n=new THREE.Vector3(A.sdf(p.x+e,p.y,p.z)-A.sdf(p.x-e,p.y,p.z),A.sdf(p.x,p.y+e,p.z)-A.sdf(p.x,p.y-e,p.z),A.sdf(p.x,p.y,p.z+e)-A.sdf(p.x,p.y,p.z-e)).normalize();return{p:p.addScaledVector(n,off),n};};
  const crystal=(h,r,c,o={})=>{const g=new THREE.CylinderGeometry(r*.55,r,h,6,1);g.translate(0,h/2,0);const tip=new THREE.ConeGeometry(r*.55,h*.35,6);tip.translate(0,h+h*.175,0);const m=PB(c,Object.assign({roughness:.06,transmission:.15,thickness:.2,ior:1.5,clearcoat:1,iridescence:.4,flatShading:true,emissive:0x3A1C90,emissiveIntensity:.35},o));const grp=new THREE.Group();add(g,m,null,null,null,grp);add(tip,m,null,null,null,grp);return grp;};
  // glowing core and its light
  const core=new THREE.Group();core.userData.bone='chest';core.position.set(0,.8,.0);G.add(core);
  const cm=PB(0xF4EEFF,{emissive:0xB89CFF,emissiveIntensity:2.2,roughness:.2});const cg=new THREE.IcosahedronGeometry(.07,0);add(cg,cm,null,null,null,core).name='core';
  const pl=new THREE.PointLight(0xB89CFF,1.2,.9,2);core.add(pl);
  // eyes: two soft glowing slits under the brow
  for(const s of[-1,1]){const e=new THREE.Group();e.name=s<0?'eye_L':'eye_R';e.userData.bone='head';{const h=hit([s*.4,.04,1],[0,1.063,.05],.018);e.position.copy(h.p);e.position.z=Math.max(e.position.z,.198);e.position.x*=1.08;e.lookAt(h.p.clone().add(h.n));}G.add(e);
   const eg=new THREE.CapsuleGeometry(.014,.04,6,12);eg.rotateZ(Math.PI/2+s*.14);add(eg,PB(0xFFFFFF,{emissive:0xF0E4FF,emissiveIntensity:3.6,roughness:.2}),null,null,[1,1,.6],e);const eh=new THREE.Sprite(new THREE.SpriteMaterial({color:0xC8B0FF,transparent:true,opacity:.55,depthWrite:false,blending:THREE.AdditiveBlending}));eh.scale.set(.1,.05,1);e.add(eh);
   const lid=add(new THREE.BoxGeometry(.001,.001,.001),PB(COL.glassD),[0,.03,0],null,null,e);lid.name='lid';lid.visible=false;{const c=document.createElement('canvas');c.width=c.height=64;const x=c.getContext('2d');const g=x.createRadialGradient(32,32,0,32,32,32);g.addColorStop(0,'rgba(255,255,255,1)');g.addColorStop(.3,'rgba(216,196,255,.7)');g.addColorStop(1,'rgba(160,120,255,0)');x.fillStyle=g;x.fillRect(0,0,64,64);const sp=new THREE.Sprite(new THREE.SpriteMaterial({map:new THREE.CanvasTexture(c),transparent:true,depthWrite:false,blending:THREE.AdditiveBlending}));sp.scale.set(.09,.05,1);sp.position.z=.01;e.add(sp);}}
  // Matter mark: hexagon glyph glowing in the chest facet
  {const h=hit([0,.1,1],[0,.86,0],.003);const hx=new THREE.Group();hx.userData.bone='chest';hx.position.copy(h.p);hx.lookAt(h.p.clone().add(h.n));G.add(hx);const gm=PB(0xFFFFFF,{emissive:0xD8C8FF,emissiveIntensity:2,roughness:.3});
   const ring=new THREE.TorusGeometry(.04,.006,6,6);add(ring,gm,null,[0,0,Math.PI/6],null,hx);add(new THREE.CylinderGeometry(.012,.012,.004,6),gm,null,[Math.PI/2,0,0],null,hx);
   for(let k=0;k<3;k++){const b=add(new THREE.BoxGeometry(.004,.07,.003),gm,null,[0,0,k*Math.PI/3],null,hx);}}
  // crystal spires growing from the shoulders and back
  const spires=[[-.36,1.02,-.05,.16,.035,-.35,.1],[-.28,1.0,-.1,.11,.026,-.2,-.35],[-.42,.98,.04,.08,.02,-.6,.2],[.36,1.02,-.05,.14,.032,.35,.1],[.3,1.0,-.1,.1,.024,.25,-.3],[0,.99,-.16,.13,.03,0,-.6],[-.1,.97,-.17,.09,.022,-.25,-.7],[.12,.96,-.17,.08,.02,.3,-.7]];
  for(const[x,y,z,h,r,rz,rx]of spires){const cr=crystal(h*1.5,r*1.45,0xB8A2FF);cr.position.set(x,y,z);cr.rotation.set(rx,0,rz);const s=x<-.2?'shL':x>.2?'shR':'chest';cr.userData.bone=s;G.add(cr);}
  // warden's granite bracers, iron-banded, with the Matter hex
  for(const s of[-1,1]){const el=new THREE.Vector3(s*.44,.62,.04),wr=new THREE.Vector3(s*.46,.41,.08);const br=new THREE.Group();br.userData.bone='el'+(s<0?'L':'R');br.position.copy(el.clone().lerp(wr,.55));br.quaternion.setFromUnitVectors(new THREE.Vector3(0,1,0),wr.clone().sub(el).normalize());G.add(br);
   const stone=PB(COL.stone,{roughness:.85,flatShading:true}),iron=PB(COL.iron,{metalness:.8,roughness:.4}),gm=PB(0xFFFFFF,{emissive:0xC8B4FF,emissiveIntensity:1.6});
   add(new THREE.CylinderGeometry(.098,.104,.13,8,1),stone,null,[0,Math.PI/8,0],null,br);for(const y of[-.06,.06])add(new THREE.TorusGeometry(.102,.008,6,8),iron,[0,y,0],[Math.PI/2,0,Math.PI/8],null,br);
   const bd=new THREE.Group();bd.position.set(s*.08,0,.07);bd.rotation.set(0,s*.9,0);br.add(bd);add(new THREE.CylinderGeometry(.03,.03,.012,6),iron,null,[Math.PI/2,0,0],null,bd);add(new THREE.CylinderGeometry(.018,.018,.004,6),gm,[0,0,.008],[Math.PI/2,0,0],null,bd);}
  // the crystal wall it raises (ability): three slabs rising in front
  const wall=new THREE.Group();wall.userData.bone='root';wall.userData.fx='wall';wall.userData.fxMode='show';wall.position.set(0,0,.55);G.add(wall);
  for(let k=0;k<3;k++){const w=new THREE.Group();w.position.set((k-1)*.34,0,Math.abs(k-1)*-.06);w.rotation.y=(k-1)*-.2;wall.add(w);for(let q=0;q<4;q++){const cr=crystal(.34+((k*3+q)%4)*.08,.05+(q%2)*.02,0xC8B8FF,{transmission:.6});cr.position.set((q-1.5)*.075,0,(q%2)*.03);cr.rotation.set((q%3-1)*.08,0,(q-1.5)*.06);w.add(cr);}}
  return G;}};
export const S=makeSculpt(def);
// cut the clay into flat facets: every vertex is pulled onto its facet's plane and takes that plane's normal
function facet(grp){const body=grp.getObjectByName('body');if(!body||body.geometry.userData.faceted)return grp;const g=body.geometry,P=g.attributes.position,N=g.attributes.normal,n=P.count;const acc=new Map();const keys=new Array(n);
 for(let i=0;i<n;i++){const x=P.getX(i),y=P.getY(i),z=P.getZ(i),nx=N.getX(i),ny=N.getY(i),nz=N.getZ(i);const k=fkey(x,y,z,nx,ny,nz);keys[i]=k;let a=acc.get(k);if(!a){a=[0,0,0,0,0,0,0];acc.set(k,a);}a[0]+=x;a[1]+=y;a[2]+=z;a[3]+=nx;a[4]+=ny;a[5]+=nz;a[6]++;}
 for(const a of acc.values()){const l=Math.hypot(a[3],a[4],a[5])||1;a[3]/=l;a[4]/=l;a[5]/=l;a[0]/=a[6];a[1]/=a[6];a[2]/=a[6];}
 for(let i=0;i<n;i++){const a=acc.get(keys[i]);if(a[6]<4)continue;const x=P.getX(i),y=P.getY(i),z=P.getZ(i);let dd=(x-a[0])*a[3]+(y-a[1])*a[4]+(z-a[2])*a[5];dd=clamp(dd,-.03,.03);P.setXYZ(i,x-a[3]*dd*.92,y-a[4]*dd*.92,z-a[5]*dd*.92);N.setXYZ(i,a[3],a[4],a[5]);}
 P.needsUpdate=N.needsUpdate=true;g.userData.faceted=true;g.computeBoundingSphere();return grp;}
const J={root:[null,[0,0,0]],hips:['root',[0,.5,0]],chest:['hips',[0,.8,0]],head:['chest',[0,.98,.04]],earL:['head',[-.1,1.12,.03]],earR:['head',[.1,1.12,.03]],
 shL:['chest',[-.37,.88,0]],elL:['shL',[-.44,.62,.04]],haL:['elL',[-.46,.41,.08]],shR:['chest',[.37,.88,0]],elR:['shR',[.44,.62,.04]],haR:['elR',[.46,.41,.08]],
 thL:['hips',[-.13,.44,0]],knL:['thL',[-.14,.33,.01]],ftL:['knL',[-.15,.11,.03]],thR:['hips',[.13,.44,0]],knR:['thR',[.14,.33,.01]],ftR:['knR',[.15,.11,.03]],tail:['hips',[0,.46,-.12]]};
const cfg={name:'glassgolem',J,TIP:{haL:[-.47,.24,.13],haR:[.47,.24,.13],ftL:[-.15,.01,.2],ftR:[.15,.01,.2]},
 TORSO:{hips:[[0,.36,0],[0,.64,0],.22],chest:[[0,.68,0],[0,.97,-.01],.3],head:[[0,.95,.05],[0,1.16,.05],.14]},
 AIM:[['shL','elL',[-.25,-1,.14]],['elL','haL',[-.08,-1,.18]],['shR','elR',[.25,-1,.14]],['elR','haR',[.08,-1,.18]]],floor:.008,pivot:.5,shMin:-1.5,springs:[]};
const RK=makeRigKit(S,cfg);export const makeRig=RK.makeRig,skinGeo=RK.skinGeo;
export const CLIPS=stdClips({w:.95,arm:.26,x:{
 idle:{label:'Idle',len:6,f:t=>{const b=Math.sin(t*TAU/6)*.5+.5;const look=sstep(.35,.45,cyc(t,12))*(1-sstep(.6,.7,cyc(t,12)));return{sq:b*.006,hx:-.08*look+Math.sin(t*.5)*.015,hy:.25*look,hz:0,eye:blink(t,6,1.5),b:{chest:[-b*.02,0,0],shL:[0,0,-.03],shR:[0,0,.03],elL:[-.12,0,0],elR:[-.12,0,0]}};}},
 ability:{label:'Crystal wall',len:3.2,f:t=>{const u=cyc(t,3.2);const plant=sstep(0,.2,u)*(1-sstep(.88,1,u)),raise=sstep(.18,.34,u)*(1-sstep(.86,.98,u)),slam=bump(u,.16,.3);
  return{y:-.04*plant,sq:-.04*plant-slam*.05,rx:.1*plant,hx:.15*plant,eye:1+raise*.2,eyeW:1+raise*.05,wall:raise,rz:Math.sin(u*70)*.01*slam,
   b:{thL:[-.35*plant,0,-.2*plant],knL:[.5*plant,0,0],ftL:[-.15*plant,0,0],thR:[-.35*plant,0,.2*plant],knR:[.5*plant,0,0],ftR:[-.15*plant,0,0],shL:[-1.3*slam-.6*raise,0,-.2],shR:[-1.3*slam-.6*raise,0,.2],elL:[-.3,0,0],elR:[-.3,0,0],chest:[.15*plant,0,0]}};}},
 nap:{label:'Rest',len:6,f:t=>{const b=Math.sin(t*TAU/6)*.5+.5;return{y:-.14,sq:-.03,rx:.04,hx:.3,eye:.05+b*.05,b:{thL:[-1.4,0,-.25],knL:[1.9,0,0],ftL:[-.3,0,0],thR:[-1.4,0,.25],knR:[1.9,0,0],ftR:[-.3,0,0],shL:[-.35,0,.15],elL:[-1.1,0,0],shR:[-.35,0,-.15],elR:[-1.1,0,0],chest:[.2,0,0]}};}},
 work:{label:'Watch the sky',len:6,f:t=>{const u=cyc(t,6);const up=sstep(0,.2,u)*(1-sstep(.8,1,u));const sway=Math.sin(t*.6);return{hx:-.45*up,hy:sway*.25*up,eye:blink(t,6,2),b:{chest:[-.1*up,sway*.05*up,0],shL:[0,0,-.02],shR:[0,0,.02],elL:[-.1,0,0],elR:[-.1,0,0]}};}},
 celebrate:{label:'Celebrate',len:2.6,f:t=>{const u=cyc(t,2.6);const r=bump(u,.05,.5),s=bump(u,.5,.95);return{y:r*.03,sq:r*.02,hx:-.2*r,eye:1+r*.25,wall:s*.35,b:{shL:[-2.2*r,0,-.2*r],shR:[-2.2*r,0,.2*r],elL:[-.4,0,0],elR:[-.4,0,0],chest:[-.1*r,0,0]}};}}}});
export const EXPR={
 calm:{label:'Calm',hx:.05,eye:.75,b:{}},
 focus:{label:'Watchful',hx:-.08,hy:.2,eye:.55,eyeW:1.05,b:{chest:[.08,0,0],shL:[-.2,0,-.15],shR:[-.2,0,.15],elL:[-.4,0,0],elR:[-.4,0,0]}},
 startled:{label:'Startled',hx:-.15,eye:1.3,eyeW:1.12,b:{shL:[-.35,0,-.4],shR:[-.35,0,.4],elL:[-.4,0,0],elR:[-.4,0,0]}},
 caught:{label:'Cracked',hx:.3,hz:.1,eye:.4,b:{shL:[.1,0,.1],shR:[.1,0,-.1],chest:[.2,0,.05]}}};
function crystalize(grp){const body=grp.getObjectByName('body');if(!body||body.geometry.userData.cryst)return grp;let g=S.mesh(.03);const P=g.attributes.position;for(let i=0;i<P.count;i++){const x=P.getX(i),y=P.getY(i),z=P.getZ(i);const j=.008;P.setXYZ(i,x+(h3(x*97,y*71,z*53,1)-.5)*j,y+(h3(x*61,y*89,z*47,2)-.5)*j,z+(h3(x*43,y*57,z*101,3)-.5)*j);}
 g=g.toNonIndexed();g.computeVertexNormals();const Q=g.attributes.position,N=g.attributes.normal,n=Q.count,col=new Float32Array(n*3),c=new THREE.Color();
 for(let t=0;t<n;t+=3){const x=(Q.getX(t)+Q.getX(t+1)+Q.getX(t+2))/3,y=(Q.getY(t)+Q.getY(t+1)+Q.getY(t+2))/3,z=(Q.getZ(t)+Q.getZ(t+1)+Q.getZ(t+2))/3;const nx=N.getX(t),ny=N.getY(t),nz=N.getZ(t);const k=h3(Math.round(nx*2.2),Math.round(ny*2.2),Math.round(nz*2.2),Math.round(x*6)*7+Math.round(y*6)*3+Math.round(z*6));
  c.copy(K.glass).lerp(K.glassL,k*.28+sstep(.1,.95,ny)*.4+sstep(.4,.95,nz)*.12).lerp(K.glassD,sstep(.2,-.7,ny)*.4+sstep(.3,0,k)*.18);
  const core=Math.hypot(x/.2,(y-.8)/.22,z/.18);c.lerp(K.core,sstep(1.2,.4,core)*.55*sstep(-.2,.6,nz));
  const st=S.api?0:0;for(let q=0;q<3;q++){col[(t+q)*3]=c.r;col[(t+q)*3+1]=c.g;col[(t+q)*3+2]=c.b;}}
 g.setAttribute('color',new THREE.BufferAttribute(col,3));{const ix=new Uint32Array(n);for(let i=0;i<n;i++)ix[i]=i;g.setIndex(new THREE.BufferAttribute(ix,1));}g.computeBoundingSphere();g.userData.cryst=true;g.userData.ck='cryst';body.geometry=g;body.material.flatShading=true;body.material.needsUpdate=true;return grp;}
export const build=o=>crystalize(S.build(o)),loadBaked=(u,r)=>S.loadBaked(u,r);
export const BIN='glassgolem.bin?v=5',RES=.0085,GAME_SCALE=1.15;
export const EMBERS=[['shL',[-.38,1.12,-.05]],['shR',[.38,1.12,-.05]],['head',[0,1.2,.03]]];
export const ROUTE=[{to:[1,-.3],clip:'walk',sp:.18},{at:true,clip:'work',dur:6,face:[3,-3]},{to:[-.6,1],clip:'walk',sp:.18},{at:true,clip:'ability',dur:3.2,face:[1,3]},{at:true,clip:'idle',dur:4,face:[1,3]},{to:[.2,.2],clip:'carry',sp:.16},{at:true,clip:'nap',dur:5,face:[2,2]}];
export const HERO={cam:[1.8,1.25,3.8],target:[0,.62,0],clip:'idle'};
