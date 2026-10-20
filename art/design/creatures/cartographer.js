import * as THREE from 'three';
import {makeSculpt,makeRigKit,stdClips,sstep,vnoise,clamp,ease,bump,blink,cyc,TAU,merge,gait} from './creature-kit.js';
import {parts} from './creature-parts.js';
// ============ THE CARTOGRAPHER · Visitor · sells scouting maps · rides a small balloon draped in maps (GDD 11.7, 21.6) ============
// A round-eared mouse aviator in a teal flight coat, brass goggles on its brow, a spyglass in hand, standing in a wicker basket under a patchwork map balloon.
const COL={fur:0xC49A70,furL:0xE8C9A0,furD:0x6E4C30,cream:0xF6E8D0,creamD:0xD8C0A0,ear:0xF0A4A0,nose:0xE0706E,coat:0x2A7A8A,coatL:0x4AA8B4,coatD:0x16424C,brass:0xE9B65C,mouth:0x5A2420,tail:0xE6A29C};
const K=Object.fromEntries(Object.entries(COL).map(([k,v])=>[k,new THREE.Color(v)]));
const mir=(p,s)=>[p[0]*s,p[1],p[2]];let A0=null;
function mapTex(seed=7){const c=document.createElement('canvas');c.width=1024;c.height=512;const x=c.getContext('2d');let sd=seed;const R=()=>(sd=(sd*16807)%2147483647)/2147483647;
 const tones=['#EAD6AA','#DFC898','#F2E2BE','#D6BC88'];for(let i=0;i<8;i++){x.fillStyle=tones[i%4];x.fillRect(i*128,0,128,512);}
 for(let i=0;i<2600;i++){x.fillStyle='rgba(120,80,40,'+(R()*.06)+')';x.fillRect(R()*1024,R()*512,2+R()*5,2+R()*5);}
 x.strokeStyle='rgba(120,90,50,.16)';x.lineWidth=1;for(let i=0;i<=32;i++){x.beginPath();x.moveTo(i*32,0);x.lineTo(i*32,512);x.stroke();}for(let i=0;i<=32;i++){x.beginPath();x.moveTo(0,i*16);x.lineTo(1024,i*16);x.stroke();}
 for(let k=0;k<15;k++){const cx=R()*1024,cy=70+R()*372,r=16+R()*38,ph=R()*6;x.beginPath();for(let a=0;a<=28;a++){const t=a/28*TAU,rr=r*(.75+.22*Math.sin(t*3+ph)+.12*Math.sin(t*7+k));x.lineTo(cx+Math.cos(t)*rr*1.35,cy+Math.sin(t)*rr);}x.closePath();x.fillStyle='rgba(126,168,112,.5)';x.fill();x.strokeStyle='rgba(70,46,24,.85)';x.lineWidth=2.2;x.stroke();
  x.strokeStyle='rgba(70,110,150,.35)';x.lineWidth=1.2;x.beginPath();for(let a=0;a<=28;a++){const t=a/28*TAU,rr=(r+7)*(.75+.22*Math.sin(t*3+ph)+.12*Math.sin(t*7+k));x.lineTo(cx+Math.cos(t)*rr*1.35,cy+Math.sin(t)*rr);}x.stroke();}
 x.setLineDash([9,7]);x.strokeStyle='rgba(176,52,40,.85)';x.lineWidth=3;for(let k=0;k<5;k++){x.beginPath();x.moveTo(R()*1024,R()*512);x.bezierCurveTo(R()*1024,R()*512,R()*1024,R()*512,R()*1024,R()*512);x.stroke();}x.setLineDash([]);
 for(const [cx,cy,s] of [[190,250,1],[700,170,.8],[460,420,.6]]){x.save();x.translate(cx,cy);x.scale(s,s);x.fillStyle='rgba(66,38,18,.9)';for(let a=0;a<8;a++){x.rotate(Math.PI/4);x.beginPath();x.moveTo(0,a%2?-22:-38);x.lineTo(6,0);x.lineTo(-6,0);x.closePath();x.fill();}x.strokeStyle='rgba(66,38,18,.75)';x.lineWidth=2;x.beginPath();x.arc(0,0,24,0,TAU);x.stroke();x.restore();}
 x.strokeStyle='rgba(176,40,30,.95)';x.lineWidth=4;for(const [cx,cy] of [[430,320],[900,120],[80,90]]){x.beginPath();x.moveTo(cx-9,cy-9);x.lineTo(cx+9,cy+9);x.moveTo(cx+9,cy-9);x.lineTo(cx-9,cy+9);x.stroke();}
 x.strokeStyle='rgba(90,60,30,.6)';x.lineWidth=3;for(let i=0;i<=8;i++){x.beginPath();x.moveTo(i*128,0);x.lineTo(i*128,512);x.stroke();}
 const t=new THREE.CanvasTexture(c);t.colorSpace=THREE.SRGBColorSpace;t.anisotropy=4;t.wrapS=THREE.RepeatWrapping;return t;}
const def={name:'cartographer',box:[[-.27,0,-.25],[.27,.8,.25]],res:.0052,warm:0x2A1406,aoWarm:.2,sheen:0xFFE8C8,rim:0xBFEFFF,
 bodyMat:{roughness:.7,sheen:.45,sheenRoughness:.5},fur:{shells:0},
 sculpt(A){const{E,C}=A;A0=A;
  E('T:body',[0,.3,0],[.13,.15,.12],null,.06);E('T:belly',[0,.28,.05],[.1,.11,.08],null,.05);C('T:neck',[0,.4,0],[0,.45,.01],.075,.085,.05);
  E('T:head',[0,.55,.01],[.16,.145,.14],null,.06);E('T:muzzle',[0,.51,.12],[.07,.052,.052],[-.12,0,0],.04);E('T:nose',[0,.527,.172],[.021,.016,.016],null,.012);
  for(const s of[-1,1]){const L=s<0?'L':'R';E('T:cheek'+L,mir([.085,.5,.09],s),[.055,.045,.045],null,.035);
   // big round mouse ears with a soft cupped front
   E('ear'+L+':ear',mir([.13,.685,-.015],s),[.078,.078,.022],[0,s*.35,-s*.32],.012);E('ear'+L+':cup',mir([.136,.688,.004],s),[.058,.058,.012],[0,s*.35,-s*.32],.004,'s');
   const sh=mir([.12,.37,0],s),el=mir([.17,.29,.04],s),wr=mir([.18,.21,.08],s);C('sh'+L+':arm1',sh,el,.032,.026,.02);C('el'+L+':arm2',el,wr,.026,.021,.015);
   E('ha'+L+':palm',mir([.185,.19,.09],s),[.028,.024,.022],null,.012);for(let k=0;k<3;k++){const a=(k-1)*.5;C('ha'+L+':finger'+k,mir([.187,.175,.1],s),mir([.19+Math.sin(a)*.015,.15,.112],s),.009,.007,.005);}
   C('th'+L+':leg1',mir([.06,.2,0],s),mir([.07,.11,.01],s),.042,.034,.03);C('kn'+L+':leg2',mir([.07,.11,.01],s),mir([.072,.04,.02],s),.032,.026,.02);
   E('ft'+L+':foot',mir([.072,.024,.05],s),[.036,.02,.058],null,.015);}
  E('tail:root',[0,.2,-.11],[.03,.028,.025],null,.02);},
 disp(x,y,z,d){if(Math.abs(d)>.03)return d;const face=sstep(.03,.006,A0.minD(/^T:(muzzle|cheek|nose)/,x,y,z));
  return d+(1-face)*Math.pow(vnoise(x*70,y*30,z*70),2)*-.0014+(vnoise(x*140,y*140,z*140)-.5)*.0005;},
 paint(x,y,z,nx,ny,nz,ao,c,A){
  c.copy(K.fur).lerp(K.furL,sstep(.2,.95,ny)*.3+sstep(.3,.9,nz)*.1).lerp(K.furD,(1-ao)*.5+sstep(-.2,-.8,ny)*.15);c.lerp(K.furD,Math.pow(vnoise(x*50,y*20,z*50),3)*.25);
  const muz=sstep(.012,0,A.minD(/^T:(muzzle|cheek)/,x,y,z))*sstep(.06,.1,z)*sstep(.56,.53,y);c.lerp(K.cream,muz*.95);
  const bel=sstep(.004,-.001,A.dist('T:belly',x,y,z))*sstep(.05,.08,z);
  // teal flight coat, open at the front over a cream vest, with lighter lapels and cuffs
  const onBody=A.minD(/^T:(body|belly|neck)/,x,y,z)<.004&&y<.445&&y>.14;const vest=Math.abs(x)<.052&&z>.07&&y<.425;
  if(onBody&&!vest){c.copy(K.coat).lerp(K.coatL,sstep(.3,.9,ny)*.3+sstep(.2,.8,nz)*.1).lerp(K.coatD,(1-ao)*.55+sstep(-.1,-.8,ny)*.2);c.lerp(K.coatD,(vnoise(x*120,y*40,z*120)-.5)*.2+.1);
   if(Math.abs(Math.abs(x)-.058)<.012&&z>.06)c.lerp(K.coatL,.55);if(y>.405)c.lerp(K.coatL,.45);}
  else if(onBody&&vest)c.copy(K.cream).lerp(K.creamD,(1-ao)*.5+sstep(.2,-.6,ny)*.2);
  if(A.minD(/^(sh|el)[LR]:/,x,y,z)<.004){const cuf=A.minD(/^ha[LR]:/,x,y,z);c.copy(K.coat).lerp(K.coatL,sstep(.2,.9,ny)*.3).lerp(K.coatD,(1-ao)*.5);if(cuf<.03)c.lerp(K.coatL,.6);}
  if(A.minD(/^ha[LR]:/,x,y,z)<.003)c.copy(K.furL).lerp(K.furD,(1-ao)*.35);
  if(A.minD(/^ear[LR]:/,x,y,z)<.004){const s=x<0?-1:1;const r=Math.hypot(x-s*.136,y-.688);const fr=(z>-.005)?sstep(.06,.048,r):0;c.lerp(K.ear,fr*.9);c.lerp(K.furD,sstep(.07,.08,r)*.3);}
  if(A.dist('T:nose',x,y,z)<.004)c.copy(K.nose).lerp(new THREE.Color(0xFFC8C0),sstep(.4,.9,ny)*.4);
  if(z>.15&&Math.abs(x)<.034){const u=x/.034,cy=.477+.006*u*u;const dd=Math.abs(y-cy),w=.0024*(1-u*u*.5);if(dd<w)c.copy(K.mouth);else if(dd<w+.003)c.lerp(K.mouth,.35*(1-(dd-w)/.003));}
  if(z>.1&&y<.53&&y>.46)for(const s of[-1,1])for(let k=0;k<3;k++){const r=Math.hypot(x-s*(.04+k*.012),y-(.5-k*.008));c.lerp(K.furD,sstep(.004,.002,r)*.7);}
  for(const s of[-1,1])c.lerp(new THREE.Color(0xF08C84),sstep(.03,0,Math.hypot(x-s*.1,y-.515,(z-.1)*1.4))*.4);
  return 0;},
 accessories(A){const G=new THREE.Group();const P=parts(A,G);const{PB,add,irisTex,eye,glowTex}=P;
  const tex=irisTex('#0A0602','#4A2A12','#C8883E','#1A1206',{pup:.34});
  for(const s of[-1,1])eye(s,{r:.046,ctr:[0,.55,.01],dir:[.42,.04,1],off:-.015,tex,lid:COL.furD,lidCut:.22,yaw:.38,irisK:1.3});
  const brass=PB(COL.brass,{metalness:.85,roughness:.28}),glass=PB(0x9BEAF3,{roughness:.05,transmission:.6,thickness:.01,transparent:true,opacity:.7,clearcoat:1});
  // flying goggles pushed up on the brow
  {const g=new THREE.Group();g.userData.bone='head';G.add(g);for(const s of[-1,1]){const p=mir([.052,.648,.105],s);const m=add(new THREE.TorusGeometry(.03,.009,10,28),brass,p,[-.62,s*.22,0],null,g);add(new THREE.CircleGeometry(.028,24),glass,[p[0],p[1]+.004,p[2]+.004],[-.62,s*.22,0],null,g);}
   add(new THREE.CylinderGeometry(.006,.006,.03,8),brass,[0,.652,.112],[0,0,Math.PI/2],null,g);}
  // whiskers
  {const g=new THREE.Group();g.userData.bone='head';G.add(g);const wm=PB(0xFFF8EE,{roughness:.4});for(const s of[-1,1])for(let k=0;k<3;k++){const cu=new THREE.QuadraticBezierCurve3(new THREE.Vector3(s*.05,.5-k*.008,.155),new THREE.Vector3(s*.12,.505-k*.014,.16),new THREE.Vector3(s*.19,.49-k*.03,.13));add(new THREE.TubeGeometry(cu,12,.0018,4),wm,null,null,null,g);}}
  // rust scarf with a tail blowing back
  {const g=new THREE.Group();g.userData.bone='chest';G.add(g);const sm=PB(0xC8583A,{roughness:.8,sheen:.6,sheenColor:new THREE.Color(0xFFB090)});add(new THREE.TorusGeometry(.085,.026,12,36),sm,[0,.425,.005],[Math.PI/2,0,0],[1,1,.8],g);
   const cu=new THREE.CatmullRomCurve3([new THREE.Vector3(.05,.43,-.07),new THREE.Vector3(.09,.41,-.13),new THREE.Vector3(.12,.37,-.16),new THREE.Vector3(.13,.33,-.2)]);add(new THREE.TubeGeometry(cu,20,.02,8),sm,null,null,[1,1,.5],g);}
  // coat buttons
  {const g=new THREE.Group();g.userData.bone='chest';G.add(g);for(const s of[-1,1])for(const y of[.37,.3])add(new THREE.SphereGeometry(.009,10,8),brass,[s*.064,y,.114-(.37-y)*.1],null,null,g);}
  // brass spyglass in the right paw
  {const g=new THREE.Group();g.userData.bone='haR';g.position.set(.186,.175,.1);g.rotation.set(-.2,.1,0);G.add(g);
   add(new THREE.CylinderGeometry(.013,.013,.08,16),brass,[0,0,.02],[Math.PI/2,0,0],null,g);add(new THREE.CylinderGeometry(.017,.017,.06,16),PB(0x7A4A28,{roughness:.6}),[0,0,-.04],[Math.PI/2,0,0],null,g);
   add(new THREE.TorusGeometry(.017,.004,8,20),brass,[0,0,.062],null,null,g);add(new THREE.CircleGeometry(.014,16),glass,[0,0,.064],null,null,g);}
  // mouse tail curling over the basket rim
  {const g=new THREE.Group();g.userData.bone='tail';G.add(g);const cu=new THREE.CatmullRomCurve3([new THREE.Vector3(0,.2,-.11),new THREE.Vector3(0,.28,-.18),new THREE.Vector3(.01,.31,-.22),new THREE.Vector3(.03,.25,-.245),new THREE.Vector3(.06,.17,-.235),new THREE.Vector3(.1,.14,-.2)]);
   const tg=new THREE.TubeGeometry(cu,60,.014,8);{const p=tg.attributes.position,uv=tg.attributes.uv,cen=new THREE.Vector3(),q=new THREE.Vector3();for(let i=0;i<p.count;i++){const u=uv.getX(i);cu.getPoint(u,cen);q.set(p.getX(i),p.getY(i),p.getZ(i)).sub(cen).multiplyScalar(1-u*.75).add(cen);p.setXYZ(i,q.x,q.y,q.z);}tg.computeVertexNormals();}
   add(tg,PB(COL.tail,{roughness:.55,sheen:.4}),null,null,null,g);}
  // wicker basket around its legs, with sandbags and draped maps; the balloon rides above
  const MT=mapTex(7),MT2=mapTex(31);
  {const g=new THREE.Group();g.userData.bone='hips';G.add(g);
   const pts=[];for(let i=0;i<=12;i++){const t=i/12;pts.push(new THREE.Vector2(.155+t*.05+Math.sin(t*Math.PI)*.012,.02+t*.25));}const lat=new THREE.LatheGeometry(pts,40);
   {const p=lat.attributes.position;const col=[];for(let i=0;i<p.count;i++){const a=Math.atan2(p.getX(i),p.getZ(i)),y=p.getY(i);const w=(Math.sin(a*22+(Math.floor(y*70)%2)*Math.PI)>0)?1:0;const c=new THREE.Color(0xD4A460).lerp(new THREE.Color(0x8A5A2A),w*.5+sstep(.06,.02,y)*.3).lerp(new THREE.Color(0xF0C888),vnoise(a*4,y*30,0)*.15);col.push(c.r,c.g,c.b);}lat.setAttribute('color',new THREE.Float32BufferAttribute(col,3));}
   add(lat,PB(0xFFFFFF,{vertexColors:true,roughness:.85,side:THREE.DoubleSide}),null,null,null,g);add(new THREE.CircleGeometry(.155,32),PB(0x6A4220,{roughness:.9}),[0,.022,0],[-Math.PI/2,0,0],null,g);
   const wd=PB(0x7A4A22,{roughness:.8});add(new THREE.TorusGeometry(.207,.012,10,48),wd,[0,.272,0],[Math.PI/2,0,0],null,g);add(new THREE.TorusGeometry(.158,.01,8,40),wd,[0,.03,0],[Math.PI/2,0,0],null,g);
   const rope=PB(0xC8A878,{roughness:.9});
   for(const a of[.9,2.6,4.4]){const px=Math.sin(a)*.215,pz=Math.cos(a)*.215;add(new THREE.CylinderGeometry(.002,.002,.06,4),rope,[px,.24,pz],null,null,g);add(new THREE.SphereGeometry(.028,14,10),PB(0xA88A5A,{roughness:.95}),[px,.2,pz],null,[1,1.25,1],g);add(new THREE.TorusGeometry(.012,.003,6,14),rope,[px,.227,pz],[Math.PI/2,0,0],null,g);}
   const mpm=(t)=>PB(0xFFFFFF,{map:t,roughness:.85,side:THREE.DoubleSide});
   for(const [a,t] of [[.35,MT],[3.6,MT2]]){const pg=new THREE.PlaneGeometry(.13,.17,6,8);const p=pg.attributes.position;for(let i=0;i<p.count;i++){const yy=p.getY(i);p.setZ(i,Math.sin((yy+.085)*6)*.008+(yy>.06?(yy-.06)*-.9:0));}pg.computeVertexNormals();
    const pl=new THREE.Group();pl.position.set(Math.sin(a)*.214,.2,Math.cos(a)*.214);pl.rotation.y=a;g.add(pl);add(pg,mpm(t),null,[0,0,.08],null,pl);}
   // ropes rise straight past the ears, then gather to the balloon's load ring
   for(let k=0;k<4;k++){const a=k*Math.PI/2+Math.PI/4;const s=Math.sin(a),c=Math.cos(a);const cu=new THREE.CatmullRomCurve3([new THREE.Vector3(s*.205,.275,c*.205),new THREE.Vector3(s*.215,.62,c*.215),new THREE.Vector3(s*.2,.88,c*.2),new THREE.Vector3(s*.085,1.0,c*.085)]);add(new THREE.TubeGeometry(cu,30,.0035,5),rope,null,null,null,g);}
   add(new THREE.TorusGeometry(.08,.008,8,32),brass,[0,1.0,0],[Math.PI/2,0,0],null,g);
   // patchwork map balloon
   const bp=[];for(let i=0;i<=60;i++){const t=i/60;bp.push(new THREE.Vector2(Math.max(.0005,.28*Math.sin(Math.PI*Math.pow(t,1.28))+.07*(1-t)),t*.62));}
   const bl=new THREE.LatheGeometry(bp,64);MT.repeat.set(1,1);add(bl,PB(0xFFFFFF,{map:MT,roughness:.75,sheen:.5,sheenColor:new THREE.Color(0xFFF0D0),side:THREE.DoubleSide}),[0,1.0,0],null,null,g);
   for(let k=0;k<8;k++){const a=k/8*TAU;const cu=new THREE.Curve();cu.getPoint=(t,o=new THREE.Vector3())=>{const r=.28*Math.sin(Math.PI*Math.pow(t,1.28))+.07*(1-t)+.003;return o.set(Math.sin(a)*r,1.0+t*.62,Math.cos(a)*r);};add(new THREE.TubeGeometry(cu,40,.0035,5),PB(0x8A5A2A,{roughness:.8}),null,null,null,g);}
   add(new THREE.SphereGeometry(.03,16,10),brass,[0,1.625,0],null,[1,.5,1],g);add(new THREE.CylinderGeometry(.004,.004,.12,6),PB(0x5A3A20),[0,1.69,0],null,null,g);
   const fl=new THREE.Shape();fl.moveTo(0,0);fl.lineTo(.09,-.02);fl.lineTo(0,-.045);add(new THREE.ShapeGeometry(fl),PB(0x9BEAF3,{roughness:.5,side:THREE.DoubleSide,emissive:0x2A6A7A,emissiveIntensity:.3}),[0,1.748,0],null,null,g);
   // map-sheet tassels hanging from the balloon skirt
   for(let k=0;k<6;k++){const a=k/6*TAU+.3;const pg=new THREE.PlaneGeometry(.055,.075);const pl=new THREE.Group();pl.position.set(Math.sin(a)*.13,1.05,Math.cos(a)*.13);pl.rotation.set(0,a,0);g.add(pl);add(pg,mpm(k%2?MT:MT2),[0,-.04,0],[.25,0,.1*(k%2?1:-1)],null,pl);}}
  // chart a map (ability): a glowing map unrolls in front of it
  const fx=new THREE.Group();fx.userData.bone='root';fx.userData.fx='split';fx.userData.fxMode='grow';fx.userData.fxBase=0;fx.userData.fxGain=1;fx.position.set(0,.42,.32);G.add(fx);
  {const pg=new THREE.PlaneGeometry(.36,.26,12,4);const p=pg.attributes.position;for(let i=0;i<p.count;i++){const xx=p.getX(i);p.setZ(i,-Math.pow(xx/.18,2)*.03);}pg.computeVertexNormals();
   add(pg,PB(0xFFFFFF,{map:MT2,roughness:.7,side:THREE.DoubleSide,emissive:0x2A5A6A,emissiveIntensity:.25}),null,[-.15,0,0],null,fx);
   for(const s of[-1,1])add(new THREE.CylinderGeometry(.014,.014,.28,12),PB(0xE8D0A0,{roughness:.7}),[s*.185,0,-.03],[-.15,0,0],null,fx);
   const gl=new THREE.Sprite(new THREE.SpriteMaterial({map:glowTex('rgba(155,234,243,.8)'),transparent:true,depthWrite:false,blending:THREE.AdditiveBlending}));gl.scale.setScalar(.55);fx.add(gl);}
  return G;}};
export const S=makeSculpt(def);
const J={root:[null,[0,0,0]],hips:['root',[0,.24,0]],chest:['hips',[0,.37,0]],head:['chest',[0,.45,.01]],earL:['head',[-.1,.66,-.01]],earR:['head',[.1,.66,-.01]],
 shL:['chest',[-.12,.37,0]],elL:['shL',[-.17,.29,.04]],haL:['elL',[-.18,.21,.08]],shR:['chest',[.12,.37,0]],elR:['shR',[.17,.29,.04]],haR:['elR',[.18,.21,.08]],
 thL:['hips',[-.06,.2,0]],knL:['thL',[-.07,.11,.01]],ftL:['knL',[-.072,.04,.02]],thR:['hips',[.06,.2,0]],knR:['thR',[.07,.11,.01]],ftR:['knR',[.072,.04,.02]],tail:['hips',[0,.2,-.11]]};
const cfg={name:'cartographer',J,TIP:{haL:[-.19,.15,.112],haR:[.19,.15,.112],ftL:[-.072,.006,.1],ftR:[.072,.006,.1]},
 TORSO:{hips:[[0,.14,0],[0,.36,0],.15],chest:[[0,.3,0],[0,.46,0],.14],head:[[0,.44,.01],[0,.78,.02],.22]},
 AIM:[],floor:.004,pivot:.24,shMin:-2,springs:[['earL','vx',-.35,110,6,0,.4],['earR','vx',-.35,110,6,0,.4],['tail','vx',-.3,110,8,0,.3]]};
const RK=makeRigKit(S,cfg);export const makeRig=RK.makeRig,skinGeo=RK.skinGeo;
const HOLD={shR:[-.55,0,-.08],elR:[-.95,0,0],haR:[.25,0,0]};
export const CLIPS=stdClips({w:.2,arm:.2,x:{
 idle:{label:'Idle',len:4,f:t=>{const u=cyc(t,4);const look=bump(u,.45,.85);return{y:Math.sin(t*1.6)*.012,rz:Math.sin(t*.9)*.02,hy:look*.4,hx:-.03,eye:blink(t,4,.6),b:merge(HOLD,{shL:[-.25,0,.12],elL:[-.55,0,0]})};}},
 idle2:{label:'Check the map',len:4.4,f:t=>{const u=cyc(t,4.4);const k=bump(u,.1,.85);const tr=Math.sin(t*1.4)*k;return{hx:.3*k,hy:tr*.25,eye:1-k*.15,y:Math.sin(t*1.6)*.01,b:{shL:[-.95*k-.2,0,.25*k],shR:[-.95*k-.2,0,-.25*k],elL:[-.85*k-.4,0,0],elR:[-.85*k-.4,0,0],chest:[.08*k,0,0]}};}},
 walk:{label:'Drift',len:2.4,f:t=>{const u=cyc(t,2.4);return{y:.03+Math.sin(u*TAU)*.022,rz:Math.sin(u*TAU)*.05,rx:.05,hy:Math.sin(u*TAU)*.12,eye:blink(t,3),b:merge(HOLD,{shL:[-.3,0,.18],elL:[-.45,0,0]})};}},
 run:{label:'Catch a gust',len:1.2,f:t=>{const u=cyc(t,1.2);return{y:.05+Math.sin(u*TAU)*.03,rz:Math.sin(u*TAU)*.09,rx:.14,hx:-.08,elx:-.4,eye:.95,b:{shL:[-.6,0,-.7],shR:[-.6,0,.7],elL:[-.4,0,0],elR:[-.4,0,0]}};}},
 ability:{label:'Chart a map',len:3,f:t=>{const u=cyc(t,3);const k=ease(sstep(.06,.4,u))*(1-sstep(.86,1,u));return{split:k,hx:.18*k,y:Math.sin(t*1.6)*.01,eye:1-k*.1,b:{shL:[-1.25*k,0,.12*k],shR:[-1.25*k,0,-.12*k],elL:[-.35*k,0,0],elR:[-.35*k,0,0]}};}},
 work:{label:'Survey the horizon',len:4.6,f:t=>{const u=cyc(t,4.6);const k=ease(sstep(.05,.2,u))*(1-sstep(.85,1,u));const sw=Math.sin(u*TAU*1.5)*k;return{hy:sw*.5,hx:-.12*k,ry:sw*.3,eye:1-k*.35,y:Math.sin(t*1.6)*.01,b:{shR:[-1.75*k-.4*(1-k),0,-.35*k],elR:[-1.35*k-.6*(1-k),0,0],haR:[.3*k,0,0],shL:[-.4,0,.15],elL:[-.6,0,0]}};}},
 nap:{label:'Doze on the rim',len:4.8,f:t=>{const b=Math.sin(t*TAU/4.8)*.5+.5;return{y:-.02,sq:-.03+b*.02,hx:.42,hz:.15,eye:.05,b:{chest:[.3+b*.04,0,0],shL:[-1.25,0,.35],shR:[-1.25,0,-.35],elL:[-1.1,0,0],elR:[-1.1,0,0]}};}}}});
export const EXPR={
 happy:{label:'Chuffed',hz:-.12,hx:.04,eye:.86,b:merge(HOLD,{shL:[-.4,0,.3],elL:[-.9,0,0]})},
 focus:{label:'Charting',hx:.24,eye:.72,b:{shL:[-.95,0,.25],shR:[-.95,0,-.25],elL:[-.9,0,0],elR:[-.9,0,0]}},
 startled:{label:'Startled',hx:-.15,eye:1.2,eyeW:1.08,b:{shL:[-.3,0,-.9],shR:[-.3,0,.9]}},
 caught:{label:'Lost',hx:.3,hz:.15,eye:.6,b:{chest:[.2,0,0],shL:[.15,0,.1],shR:[.15,0,-.1]}}};
export const build=o=>S.build(o),loadBaked=(u,r)=>S.loadBaked(u,r);
export const BIN='cartographer.bin?v=1',RES=.0052,GAME_SCALE=.95;
export const EMBERS=[['earL',[-.16,.75,-.02]],['earR',[.16,.75,-.02]],['hips',[0,1.62,0]]];
export const ROUTE=[{to:[1.1,-.4],clip:'walk',sp:.18},{at:true,clip:'work',dur:4.6,face:[2,-1]},{to:[-.7,1],clip:'walk',sp:.18},{at:true,clip:'ability',dur:3,face:[1,3]},{at:true,clip:'idle',dur:4,face:[1,3]},{to:[.2,.2],clip:'run',sp:.28},{at:true,clip:'nap',dur:4.8,face:[2,2]}];
export const HERO={cam:[2.35,1.2,3.6],target:[0,.86,0],clip:'idle'};
