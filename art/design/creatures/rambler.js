import * as THREE from 'three';
import {makeSculpt,makeRigKit,stdClips,sstep,vnoise,clamp,ease,bump,blink,cyc,TAU,merge,gait} from './creature-kit.js';
// ============ RAMBLER · Breaker · Motion · stocky ram-horned ball, 0.9 m, gold and brown (GDD 11.4) ============
const COL={wool:0xDDAA58,woolL:0xF2D596,woolD:0x8E5A26,woolS:0x7A4A22,face:0x5E3A28,faceL:0x86563A,muzzle:0xC89A74,nose:0x3A2226,hoof:0x3A2A26,hoofL:0x6A5448,ear:0x8A5A40,earIn:0xE8A088,mouth:0x4A2228};
const K=Object.fromEntries(Object.entries(COL).map(([k,v])=>[k,new THREE.Color(v)]));
const mir=(p,s)=>[p[0]*s,p[1],p[2]];
const h3=(x,y,z,s)=>{const v=Math.sin(x*127.1+y*311.7+z*74.7+s*19.19)*43758.5453;return v-Math.floor(v);};
const cell=(x,y,z)=>{const xi=Math.floor(x),yi=Math.floor(y),zi=Math.floor(z);let d1=9,d2=9,id=0;for(let i=-1;i<=1;i++)for(let j=-1;j<=1;j++)for(let k=-1;k<=1;k++){const cx=xi+i,cy=yi+j,cz=zi+k;const px=cx+h3(cx,cy,cz,1)-x,py=cy+h3(cx,cy,cz,2)-y,pz=cz+h3(cx,cy,cz,3)-z;const d=px*px+py*py+pz*pz;if(d<d1){d2=d1;d1=d;id=h3(cx,cy,cz,4);}else if(d<d2)d2=d;}return[Math.sqrt(d1),Math.sqrt(d2),id];};
// bare face: the front of the head below the wool cap
const faceM=(x,y,z)=>{if(!A0)return 0;const hd=A0.minD(/^T:(skull|jaw|muzzle|chin|cheek|brow|nose|sock|mouth)/,x,y,z);return Math.max(sstep(.13,.2,z+Math.abs(x)*.25)*sstep(.73,.67,y+(vnoise(x*14,y*14,z*14)-.5)*.03)*sstep(.47,.52,y+sstep(.1,.2,z)*.03)*sstep(.03,.012,hd),sstep(.19,.23,z)*sstep(.685,.665,y)*sstep(.5,.53,y)*sstep(.17,.145,Math.abs(x)));};
let A0=null;const bare=(x,y,z)=>{if(!A0)return 0;const f=faceM(x,y,z);const l=Math.max(sstep(.034,.016,A0.minD(/:hoof|:foot|:heel|:cleft/,x,y,z)),sstep(.028,.012,A0.minD(/:arm2|:shin/,x,y,z))*sstep(.3,.24,y),sstep(.03,.012,A0.minD(/ear[LR]:/,x,y,z)));return Math.max(f,l);};
const def={name:'rambler',box:[[-.44,0,-.42],[.44,.86,.46]],res:.0068,warm:0x5A2A10,aoWarm:.2,sheen:0xFFE6B0,rim:0xFFE0A0,bodyMat:{roughness:.9,sheen:.32,sheenRoughness:.7},fur:{len:.011,dens:[1300,1000,1300],shells:7},
 sculpt(A){const{E,C}=A;A0=A;
  // one round woolly ball: body, chest and the wool cap merge into a single silhouette
  E('T:body',[0,.34,-.05],[.3,.26,.29],null,.09);E('T:chest',[0,.43,.09],[.24,.21,.21],null,.09);E('T:rump',[0,.3,-.2],[.22,.19,.16],null,.08);
  E('T:skull',[0,.61,.13],[.19,.165,.175],null,.07);E('T:wooltop',[0,.72,.07],[.2,.1,.17],null,.07);E('T:fringe',[0,.705,.2],[.14,.05,.07],null,.05);
  // wide jaw and short muzzle
  E('T:jaw',[0,.515,.21],[.17,.085,.12],null,.06);E('T:muzzle',[0,.555,.295],[.105,.075,.075],[-.15,0,0],.045);E('T:chin',[0,.495,.28],[.07,.04,.05],null,.035);
  E('T:nose',[0,.585,.36],[.05,.03,.02],[-.3,0,0],.015);
  for(const s of[-1,1]){const L=s<0?'L':'R';
   E('T:cheek'+L,[s*.12,.555,.24],[.07,.06,.06],null,.04);E('T:brow'+L,[s*.07,.655,.265],[.055,.022,.03],[0,0,-s*.25],.03);
   E('T:sock'+L,[s*.075,.618,.286],[.03,.026,.02],null,.012,'s');
   // floppy ears poking out sideways under the horns
   E('ear'+L+':ear',[s*.21,.6,.08],[.075,.026,.042],[0,s*.25,-s*.5],.025);
   // short arms ending in cloven hooves
   const sh=mir([.23,.44,.09],s),el=mir([.29,.31,.13],s),wr=mir([.31,.21,.16],s);C('sh'+L+':arm1',sh,el,.085,.07,.06);C('el'+L+':arm2',el,wr,.058,.05,.035);
   E('ha'+L+':hoof',mir([.315,.175,.175],s),[.056,.05,.062],null,.025);E('ha'+L+':cleft',mir([.315,.16,.235],s),[.004,.035,.03],null,.004,'s');
   // tiny sturdy legs
   E('th'+L+':haunch',mir([.13,.2,-.03],s),[.11,.11,.12],null,.06);C('kn'+L+':shin',mir([.13,.14,.0],s),mir([.135,.075,.02],s),.062,.055,.035);
   E('ft'+L+':foot',mir([.135,.036,.055],s),[.066,.036,.082],null,.025);E('ft'+L+':cleft',mir([.135,.03,.125],s),[.004,.03,.035],null,.004,'s');E('ft'+L+':heel',mir([.135,.045,-.005],s),[.05,.03,.04],null,.02);}
  E('tail:tail',[0,.36,-.33],[.065,.06,.05],null,.04);},
 disp(x,y,z,d){if(Math.abs(d)>.03)return d;const b=bare(x,y,z);
  // curly fleece: overlapping domed curls with deep gaps between them
  const[c1,c2]=cell(x*15+vnoise(x*5,y*5,z*5)*1.2,y*18,z*15);const dome=Math.sqrt(Math.max(0,1-c1*c1*2.2));const curl=dome*.011-sstep(.1,0,c2-c1)*.004;const sw=Math.sin(c1*34+Math.atan2(y*18%1-.5,x*15%1-.5)*2)*.0011*dome;const clump=(vnoise(x*5,y*5,z*5)-.5)*.006;
  return d-(curl+sw+clump+(vnoise(x*70,y*70,z*70)-.5)*.0012)*(1-b)-(vnoise(x*50,y*50,z*50)-.5)*.0012*b;},
 paint(x,y,z,nx,ny,nz,ao,c,A){const b=bare(x,y,z),f=faceM(x,y,z);
  const[c1,c2,id]=cell(x*15+vnoise(x*5,y*5,z*5)*1.2,y*18,z*15);const gap=sstep(.12,0,c2-c1);const ring=Math.max(0,Math.sin(c1*34+Math.atan2(y*18%1-.5,x*15%1-.5)*2));
  c.copy(K.wool).lerp(K.woolL,sstep(.2,.9,ny)*.3+sstep(.45,.05,c1)*.22).offsetHSL((id-.5)*.02,(id-.5)*.04,(id-.5)*.05);c.lerp(K.woolD,gap*.85+(1-ao)*.4+ring*.12*sstep(.1,.4,c1));c.lerp(K.woolS,sstep(-.2,-.8,ny)*.35);
  const fc=K.face.clone().lerp(K.faceL,sstep(.2,.9,ny)*.4+sstep(.25,.33,z)*.25+(vnoise(x*30,y*30,z*30)-.5)*.06);fc.lerp(K.nose,sstep(.02,.004,A.minD(/:sock/,x,y,z))*.35);
  fc.lerp(K.muzzle,sstep(.012,-.004,Math.min(A.dist('T:muzzle',x,y,z),A.dist('T:chin',x,y,z)))*.9);
  fc.lerp(K.nose,sstep(.004,-.002,A.dist('T:nose',x,y,z)));fc.lerp(K.mouth,sstep(.006,.001,Math.abs(y-.518-(x*x*9-.004)))*sstep(.3,.33,z)*sstep(.058,.035,Math.abs(x))*.9);
  const hf=A.minD(/:hoof|:foot|:heel|:cleft/,x,y,z)-.018;const lg=A.minD(/:arm2|:shin/,x,y,z)-.014;const er=A.minD(/ear[LR]:/,x,y,z)-.014;
  if(er<.006){fc.copy(K.ear);fc.lerp(K.earIn,sstep(.1,.6,nz)*sstep(.04,.012,Math.abs(y-.6))*.7);}
  if(lg<.006&&hf>.004)fc.copy(K.face).lerp(K.faceL,.2);
  if(hf<.004){const lo=sstep(.2,.1,y)*sstep(.06,.01,y)+sstep(.22,.14,y)*sstep(.12,.17,y);fc.lerp(K.hoof,sstep(.004,-.01,hf)*(.55+.45*sstep(-.1,-.6,ny))).lerp(K.hoofL,sstep(.4,.95,ny)*.25);}
  c.lerp(fc,b);return (1-b)*(1-gap*.45)*(.8+.2*sstep(.3,.6,c1));},
 accessories(A){const G=new THREE.Group();const PB=(c,o={})=>new THREE.MeshPhysicalMaterial(Object.assign({color:c,roughness:.5},o));const add=(geo,m,p,r,s,par=G,bone)=>{const o=new THREE.Mesh(geo,m);if(p)o.position.set(...p);if(r)o.rotation.set(...r);if(s)o.scale.set(...s);o.castShadow=o.receiveShadow=true;if(bone)o.userData.bone=bone;par.add(o);return o;};
  const hit=(dir,ctr,off=0)=>{const d=new THREE.Vector3(...dir).normalize(),c=new THREE.Vector3(...ctr);let t=1;for(let i=0;i<220;i++){const p=c.clone().addScaledVector(d,t);const s=A.sdf(p.x,p.y,p.z);if(s<.0008)break;t-=Math.max(s*.8,.0008);}const p=c.clone().addScaledVector(d,t);const e=.002;const n=new THREE.Vector3(A.sdf(p.x+e,p.y,p.z)-A.sdf(p.x-e,p.y,p.z),A.sdf(p.x,p.y+e,p.z)-A.sdf(p.x,p.y-e,p.z),A.sdf(p.x,p.y,p.z+e)-A.sdf(p.x,p.y,p.z-e)).normalize();return{p:p.addScaledVector(n,off),n};};
  // eyes: big and cheerful, amber with a stubborn lid
  const ic=document.createElement('canvas');ic.width=ic.height=128;{const x=ic.getContext('2d');const g=x.createRadialGradient(64,64,0,64,64,64);g.addColorStop(0,'#140A04');g.addColorStop(.4,'#140A04');g.addColorStop(.48,'#7A4A10');g.addColorStop(.82,'#D89A30');g.addColorStop(1,'#4A2A08');x.fillStyle=g;x.fillRect(0,0,128,128);}
  const it=new THREE.CanvasTexture(ic);it.colorSpace=THREE.SRGBColorSpace;const irisM=PB(0xffffff,{map:it,roughness:.12,clearcoat:1,clearcoatRoughness:.05});const lidM=PB(COL.face,{roughness:.85});
  for(const s of[-1,1]){const e=new THREE.Group();e.name=s<0?'eye_L':'eye_R';e.userData.bone='head';e.position.set(s*.075,.62,.268);e.rotation.set(0,s*.35,0);G.add(e);
   const eg=new THREE.SphereGeometry(.029,32,20);{const uv=eg.attributes.uv,p=eg.attributes.position;for(let i=0;i<p.count;i++){if(p.getZ(i)<.004)uv.setXY(i,0,0);else uv.setXY(i,.5+p.getX(i)/.048,.5+p.getY(i)/.048);}}add(eg,irisM,null,null,[1,.94,.72],e);
   const lid=add(new THREE.SphereGeometry(.032,28,12,0,Math.PI*2,0,Math.PI*.34),lidM,[0,.001,0],[-.86,0,s*.22],null,e);lid.name='lid';const lo=add(new THREE.SphereGeometry(.0305,28,10,0,Math.PI*2,Math.PI*.72,Math.PI*.28),lidM,[0,-.001,-.002],[.1,0,0],[1,1,.85],e);lo.name='lidLo';
   for(const[r,x,y]of[[.0075,-.009,.011],[.0035,.01,-.008]]){const sp=new THREE.Mesh(new THREE.SphereGeometry(r,10,8),new THREE.MeshBasicMaterial({color:0xffffff}));sp.position.set(x,y,.025);e.add(sp);}}
  // curled ram horns with growth ridges
  const hornM=PB(0xD8BE8E,{roughness:.5,clearcoat:.5,clearcoatRoughness:.35}),hornD=0x6E4E2C;
  for(const s of[-1,1]){const pts=[];const N=80,base=new THREE.Vector3(s*.1,.735,.1),ctr=new THREE.Vector3(s*.215,.63,.035);
   for(let i=0;i<=N;i++){const u=i/N,a=Math.PI*.62-u*TAU*1.12;const r=.108*(1-u*.62);pts.push(new THREE.Vector3(ctr.x+s*(Math.cos(a)*.18)*r/.108*.5+s*u*.035,ctr.y+Math.sin(a)*r,ctr.z+Math.cos(a)*r*.95));}
   pts[0].lerp(base,.85);const cu=new THREE.CatmullRomCurve3(pts);const R=24,geo=new THREE.TubeGeometry(cu,N*2,1,R,false);const p=geo.attributes.position,cols=[];const fr=cu.computeFrenetFrames(N*2,false);const col=new THREE.Color();
   for(let i=0;i<=N*2;i++){const u=i/(N*2),q=cu.getPointAt(u);const rad=.052*Math.pow(1-u,.8)+.006;const ridge=1+Math.pow(Math.max(0,Math.sin(u*110)),3)*.11;for(let j=0;j<=R;j++){const k=i*(R+1)+j,v=j/R*TAU;const nn=fr.normals[i].clone().multiplyScalar(-Math.cos(v)).add(fr.binormals[i].clone().multiplyScalar(Math.sin(v)));const flat=1-.18*Math.pow(Math.max(0,Math.cos(v*2)),3);p.setXYZ(k,q.x+nn.x*rad*ridge*flat,q.y+nn.y*rad*ridge*flat,q.z+nn.z*rad*ridge*flat);col.set(0xffffff).lerp(new THREE.Color(hornD),Math.pow(Math.max(0,Math.sin(u*110-.9)),2)*.55+Math.pow(u,1.6)*.45+(1-Math.abs(Math.cos(v)))*.08);cols.push(col.r,col.g,col.b);}}
   geo.setAttribute('color',new THREE.Float32BufferAttribute(cols,3));geo.computeVertexNormals();const hm=hornM.clone();hm.vertexColors=true;const h=add(geo,hm,null,null,null,G,'head');h.name='horn_'+(s<0?'L':'R');
   add(new THREE.SphereGeometry(.05,16,12),hm,[pts[0].x,pts[0].y,pts[0].z],null,[1,.8,1],G,'head');}
  // breaker's brass brow guard, riveted, with the Motion chevron
  const brass=PB(0xD9A84A,{metalness:1,roughness:.32}),brassD=PB(0x8A6424,{metalness:1,roughness:.45}),leather=PB(0x6A3A22,{roughness:.8});
  {const h=hit([0,.35,1],[0,.66,.13],.015);const gd=new THREE.Group();gd.userData.bone='head';gd.position.set(0,h.p.y,h.p.z);gd.rotation.set(-Math.asin(Math.max(-.9,Math.min(.9,h.n.y))),0,0);G.add(gd);
   const sh=new THREE.Shape();sh.moveTo(-.075,-.025);sh.quadraticCurveTo(0,-.045,.075,-.025);sh.lineTo(.062,.035);sh.quadraticCurveTo(0,.055,-.062,.035);sh.closePath();const pg=new THREE.ExtrudeGeometry(sh,{depth:.008,bevelEnabled:true,bevelThickness:.004,bevelSize:.004,bevelSegments:3,curveSegments:16});{const pp=pg.attributes.position;for(let i=0;i<pp.count;i++){const x=pp.getX(i);pp.setZ(i,pp.getZ(i)-x*x*2.6);}pg.computeVertexNormals();}add(pg,brass,[0,0,-.004],null,null,gd);
   for(const[x,y]of[[-.058,-.018],[.058,-.018],[-.05,.028],[.05,.028]])add(new THREE.SphereGeometry(.0055,10,8),brassD,[x,y,.012-x*x*2.6],null,null,gd);
   const cv=new THREE.Shape();cv.moveTo(-.03,.012);cv.lineTo(0,-.016);cv.lineTo(.03,.012);cv.lineTo(.03,.026);cv.lineTo(0,-.002);cv.lineTo(-.03,.026);cv.closePath();add(new THREE.ExtrudeGeometry(cv,{depth:.003,bevelEnabled:true,bevelThickness:.0015,bevelSize:.0015,bevelSegments:2}),PB(0xFFE6A0,{metalness:.6,roughness:.25,emissive:0x5A3A00,emissiveIntensity:.25}),[0,-.002,.014],null,null,gd);
   // leather strap running back over the wool behind the horns
   for(const s of[-1,1]){const pts=[];for(let i=0;i<=12;i++){const u=i/12,a=s*(.35+u*1.15);const r=.212;pts.push(new THREE.Vector3(Math.sin(a)*r*.95,.672+Math.sin(u*Math.PI)*.02,.13+Math.cos(a)*r-.2+.02));}const cu=new THREE.CatmullRomCurve3(pts);add(new THREE.TubeGeometry(cu,24,.009,6),leather,null,null,[1,.55,1],G,'head');}}
  // dust trail kicked up while charging (ability)
  const dust=new THREE.Group();dust.userData.bone='root';dust.userData.fx='dust';dust.userData.fxMode='show';dust.position.set(0,.02,-.3);G.add(dust);const dm=PB(0xE8D2A8,{roughness:1,transparent:true,opacity:.5,depthWrite:false});
  for(let k=0;k<9;k++){const r=.05+(k%3)*.022;add(new THREE.IcosahedronGeometry(r,2),dm,[((k*37)%7-3)*.045,.02+(k%3)*.035,-k*.055],null,null,dust);}
  return G;}};
export const S=makeSculpt(def);
const J={root:[null,[0,0,0]],hips:['root',[0,.3,0]],chest:['hips',[0,.43,.05]],head:['chest',[0,.55,.12]],earL:['head',[-.19,.6,.09]],earR:['head',[.19,.6,.09]],
 shL:['chest',[-.23,.44,.09]],elL:['shL',[-.29,.31,.13]],haL:['elL',[-.31,.21,.16]],shR:['chest',[.23,.44,.09]],elR:['shR',[.29,.31,.13]],haR:['elR',[.31,.21,.16]],
 thL:['hips',[-.13,.22,-.03]],knL:['thL',[-.13,.14,0]],ftL:['knL',[-.135,.075,.02]],thR:['hips',[.13,.22,-.03]],knR:['thR',[.13,.14,0]],ftR:['knR',[.135,.075,.02]],tail:['hips',[0,.34,-.3]]};
const cfg={name:'rambler',J,TIP:{haL:[-.315,.13,.2],haR:[.315,.13,.2],ftL:[-.135,.01,.13],ftR:[.135,.01,.13]},
 TORSO:{hips:[[0,.12,-.04],[0,.36,-.02],.28],chest:[[0,.4,.04],[0,.5,.08],.24],head:[[0,.52,.18],[0,.74,.1],.2]},
 AIM:[['shL','elL',[-.25,-1,.2]],['elL','haL',[-.1,-1,.25]],['shR','elR',[.25,-1,.2]],['elR','haR',[.1,-1,.25]]],floor:.008,pivot:.3,shMin:-1.6,
 springs:[['earL','vy',-.9,110,7,0,.6],['earR','vy',-.9,105,7,0,.6],['tail','vy',-.6,160,9,0,.5]]};
const RK=makeRigKit(S,cfg);export const makeRig=RK.makeRig,skinGeo=RK.skinGeo;
export const CLIPS=stdClips({w:.55,arm:.38,x:{
 idle:{label:'Idle',len:3.6,f:t=>{const b=Math.sin(t*TAU/1.8)*.5+.5;const nod=bump(t%3.6,2.2,2.6);return{sq:b*.02,y:b*.004,hx:.05+nod*.25+Math.sin(t*1.7)*.03,hz:Math.sin(t*.9)*.06,elx:-.1,eye:blink(t,3.6,.4),b:{chest:[-b*.04,0,0],shL:[Math.sin(t*1.6)*.05,0,-.05],shR:[Math.sin(t*1.6+1)*.05,0,.05],elL:[-.25,0,0],elR:[-.25,0,0],thL:[0,0,-.04],thR:[0,0,.04]}};}},
 ability:{label:'Charge',len:2.4,f:t=>{const u=cyc(t,2.4);const wind=bump(u,0,.28),go=sstep(.24,.32,u)*(1-sstep(.8,.92,u)),hitB=bump(u,.8,.9);const ph=cyc(t,.26);const g=gait(ph,{leg:.9,knee:1.2,arm:.2,twist:.04});
  const B=merge(go>0?g:{},{chest:[.14*go+.1*wind,0,0],hips:[.05*go,0,0],thL:[-.5*wind,0,0],knL:[.7*wind,0,0],thR:[.3*wind,0,0],shL:[-.9*go+.4*wind,0,-.15],shR:[-.9*go+.4*wind,0,.15],elL:[-.9*go-.3,0,0],elR:[-.9*go-.3,0,0]});
  return{z:-.12*wind+go*sstep(.24,.8,u)*.55-hitB*.06,y:go*Math.abs(Math.sin(ph*TAU))*.03,sq:-.08*wind+hitB*-.12,rx:.2*go+.08*wind-.15*hitB,hx:.28*go+.18*wind,rz:-.06*wind,elx:.4*go,eye:go?.7:1,eyeW:go?1.05:1,dust:go,b:B};}},
 nap:{label:'Nap',len:4,f:t=>{const b=Math.sin(t*TAU/4)*.5+.5;return{y:-.1,sq:-.08+b*.03,rx:.2,hx:.45+b*.03,hz:.1,elx:.4,eye:.08,b:{thL:[-1.5,0,-.2],knL:[2,0,0],ftL:[-.3,0,0],thR:[-1.5,0,.2],knR:[2,0,0],ftR:[-.3,0,0],shL:[-.9,0,.4],elL:[-1.2,0,0],shR:[-.9,0,-.4],elR:[-1.2,0,0],chest:[.35+b*.03,0,0]}};}},
 work:{label:'Work loop',len:2.6,f:t=>{const u=cyc(t,2.6);const back=bump(u,0,.45),butt=bump(u,.45,.62),rec=sstep(.62,1,u);return{z:-back*.05+butt*.06,rx:-.12*back+.3*butt,hx:-.2*back+.55*butt,sq:-butt*.1,eye:butt>.5?.25:1,elx:.3*butt,b:{chest:[-.15*back+.3*butt,0,0],thL:[-.3*back,0,0],knL:[.4*back,0,0],thR:[.2*back,0,0],shL:[-.2*butt,0,-.2*butt],shR:[-.2*butt,0,.2*butt],elL:[-.3,0,0],elR:[-.3,0,0]}};}},
 celebrate:{label:'Celebrate',len:1.6,f:t=>{const u=cyc(t,1.6);const j=bump(u,.05,.5),j2=bump(u,.55,.95);const air=j+j2*.7;return{y:j*.2+j2*.12,sq:air*.06-bump(u,.47,.56)*.14-bump(u,.93,1)*.1,rx:-.1*j,hx:-.2*j+.3*j2,hz:Math.sin(t*8)*.08,elx:-.4*air,eye:u>.15&&u<.3?.2:1,b:{shL:[-1.05*j,0,-.3*j],shR:[-1.05*j,0,.3*j],elL:[-.7,0,0],elR:[-.7,0,0],thL:[-.8*air,0,0],knL:[1.2*air,0,0],thR:[-.8*air,0,0],knR:[1.2*air,0,0]}};}}}});
export const EXPR={
 cheeky:{label:'Cheerful',hz:-.12,hx:.05,eye:.9,elx:-.2,b:{shL:[-.2,0,-.2],shR:[-.2,0,.2]}},
 stubborn:{label:'Stubborn',hx:.3,eye:.6,eyeW:1.04,b:{chest:[.2,0,0],shL:[.2,0,-.15],shR:[.2,0,.15],elL:[-.8,0,0],elR:[-.8,0,0]}},
 startled:{label:'Startled',hx:-.2,elx:-.5,eye:1.2,eyeW:1.08,b:{shL:[-.5,0,-.5],shR:[-.5,0,.5],elL:[-.4,0,0],elR:[-.4,0,0]}},
 caught:{label:'Sorry',hx:.4,hz:.1,elx:.5,elz:.3,eye:.6,b:{shL:[-.4,0,.3],shR:[-.4,0,-.3],elL:[-1,0,0],elR:[-1,0,0],chest:[.2,0,0]}}};
export const build=o=>S.build(o),loadBaked=(u,r)=>S.loadBaked(u,r);
export const BIN='rambler.bin?v=4',RES=.0068,GAME_SCALE=1.1;
export const EMBERS=[['head',[-.22,.66,.02]],['head',[.22,.66,.02]],['tail',[0,.36,-.37]]];
export const ROUTE=[{to:[1.2,-.4],clip:'walk',sp:.3},{at:true,clip:'work',dur:5.2,face:[2,-1]},{to:[-1.2,.6],clip:'run',sp:.6},{at:true,clip:'ability',dur:2.4,face:[1,.6]},{at:true,clip:'celebrate',dur:1.6,face:[0,1]},{to:[.2,.4],clip:'carry',sp:.24},{at:true,clip:'nap',dur:4,face:[1,2]}];
export const HERO={cam:[1.25,.8,2.8],target:[0,.42,0],clip:'idle'};
