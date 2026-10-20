import * as THREE from 'three';
import {partDists,arcCache,fromCache,setFlip} from './archivist-sculpt.js?v=6';
const sstep=(a,b,x)=>{const t=Math.max(0,Math.min(1,(x-a)/(b-a)));return t*t*(3-2*t);};
// ---------- skeleton (sculpt units, faces +Z, character's right = +x) ----------
const J={root:[null,[0,0,0]],hips:['root',[0,.6,0]],spine:['hips',[0,.78,0]],chest:['spine',[0,.93,0]],neck:['chest',[0,1.05,0]],head:['neck',[0,1.13,.02]],
 beard:['head',[0,1.02,.17]],browL:['head',[-.056,1.262,.128]],browR:['head',[.056,1.262,.128]],stache:['head',[0,1.122,.162]],
 shR:['chest',[.2,.99,0]],elR:['shR',[.39,.8,.03]],haR:['elR',[.455,.69,.14]],
 shL:['chest',[-.2,.99,0]],elL:['shL',[-.39,.8,0]],haL:['elL',[-.38,.774,.175]],
 thR:['hips',[.1,.56,0]],knR:['thR',[.1,.3,.04]],ftR:['knR',[.1,.08,.16]],
 thL:['hips',[-.1,.56,0]],knL:['thL',[-.1,.3,.04]],ftL:['knL',[-.1,.08,.16]]};
const BONES=Object.keys(J);
const PART=n=>{if(n==='slR1')return'shR';if(/^(slR2|drapeR|cuffcutR)/.test(n))return'elR';if(/^(wristR|handR|fgR|tbR)/.test(n))return'haR';
 if(n==='slL1')return'shL';if(/^(slL2|drapeL|cuffcutL)/.test(n))return'elL';if(/^(wristL|handL|fgL|tbL)/.test(n))return'haL';
 if(/^(shoe1|toe1)$/.test(n))return'ftR';if(/^(shoe-1|toe-1)$/.test(n))return'ftL';if(/^(robeHem|robeLow|fold)/.test(n))return'ROBE';
 if(n==='waist')return'hips';if(n==='belly')return'spine';if(/^(chest|shoulders|collar|hood)/.test(n))return'chest';
 if(/^beard[234]/.test(n))return'beard';if(n==='brow-1')return'browL';if(n==='brow1')return'browR';if(/^stache/.test(n))return'stache';return'head';};
export function skinGeo(g){if(g.userData.skinned)return;const SC=arcCache(),SK=g.userData.ck&&SC[g.userData.ck];
 if(SK&&SK.si){g.setAttribute('skinIndex',new THREE.Uint16BufferAttribute(fromCache(SK.si),4));g.setAttribute('skinWeight',new THREE.Float32BufferAttribute(fromCache(SK.sw),4));g.userData.skinned=true;return;}
 const P=g.attributes.position,n=P.count,bi=Object.fromEntries(BONES.map((b,i)=>[b,i]));const si=new Uint16Array(n*4),sw=new Float32Array(n*4);
 for(let v=0;v<n;v++){const x=P.getX(v),y=P.getY(v),z=P.getZ(v);const acc={};const add=(b,w)=>{acc[b]=(acc[b]||0)+w;};
  for(const[name,d]of partDists(x,y,z)){const b=PART(name);const w=Math.exp(-Math.max(0,d)/.012);
   if(b==='ROBE'){const f=sstep(.62,.12,y)*.7,sx=sstep(-.14,.14,x);add('hips',w*(1-f));add('thR',w*f*sx);add('thL',w*f*(1-sx));}else add(b,w);}
  let ent=Object.entries(acc).sort((a,b)=>b[1]-a[1]).slice(0,4);if(!ent.length)ent=[['hips',1]];const tot=ent.reduce((a,e)=>a+e[1],0);ent.forEach(([b,w],k)=>{si[v*4+k]=bi[b];sw[v*4+k]=w/tot;});}
 g.setAttribute('skinIndex',new THREE.Uint16BufferAttribute(si,4));g.setAttribute('skinWeight',new THREE.Float32BufferAttribute(sw,4));g.userData.skinned=true;
 if(SK){SK.si=si;SK.sw=sw;}}
const spring=(s,tgt,k,c,dt)=>{s[1]+=((tgt-s[0])*k-s[1]*c)*dt;s[0]+=s[1]*dt;return s[0];};
export function blendPose(a,b,w){const o={};const keys=new Set([...Object.keys(a),...Object.keys(b)]);for(const k of keys){if(k==='b'||k==='book')continue;const va=a[k],vb=b[k];if(typeof va==='number'||typeof vb==='number'){const d=(k==='eye'||k==='glow'||k==='flip')?1:0;o[k]=(va??d)+((vb??d)-(va??d))*w;}else o[k]=w<.5?va:vb;}
 o.b={};const bk=new Set([...Object.keys(a.b||{}),...Object.keys(b.b||{})]);for(const k of bk){const x=(a.b||{})[k]||[0,0,0],y=(b.b||{})[k]||[0,0,0];o.b[k]=[x[0]+(y[0]-x[0])*w,x[1]+(y[1]-x[1])*w,x[2]+(y[2]-x[2])*w];}
 const ba=a.book||{},bb=b.book||{};o.book={};for(const k of new Set([...Object.keys(ba),...Object.keys(bb)])){const d=k==='glow'?1:0;o.book[k]=(ba[k]??d)+((bb[k]??d)-(ba[k]??d))*w;}return o;}
// ---------- rig ----------
export function makeRig(src){
 const g=src.getObjectByName('body').geometry;skinGeo(g);
 const grp=new THREE.Group();grp.name='archivist';
 const bones={};for(const b of BONES){const o=new THREE.Bone();o.name=b;bones[b]=o;}
 for(const b of BONES){const[p,w]=J[b];if(p){bones[p].add(bones[b]);bones[b].position.set(w[0]-J[p][1][0],w[1]-J[p][1][1],w[2]-J[p][1][2]);}else bones[b].position.set(...w);}
 const skel=new THREE.Skeleton(BONES.map(b=>bones[b]));const meshes=[];
 for(const o of[...src.children]){if(o.isMesh&&(o.name==='body'||o.name.startsWith('hair_shell'))){const sm=new THREE.SkinnedMesh(o.geometry,o.material);sm.name=o.name;sm.castShadow=o.castShadow;sm.receiveShadow=true;sm.frustumCulled=false;grp.add(sm);meshes.push(sm);}}
 meshes[0].add(bones.root);meshes.forEach(m=>m.bind(skel));
 const acc=src.getObjectByName('accessories');grp.add(acc);grp.updateMatrixWorld(true);
 const E={eyeL:acc.getObjectByName('eye_L'),eyeR:acc.getObjectByName('eye_R'),spec:acc.getObjectByName('spectacles'),staff:acc.getObjectByName('staff'),sash:acc.getObjectByName('sash'),book:acc.getObjectByName('book'),page:acc.getObjectByName('loose_page')};
 for(const k of['eyeL','eyeR','spec'])bones.head.attach(E[k]);bones.haR.attach(E.staff);bones.hips.attach(E.sash);
 const pos0={};for(const b of BONES)pos0[b]=bones[b].position.clone();
 const bookHome=new THREE.Vector3(-.38,.945,.27),bookRot=new THREE.Euler(.62,.35,-.28);const handRest=new THREE.Vector3(-.38,.774,.175);
 const root=new THREE.Group();root.name='archivist_rig';const lean=new THREE.Group();lean.position.y=.6;grp.position.y=-.6;root.add(lean);lean.add(grp);
 const q=new THREE.Quaternion(),e=new THREE.Euler(),v=new THREE.Vector3(),w2=new THREE.Vector3();
 const SP={beard:[0,0],beardZ:[0,0],bx:[0,0],by:[0,0],bz:[0,0],rib:[0,0]};let last=performance.now(),lastY=null,lastHy=null,prevP=null,blendFrom=null,blendT0=0,lastClip=null,flipC=0,bookInit=false;
 const rig={root,bones,acc,E,
  play(p,clip){if(clip!==lastClip){if(prevP&&lastClip!==null){blendFrom=prevP;blendT0=performance.now();}lastClip=clip;}let qq=p;if(blendFrom){const w=Math.min(1,(performance.now()-blendT0)/320);qq=blendPose(blendFrom,p,w*w*(3-2*w));if(w>=1)blendFrom=null;}prevP=qq;this.set(qq);},
  set(p){const now=performance.now(),dt=Math.min(.05,(now-last)/1000)||.016;last=now;
   for(const b of BONES){bones[b].quaternion.identity();bones[b].position.copy(pos0[b]);}
   const off=Object.assign({},p.b||{});const put=(b,x,y,z)=>{const o=off[b]||[0,0,0];off[b]=[o[0]+(x||0),o[1]+(y||0),o[2]+(z||0)];};
   const y0=(p.y||0),vy=lastY==null?0:(y0-lastY)/dt;lastY=y0;const hy=(p.hy||0)+(p.ry||0),wy=lastHy==null?0:(hy-lastHy)/dt;lastHy=hy;
   const bd=spring(SP.beard,Math.max(-.35,Math.min(.35,-vy*1.2+(p.hx||0)*-.6)),110,9,dt),bz=spring(SP.beardZ,Math.max(-.3,Math.min(.3,-wy*.08)),90,8,dt);
   put('head',p.hx,p.hy,p.hz);put('beard',bd+Math.sin(now/900)*.02,0,bz);
   for(const b in off){if(!bones[b])continue;const o=off[b];q.setFromEuler(e.set(o[0],o[1],o[2],'YXZ'));bones[b].quaternion.copy(q);}
   {const up=p.upright??.9;if(up>0){const Q=new THREE.Quaternion();for(const b of['hips','spine','chest','shR','elR'])Q.multiply(bones[b].quaternion);const corr=Q.clone().invert().multiply(bones.haR.quaternion.clone().premultiply(new THREE.Quaternion()));const h0=bones.haR.quaternion.clone();bones.haR.quaternion.copy(h0.slerp(Q.invert().multiply(h0.clone()),up));}}
   const br=p.brow||0,fr=p.frown||0;bones.browL.position.y+=.0075*br-.002*fr;bones.browR.position.y+=.0075*br-.002*fr;bones.browL.rotation.z=-fr*.28+(p.browTilt||0);bones.browR.rotation.z=fr*.28+(p.browTilt||0)*.4;
   bones.stache.position.y+=.0035*(p.smile||0);bones.stache.rotation.x=-.1*(p.smile||0);
   const ey=p.eye??1;for(const k of['eyeL','eyeR']){const l=E[k].userData.lid;l.rotation.x=-.45+(1-Math.min(1,ey))*1.45-(Math.max(0,ey-1))*.6;E[k].scale.setScalar(1+(Math.max(0,ey-1))*.25);}
   root.position.set(p.x||0,y0,p.z||0);root.rotation.set(0,p.ry||0,0);lean.rotation.set(p.rx||0,0,p.rz||0);const sq=p.sq||0;lean.scale.set(1-sq*.5,1+sq,1-sq*.5);
   // lantern
   const st=E.staff.userData,gl=(p.glow??1)*(.9+Math.sin(now/140)*.05+Math.sin(now/77)*.04);st.glow.material.opacity=Math.min(1,.8*gl);st.glow.scale.setScalar(.22*(.7+.3*gl));st.light.intensity=.6*gl;st.page.rotation.y=now/1600;const rb=spring(SP.rib,-vy*.8,60,5,dt);st.ribbons.forEach((r,i)=>r.rotation.x=Math.sin(now/560+i*1.7)*.15+rb);
   // book: floats above the left palm, lags behind, pages turn by themselves
   grp.updateMatrixWorld(true);bones.haL.getWorldPosition(v);acc.worldToLocal(v);const B=p.book||{};
   w2.set(v.x-handRest.x+bookHome.x+(B.dx||0),v.y-handRest.y+bookHome.y+(B.dy||0)+Math.sin(now/620)*.012,v.z-handRest.z+bookHome.z+(B.dz||0));
   if(B.orbit!=null){const a=B.orbit;w2.set(Math.sin(a)*.52,.98+Math.sin(now/500)*.02,Math.cos(a)*.52);}
   const bk=E.book;if(!bookInit){SP.bx[0]=w2.x;SP.by[0]=w2.y;SP.bz[0]=w2.z;bookInit=true;}
   bk.position.set(spring(SP.bx,w2.x,70,11,dt),spring(SP.by,w2.y,70,11,dt),spring(SP.bz,w2.z,70,11,dt));
   bk.rotation.set(bookRot.x+(B.rx||0),bookRot.y+(B.ry||0)+(B.spin||0),bookRot.z+(B.rz||0)+Math.sin(now/900)*.03);
   const bg=B.glow??1;bk.userData.halo.material.opacity=Math.min(1,(.45+Math.sin(now/430)*.1)*bg);bk.userData.halo.scale.setScalar(.3*(.8+.2*bg));
   flipC+=dt*(p.flip??1)/3.6;const u=flipC%1;bk.userData.flip.forEach((f,i)=>{const s=u*3-i*.2;setFlip(bk,i,Math.max(0,Math.min(1,(s-.35)*1.3))*(u<.98?1:0));});
   bk.userData.motes.forEach(m=>{const k=(now/2600*(bg>1.5?2:1)+m.userData.ph)%1;m.position.set(Math.cos(m.userData.a+now/900)*.05*(1-k),.02+k*.17*(.8+.3*bg),Math.sin(m.userData.a+now/900)*.04*(1-k));m.material.opacity=Math.sin(k*Math.PI)*.9*Math.min(1.4,bg);});
   // loose page (opening: the Archivist catches a falling page)
   const pg=E.page;if(p.page==null){pg.visible=false;}else{pg.visible=true;const hv=v.clone();hv.y+=.05;hv.z+=.04;const k=Math.min(1,p.page);const top=new THREE.Vector3(-.25,1.95,.42);pg.position.lerpVectors(top,hv,k*k);pg.position.x+=Math.sin(now/260)*.05*(1-k);pg.rotation.set(-1.1+Math.sin(now/300)*.5*(1-k),now/700*(1-k),Math.sin(now/220)*.4*(1-k));pg.material.emissiveIntensity=1.1+(p.pageGlow||0);}
  }};
 return rig;}
// ---------- expressions ----------
export const EXPR={
 kind:{label:'Kind',eye:.72,smile:1,brow:.25,hz:.08,hx:.05},
 ponder:{label:'Pondering',eye:.82,brow:.5,browTilt:.12,frown:.2,hx:.08,hy:-.22,b:{shL:[-.95,0,.5],elL:[-1.25,.3,0]},book:{dx:-.1,dy:-.05}},
 amazed:{label:'Amazed',eye:1.22,brow:1,hx:-.14,b:{shL:[-.3,0,-.35],shR:[-.2,0,.2]},book:{dy:.08}},
 stern:{label:'Stern',eye:.6,brow:-.6,frown:1,hx:.12}};
// ---------- helpers ----------
const ease=x=>x<.5?2*x*x:1-Math.pow(-2*x+2,2)/2;const bump=(x,a,b)=>x<a||x>b?0:Math.sin((x-a)/(b-a)*Math.PI);const ramp=(x,a,b)=>ease(Math.max(0,Math.min(1,(x-a)/(b-a))));
const blink=(t,per,off=0)=>(((t+off)%per)/per)>.965?.05:1;const cyc=(t,l)=>(t%l)/l;const TAU=Math.PI*2;
function gait(ph,A={}){const s=Math.sin(ph*TAU),c=Math.cos(ph*TAU);const L=A.leg??.28,K=A.knee??.45;
 const leg=sg=>{const ss=s*sg,cc=c*sg;const th=-L*ss;const kn=.06+K*Math.max(0,cc);return[[th,0,0],[kn,0,0],[-(th+kn)*.8,0,0]];};
 const[tL,kL,fL]=leg(1),[tR,kR,fR]=leg(-1);return{thL:tL,knL:kL,ftL:fL,thR:tR,knR:kR,ftR:fR,hips:[0,s*.06,s*.025],chest:[A.lean||.03,-s*.05,-s*.02]};}
const merge=(...o)=>{const r={};for(const m of o)for(const k in m){const a=r[k]||[0,0,0],v=m[k];r[k]=[a[0]+v[0],a[1]+v[1],a[2]+v[2]];}return r;};
export const CLIPS={
 idle:{label:'Idle',len:5,f:t=>{const b=Math.sin(t*TAU/3.6)*.5+.5;return{y:b*.004,hx:Math.sin(t*.9)*.03,hz:Math.sin(t*.55)*.04,hy:Math.sin(t*.4)*.08,eye:blink(t,4.2,.6)*.92,smile:.35,brow:.1,
  b:{chest:[-b*.025,0,0],spine:[b*.01,0,0],shL:[Math.sin(t*1.1)*.03-b*.02,0,-b*.015],elL:[-Math.sin(t*1.1)*.02,0,0],shR:[b*.015,0,b*.01]}};}},
 read:{label:'Read',len:6,f:t=>{const u=cyc(t,6);const look=ramp(u,0,.12)*(1-ramp(u,.88,1));const nod=bump(u,.45,.6);return{hy:-.42*look,hx:.22*look+nod*.1,hz:-.06*look,eye:(.78+.1*look)*blink(t,3.1,.4),brow:.3*look+nod*.3,frown:.15*look,smile:.2+nod*.5,flip:1.8,
  b:{shL:[-.25*look,0,.12*look],elL:[-.15*look,.2*look,0],chest:[.05*look,-.08*look,0]},book:{dx:.1*look,dy:.07*look,dz:-.04*look,rz:.15*look}};}},
 walk:{label:'Walk',len:1.3,f:t=>{const ph=cyc(t,1.3);const bob=Math.abs(Math.cos(ph*TAU));const s=Math.sin(ph*TAU);return{y:bob*.012,rx:.04,hz:s*.03,hy:s*.04,hx:.02,eye:blink(t,3.7)*.9,smile:.3,
  b:merge(gait(ph),{shR:[-.12-.14*Math.sin(ph*TAU+.4),0,0],elR:[-.06,0,0],shL:[.05*s,0,0],elL:[-.03*s,0,0]})};}},
 suspend:{label:'Suspend',len:3.6,f:t=>{const u=cyc(t,3.6);const up=ramp(u,.05,.25)*(1-ramp(u,.75,.95)),hit=bump(u,.24,.36),hold=ramp(u,.25,.3)*(1-ramp(u,.7,.8));return{upright:1,y:.02*hold,sq:-.04*bump(u,.02,.12)+.03*hit,rx:-.06*up,hx:-.32*up,eye:1+.15*hold,brow:.8*up,frown:.3*hold,glow:1+2.4*hold+2*hit,flip:1+7*hold,
  b:{shR:[-2.35*up,0,.25*up],elR:[-.25*up,0,0],shL:[-.55*up,0,-.45*up],elL:[-.4*up,0,0],chest:[-.12*up,0,0]},book:{dy:.42*up,dx:.18*up,dz:-.1*up,rx:-.5*up,glow:1+2.2*hold}};}},
 reveal:{label:'Reveal',len:3.4,f:t=>{const u=cyc(t,3.4);const up=ramp(u,.04,.2)*(1-ramp(u,.82,.96));const sw=Math.sin(ramp(u,.2,.82)*Math.PI*2)*.75;return{upright:1-.45*up,hx:.05*up,hy:sw*.7*up,eye:1.05,brow:.4*up,glow:1+2.6*up,
  b:{shR:[-1.45*up,sw*.55*up,.1*up],elR:[-.15*up,0,0],chest:[0,sw*.25*up,0],spine:[0,sw*.12*up,0],shL:[-.2*up,0,-.2*up]},book:{dy:.05*up,glow:1+.8*up}};}},
 recall:{label:'Recall',len:3.8,f:t=>{const u=cyc(t,3.8);const d=ramp(u,.05,.3)*(1-ramp(u,.78,.95)),glow=bump(u,.3,.75);return{y:-.07*d,hx:.32*d,eye:.85+.2*glow,brow:.5*glow,smile:.6*glow,
  b:{hips:[.14*d,0,0],spine:[.1*d,0,0],thL:[-.3*d,0,0],knL:[.62*d,0,0],ftL:[-.32*d,0,0],thR:[-.3*d,0,0],knR:[.62*d,0,0],ftR:[-.32*d,0,0],shL:[-.95*d,0,.25*d],elL:[-.1*d,-.4*d,0],shR:[-.2*d,0,0]},book:{dz:.22*d,dy:-.04*d,rx:-.3*d,glow:1+2.6*glow}};}},
 tip:{label:'Tip',len:2.8,f:t=>{const u=cyc(t,2.8);const r=ramp(u,.05,.22)*(1-ramp(u,.8,.95));const nod=Math.sin(ramp(u,.3,.7)*Math.PI*4)*.09;return{hx:.04*r+nod,hz:.12*r,eye:.8*blink(t,2.8,.9),brow:.7*r,browTilt:.1*r,smile:.8*r,
  b:{shL:[-1.75*r,0,-.15*r],elL:[-1.15*r,.35*r,0],chest:[0,.08*r,0]},book:{dx:-.16*r,dy:.02*r,dz:-.08*r}};}},
 guard:{label:'On guard',len:5,f:t=>{const u=cyc(t,5);const scan=Math.sin(u*TAU)*.55;return{hy:scan,hx:-.04,eye:.78,brow:-.4,frown:.7,glow:1.8,
  b:{shR:[-.62,0,.12],elR:[-.55,0,0],chest:[-.03,scan*.2,0],shL:[-.1,0,-.1]},book:{orbit:t*.9}};}},
 celebrate:{label:'Celebrate',len:2.4,f:t=>{const u=cyc(t,2.4);const ch=Math.abs(Math.sin(t*15))*(1-ramp(u,.6,.95));const tap=bump(u,.05,.25);return{y:ch*.012+tap*.02,sq:ch*.012,hx:-.18*ramp(u,0,.15)*(1-ramp(u,.6,.95))+ch*.04,eye:.35,brow:.6,smile:1,glow:1.6,flip:4,
  b:{chest:[-.06*ch,0,0],shR:[-.35*tap,0,0],shL:[-.4*ch,0,-.2*ch]},book:{spin:ease(ramp(u,.1,.8))*TAU,dy:.12*bump(u,.1,.8),glow:2}};}},
 catch:{label:'Catch the page',len:3.8,f:t=>{const u=cyc(t,3.8);const up=ramp(u,.05,.28)*(1-ramp(u,.42,.62)),down=ramp(u,.42,.62)*(1-ramp(u,.9,.98));const fall=Math.min(1,u/.36);return{hx:-.42*up+.2*down,eye:1.15-.3*down,brow:.9*up+.3*down,smile:.8*down,page:u<.95?fall:null,pageGlow:.8*down,
  b:{shL:[-2.45*up-.55*down,0,-.1*up],elL:[-.15*up-.9*down,0,0],chest:[-.1*up,0,0]},book:{dx:-.18*(up+down),dy:.18*(up+down),dz:-.1*(up+down)}};}}};
