import * as THREE from 'three';
import {makeSculpt,makeRigKit,stdClips,sstep,vnoise,clamp,ease,bump,blink,cyc,TAU,merge,gait} from './creature-kit.js';
// ============ FEATHERKIN · Scout · Motion · owl-like sprite with a feather cape, 0.6 m, gold and cream (GDD 11.4) ============
const COL={gold:0xE9A93A,honey:0xFFD27A,amber:0xB86A1E,deep:0x7A3E14,cream:0xFFF2DE,creamS:0xF4DDB4,beak:0x5E5260,skin:0xD8A890,claw:0x3A2A30,blue:0x5AB4EC};
const K=Object.fromEntries(Object.entries(COL).map(([k,v])=>[k,new THREE.Color(v)]));
const mir=(p,s)=>[p[0]*s,p[1],p[2]];
const fpat=(x,y,z)=>{const hd=sstep(.5,.6,y);const fr=21+hd*20;const ang=Math.atan2(x,z),row=y*fr+Math.sin(ang*3)*.25,rf=row-Math.floor(row),cf=(((ang*(3.8+hd*4.2)+Math.floor(row)*.5)%1)+1)%1;const u=cf-.5;const sc=rf+.55*Math.pow(Math.abs(u)*2,2);return{rf,u,sc,edge:sstep(.78,.96,sc)};};
const def={name:'featherkin',box:[[-.5,0,-.36],[.5,1.12,.36]],res:.0078,warm:0x9A4A18,sheen:0xFFF0D0,rim:0xBFE4FF,fur:{len:.0026,dens:[820,640,820],shells:0},
 sculpt({E,C,along}){
  E('T:belly',[0,.3,.01],[.19,.2,.18],null,.06);
  E('T:chest',[0,.44,.04],[.18,.14,.165],null,.07);
  E('T:skull',[0,.66,.02],[.24,.225,.215],null,.08);
  E('T:crown',[0,.8,-.01],[.17,.08,.15],null,.06);
  for(const s of[-1,1]){const L=s<0?'L':'R';
   E('T:disc'+L,[s*.088,.64,.192],[.128,.14,.062],[0,s*.3,-s*.05],.045);
   E('T:brow'+L,[s*.082,.722,.238],[.078,.016,.026],[0,s*.32,-s*.1],.022);
   E('T:cheek'+L,[s*.2,.57,.08],[.06,.05,.06],[0,0,s*.5],.04);
   E('T:sock'+L,[s*.104,.632,.262],[.07,.07,.05],null,.02,'s');
   // ear tufts (feathered)
   const tp=[[.12,.83,.01],[.165,.9,-.02],[.215,.955,-.06],[.255,.985,-.1]].map(p=>mir(p,s));const W=[.062,.056,.04,.014];
   for(let i=0;i<3;i++){const a=tp[i],b=tp[i+1];const c=[(a[0]+b[0])/2,(a[1]+b[1])/2,(a[2]+b[2])/2];const L2=Math.hypot(b[0]-a[0],b[1]-a[1],b[2]-a[2]);E((i?'ear'+L+'2':'ear'+L)+':tuft'+i,c,[.018,L2*.66,(W[i]+W[i+1])/2],along(a,b,s*.5),.03);}
   // wing (A-posed): upper, forearm, blade, primaries
   const sh=mir([.17,.49,0],s),el=mir([.28,.39,-.02],s),wr=mir([.35,.29,0],s),tip=mir([.41,.16,.0],s);
   C('sh'+L+':wing1',sh,el,.066,.05,.05);C('el'+L+':wing2',el,wr,.05,.034,.03);
   E('el'+L+':blade',[(el[0]+tip[0])/2,(el[1]+tip[1])/2,-.01],[.024,.13,.075],along(el,tip),.03);
   for(let k=0;k<3;k++){const a=[wr[0]+s*.004*k,wr[1]-.02,-.04+k*.035],b=[wr[0]+s*(.05+.006*k),wr[1]-.15+k*.012,-.045+k*.04];E('ha'+L+':prim'+k,[(a[0]+b[0])/2,(a[1]+b[1])/2,(a[2]+b[2])/2],[.013,.078,.026],along(a,b),.014);}
   // feathered legs + talons
   E('th'+L+':thigh',mir([.075,.17,.03],s),[.078,.075,.078],null,.05);C('kn'+L+':shin',mir([.08,.14,.04],s),mir([.082,.07,.05],s),.032,.026,.03);
   E('ft'+L+':foot',mir([.082,.045,.075],s),[.04,.022,.05],null,.02);
   for(let k=0;k<3;k++){const o=(k-1)*.028;C('ft'+L+':toe'+k,mir([.082,.045,.08],s),mir([.082+o,.026,.14-Math.abs(k-1)*.008],s),.016,.01,.012);}
   C('ft'+L+':toeB',mir([.082,.045,.06],s),mir([.082,.03,.012],s),.014,.009,.012);}
  C('T:beak',[0,.638,.262],[0,.588,.29],.025,.006,.012);E('T:beakTop',[0,.628,.268],[.023,.025,.02],null,.012);
  for(const[x,y,z]of[[0,.505,.19],[-.055,.475,.18],[.055,.475,.18],[0,.455,.2]])E('T:ruff'+x+y,[x,y,z],[.046,.03,.02],[.3,0,0],.03);
  for(let k=0;k<5;k++){const a=[0,.22,-.15],b=[(k-2)*.04,.1,-.25];E('tail:fan'+k,[(a[0]+b[0])/2,(a[1]+b[1])/2,(a[2]+b[2])/2],[.02,.07,.011],along(a,b),.02);}
 },
 disp:(x,y,z,d)=>d+(vnoise(x*34,y*34,z*34)-.5)*.003,
 disp(x,y,z,d){if(Math.abs(d)>.02)return d;const FP=fpat(x,y,z);const lay=(sstep(.35,.96,FP.sc)*.0052-sstep(.965,1,FP.sc)*.0046-sstep(.1,0,FP.sc)*.0012);return d-lay*(y>.52?sstep(.2,.13,z):1)*(1-sstep(.8,.6,Math.hypot(x/.15,(y-.32)/.2,(z-.16)/.11))*.6);},
 paint(x,y,z,nx,ny,nz,ao,c,A){const d=n=>A.dist(n,x,y,z);c.copy(K.gold);
  const FP=fpat(x,y,z),rf=FP.rf,sc=FP.sc,edge=FP.edge,cf=FP.u+.5;
  const back=clamp(sstep(.3,-.2,nz)+sstep(.7,.86,y)*.8+sstep(.2,.5,Math.abs(nx))*.6,0,1)*(1-sstep(.012,-.006,Math.min(d('T:discL'),d('T:discR'))));c.lerp(K.amber,sstep(.55,.1,sc)*.42*back);c.lerp(K.honey,edge*.72*back);c.lerp(K.deep,sstep(.035,.008,Math.abs(FP.u))*sstep(.1,.7,sc)*.35*back*(1-edge));const barb=Math.sin((rf*26+Math.abs(FP.u)*34)*1.0);c.lerp(K.amber,sstep(.55,1,barb)*.14*back*(1-edge));c.lerp(K.deep,sstep(.965,.995,sc)*.45*back);c.lerp(K.deep,sstep(.14,0,sc)*.38*back);c.lerp(K.cream,sstep(.88,.955,sc)*sstep(.97,.95,sc)*.35*back);
  const fd=Math.min(d('T:discL'),d('T:discR'));const face=sstep(.01,-.006,fd)*sstep(.16,.21,z)*sstep(-.2,.3,nz);c.lerp(K.cream,face);
  {const ex=x-(x<0?-.104:.104),ey=y-.632;const ra=Math.atan2(ey,ex),rr=Math.hypot(ex,ey);const rad=sstep(.55,1,Math.sin(ra*26+rr*40)*.5+.5)*sstep(.07,.12,rr);c.lerp(K.creamS,face*rad*.45);c.lerp(K.honey,face*sstep(.1,.16,rr)*.35);c.lerp(K.amber,sstep(.016,.0,Math.abs(fd-.004))*sstep(.14,.19,z)*.45);}
  c.lerp(K.cream,sstep(.008,-.004,Math.min(d('T:browL'),d('T:browR'))));
  const bel=Math.hypot(x/.15,(y-.32)/.2,(z-.16)/.11),bm=sstep(1.1,.8,bel)*sstep(-.1,.3,nz);c.lerp(K.cream,bm*.95);
  const bar=sstep(.8,.93,(y*19+Math.abs(x)*7)%1)*sstep(.03,.06,Math.abs(((x*14)%1+1)%1-.5));c.lerp(K.amber,bar*bm*.5*sstep(.46,.38,y));
  c.lerp(K.creamS,sstep(.01,-.004,A.minD(/^T:ruff/,x,y,z))*.85);
  const bk=Math.min(d('T:beak'),d('T:beakTop'));const bkm=sstep(.004,-.002,bk);c.lerp(K.beak,bkm);c.lerp(K.claw,bkm*sstep(.61,.59,y)*.6);
  const tf=A.minD(/:tuft/,x,y,z);if(tf<.012){const m=sstep(.012,0,tf),tip=sstep(.9,.99,y);c.lerp(K.honey,m*(1-tip)*.4);c.lerp(K.amber,m*tip*.8);c.lerp(K.cream,m*sstep(.3,.6,nz)*.25);}
  const pr=A.minD(/:prim/,x,y,z);if(pr<.01){const m=sstep(.01,-.002,pr);c.lerp(K.amber,m*.65);c.lerp(K.cream,m*sstep(.72,.88,(y*26)%1)*.45);}
  const wb=A.minD(/:blade|:wing/,x,y,z);if(wb<.006)c.lerp(K.honey,edge*.35);
  const pants=sstep(.008,-.004,A.minD(/^(th|kn)[LR]:/,x,y,z));c.lerp(K.creamS,pants*.85);
  const toe=A.minD(/:toe|:foot/,x,y,z),tm=sstep(.004,-.002,toe);c.lerp(K.skin,tm);c.lerp(K.claw,tm*Math.max(sstep(.125,.14,z),sstep(.03,.015,z)));
  const tl=A.minD(/^tail:/,x,y,z);if(tl<.006){c.lerp(K.amber,.35);c.lerp(K.honey,sstep(.7,.86,(y*28)%1)*.5);}
  return tm>.5||bkm>.5?0:face>.5?.55:pr<.004?.35:1;},
 accessories(A){const G=new THREE.Group();const PB=(c,o={})=>new THREE.MeshPhysicalMaterial(Object.assign({color:c,roughness:.5},o));const add=(geo,m,p,r,s,par=G,bone)=>{const o=new THREE.Mesh(geo,m);if(p)o.position.set(...p);if(r)o.rotation.set(...r);if(s)o.scale.set(...s);o.castShadow=o.receiveShadow=true;if(bone)o.userData.bone=bone;par.add(o);return o;};
  const proj=(x,y,off=.0025)=>{let z=.45;for(let i=0;i<200;i++){const d=A.sdf(x,y,z);if(d<.0005)break;z-=Math.max(d*.8,.0008);}const e=.002;const nx=A.sdf(x+e,y,z)-A.sdf(x-e,y,z),ny=A.sdf(x,y+e,z)-A.sdf(x,y-e,z),nz=A.sdf(x,y,z+e)-A.sdf(x,y,z-e);const l=Math.hypot(nx,ny,nz)||1;return new THREE.Vector3(x+nx/l*off,y+ny/l*off,z+nz/l*off);};
  // eyes: big, set low and wide in the facial disc
  const ic=document.createElement('canvas');ic.width=ic.height=256;{const x=ic.getContext('2d');const g=x.createRadialGradient(128,128,0,128,128,128);g.addColorStop(0,'#0A0604');g.addColorStop(.42,'#0A0604');g.addColorStop(.47,'#6A3A0C');g.addColorStop(.66,'#E8A628');g.addColorStop(.86,'#F6CE5A');g.addColorStop(.95,'#8A4E12');g.addColorStop(1,'#3A1E08');x.fillStyle=g;x.fillRect(0,0,256,256);for(let i=0;i<48;i++){const a=Math.random()*6.28;x.strokeStyle='rgba(255,236,170,'+(.05+Math.random()*.1)+')';x.lineWidth=1.5;x.beginPath();x.moveTo(128+Math.cos(a)*62,128+Math.sin(a)*62);x.lineTo(128+Math.cos(a)*112,128+Math.sin(a)*112);x.stroke();}}
  const it=new THREE.CanvasTexture(ic);it.colorSpace=THREE.SRGBColorSpace;const irisM=PB(0xffffff,{map:it,roughness:.2});
  for(const s of[-1,1]){const e=new THREE.Group();e.name=s<0?'eye_L':'eye_R';e.userData.bone='head';e.position.set(s*.104,.632,.235);e.rotation.set(-.05,s*.3,0);e.scale.set(1,1,.8);G.add(e);
   add(new THREE.SphereGeometry(.056,40,28),PB(0xFFF6E8,{roughness:.3,clearcoat:.8,clearcoatRoughness:.12}),null,null,null,e);
   const ig=new THREE.SphereGeometry(.045,40,24,0,Math.PI*2,0,Math.PI*.5);ig.rotateX(Math.PI/2);{const uv=ig.attributes.uv,p=ig.attributes.position;for(let i=0;i<p.count;i++)uv.setXY(i,.5+p.getX(i)/.098,.5+p.getY(i)/.098);}add(ig,irisM,[s*-.002,-.003,.02],null,[1,1.02,1],e);
   add(new THREE.TorusGeometry(.056,.0048,12,48),PB(0x6A4024,{roughness:.6}),[0,0,.01],null,[1,1,.7],e);{const lg=new THREE.SphereGeometry(.0605,40,20,0,Math.PI*2,0,Math.PI*.3);lg.rotateX(-.35);add(lg,PB(COL.creamS,{roughness:.8,sheen:.5}),null,null,[1,1,.95],e).name='lid';}
   for(const[r,x,y]of[[.009,-.013,.016],[.0042,.012,-.011]]){const sp=new THREE.Mesh(new THREE.SphereGeometry(r,12,8),new THREE.MeshBasicMaterial({color:0xffffff}));sp.position.set(x,y,.054);e.add(sp);}}
  // Motion chevron on the forehead
  const blue=PB(COL.blue,{roughness:.45,sheen:.6});const ch=add(new THREE.TubeGeometry(new THREE.CatmullRomCurve3([proj(-.055,.79),proj(-.028,.772),proj(0,.756),proj(.028,.772),proj(.055,.79)],false,'catmullrom',.1),24,.0105,8),blue);ch.name='motion_chevron';ch.userData.bone='head';
  // feather cape: four staggered rows around the back, split so it can spread
  const fg=(len,w=.085)=>{const sh=new THREE.Shape();sh.moveTo(0,0);sh.bezierCurveTo(w*.62,-len*.08,w*.58,-len*.72,0,-len);sh.bezierCurveTo(-w*.58,-len*.72,-w*.62,-len*.08,0,0);const g=new THREE.ExtrudeGeometry(sh,{depth:.005,bevelEnabled:true,bevelThickness:.003,bevelSize:.0028,bevelSegments:2,curveSegments:10});g.translate(0,0,-.0025);{const p=g.attributes.position;for(let i=0;i<p.count;i++){const u=-p.getY(i)/len,xx=p.getX(i)/w;p.setZ(i,p.getZ(i)-u*u*len*.22+xx*xx*.012);}g.computeVertexNormals();}
   const p=g.attributes.position,cl=new Float32Array(p.count*3),c=new THREE.Color();for(let i=0;i<p.count;i++){const u=-p.getY(i)/len,cx=Math.abs(p.getX(i))/(w*.5);c.copy(K.gold).lerp(K.amber,sstep(.3,0,Math.abs(cx))*.5).lerp(K.amber,sstep(.7,1,Math.abs(cx))*.35).lerp(K.honey,sstep(.72,.9,u)*.6).lerp(K.cream,sstep(.9,1,u)*.7);cl.set([c.r,c.g,c.b],i*3);}g.setAttribute('color',new THREE.BufferAttribute(cl,3));return g;};
  const capeM=A.rimize(PB(0xffffff,{vertexColors:true,roughness:.82,sheen:.35,sheenColor:new THREE.Color(0xFFE6B0),side:THREE.DoubleSide}),0x8FC8F0,.2);
  const ROWS=[[.63,.232,.1,9,1.45,.1],[.56,.255,.14,11,1.66,.1],[.47,.258,.17,12,1.72,.13],[.375,.262,.19,13,1.76,.16],[.28,.262,.2,14,1.78,.18]];
  ROWS.forEach(([y0,R,len,n,sp,fl],ri)=>{const g=fg(len,.088);for(let k=0;k<n;k++){const a=Math.PI-sp+2*sp*k/(n-1)+(ri%2?sp/(n-1):0)*.5;const jr=Math.sin(k*12.9+ri*7.3);const o=add(g,capeM,[Math.sin(a)*R,y0+jr*.008,Math.cos(a)*R]);o.rotation.set(0,a,0);o.rotateX(-fl-jr*.03);o.rotateZ((k-(n-1)/2)*.025+jr*.06);o.scale.set(1+jr*.06,1+jr*.08,1);o.userData.bone=a<Math.PI-.5?'capeR':a>Math.PI+.5?'capeL':'capeC';o.name='cape_feather';}});
  // cord + clasp
  const gold=PB(0xD9B86A,{metalness:1,roughness:.3});add(new THREE.TorusGeometry(.215,.009,8,64,Math.PI*1.6),PB(0x7A4A2A,{roughness:.6}),[0,.545,.0],[Math.PI/2,0,Math.PI*1.7],[1,.9,1],G,'chest').name='cape_cord';
  add(new THREE.TorusGeometry(.024,.007,10,28),gold,[0,.535,.205],[.1,0,0],null,G,'chest');const gem=add(new THREE.SphereGeometry(.019,20,14),PB(COL.blue,{roughness:.1,clearcoat:1,metalness:.1}),[0,.535,.208],null,[1,1,.6],G,'chest');gem.name='clasp';
  // scout spyglass on a strap
  const cu=new THREE.CatmullRomCurve3([[.16,.5],[.11,.46],[.055,.42],[0,.38],[-.055,.345],[-.11,.31],[-.155,.28]].map(([x,y])=>proj(x,y,.006)));
  const stc=document.createElement('canvas');stc.width=64;stc.height=128;{const x=stc.getContext('2d');const g=x.createLinearGradient(0,0,64,0);g.addColorStop(0,'#4A2A16');g.addColorStop(.18,'#7A4A2A');g.addColorStop(.5,'#8A5632');g.addColorStop(.82,'#7A4A2A');g.addColorStop(1,'#4A2A16');x.fillStyle=g;x.fillRect(0,0,64,128);x.fillStyle='#E8C890';for(let i=0;i<8;i++){x.fillRect(9,i*16+4,3,8);x.fillRect(52,i*16+4,3,8);}}
  const stt=new THREE.CanvasTexture(stc);stt.colorSpace=THREE.SRGBColorSpace;stt.wrapT=THREE.RepeatWrapping;
  {const N=60,W=.013,T=.0028,pos=[],uv=[],idx=[];const L=cu.getLength();for(let i=0;i<=N;i++){const u=i/N,p=cu.getPoint(u),t=cu.getTangent(u);const n=new THREE.Vector3(p.x,(p.y-.42)*.3,p.z+.03).normalize();const bn=new THREE.Vector3().crossVectors(t,n).normalize();const v=u*L*14;for(const[s,h]of[[-1,1],[1,1],[1,-1],[-1,-1]]){const q=p.clone().addScaledVector(bn,W*s).addScaledVector(n,T*h);pos.push(q.x,q.y,q.z);uv.push(s<0?0:1,v);}if(i<N){const k=i*4;for(let f2=0;f2<4;f2++){const a2=k+f2,b2=k+(f2+1)%4,c2=a2+4,d2=b2+4;idx.push(a2,c2,b2,b2,c2,d2);}}}
   const g=new THREE.BufferGeometry();g.setAttribute('position',new THREE.Float32BufferAttribute(pos,3));g.setAttribute('uv',new THREE.Float32BufferAttribute(uv,2));g.setIndex(idx);g.computeVertexNormals();add(g,PB(0xffffff,{map:stt,roughness:.62,sheen:.3}),null,null,null,G,'chest').name='strap';}
  const brass=PB(0xE0B860,{metalness:1,roughness:.26}),brassD=PB(0xA8802E,{metalness:1,roughness:.35}),lea=PB(0x4A2A18,{roughness:.7}),glass=PB(0x9ED8F0,{roughness:0,clearcoat:1,metalness:.2});
  {const bp=cu.getPoint(.62),bn2=cu.getTangent(.62);const bk=new THREE.Group();bk.userData.bone='chest';bk.position.copy(bp);bk.lookAt(bp.clone().add(new THREE.Vector3(bp.x,(bp.y-.42)*.3,bp.z+.03)));bk.rotateZ(Math.atan2(bn2.y,bn2.x));G.add(bk);add(new THREE.TorusGeometry(.017,.0032,8,4,Math.PI*2),brass,[0,0,.004],[0,0,Math.PI/4],[1,1.35,1],bk);add(new THREE.BoxGeometry(.003,.03,.004),brass,[0,0,.005],null,null,bk);}
  const sg=new THREE.Group();sg.name='binoculars';sg.userData.bone='hips';sg.position.set(-.19,.25,.14);sg.rotation.set(.15,.25,.3);G.add(sg);
  for(const s of[-1,1]){const bx=s*.022;add(new THREE.CylinderGeometry(.0165,.0185,.054,28),lea,[bx,0,0],null,null,sg);add(new THREE.CylinderGeometry(.0195,.0195,.012,28),brass,[bx,-.031,0],null,null,sg);add(new THREE.TorusGeometry(.0185,.0026,10,28),brassD,[bx,-.037,0],[Math.PI/2,0,0],null,sg);add(new THREE.CircleGeometry(.0155,24),glass,[bx,-.0375,0],[Math.PI/2,0,0],null,sg);
   add(new THREE.CylinderGeometry(.0105,.0135,.02,24),brass,[bx,.037,0],null,null,sg);add(new THREE.CylinderGeometry(.0112,.0112,.008,24),lea,[bx,.05,0],null,null,sg);add(new THREE.CircleGeometry(.008,20),glass,[bx,.0545,0],[-Math.PI/2,0,0],null,sg);
   for(const yy of[-.012,.012])add(new THREE.TorusGeometry(.0172,.0012,6,28),brassD,[bx,yy,0],[Math.PI/2,0,0],null,sg);}
  add(new THREE.BoxGeometry(.03,.012,.01),brass,[0,.03,0],null,null,sg);add(new THREE.CylinderGeometry(.006,.006,.03,16),brassD,[0,.03,0],[0,0,Math.PI/2],null,sg);add(new THREE.CylinderGeometry(.0075,.0075,.008,16),brass,[0,.046,0],null,null,sg);
  add(new THREE.TorusGeometry(.007,.0018,8,16),brass,[-.041,.028,0],null,null,sg);
  return G;}};
export const S=makeSculpt(def);
const J={root:[null,[0,0,0]],hips:['root',[0,.3,0]],chest:['hips',[0,.44,.03]],head:['chest',[0,.56,.03]],
 earL:['head',[-.12,.83,.01]],earL2:['earL',[-.165,.9,-.02]],earR:['head',[.12,.83,.01]],earR2:['earR',[.165,.9,-.02]],
 shL:['chest',[-.17,.49,0]],elL:['shL',[-.28,.39,-.02]],haL:['elL',[-.35,.29,0]],shR:['chest',[.17,.49,0]],elR:['shR',[.28,.39,-.02]],haR:['elR',[.35,.29,0]],
 thL:['hips',[-.075,.19,.03]],knL:['thL',[-.08,.14,.04]],ftL:['knL',[-.082,.06,.05]],thR:['hips',[.075,.19,.03]],knR:['thR',[.08,.14,.04]],ftR:['knR',[.082,.06,.05]],
 tail:['hips',[0,.23,-.14]],capeL:['chest',[-.13,.56,-.1]],capeR:['chest',[.13,.56,-.1]],capeC:['chest',[0,.57,-.14]]};
const cfg={name:'featherkin',J,TIP:{haL:[-.41,.16,0],haR:[.41,.16,0],ftL:[-.082,.026,.14],ftR:[.082,.026,.14]},
 TORSO:{hips:[[0,.1,0],[0,.36,.02],.17],chest:[[0,.38,.03],[0,.5,.04],.15],head:[[0,.56,.03],[0,.86,.01],.22]},
 AIM:[['shL','elL',[-.32,-1,-.04]],['elL','haL',[-.14,-1,.06]],['shR','elR',[.32,-1,-.04]],['elR','haR',[.14,-1,.06]]],floor:.006,pivot:.22,shMin:-2.2,shMax:1.2,
 springs:[['earL','vy',-.8,150,10,0,.55],['earR','vy',-.8,140,10,0,.55],['earL2','wy',-.12,120,9,2,.5],['earR2','wy',.12,110,8,2,.5],['tail','vy',-.6,200,12,0,.5],['capeC','vy',-.5,110,9,0,.45],['capeL','vy',-.4,100,8,2,.35],['capeR','vy',.4,100,8,2,.35],['capeC','t',.04,50,6,0,.08,2.1],['capeL','t',.03,50,6,2,.06,1.7]]};
const RK=makeRigKit(S,cfg);export const makeRig=RK.makeRig,skinGeo=RK.skinGeo;
const glide=t=>{const u=cyc(t,2.2);const up=bump(u,0,.25),air=clamp(sstep(.12,.3,u)-sstep(.78,.95,u),0,1),land=bump(u,.84,1);const fl=Math.sin(t*16)*.12*up;return{y:air*.28+up*.05-land*.04,z:air*.12,rx:.1+air*.32-land*.15,rz:Math.sin(t*1.6)*.08*air,sq:up*.06-land*.1,hx:-.15*air,elx:-.5*air,elz:.15,eye:1.05,
 b:{shL:[-.15*air,0,-1.45*air-fl],shR:[-.15*air,0,1.45*air+fl],elL:[.1*air,0,0],elR:[.1*air,0,0],haL:[0,0,-.2*air],haR:[0,0,.2*air],capeL:[-.1*air,0,-.85*air],capeR:[-.1*air,0,.85*air],capeC:[-.55*air,0,0],thL:[.6*air-.8*land,0,0],knL:[.9*air+1*land,0,0],thR:[.6*air-.8*land,0,0],knR:[.9*air+1*land,0,0],ftL:[.5*air,0,0],ftR:[.5*air,0,0],tail:[-.4*air,0,0]}};};
export const CLIPS=stdClips({w:.1,arm:.2,x:{
 idle:{label:'Idle',len:4,f:t=>{const b=Math.sin(t*Math.PI*.9)*.5+.5;const tw=bump(t%4,2.4,2.8);return{sq:b*.016,hx:Math.sin(t*1.4)*.03,hz:Math.sin(t*.7)*.08+tw*.25,elx:-.05-tw*.3,elz:.06,eye:blink(t,4,.5),b:{chest:[-b*.03,0,0],shL:[0,0,-.04-b*.04],shR:[0,0,.04+b*.04],elL:[-.12,0,0],elR:[-.12,0,0],capeC:[-b*.05,0,0]}};}},
 idle2:{label:'Idle 2',len:5,f:t=>{const u=cyc(t,5);const look=u<.25?ease(u/.25):u<.45?1:u<.7?1-2*ease((u-.45)/.25):u<.85?-1:-1+ease((u-.85)/.15);const tilt=bump(u,.28,.42)-bump(u,.72,.84);return{hy:look*1.05,hz:tilt*.4,elx:-.1-Math.abs(tilt)*.3,elz:.1,eye:blink(t,2.5,.2)*(1+Math.abs(tilt)*.12),b:{shL:[0,0,-.05],shR:[0,0,.05],elL:[-.12,0,0],elR:[-.12,0,0],chest:[0,look*.08,0]}};}},
 walk:{label:'Walk',len:.72,f:t=>{const ph=cyc(t,.72);const bob=Math.abs(Math.cos(ph*TAU));return{y:bob*.014,rx:.04,rz:Math.sin(ph*TAU)*.09,hz:-Math.sin(ph*TAU)*.06,hx:-.02,hy:Math.sin(ph*TAU)*.06,elz:.1,eye:blink(t,3.3),b:merge(gait(ph,{leg:.55,knee:.7,arm:.14,sway:.09,twist:.05}),{shL:[0,0,-.08],shR:[0,0,.08],capeC:[-bob*.08,0,0]})};}},
 run:{label:'Run',len:.42,f:t=>{const ph=cyc(t,.42);const fly=Math.abs(Math.sin(ph*TAU));const fl=Math.sin(t*22)*.2;return{y:.012+fly*.06,sq:fly*.03,rx:.3,rz:Math.sin(ph*TAU)*.05,hx:-.2,elx:-.6,elz:.04,b:merge(gait(ph,{leg:.85,knee:1.3,arm:0,toe:.4,sway:.03}),{shL:[-.3,0,-.75-fl],shR:[-.3,0,.75+fl],elL:[-.2,0,0],elR:[-.2,0,0],capeL:[0,0,-.4],capeR:[0,0,.4],capeC:[-.45,0,0]})};}},
 ability:{label:'Glide',len:2.2,f:glide},
 celebrate:{label:'Celebrate',len:1.8,f:t=>{const u=cyc(t,1.8);const j=bump(u,0,.45)+bump(u,.5,.95);const fl=Math.sin(t*20)*.5;return{y:j*.22,ry:ease(clamp((u-.5)/.45,0,1))*TAU,sq:j*.06-bump(u,.43,.52)*.1,hz:Math.sin(t*6)*.12,elx:-.4,elz:.2,eye:u>.2&&u<.3?.2:1,b:{shL:[-.2,0,-1.1-fl*j],shR:[-.2,0,1.1+fl*j],capeL:[0,0,-.5*j],capeR:[0,0,.5*j],thL:[-.6*j,0,0],knL:[.9*j,0,0],thR:[-.6*j,0,0],knR:[.9*j,0,0]}};}},
 nap:{label:'Nap',len:4,f:t=>{const b=Math.sin(t*TAU/4)*.5+.5;return{y:-.04,sq:-.04+b*.03,hx:.22+b*.04,hz:.12,hy:.25,elx:.35,elz:.35,eye:.1,b:{shL:[0,0,.08],shR:[0,0,-.08],elL:[-.05,0,0],elR:[-.05,0,0],thL:[-.5,0,0],knL:[.9,0,0],thR:[-.5,0,0],knR:[.9,0,0],capeC:[.1,0,0],chest:[.1+b*.04,0,0]}};}},
 work:{label:'Work loop',len:1.6,f:t=>{const u=cyc(t,1.6);const pk=bump(u,.1,.28)+bump(u,.34,.5),look=bump(u,.6,.95);return{y:-pk*.02,hx:pk*.45,hy:look*.6,elx:-.1,elz:.1,eye:u>.82&&u<.88?.15:1,b:{chest:[.45*pk,0,0],hips:[.15*pk,0,0],shL:[-.3*pk,0,-.35*pk],shR:[-.3*pk,0,.35*pk],thL:[-.3*pk,0,0],knL:[.5*pk,0,0],thR:[-.3*pk,0,0],knR:[.5*pk,0,0]}};}},
 leap:{label:'Leap',len:1.6,f:t=>{const u=cyc(t,1.6);const cr=bump(u,0,.2)+bump(u,.8,.98),air=bump(u,.16,.82);const fl=Math.sin(t*18)*.35*air;return{y:air*.42-cr*.04,z:air*.1,sq:-cr*.1+air*.05,rx:-cr*.1+air*.15,hx:cr*.15-air*.1,elx:-.5*air,elz:.1,eye:1-cr*.2,b:{thL:[-1*cr+.5*air,0,0],knL:[1.4*cr+.8*air,0,0],thR:[-1*cr+.5*air,0,0],knR:[1.4*cr+.8*air,0,0],shL:[-.2*air,0,-1.2*air-fl],shR:[-.2*air,0,1.2*air+fl],capeL:[0,0,-.6*air],capeR:[0,0,.6*air],capeC:[-.4*air,0,0],chest:[.2*cr,0,0]}};}}}});
export const EXPR={
 curious:{label:'Curious',hz:.38,hx:-.05,elx:-.3,elz:.12,eye:1.08,b:{shL:[0,0,-.1],shR:[0,0,.1]}},
 focus:{label:'Focused',hx:.14,elx:.1,elz:-.1,eye:.62,eyeW:1.04,b:{shL:[-.2,0,-.15],shR:[-.2,0,.15]}},
 startled:{label:'Startled',hx:-.14,elx:-.6,elz:-.12,eye:1.2,eyeW:1.1,b:{shL:[-.2,0,-.8],shR:[-.2,0,.8],capeL:[0,0,-.3],capeR:[0,0,.3]}},
 caught:{label:'Caught',hx:.3,hz:.08,elx:.45,elz:.4,erz:-.4,eye:.7,b:{shL:[.1,0,.12],shR:[.1,0,-.12],chest:[.15,0,0],capeC:[.2,0,0]}}};
export const build=o=>S.build(o),loadBaked=(u,r)=>S.loadBaked(u,r);
export const BIN='featherkin.bin?v=4',RES=.0078,GAME_SCALE=.62;
export const EMBERS=[['earL2',[-.255,.985,-.1]],['earR2',[.255,.985,-.1]],['tail',[0,.1,-.25]]];
export const ROUTE=[{to:[.62,1.72],clip:'walk',sp:.34},{at:true,clip:'work',dur:3.2,face:[1.4,2.3]},{to:[-1.3,-.3],clip:'ability',sp:.9},{at:true,clip:'idle2',dur:4,face:[0,2]},{to:[.3,.5],clip:'run',sp:.9},{at:true,clip:'idle',dur:2.4,face:[3,4]}];
export const HERO={cam:[1.3,.85,2.9],target:[0,.56,0],clip:'idle'};
