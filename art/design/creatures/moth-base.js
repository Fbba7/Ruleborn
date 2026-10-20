import * as THREE from 'three';
import {makeSculpt,makeRigKit,sstep,vnoise,clamp,ease,bump,blink,cyc,TAU} from './creature-kit.js';
import {parts} from './creature-parts.js';
// ============ MOTH · a fuzzy round moth with feathery antennae and four painted wings (realm wildlife, 5.7) ============
const mir=(p,s)=>[p[0]*s,p[1],p[2]];
export function makeMoth(V){
 const COL=Object.assign({fuzz:0xF2E2C0,fuzzL:0xFFF6E0,fuzzD:0xA8865A,belly:0xFFF0C8,glow:0xFFD27A,leg:0x6A4A30,ant:0x8A6A40},V.col||{});
 const K=Object.fromEntries(Object.entries(COL).map(([k,v])=>[k,new THREE.Color(v)]));let A0=null;
 const def={name:V.name,box:[[-.12,.18,-.2],[.12,.42,.14]],res:.0036,warm:0x2A1A10,aoWarm:.22,sheen:0xFFF4E0,rim:V.rim||0xFFE6B0,
  bodyMat:{roughness:.85,sheen:1,sheenRoughness:.5,sheenColor:new THREE.Color(V.sheen||0xFFF4E0)},fur:{shells:0},
  sculpt(A){const{E,C}=A;A0=A;
   E('T:thorax',[0,.3,0],[.052,.05,.05],null,.03);E('T:ruff',[0,.315,.028],[.058,.05,.034],null,.03);
   C('hips:abdomen',[0,.298,-.03],[0,.27,-.13],.045,.022,.03);for(let k=0;k<4;k++)E('hips:seg'+k,[0,.292-k*.007,-.05-k*.024],[.043-k*.006,.04-k*.006,.014],null,.012);
   E('head:head',[0,.318,.058],[.04,.038,.036],null,.025);E('head:cheekL',[-.022,.307,.075],[.018,.016,.016],null,.012);E('head:cheekR',[.022,.307,.075],[.018,.016,.016],null,.012);},
  disp(x,y,z,d){if(Math.abs(d)>.02)return d;const f=vnoise(x*170,y*170,z*170)*.6+vnoise(x*380,y*380,z*380)*.4;return d+(f-.5)*.0032;},
  paint(x,y,z,nx,ny,nz,ao,c,A){
   c.copy(K.fuzz).lerp(K.fuzzL,sstep(.2,.95,ny)*.4+sstep(.3,.9,nz)*.15).lerp(K.fuzzD,(1-ao)*.55+sstep(-.1,-.8,ny)*.2);
   c.lerp(K.fuzzD,Math.pow(vnoise(x*120,y*120,z*120),3)*.35);
   if(A.minD(/^hips:/,x,y,z)<.004){const s=Math.sin(z*260)*.5+.5;c.lerp(K.fuzzD,sstep(.7,.9,s)*.35);if(V.glowTail){const g=sstep(-.09,-.125,z);c.lerp(K.glow,g*.95);}}
   if(A.dist('T:ruff',x,y,z)<.004&&nz>.2)c.lerp(K.belly,.6);
   if(A.minD(/^head:/,x,y,z)<.004&&nz>.4){c.lerp(K.belly,.45);}
   if(V.paint)V.paint(x,y,z,nx,ny,nz,ao,c,A,K);return 0;},
  accessories(A){const G=new THREE.Group();const P=parts(A,G);const{PB,add,irisTex,eye,glowTex}=P;
   const et=V.eye||['#060404','#2A1A0E','#6A4A2A','#0A0604'];const tex=irisTex(et[0],et[1],et[2],et[3],{pup:.5});
   for(const s of[-1,1])eye(s,{r:.0165,ctr:[0,.318,.058],dir:[.5,.08,1],off:-.006,tex,lid:COL.fuzzD,lidCut:.12,yaw:.55,irisK:1.1});
   // feathery antennae: a curved quill with fine barbs, bound to the ear bones so they sway
   for(const s of[-1,1]){const L=s<0?'L':'R';const g=new THREE.Group();g.userData.bone='ear'+L;G.add(g);const base=new THREE.Vector3(s*.018,.348,.07);
    const cu=new THREE.CatmullRomCurve3([base,base.clone().add(new THREE.Vector3(s*.02,.04,.01)),base.clone().add(new THREE.Vector3(s*.05,.07,-.005)),base.clone().add(new THREE.Vector3(s*.085,.08,-.03))]);
    const am=PB(COL.ant,{roughness:.6,sheen:.6});add(new THREE.TubeGeometry(cu,24,.0028,6),am,null,null,null,g);
    for(let k=1;k<14;k++){const u=k/14,p=cu.getPoint(u),tn=cu.getTangent(u);const n=new THREE.Vector3(0,1,0).cross(tn).normalize();const len=.018*Math.sin(u*Math.PI)+.004;
     for(const q of[-1,1]){const b=add(new THREE.CylinderGeometry(.0008,.0012,len,4),am,[p.x+n.x*q*len*.5,p.y+n.y*q*len*.5+.002,p.z+n.z*q*len*.5],null,null,g);b.lookAt(p.x+n.x*q,p.y+n.y*q+.2,p.z+n.z*q);b.rotateX(Math.PI/2);b.castShadow=false;}}}
   // four painted wings: forewings on the shoulder bones, hindwings on the thigh bones
   const wingTex=(fore)=>{const c=document.createElement('canvas');c.width=c.height=256;const x=c.getContext('2d');x.clearRect(0,0,256,256);
    const path=()=>{x.beginPath();if(fore){x.moveTo(250,120);x.bezierCurveTo(190,30,60,10,14,60);x.bezierCurveTo(4,110,40,170,110,178);x.bezierCurveTo(170,184,230,160,250,136);}else{x.moveTo(250,110);x.bezierCurveTo(200,70,100,70,40,110);x.bezierCurveTo(20,170,90,236,160,220);x.bezierCurveTo(220,200,248,150,250,126);}x.closePath();};
    path();const g=x.createLinearGradient(250,0,0,0);g.addColorStop(0,V.wing[0]);g.addColorStop(.55,V.wing[1]);g.addColorStop(1,V.wing[2]);x.fillStyle=g;x.fill();
    x.save();path();x.clip();x.strokeStyle=V.vein||'rgba(60,40,20,.35)';x.lineWidth=2;for(let k=0;k<6;k++){x.beginPath();x.moveTo(250,124);x.quadraticCurveTo(160,110+k*(fore?-14:16),30+k*10,fore?60+k*22:110+k*20);x.stroke();}
    x.lineWidth=14;x.strokeStyle=V.edge||'rgba(90,60,30,.45)';path();x.stroke();
    if(V.spots)V.spots(x,fore);x.restore();x.lineWidth=3;x.strokeStyle='rgba(30,20,10,.5)';path();x.stroke();
    const t=new THREE.CanvasTexture(c);t.colorSpace=THREE.SRGBColorSpace;t.anisotropy=4;return t;};
   const mk=(fore)=>{const tx=wingTex(fore);return PB(0xffffff,{map:tx,alphaTest:.5,side:THREE.DoubleSide,roughness:.6,sheen:.2,envMapIntensity:.8,sheenColor:new THREE.Color(V.wingSheen||0xFFFFFF),iridescence:V.irid||.2,emissive:0xffffff,emissiveMap:tx,emissiveIntensity:V.wingGlow?.55:.32});};
   const fm=mk(true),hm=mk(false);
   for(const s of[-1,1]){const L=s<0?'L':'R';
    for(const [bone,m,w,h,pos,rot] of[['sh'+L,fm,.3,.3,[.012,.312,.01],[-Math.PI/2+.18,0,-.1*s]],['th'+L,hm,.23,.23,[.01,.296,-.028],[-Math.PI/2+.1,0,-.45*s]]]){
     const g=new THREE.Group();g.userData.bone=bone;g.position.set(s*pos[0],pos[1],pos[2]);G.add(g);const geo=new THREE.PlaneGeometry(w,h);geo.translate(-w/2+.004,h*.03,0);if(s>0)geo.scale(-1,1,1);
     const pl=add(geo,m,null,rot,null,g);pl.castShadow=true;}}
   // six little legs tucked under the thorax
   const lm=PB(COL.leg,{roughness:.8,sheen:.8});for(const s of[-1,1])for(let k=0;k<3;k++){const g=new THREE.Group();g.userData.bone='chest';G.add(g);const a=new THREE.Vector3(s*.024,.27,.02-k*.02),b=new THREE.Vector3(s*.04,.252,.03-k*.024),c2=new THREE.Vector3(s*.036,.236,.04-k*.026);
    add(new THREE.TubeGeometry(new THREE.CatmullRomCurve3([a,b,c2]),10,.004,5),lm,null,null,null,g);add(new THREE.SphereGeometry(.005,8,6),lm,[c2.x,c2.y,c2.z],null,null,g);}
   if(V.glowTail){const gl=new THREE.Sprite(new THREE.SpriteMaterial({map:glowTex(V.glowCss||'rgba(255,210,120,.95)'),transparent:true,depthWrite:false,blending:THREE.AdditiveBlending}));gl.position.set(0,.272,-.13);gl.scale.setScalar(.075);gl.userData.bone='hips';G.add(gl);gl.userData.fx='glow';gl.userData.fxBase=1;gl.userData.fxGain=.6;}
   if(V.acc)V.acc(A,G,P,COL);
   // ability: a burst of motes spiralling off the wings
   const fx=new THREE.Group();fx.userData.bone='chest';fx.userData.fx='split';fx.userData.fxMode='show';fx.position.set(0,.3,0);fx.userData.spin=3;fx.userData.spinAx='y';G.add(fx);
   const mt=new THREE.SpriteMaterial({map:glowTex(V.moteCss||'rgba(255,230,160,.95)'),transparent:true,depthWrite:false,blending:THREE.AdditiveBlending});
   for(let k=0;k<10;k++){const a=k/10*TAU;const sp=new THREE.Sprite(mt);sp.position.set(Math.sin(a)*(.16+k%3*.03),(k%4-1.5)*.03,Math.cos(a)*(.16+k%3*.03));sp.scale.setScalar(.04);fx.add(sp);}
   return G;}};
 const S=makeSculpt(def);
 const J={root:[null,[0,0,0]],hips:['root',[0,.298,-.03]],chest:['hips',[0,.3,0]],head:['chest',[0,.316,.05]],earL:['head',[-.018,.348,.07]],earR:['head',[.018,.348,.07]],
  shL:['chest',[-.006,.31,.012]],shR:['chest',[.006,.31,.012]],thL:['chest',[-.004,.292,-.03]],thR:['chest',[.004,.292,-.03]],tail:['hips',[0,.27,-.13]]};
 const cfg={name:V.name,J,TIP:{},feet:['hips'],TORSO:{hips:[[0,.29,-.03],[0,.27,-.14],.05],chest:[[0,.3,-.02],[0,.31,.04],.05],head:[[0,.315,.04],[0,.32,.09],.04]},
  AIM:[],floor:V.floor??.34,pivot:.3,springs:[['earL','vx',.8,110,6,0,.5],['earR','vx',.8,110,6,0,.5],['earL','t',.12,80,5,2,.2,2.3],['earR','t',-.12,80,5,2,.2,2.1]]};
 const RK=makeRigKit(S,cfg);
 // wings: flap = up-down roll, fold = sweep back; left wings roll -, right +
 const W=(f,fold=0,lag=.8)=>({shL:[0,-fold,-f],shR:[0,fold,f],thL:[0,-fold*.8,-f*lag],thR:[0,fold*.8,f*lag]});
 const hover=(t,rate,amp,base=.1)=>{const f=Math.sin(t*rate)*amp+base;return f;};
 const CLIPS={
  idle:{label:'Hover',len:3,f:t=>{const u=cyc(t,3);return{y:Math.sin(u*TAU)*.02,rx:Math.sin(t*1.7)*.05,rz:Math.sin(t*1.1)*.05,hz:Math.sin(t*.9)*.08,eye:blink(t,3,.4),b:W(hover(t,9,.3,.28),.1)};}},
  idle2:{label:'Rest & fan',len:5,f:t=>{const u=cyc(t,5);const land=ease(sstep(.05,.25,u))*(1-ease(sstep(.78,.95,u)));const fan=bump(u,.3,.72);const f=land?(Math.sin(t*3)*.35+.2)*fan+(-.9)*(1-fan)*land:0;const fly=hover(t,22,.7,.15)*(1-land);return{y:-land*.11,rx:-.05*land,eye:blink(t,2.5,.2),hy:Math.sin(t*.8)*.3*land,b:W(fly+f*land,.7*land*(1-fan))};}},
  walk:{label:'Fly',len:1.8,f:t=>{const u=cyc(t,1.8);return{y:Math.sin(u*TAU*2)*.025,rx:.18,rz:Math.sin(u*TAU)*.08,hx:-.05,eye:blink(t,3),b:W(hover(t,26,.85,.1))};}},
  run:{label:'Dart',len:1,f:t=>{const u=cyc(t,1);return{y:Math.sin(u*TAU)*.04,rx:.3,rz:Math.sin(u*TAU*2)*.14,b:W(hover(t,40,.9,.05))};}},
  ability:{label:V.abilityLabel||'Glow burst',len:2.4,f:t=>{const u=cyc(t,2.4);const b=bump(u,.12,.85);return{y:b*.05,sq:b*.08,split:sstep(.12,.25,u)*(1-sstep(.75,.9,u)),glow:b,ry:ease(sstep(.1,.8,u))*TAU,eye:1-b*.3,b:W(hover(t,30,.9*b+.5,.2))};}},
  work:{label:V.workLabel||'Circle the light',len:4,f:t=>{const u=cyc(t,4);const a=u*TAU;return{x:Math.sin(a)*.12,z:Math.cos(a)*.12-.12,ry:a+Math.PI/2,rz:-.25,y:Math.sin(a*2)*.02,eye:blink(t,4),b:W(hover(t,24,.8,.12))};}},
  nap:{label:'Sleep on a leaf',len:5,f:t=>{const b=Math.sin(t*TAU/5)*.5+.5;return{y:-.12,sq:-.04+b*.02,hx:.15,eye:.05,b:W(-1,.9)};}},
  celebrate:{label:'Loop',len:1.6,f:t=>{const u=cyc(t,1.6);const a=ease(u)*TAU;return{y:Math.sin(a)*.08,z:(1-Math.cos(a))*.04,rx:-a,eye:1,b:W(hover(t,30,.9,.1))};}},
  hit:{label:'Tumble',len:1.4,f:t=>{const u=cyc(t,1.4);const k=bump(u,0,.35),r=1-ease(sstep(.3,1,u));return{y:-k*.06,rz:Math.sin(u*30)*.4*r,rx:-.3*k,eye:1+k*.3,b:W(Math.sin(t*50)*.9*r+.1)};}}};
 const EXPR={happy:{label:'Content',hz:-.1,eye:.7,elx:.2},focus:{label:'Drawn to light',hx:-.12,eye:1.1},startled:{label:'Startled',eye:1.25,eyeW:1.1},caught:{label:'Dozy',hx:.2,eye:.35}};
 return {S,makeRig:RK.makeRig,skinGeo:RK.skinGeo,CLIPS,EXPR,build:o=>S.build(o),loadBaked:(u,r)=>S.loadBaked(u,r)};}
