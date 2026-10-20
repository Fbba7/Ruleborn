import * as THREE from 'three';
// shared accessory helpers for the kit characters: materials, placement by ray-march onto the sculpt, eyes
export function parts(A,G){
 const PB=(c,o={})=>new THREE.MeshPhysicalMaterial(Object.assign({color:c,roughness:.5},o));
 const add=(geo,m,p,r,s,par=G,bone)=>{const o=new THREE.Mesh(geo,m);if(p)o.position.set(...p);if(r)o.rotation.set(...r);if(s)o.scale.set(...s);o.castShadow=o.receiveShadow=true;if(bone)o.userData.bone=bone;par.add(o);return o;};
 const hit=(dir,ctr,off=0)=>{const d=new THREE.Vector3(...dir).normalize(),c=new THREE.Vector3(...ctr);let t=.7;for(let i=0;i<240;i++){const p=c.clone().addScaledVector(d,t);const s=A.sdf(p.x,p.y,p.z);if(s<.0008)break;t-=Math.max(s*.8,.0008);}
  const p=c.clone().addScaledVector(d,t);const e=.002;const n=new THREE.Vector3(A.sdf(p.x+e,p.y,p.z)-A.sdf(p.x-e,p.y,p.z),A.sdf(p.x,p.y+e,p.z)-A.sdf(p.x,p.y-e,p.z),A.sdf(p.x,p.y,p.z+e)-A.sdf(p.x,p.y,p.z-e)).normalize();return{p:p.addScaledVector(n,off),n};};
 const onSurf=(grp,dir,ctr,off,bone,up)=>{const h=hit(dir,ctr,off);grp.position.copy(h.p);grp.quaternion.setFromUnitVectors(new THREE.Vector3(0,0,1),h.n);if(up)grp.rotateZ(up);grp.userData.bone=bone;G.add(grp);return h;};
 // iris texture: pupil, iris ring with radial streaks, limbal ring
 const irisTex=(pupil,inner,outer,limb,o={})=>{const c=document.createElement('canvas');c.width=c.height=256;const x=c.getContext('2d');x.fillStyle=limb;x.fillRect(0,0,256,256);
  const g=x.createRadialGradient(128,128,0,128,128,128);g.addColorStop(0,pupil);g.addColorStop(o.pup??.3,pupil);g.addColorStop((o.pup??.3)+.04,inner);g.addColorStop(.8,outer);g.addColorStop(.93,limb);x.fillStyle=g;x.beginPath();x.arc(128,128,128,0,6.3);x.fill();
  if(o.human){const pr=128*(o.pup??.3);const g2=x.createRadialGradient(128,128,pr,128,128,128*.96);g2.addColorStop(0,'rgba(255,230,180,.35)');g2.addColorStop(.3,'rgba(255,230,180,0)');g2.addColorStop(.82,'rgba(0,0,0,0)');g2.addColorStop(1,'rgba(0,0,0,.55)');x.fillStyle=g2;x.beginPath();x.arc(128,128,124,0,6.3);x.fill();
   for(let i=0;i<260;i++){const a=Math.random()*6.283,r0=pr+4+Math.random()*10,r1=r0+14+Math.random()*50;x.strokeStyle=Math.random()<.5?'rgba(255,240,210,.12)':'rgba(0,0,0,.12)';x.lineWidth=.8+Math.random();x.beginPath();x.moveTo(128+Math.cos(a)*r0,128+Math.sin(a)*r0);x.quadraticCurveTo(128+Math.cos(a+.08)*(r0+r1)/2,128+Math.sin(a+.08)*(r0+r1)/2,128+Math.cos(a)*r1,128+Math.sin(a)*r1);x.stroke();}
   x.fillStyle=pupil;x.beginPath();x.arc(128,128,pr,0,6.3);x.fill();const t=new THREE.CanvasTexture(c);t.colorSpace=THREE.SRGBColorSpace;return t;}
  x.globalAlpha=.22;for(let i=0;i<90;i++){const a=i/90*6.283;x.strokeStyle=i%2?'#fff':'#000';x.lineWidth=1.4;x.beginPath();x.moveTo(128+Math.cos(a)*128*((o.pup??.3)+.06),128+Math.sin(a)*128*((o.pup??.3)+.06));x.lineTo(128+Math.cos(a)*110,128+Math.sin(a)*110);x.stroke();}x.globalAlpha=1;
  if(o.hex){x.strokeStyle='rgba(255,255,255,.18)';x.lineWidth=2;const r=14;for(let yy=0;yy<300;yy+=r*1.5)for(let xx=0;xx<300;xx+=r*1.732){const cx=xx+((yy/(r*1.5))%2)*r*.866,cy=yy;x.beginPath();for(let k=0;k<6;k++){const a=k/6*6.283+Math.PI/6;x.lineTo(cx+Math.cos(a)*r,cy+Math.sin(a)*r);}x.closePath();x.stroke();}}
  const t=new THREE.CanvasTexture(c);t.colorSpace=THREE.SRGBColorSpace;return t;};
 // eye: sphere with iris decal, upper lid, catch-light. opts: r, ctr, dir(side sign applied), off, iris texture, lid colour, lidCut, squash, yaw, tilt
 const eye=(s,o)=>{const e=new THREE.Group();e.name=s<0?'eye_L':'eye_R';e.userData.bone='head';const h=hit([s*o.dir[0],o.dir[1],o.dir[2]],o.ctr,o.off??-o.r*.35);e.position.copy(h.p);e.rotation.set(o.tilt||0,s*(o.yaw??.35),s*(o.roll||0));G.add(e);
  const r=o.r,eg=new THREE.SphereGeometry(r,32,20);{const uv=eg.attributes.uv,p=eg.attributes.position,k=o.irisK??1.7;for(let i=0;i<p.count;i++){if(p.getZ(i)<r*.15)uv.setXY(i,0,0);else uv.setXY(i,.5+p.getX(i)/(r*k*2)*1.0,.5+p.getY(i)/(r*k*2)*1.0);}}
  if(o.human){const sk=new THREE.Color(o.skin),skD=sk.clone().multiplyScalar(.78);add(eg,PB(0xF6F0EA,{map:o.tex,roughness:.12,clearcoat:1,clearcoatRoughness:.05}),null,null,[1,o.squash??1,.85],e);
   const lc=Math.max(o.lidCut??.36,.41),lt=(o.lidTilt??.35)+.12;const up=add(new THREE.SphereGeometry(r*1.09,32,14,0,Math.PI*2,0,Math.PI*lc),PB(sk.getHex(),{roughness:.6}),[0,r*.02,0],[-lt,0,0],[1,o.squash??1,1],e);up.name='lid';
   const lash=add(new THREE.TorusGeometry(r*1.09*Math.sin(Math.PI*lc),r*.085,8,40,Math.PI*1.05),PB(o.lash??0x1A0C08,{roughness:.7}),null,null,[1,1,.6],up);lash.rotation.set(Math.PI/2,0,-Math.PI*.025);lash.position.y=r*1.06*Math.cos(Math.PI*lc);
   const crease=add(new THREE.TorusGeometry(r*1.02,r*.05,6,40,Math.PI*.9),PB(skD.getHex(),{roughness:.8}),[0,r*.2,r*.1],[-.4,0,Math.PI*.05],[1,.8,1],e);
   const lo=add(new THREE.TorusGeometry(r*.92,r*.07,6,40,Math.PI*.95),PB(sk.getHex(),{roughness:.6}),[0,-r*.16,r*.22],[.5,0,Math.PI+Math.PI*.025],[1,.62,1],e);lo.name='lidLo';
   const sp=new THREE.Mesh(new THREE.SphereGeometry(r*.11,10,8),new THREE.MeshBasicMaterial({color:0xffffff}));sp.position.set(-r*.26,r*.22,r*.84);e.add(sp);
   const sp2=new THREE.Mesh(new THREE.SphereGeometry(r*.05,8,6),new THREE.MeshBasicMaterial({color:0xffffff,transparent:true,opacity:.7}));sp2.position.set(r*.24,-r*.2,r*.86);e.add(sp2);return e;}
  add(eg,PB(0xffffff,{map:o.tex,roughness:.08,clearcoat:1,clearcoatRoughness:.03}),null,null,[1,o.squash??1,.85],e);
  const lid=add(new THREE.SphereGeometry(r*1.1,28,12,0,Math.PI*2,0,Math.PI*(o.lidCut??.36)),PB(o.lid,{roughness:.8}),[0,r*.02,0],[-(o.lidTilt??.35),0,0],[1,o.squash??1,1],e);lid.name='lid';
  const sp=new THREE.Mesh(new THREE.SphereGeometry(r*.2,10,8),new THREE.MeshBasicMaterial({color:0xffffff}));sp.position.set(-r*.3,r*.32,r*.8);e.add(sp);
  const sp2=new THREE.Mesh(new THREE.SphereGeometry(r*.09,8,6),new THREE.MeshBasicMaterial({color:0xffffff}));sp2.position.set(r*.28,-r*.25,r*.85);e.add(sp2);return e;};
 const glowTex=(c1)=>{const c=document.createElement('canvas');c.width=c.height=128;const x=c.getContext('2d');const g=x.createRadialGradient(64,64,0,64,64,64);g.addColorStop(0,c1);g.addColorStop(1,'rgba(0,0,0,0)');x.fillStyle=g;x.fillRect(0,0,128,128);const t=new THREE.CanvasTexture(c);return t;};
 const ring=(col,r0,r1)=>new THREE.Mesh(new THREE.RingGeometry(r0,r1,64),new THREE.MeshBasicMaterial({color:col,transparent:true,opacity:.7,depthWrite:false,side:THREE.DoubleSide,blending:THREE.AdditiveBlending}));
 return{PB,add,hit,onSurf,irisTex,eye,glowTex,ring,THREE};}
// hourglass (Time mark / Hourkeeper belly): brass caps, posts, glass bulbs, glowing sand
export function hourglass(P,h,col=0x9BEAF3,brass=0xC8963E){const{PB,add,THREE:T}=P;const g=new T.Group();const b=PB(brass,{metalness:1,roughness:.3});const gl=PB(0xEAF8FF,{roughness:.02,transmission:.9,thickness:.02,ior:1.45,transparent:true,opacity:.55,clearcoat:1});const sd=PB(col,{emissive:col,emissiveIntensity:.9,roughness:.6});
 for(const y of[-1,1])add(new T.CylinderGeometry(h*.42,h*.42,h*.09,24),b,[0,y*h*.5,0],null,null,g);for(let k=0;k<3;k++){const a=k/3*6.283+.5;add(new T.CylinderGeometry(h*.03,h*.03,h,8),b,[Math.cos(a)*h*.36,0,Math.sin(a)*h*.36],null,null,g);}
 const pr=[];for(let i=0;i<=16;i++){const u=i/16;pr.push(new T.Vector2(h*.03+Math.pow(Math.abs(Math.sin(u*Math.PI)),.8)*h*.28,(u-.5)*h*.9));}add(new T.LatheGeometry(pr,28),gl,null,null,null,g);
 const sp=[];for(let i=0;i<=8;i++){const u=i/8;sp.push(new T.Vector2(h*.02+Math.sin(u*Math.PI*.5)*h*.25,-h*.44+u*h*.2));}sp.push(new T.Vector2(0,-h*.24));add(new T.LatheGeometry(sp,24),sd,null,null,null,g);
 add(new T.ConeGeometry(h*.14,h*.12,24),sd,[0,h*.26,0],[Math.PI,0,0],null,g);add(new T.CylinderGeometry(h*.012,h*.012,h*.44,6),sd,[0,-.02*h,0],null,null,g);return g;}
