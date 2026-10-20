import * as THREE from 'three';
import {makeSculpt,makeRigKit,stdClips,sstep,vnoise,clamp,ease,bump,blink,cyc,TAU,merge,gait} from './creature-kit.js';
// ============ QUARRYBACK · Breaker · Matter · armadillo with a stone shell and a pick tail, 0.9 m, violet-grey (GDD 11.4) ============
const COL={stone:0x6A6284,stoneL:0x908AAE,stoneD:0x322C46,seam:0x221C30,wear:0xB8B0CC,skin:0x8C7A8A,skinL:0xB8A4B0,skinD:0x5A4A5E,nose:0x3E2E3E,claw:0xE6DCCC,clawT:0x5A4A48,ear:0x8A7A8E,earIn:0xD6A8B0,lichen:0xB8C2A0};
const K=Object.fromEntries(Object.entries(COL).map(([k,v])=>[k,new THREE.Color(v)]));
const mir=(p,s)=>[p[0]*s,p[1],p[2]];
const h3=(x,y,z,s)=>{const v=Math.sin(x*127.1+y*311.7+z*74.7+s*19.19)*43758.5453;return v-Math.floor(v);};
const cell=(x,y,z)=>{const xi=Math.floor(x),yi=Math.floor(y),zi=Math.floor(z);let d1=9,d2=9,id=0;for(let i=-1;i<=1;i++)for(let j=-1;j<=1;j++)for(let k=-1;k<=1;k++){const cx=xi+i,cy=yi+j,cz=zi+k;const px=cx+h3(cx,cy,cz,1)-x,py=cy+h3(cx,cy,cz,2)-y,pz=cz+h3(cx,cy,cz,3)-z;const d=px*px+py*py+pz*pz;if(d<d1){d2=d1;d1=d;id=h3(cx,cy,cz,4);}else if(d<d2)d2=d;}return[Math.sqrt(d1),Math.sqrt(d2),id];};
let A0=null;
// armour bands wrap the back like an armadillo: angle around the shell's side-to-side axis
const plate=(x,y,z)=>{const s=(y-.14)*.8+(-z-.02)*-.6+(.0);const ax=(y-.14)*.8-(z+.3)*.6;const u=ax;const perp=Math.atan2(x,((y-.44)*.6+(z+.1)*.8)+.3);
 if(u>.2&&u<.5){const q=(u-.2)/.05;const i=Math.floor(q),fr=q-i;const sc=perp*5+i*.5;const j=Math.floor(sc),g=sc-j;const e=Math.max(sstep(.16,0,fr),sstep(.1,0,Math.min(g,1-g))*.75);return{e,dome:Math.sin(fr*Math.PI)*(1-fr*.4),lip:sstep(.84,1,fr),id:h3(i,j,0,7),band:1};}
 const[c1,c2,id]=cell(x*24,y*24,z*24);return{e:sstep(.1,0,c2-c1),dome:sstep(.5,.1,c1),lip:0,id,band:0};};
const shellM=(x,y,z)=>{if(!A0)return 0;const lim=A0.minD(/^(sh|el|ha|th|kn|ft)[LR]:|^ear|^T:(skull|snout|nose|jowl|sock|brow|helm)|^tail/,x,y,z);const ds=A0.minD(/^T:shell/,x,y,z);const front=z-(.0+.34*Math.pow(Math.abs(x)/.3,2)+(vnoise(x*10,y*10,0)-.5)*.02);return sstep(.03,-.01,front)*sstep(.012,.03,lim)*sstep(.12,.18,y)*sstep(.05,.015,ds);};
const headM=(x,y,z)=>{if(!A0)return 0;return sstep(.018,.004,A0.minD(/^T:helm/,x,y,z));};
const tailM=(x,y,z)=>{if(!A0)return 0;return sstep(.018,.006,A0.minD(/^tail:/,x,y,z));};
const def={name:'quarryback',box:[[-.42,0,-.78],[.42,.9,.48]],res:.0068,warm:0x2A1A30,aoWarm:.16,sheen:0xE8D8F0,rim:0xC8B8FF,bodyMat:{roughness:.62,sheen:0,clearcoat:.15,clearcoatRoughness:.55},fur:{len:.004,dens:[900,700,900],shells:0},
 sculpt(A){const{E,C}=A;A0=A;
  // round domed shell over a soft belly; the shell sits back so the belly shows in front
  E('T:belly',[0,.34,.1],[.17,.2,.13],null,.07);E('T:chest',[0,.5,.1],[.16,.13,.11],null,.06);
  E('T:shell',[0,.45,-.1],[.31,.31,.28],[.18,0,0],.035);E('T:shellrim',[0,.19,-.1],[.29,.06,.25],null,.03);E('T:shoulderplate',[0,.63,-.03],[.26,.1,.2],[.3,0,0],.035);
  // head: a long armoured snout with a plated helm and tall ears
  E('T:skull',[0,.66,.15],[.125,.115,.125],null,.06);E('T:helm',[0,.71,.16],[.12,.06,.13],[-.25,0,0],.035);
  C('T:snout',[0,.645,.23],[0,.612,.33],.078,.048,.04);E('T:nose',[0,.614,.36],[.036,.029,.022],[-.3,0,0],.012);E('T:jowl',[0,.6,.2],[.1,.06,.08],null,.04);
  for(const s of[-1,1]){const L=s<0?'L':'R';
   E('T:sock'+L,[s*.06,.645,.244],[.028,.023,.018],null,.01,'s');E('T:brow'+L,[s*.06,.664,.25],[.04,.014,.024],[0,0,s*.3],.02);
   E('ear'+L+':ear',[s*.08,.8,.1],[.034,.065,.016],[-.25,-s*.35,s*.22],.022);E('T:earcut'+L,[s*.08,.8,.112],[.02,.045,.008],[-.25,-s*.35,s*.22],.008,'s');
   // short forearms with big digging claws
   const sh=mir([.2,.52,.1],s),el=mir([.27,.39,.15],s),wr=mir([.29,.27,.18],s);C('sh'+L+':arm1',sh,el,.07,.058,.05);C('el'+L+':arm2',el,wr,.056,.048,.035);
   E('ha'+L+':paw',mir([.295,.245,.2],s),[.058,.045,.058],null,.03);for(let k=0;k<3;k++){const o=(k-1)*.03;C('ha'+L+':claw'+k,mir([.295+o,.232,.24],s),mir([.297+o*1.2,.18,.282],s),.016,.004,.012);}
   E('th'+L+':haunch',mir([.14,.24,-.04],s),[.11,.12,.12],null,.06);C('kn'+L+':shin',mir([.14,.16,-.01],s),mir([.145,.08,.01],s),.065,.055,.04);
   E('ft'+L+':foot',mir([.145,.035,.055],s),[.065,.034,.085],null,.025);for(let k=0;k<3;k++){const o=(k-1)*.032;C('ft'+L+':claw'+k,mir([.145+o,.03,.12],s),mir([.147+o*1.15,.01,.16],s),.014,.004,.01);}}
  // long banded tail that ends in the pick head
  C('tail:t1',[0,.26,-.3],[.07,.18,-.46],.07,.05,.035);C('tail:t2',[.07,.18,-.46],[.2,.13,-.56],.05,.034,.03);C('tail:t3',[.2,.13,-.56],[.3,.12,-.58],.034,.026,.02);},
 disp(x,y,z,d){if(Math.abs(d)>.035)return d;const sm=shellM(x,y,z),hm=headM(x,y,z),tm=tailM(x,y,z);
  const b=plate(x,y,z);const groove=b.e*(b.band?.012:.008)+b.lip*.004;const dome=b.dome*(b.band?.004:.003);
  const[c1,c2]=cell(x*30,y*30,z*30);const stone=(vnoise(x*70,y*70,z*70)-.5)*.0025+sstep(.06,0,c2-c1)*.0022+sstep(.7,.9,vnoise(x*24,y*24,z*24))*.002;
  const hb=(()=>{const r=Math.hypot(x,(y-.66)*1.2);const u=(z-.07)/.05;const f=u-Math.floor(u);return sstep(.16,0,f)*.007;})();
  const tb=(()=>{const u=(-z-.28+x*.4)/.07;const f=u-Math.floor(u);return sstep(.18,0,f)*.008-Math.sin(f*Math.PI)*.003;})();
  const skin=(vnoise(x*22,y*22,z*22)-.5)*.0012+Math.max(0,Math.sin(y*95+vnoise(x*8,y*8,z*8)*3))*sstep(.45,.25,y)*.0009;
  return d+sm*(groove-dome+stone)+hm*(hb+stone*.6)+tm*(tb+stone*.5)+(1-Math.max(sm,hm,tm))*skin;},
 paint(x,y,z,nx,ny,nz,ao,c,A){const sm=shellM(x,y,z),hm=headM(x,y,z),tm=tailM(x,y,z);const arm=Math.max(sm,hm,tm);
  const b=plate(x,y,z);const[c1,c2,id]=cell(x*30,y*30,z*30);
  const sc=K.stone.clone().lerp(K.stoneL,sstep(.3,.9,ny)*.35+(b.id-.5)*.25).offsetHSL((b.id-.5)*.02,0,(b.id-.5)*.06);
  sc.lerp(K.seam,b.e*sm*.9);sc.lerp(K.wear,b.lip*sm*.5+b.dome*(1-b.band)*sm*.15+sstep(.06,.02,c2-c1)*.12);sc.lerp(K.stoneD,sstep(.07,0,c2-c1)*.35+(1-ao)*.3);
  sc.lerp(K.lichen,sstep(.78,.86,vnoise(x*14+3,y*14,z*14))*sstep(.3,.8,ny)*.45*sm);sc.offsetHSL(0,0,(vnoise(x*150,y*150,z*150)-.5)*.05);
  if(hm>.1){const u=(z-.07)/.05,f=u-Math.floor(u);sc.lerp(K.seam,sstep(.16,0,f)*.8*hm);}
  if(tm>.1){const u=(-z-.28+x*.4)/.07,f=u-Math.floor(u);sc.lerp(K.seam,sstep(.18,0,f)*.8*tm);}
  const sk=K.skin.clone().lerp(K.skinL,sstep(.1,.7,nz)*sstep(.5,.25,y)*sstep(.18,.08,Math.abs(x))*.7+sstep(.2,.9,ny)*.15).lerp(K.skinD,(1-ao)*.4).offsetHSL(0,0,(vnoise(x*9,y*9,z*9)-.5)*.05);
  sk.lerp(K.skinL,sstep(.012,0,A.minD(/^T:(snout)/,x,y,z))*sstep(-.2,-.8,ny)*.5);
  sk.lerp(K.nose,sstep(.004,-.002,A.dist('T:nose',x,y,z)));const er=A.minD(/ear[LR]:/,x,y,z);if(er<.006)sk.copy(K.ear).lerp(K.earIn,sstep(.1,.6,nz)*.75);
  const cl=A.minD(/:claw/,x,y,z);sk.lerp(K.claw,sstep(.004,-.002,cl));sk.lerp(K.clawT,sstep(.004,-.002,cl)*sstep(.2,.1,y)*.2);
  // wrinkled skin folds on the belly
  sk.lerp(K.skinD,sstep(.7,.95,Math.abs(Math.sin(y*80+vnoise(x*8,y*8,z*8)*3)))*sstep(.1,.5,nz)*sstep(.5,.2,y)*.25);
  c.copy(sk).lerp(sc,sstep(.1,.6,arm));return 0;},
 accessories(A){const G=new THREE.Group();const PB=(c,o={})=>new THREE.MeshPhysicalMaterial(Object.assign({color:c,roughness:.5},o));const add=(geo,m,p,r,s,par=G,bone)=>{const o=new THREE.Mesh(geo,m);if(p)o.position.set(...p);if(r)o.rotation.set(...r);if(s)o.scale.set(...s);o.castShadow=o.receiveShadow=true;if(bone)o.userData.bone=bone;par.add(o);return o;};
  // small grumpy eyes set low, under a heavy brow
  const ic=document.createElement('canvas');ic.width=ic.height=128;{const x=ic.getContext('2d');const g=x.createRadialGradient(64,64,0,64,64,64);g.addColorStop(0,'#0C0808');g.addColorStop(.5,'#0C0808');g.addColorStop(.58,'#3A2A4A');g.addColorStop(.88,'#7A6A9A');g.addColorStop(1,'#2A1E36');x.fillStyle=g;x.fillRect(0,0,128,128);}
  const it=new THREE.CanvasTexture(ic);it.colorSpace=THREE.SRGBColorSpace;const irisM=PB(0xffffff,{map:it,roughness:.12,clearcoat:1,clearcoatRoughness:.05});const lidM=PB(COL.skinD,{roughness:.85});
  const hit=(dir,ctr,off=0)=>{const d=new THREE.Vector3(...dir).normalize(),c=new THREE.Vector3(...ctr);let t=.6;for(let i=0;i<220;i++){const p=c.clone().addScaledVector(d,t);const s=A.sdf(p.x,p.y,p.z);if(s<.0008)break;t-=Math.max(s*.8,.0008);}const p=c.clone().addScaledVector(d,t);const e=.002;const n=new THREE.Vector3(A.sdf(p.x+e,p.y,p.z)-A.sdf(p.x-e,p.y,p.z),A.sdf(p.x,p.y+e,p.z)-A.sdf(p.x,p.y-e,p.z),A.sdf(p.x,p.y,p.z+e)-A.sdf(p.x,p.y,p.z-e)).normalize();return{p:p.addScaledVector(n,off),n};};
  for(const s of[-1,1]){const e=new THREE.Group();e.name=s<0?'eye_L':'eye_R';e.userData.bone='head';{const h=hit([s*.55,.05,1],[0,.645,.14],-.009);e.position.copy(h.p);}e.rotation.set(0,s*.45,0);G.add(e);
   const eg=new THREE.SphereGeometry(.025,28,18);{const uv=eg.attributes.uv,p=eg.attributes.position;for(let i=0;i<p.count;i++){if(p.getZ(i)<.004)uv.setXY(i,0,0);else uv.setXY(i,.5+p.getX(i)/.042,.5+p.getY(i)/.042);}}add(eg,irisM,null,null,[1,1,.8],e);
   const lid=add(new THREE.SphereGeometry(.0275,24,10,0,Math.PI*2,0,Math.PI*.38),lidM,[0,.001,0],[-.4,0,s*.3],null,e);lid.name='lid';
   const sp=new THREE.Mesh(new THREE.SphereGeometry(.0045,10,8),new THREE.MeshBasicMaterial({color:0xffffff}));sp.position.set(-.006,.006,.017);e.add(sp);}
  // Matter mark: a violet crystal hexagon set into the helm, glowing faintly
  const glow=PB(0xB8A2FF,{roughness:.1,transmission:.4,thickness:.02,emissive:0x6A48E0,emissiveIntensity:.8,clearcoat:1});
  {const hx=new THREE.Mesh(new THREE.CylinderGeometry(.022,.022,.012,6),glow);{const h=hit([0,.8,1],[0,.7,.14],.002);hx.position.copy(h.p);hx.quaternion.setFromUnitVectors(new THREE.Vector3(0,1,0),h.n);}hx.userData.bone='head';G.add(hx);const rim=add(new THREE.TorusGeometry(.024,.004,6,6),PB(0x6A5A7A,{metalness:.6,roughness:.4}),[0,0,0],[Math.PI/2,0,Math.PI/6],null,hx);}
  // miner's lamp strapped to the helm (breaker gear)
  {const lp=new THREE.Group();lp.userData.bone='head';{const h=hit([.35,.7,1],[0,.7,.14],.006);lp.position.copy(h.p);lp.lookAt(h.p.clone().add(h.n).add(new THREE.Vector3(0,-.3,.6)));}G.add(lp);const brass=PB(0xC89A4A,{metalness:1,roughness:.35});
   add(new THREE.CylinderGeometry(.024,.028,.036,16),brass,[0,0,.004],[Math.PI/2,0,0],null,lp);add(new THREE.CircleGeometry(.021,16),PB(0xFFF0C0,{emissive:0xFFC060,emissiveIntensity:1.6}),[0,0,.0225],null,null,lp);
   add(new THREE.TorusGeometry(.024,.004,6,16),brass,[0,0,.022],null,null,lp);}
  // pick head at the tip of the tail: iron-banded stone with two points
  {const pk=new THREE.Group();pk.name='pick';pk.userData.bone='tail';pk.position.set(.33,.12,-.585);pk.rotation.set(0,-1.35,0);G.add(pk);const rock=PB(0x6E6886,{roughness:.8,flatShading:true}),iron=PB(0x4A4656,{metalness:.8,roughness:.45}),tip=PB(0x8A86A0,{metalness:.6,roughness:.35});
   const hd=new THREE.IcosahedronGeometry(.055,1);{const p=hd.attributes.position;for(let i=0;i<p.count;i++){const v=new THREE.Vector3().fromBufferAttribute(p,i);v.multiplyScalar(.85+h3(v.x*9,v.y*9,v.z*9,3)*.3);p.setXYZ(i,v.x,v.y,v.z);}hd.computeVertexNormals();}add(hd,rock,[0,0,-.02],null,[1.05,.9,1],pk);
   for(const s of[-1,1]){add(new THREE.ConeGeometry(.036,.14,7),rock,[0,s*.09,-.02],[s<0?Math.PI:0,0,s*.25],[1,1,.85],pk);add(new THREE.ConeGeometry(.014,.045,7),tip,[s*.02,s*.16,-.02],[s<0?Math.PI:0,0,s*.25],null,pk);}
   add(new THREE.TorusGeometry(.05,.009,8,20),iron,[0,0,.012],null,null,pk);add(new THREE.TorusGeometry(.04,.007,8,20),iron,[0,0,.035],null,null,pk);
   for(let k=0;k<4;k++)add(new THREE.SphereGeometry(.006,8,6),PB(0xB8B0C8,{metalness:1,roughness:.3}),[Math.cos(k*1.57+.78)*.05,Math.sin(k*1.57+.78)*.05,.018],null,null,pk);}
  // chips flying from a pound (ability)
  const chips=new THREE.Group();chips.userData.bone='tail';chips.userData.fx='chips';chips.userData.fxMode='show';chips.position.set(.35,.06,-.6);G.add(chips);const cm=PB(0xB8B0C8,{roughness:.9,flatShading:true});
  for(let k=0;k<10;k++){const a=k/10*TAU;add(new THREE.TetrahedronGeometry(.012+(k%3)*.006,0),cm,[Math.cos(a)*(.06+(k%4)*.03),.02+(k%3)*.04,Math.sin(a)*(.06+(k%4)*.03)],[k,k*2,0],null,chips);}
  return G;}};
export const S=makeSculpt(def);
const J={root:[null,[0,0,0]],hips:['root',[0,.3,-.02]],chest:['hips',[0,.5,.04]],head:['chest',[0,.63,.12]],earL:['head',[-.08,.76,.11]],earR:['head',[.08,.76,.11]],
 shL:['chest',[-.2,.52,.1]],elL:['shL',[-.27,.39,.15]],haL:['elL',[-.29,.27,.18]],shR:['chest',[.2,.52,.1]],elR:['shR',[.27,.39,.15]],haR:['elR',[.29,.27,.18]],
 thL:['hips',[-.14,.25,-.04]],knL:['thL',[-.14,.16,-.01]],ftL:['knL',[-.145,.08,.01]],thR:['hips',[.14,.25,-.04]],knR:['thR',[.14,.16,-.01]],ftR:['knR',[.145,.08,.01]],tail:['hips',[0,.26,-.28]]};
const cfg={name:'quarryback',J,TIP:{haL:[-.3,.18,.28],haR:[.3,.18,.28],ftL:[-.145,.01,.16],ftR:[.145,.01,.16]},
 TORSO:{hips:[[0,.14,-.04],[0,.42,-.06],.3],chest:[[0,.44,0],[0,.62,-.02],.27],head:[[0,.6,.2],[0,.76,.15],.14]},
 AIM:[['shL','elL',[-.22,-1,.25]],['elL','haL',[-.08,-1,.3]],['shR','elR',[.22,-1,.25]],['elR','haR',[.08,-1,.3]]],floor:.008,pivot:.3,shMin:-1.6,
 springs:[['earL','vy',-.5,140,10,0,.35],['earR','vy',-.5,135,10,0,.35],['tail','vy',-.35,120,9,0,.35]]};
const RK=makeRigKit(S,cfg);export const makeRig=RK.makeRig,skinGeo=RK.skinGeo;
export const CLIPS=stdClips({w:.62,arm:.32,x:{
 idle:{label:'Idle',len:4.2,f:t=>{const b=Math.sin(t*TAU/4.2)*.5+.5;const huff=bump(t%4.2,3,3.4);return{sq:b*.012-huff*.02,hx:.1+Math.sin(t*.8)*.03+huff*.08,hz:Math.sin(t*.45)*.04,elx:-.1,eye:blink(t,4.2,.8)*(1-huff*.4),b:{chest:[-b*.03,0,0],shL:[Math.sin(t*1.2)*.03,0,-.04],shR:[Math.sin(t*1.2+1)*.03,0,.04],elL:[-.3,0,0],elR:[-.3,0,0],tail:[.05+Math.sin(t*1.1)*.04,Math.sin(t*.7)*.12,0]}};}},
 ability:{label:'Pound',len:2.2,f:t=>{const u=cyc(t,2.2);const brace=sstep(0,.18,u)*(1-sstep(.85,1,u)),lift=sstep(.1,.34,u)*(1-sstep(.5,.55,u)),slam=sstep(.48,.54,u)*(1-sstep(.75,.95,u)),imp=bump(u,.52,.66);
  return{y:-.03*brace-imp*.02,sq:-.05*brace-imp*.08,rx:.12*brace+.12*lift-.05*imp,hx:.12*brace,elx:-.2,eye:imp>.3?.2:.8,chips:imp,rz:Math.sin(u*60)*.02*imp,
   b:{tail:[2.3*lift-.25*slam,0,0],thL:[-.4*brace,0,-.2*brace],knL:[.6*brace,0,0],thR:[-.4*brace,0,.2*brace],knR:[.6*brace,0,0],shL:[-.3*brace,0,-.35*brace],shR:[-.3*brace,0,.35*brace],elL:[-.5*brace,0,0],elR:[-.5*brace,0,0],chest:[-.1*lift+.15*imp,0,0]}};}},
 nap:{label:'Nap',len:4.4,f:t=>{const b=Math.sin(t*TAU/4.4)*.5+.5;return{y:-.12,sq:-.1+b*.02,rx:.55,hx:.55,hz:.05,elx:.3,eye:.05,b:{thL:[-1.5,0,-.2],knL:[2,0,0],ftL:[-.3,0,0],thR:[-1.5,0,.2],knR:[2,0,0],ftR:[-.3,0,0],shL:[-1.1,0,.35],elL:[-1.1,0,0],shR:[-1.1,0,-.35],elR:[-1.1,0,0],chest:[.5+b*.03,0,0],tail:[-.4,.9,0]}};}},
 work:{label:'Work loop',len:1.8,f:t=>{const u=cyc(t,1.8);const dig=Math.sin(t*TAU/.45);const bend=.8;return{y:-.05,rx:.28,hx:.35,elx:-.2,eye:u>.8&&u<.86?.15:.85,b:{chest:[.45,0,0],hips:[.15,0,0],shL:[-1.1+.55*dig,0,-.1],shR:[-1.1-.55*dig,0,.1],elL:[-.6-.3*Math.max(0,dig),0,0],elR:[-.6-.3*Math.max(0,-dig),0,0],thL:[-.5,0,0],knL:[.8,0,0],thR:[-.5,0,0],knR:[.8,0,0],tail:[.1,Math.sin(t*3)*.2,0]}};}},
 celebrate:{label:'Celebrate',len:2,f:t=>{const u=cyc(t,2);const nod=bump(u,.05,.35),hop=bump(u,.4,.7),th=bump(u,.7,.85);return{y:hop*.08,sq:hop*.04-th*.06,hx:.3*nod-.15*hop,hz:.1*nod,elx:-.2,eye:nod>.4?.3:1,chips:th*.6,b:{shL:[-1.2*hop,0,-.3*hop],shR:[-1.2*hop,0,.3*hop],elL:[-.5,0,0],elR:[-.5,0,0],thL:[-.4*hop,0,0],knL:[.6*hop,0,0],thR:[-.4*hop,0,0],knR:[.6*hop,0,0],tail:[1.2*hop-.3*th,0,0]}};}}}});
export const EXPR={
 grumpy:{label:'Grumpy',hx:.12,hz:.06,eye:.62,b:{shL:[0,0,.05],shR:[0,0,-.05],elL:[-.9,0,.3],elR:[-.9,0,-.3]}},
 focus:{label:'Focused',hx:.25,eye:.5,eyeW:1.02,b:{chest:[.15,0,0],shL:[-.4,0,-.2],shR:[-.4,0,.2],elL:[-.5,0,0],elR:[-.5,0,0]}},
 startled:{label:'Startled',hx:-.2,elx:-.4,eye:1.15,eyeW:1.06,b:{shL:[-.4,0,-.45],shR:[-.4,0,.45],elL:[-.4,0,0],elR:[-.4,0,0],tail:[.5,0,0]}},
 caught:{label:'Caught',hx:.45,hz:.1,elx:.4,elz:.3,eye:.55,b:{shL:[.1,0,.12],shR:[.1,0,-.12],chest:[.25,0,0],tail:[-.3,0,0]}}};
export const build=o=>S.build(o),loadBaked=(u,r)=>S.loadBaked(u,r);
export const BIN='quarryback.bin?v=4',RES=.0068,GAME_SCALE=1.1;
export const EMBERS=[['earL',[-.08,.86,.1]],['earR',[.08,.86,.1]],['tail',[0,.17,-.76]]];
export const ROUTE=[{to:[1.3,-.5],clip:'walk',sp:.26},{at:true,clip:'work',dur:5.4,face:[2,-1]},{to:[-.8,1.1],clip:'walk',sp:.26},{at:true,clip:'ability',dur:2.2,face:[1,3]},{at:true,clip:'idle',dur:3,face:[1,3]},{to:[.2,.2],clip:'carry',sp:.22},{at:true,clip:'nap',dur:4.4,face:[2,2]}];
export const HERO={cam:[2.1,.95,2.05],target:[.03,.4,-.12],clip:'idle'};
