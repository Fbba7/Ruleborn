import * as THREE from 'three';
import {partDists,skyCache,cacheArr,fromCache,setAPose,aposeRot} from './skyskipper-sculpt.js';
// ---------- skeleton (sculpt units, character faces +Z) ----------
const J={root:[null,[0,0,0]],hips:['root',[0,.4,0]],chest:['hips',[0,.54,.05]],head:['chest',[0,.64,.07]],
 earL:['head',[-.066,.9,.01]],earL2:['earL',[-.124,1.07,-.06]],earR:['head',[.066,.9,.01]],earR2:['earR',[.11,1.08,-.056]],
 shL:['chest',[-.12,.56,.03]],elL:['shL',[-.22,.5,-.04]],haL:['elL',[-.29,.44,0]],
 shR:['chest',[.12,.57,.05]],elR:['shR',[.185,.47,.13]],haR:['elR',[.205,.455,.27]],
 thL:['hips',[-.085,.36,-.03]],knL:['thL',[-.09,.28,-.1]],ftL:['knL',[-.1,.23,-.2]],
 thR:['hips',[.085,.36,.03]],knR:['thR',[.09,.28,.1]],ftR:['knR',[.1,.19,.18]],tail:['hips',[0,.37,-.16]]};
const TIP={haL:[-.34,.42,.01],haR:[.21,.47,.34],ftL:[-.1,.158,-.08],ftR:[.1,.142,.38],earL2:[-.178,1.215,-.14],earR2:[.13,1.235,-.088]};
export const APOSE_A=.7;setAPose(APOSE_A);for(const b of['elR','haR'])J[b][1]=aposeRot(J[b][1],'R');for(const b of['elL','haL'])J[b][1]=aposeRot(J[b][1],'L');TIP.haR=aposeRot(TIP.haR,'R');TIP.haL=aposeRot(TIP.haL,'L');
const BONES=Object.keys(J);
const PART=n=>{if(/^ear-1(0)$/.test(n)||n==='ear-10')return'earL';if(/^ear-1[12]$/.test(n))return'earL2';if(n==='ear10')return'earR';if(/^ear1[12]$/.test(n))return'earR2';
 if(n==='armR1')return'shR';if(n==='armR2')return'elR';if(/pawR|wristR|finger1|thumb1/.test(n))return'haR';if(n==='armL1')return'shL';if(n==='armL2')return'elL';if(/pawL|wristL|finger-1|thumb-1/.test(n))return'haL';
 if(n==='haunchR')return'thR';if(n==='shinR')return'knR';if(/footR|toeR|heelR/.test(n))return'ftR';if(n==='haunchL')return'thL';if(n==='shinL')return'knL';if(/footL|toeL|heelL/.test(n))return'ftL';
 if(/tail/.test(n))return'tail';if(n==='belly')return'hips';if(/chest|neck/.test(n))return'chest';return'head';};
const TORSO={hips:[[0,.28,-.01],[0,.5,.04],.17],chest:[[0,.5,.05],[0,.62,.08],.12],head:[[0,.66,.08],[0,.86,.1],.19]};
const segD=(x,y,z,a,b)=>{const ax=b[0]-a[0],ay=b[1]-a[1],az=b[2]-a[2];const px=x-a[0],py=y-a[1],pz=z-a[2];let t=(px*ax+py*ay+pz*az)/(ax*ax+ay*ay+az*az);t=t<0?0:t>1?1:t;const dx=px-ax*t,dy=py-ay*t,dz=pz-az*t;return Math.sqrt(dx*dx+dy*dy+dz*dz);};
function skinGeo(g){if(g.userData.skinned)return;const SC=skyCache(),SK=g.userData.ck&&SC[g.userData.ck];if(SK&&SK.si){g.setAttribute('skinIndex',new THREE.Uint16BufferAttribute(fromCache(SK.si),4));g.setAttribute('skinWeight',new THREE.Float32BufferAttribute(fromCache(SK.sw),4));g.userData.skinned=true;return;}const P=g.attributes.position,n=P.count,NB=BONES.length;const bi=Object.fromEntries(BONES.map((b,i)=>[b,i]));const W=new Float32Array(n*NB);const side=new Uint8Array(n),tor=new Uint8Array(n);
 for(let v=0;v<n;v++){const x=P.getX(v),y=P.getY(v),z=P.getZ(v);let best=null,bd=1e9,dT=1e9;for(const[name,d]of partDists(x,y,z)){if(d<bd){bd=d;best=name;}if((name==='belly'||name==='chest')&&d<dT)dT=d;}let b=best?PART(best):'hips';
  if(/^tuft|^chestFluff/.test(best||''))b=y>.64?'head':'chest';
  if(b==='hips'||b==='chest'||b==='head'){tor[v]=1;let tot=0;const w={};for(const k in TORSO){const[A,B,rad]=TORSO[k];const dn=segD(x,y,z,A,B)/rad;w[k]=Math.exp(-dn*7);tot+=w[k];}for(const k in w)W[v*NB+bi[k]]=w[k]/tot;}
  else if(b==='shL'||b==='shR'){const sj=J[b][1],ej=J[b==='shL'?'elL':'elR'][1];const ax=ej[0]-sj[0],ay=ej[1]-sj[1],az=ej[2]-sj[2];const tt=((x-sj[0])*ax+(y-sj[1])*ay+(z-sj[2])*az)/(ax*ax+ay*ay+az*az);const px=sj[0]+ax*tt-x,py=sj[1]+ay*tt-y,pz=sj[2]+az*tt-z,dp=Math.sqrt(px*px+py*py+pz*pz);const u=Math.max(0,Math.min(1,(tt+.02)/.32)),sm=u*u*(3-2*u);const fo=Math.exp(-Math.pow(Math.max(0,dp-.048)/.022,2));let wa=sm*fo;if(dT<.012&&y<sj[1]-.015)wa*=.25;if(wa<.5)side[v]=1;let tot=0;const w={};for(const k in TORSO){const[A2,B2,rad]=TORSO[k];const dn=segD(x,y,z,A2,B2)/rad;w[k]=Math.exp(-dn*7);tot+=w[k];}for(const k in w)W[v*NB+bi[k]]+=(1-wa)*w[k]/tot;W[v*NB+bi[b]]+=wa;}
  else W[v*NB+bi[b]]=1;}
 // smooth weights across the surface so joints bend instead of tearing
 const I=g.index.array,adj=Array.from({length:n},()=>[]);for(let i=0;i<I.length;i+=3){const a=I[i],b=I[i+1],c=I[i+2];adj[a].push(b,c);adj[b].push(a,c);adj[c].push(a,b);}
 let A=W,B=new Float32Array(n*NB);for(let it=0;it<4;it++){for(let v=0;v<n;v++){const nb=adj[v];const o=v*NB;for(let k=0;k<NB;k++){let s=0;for(const u of nb)s+=A[u*NB+k];B[o+k]=nb.length?A[o+k]*.5+.5*s/nb.length:A[o+k];}}const t=A;A=B;B=t;}
 {const armB=['shL','shR','elL','elR'].map(k=>bi[k]),shy=J.shR[1][1];for(let v=0;v<n;v++){if(!(tor[v]||side[v]))continue;const y=P.getY(v);if(y>shy-.01)continue;const o=v*NB;const k=Math.max(0,Math.min(1,(shy-.01-y)/.05));for(const a of armB){const d=A[o+a]*(.9*k);A[o+a]-=d;A[o+bi.chest]+=d;}}}
 const si=new Uint16Array(n*4),sw=new Float32Array(n*4);for(let v=0;v<n;v++){const o=v*NB;const ids=[...Array(NB).keys()].sort((p,q)=>A[o+q]-A[o+p]).slice(0,4);let tot=0;for(const k of ids)tot+=A[o+k];ids.forEach((k,j)=>{si[v*4+j]=k;sw[v*4+j]=tot?A[o+k]/tot:(j?0:1);});}
 {const FM=g.attributes.furMask;if(FM){const arm=new Set(['shL','shR','elL','elR'].map(k=>bi[k]));for(let v=0;v<n;v++){let a=0;for(let j=0;j<4;j++)if(arm.has(si[v*4+j]))a+=sw[v*4+j];}FM.needsUpdate=true;}
  const CO=g.attributes.color;if(CO){const arm=new Set(['shL','shR','elL','elR'].map(k=>bi[k]));const mix=new Float32Array(n);for(let v=0;v<n;v++){let a=0;for(let j=0;j<4;j++)if(arm.has(si[v*4+j]))a+=sw[v*4+j];mix[v]=a>.04&&a<.96?1:0;}const c=CO.array;let src=new Float32Array(c),dst=new Float32Array(c);const gold=(A,v)=>A[v*3+2]<A[v*3]*.6;for(let it=0;it<4;it++){for(let v=0;v<n;v++){if(!mix[v]||gold(src,v))continue;let R=0,G=0,B=0,k=0,t=0;for(const u of adj[v]){t++;if(!gold(src,u))continue;R+=src[u*3];G+=src[u*3+1];B+=src[u*3+2];k++;}if(k&&k>=t*.5){src[v*3]=R/k;src[v*3+1]=G/k;src[v*3+2]=B/k;}}}for(let it=0;it<5;it++){for(let v=0;v<n;v++){dst[v*3]=src[v*3];dst[v*3+1]=src[v*3+1];dst[v*3+2]=src[v*3+2];if(!mix[v]||!gold(src,v))continue;let R=src[v*3],G=src[v*3+1],B=src[v*3+2],k=1;for(const u of adj[v]){if(!gold(src,u))continue;R+=src[u*3];G+=src[u*3+1];B+=src[u*3+2];k++;}dst[v*3]=R/k;dst[v*3+1]=G/k;dst[v*3+2]=B/k;}const t=src;src=dst;dst=t;}c.set(src);CO.needsUpdate=true;}}
 g.setAttribute('skinIndex',new THREE.Uint16BufferAttribute(si,4));g.setAttribute('skinWeight',new THREE.Float32BufferAttribute(sw,4));g.userData.skinned=true;if(SK){SK.si=cacheArr(si);SK.sw=cacheArr(sw);}}
function stripUD(root){const saved=[];root.traverse(o=>{saved.push([o,o.userData]);const u={};for(const k in o.userData){const v=o.userData[k];if(v===null||typeof v!=='object')u[k]=v;}o.userData=u;});return()=>saved.forEach(([o,u])=>o.userData=u);}
const V=(a)=>new THREE.Vector3(...a);
// ---------- rest (standing) pose: aim each limb segment ----------
const AIM=[['shL','elL',[-.22,-1,.08]],['elL','haL',[-.08,-1,.32]],
 ['thL','knL',[0,-1,.22]],['knL','ftL',[0,-1,-.12]],['ftL','TIP',[0,-.12,1]],['thR','knR',[0,-1,.22]],['knR','ftR',[0,-1,-.12]],['ftR','TIP',[0,-.12,1]],
 ['earL','earL2',[-.28,1,-.18]],['earR','earR2',[.28,1,-.18]]];
export function makeRig(src,opt={}){
 const g=src.getObjectByName('body').geometry;skinGeo(g);
 const restore=stripUD(src);const grp=src.clone(true);restore();
 const bones={};for(const b of BONES){const o=new THREE.Bone();o.name=b;bones[b]=o;}for(const b of BONES){const[p,w]=J[b];if(p){bones[p].add(bones[b]);bones[b].position.copy(V(w).sub(V(J[p][1])));}else bones[b].position.set(...w);}
 const skel=new THREE.Skeleton(BONES.map(b=>bones[b]));
 const meshes=[];for(const o of [...grp.children]){if(o.isMesh&&(o.name==='body'||o.name.startsWith('fur_shell'))){const sm=new THREE.SkinnedMesh(o.geometry,o.name==='body'?(()=>{const m=o.material.clone();m.side=THREE.DoubleSide;m.shadowSide=THREE.FrontSide;return m;})():o.material);sm.name=o.name;sm.castShadow=o.castShadow;sm.receiveShadow=o.receiveShadow;sm.frustumCulled=false;grp.remove(o);grp.add(sm);meshes.push(sm);}else if(o.name==='outline')grp.remove(o);}
 meshes[0].add(bones.root);meshes.forEach(m=>m.bind(skel));
 grp.updateMatrixWorld(true);
 // accessories -> bones
 const acc=grp.children.find(c=>!c.isMesh&&c.children.length);const coins=[];grp.traverse(o=>{if(o.name==='coin')coins.push(o);});
 const box=new THREE.Box3(),c=new THREE.Vector3();
 if(acc)for(const ch of [...acc.children]){if(ch.name==='coin')continue;box.setFromObject(ch);box.getCenter(c);let b='chest';if(/satchel/.test(ch.name))b='hips';else if(c.y>.64)b='head';bones[b].attach(ch);}
 let held=null;const hp=V(TIP.haR);coins.forEach(k=>{k.getWorldPosition(c);const d=c.distanceTo(hp);if(!held||d<held.y)held={k,y:d};});coins.forEach(k=>{if(k===held.k)bones.haR.attach(k);else k.visible=false;});
 const eyes=['eye_L','eye_R'].map(n=>grp.getObjectByName(n)).filter(Boolean);eyes.forEach(e=>e.userData.s0=e.scale.clone());
 // rest pose
 const tipW=b=>V(TIP[b]);
 for(const[a,ch,t]of AIM){const A=bones[a];A.updateMatrixWorld(true);const pa=new THREE.Vector3().setFromMatrixPosition(A.matrixWorld);let pc;if(ch==='TIP'){pc=tipW(a).sub(V(J[a][1])).applyQuaternion(A.getWorldQuaternion(new THREE.Quaternion())).add(pa);}else{bones[ch].updateMatrixWorld(true);pc=new THREE.Vector3().setFromMatrixPosition(bones[ch].matrixWorld);}
  const cur=pc.sub(pa).normalize(),tgt=V(t).normalize();const pq=A.parent.getWorldQuaternion(new THREE.Quaternion());const wq=A.getWorldQuaternion(new THREE.Quaternion());const dq=new THREE.Quaternion().setFromUnitVectors(cur,tgt);const nq=dq.multiply(wq);A.quaternion.copy(pq.invert().multiply(nq));A.updateMatrixWorld(true);}
{const A=bones.shR;A.updateMatrixWorld(true);const pq=A.parent.getWorldQuaternion(new THREE.Quaternion());const wq=A.getWorldQuaternion(new THREE.Quaternion());const zq=new THREE.Quaternion().setFromAxisAngle(new THREE.Vector3(0,0,1),-APOSE_A);A.quaternion.copy(pq.invert().multiply(zq.multiply(wq)));A.updateMatrixWorld(true);}
 bones.hips.quaternion.premultiply(new THREE.Quaternion().setFromEuler(new THREE.Euler(-.12,0,0)));
 const base={};for(const b of BONES)base[b]=bones[b].quaternion.clone();
 {const sm=meshes[0],G=sm.geometry,FM=G.attributes.furMask,CO=G.attributes.color;if(FM&&!G.userData.stretchFix&&!window.__noFix){G.userData.stretchFix=1;const __t0=performance.now();const P=G.attributes.position,n=P.count,I=G.index.array;const rest=new Float32Array(n*3);for(let v=0;v<n;v++){rest[v*3]=P.getX(v);rest[v*3+1]=P.getY(v);rest[v*3+2]=P.getZ(v);}
  const bad=new Uint8Array(n);const zone=[];for(let v=0;v<n;v++){const x=rest[v*3],y=rest[v*3+1];if(y>.36&&y<.64&&Math.abs(x)>.05&&Math.abs(x)<.27)zone.push(v);}const inZ=new Uint8Array(n);for(const v of zone)inZ[v]=1;const tris=[];for(let t=0;t<I.length;t+=3)if(inZ[I[t]]&&inZ[I[t+1]]&&inZ[I[t+2]])tris.push(t);const tv=new THREE.Vector3(),qq=new THREE.Quaternion(),ee=new THREE.Euler();
  const poses=[{shL:[-1.2,0,-.3],shR:[-1.45,0,.3],elL:[-1.4,0,0],elR:[-1.25,0,0]},{shL:[-1.2,.2,-.6],shR:[-1.45,-.2,.6],elL:[-.55,0,0],elR:[-.55,0,0]},{shL:[.6,0,-.2],shR:[.6,0,.2]}];
  for(const ps of poses){for(const b of BONES)bones[b].quaternion.copy(base[b]);for(const b in ps){const o=ps[b];qq.setFromEuler(ee.set(o[0],o[1],o[2],'YXZ'));bones[b].quaternion.premultiply(qq);}grp.updateMatrixWorld(true);sm.skeleton.update();
   const sk=new Float32Array(n*3);for(const v of zone){tv.set(rest[v*3],rest[v*3+1],rest[v*3+2]);sm.applyBoneTransform(v,tv);sk[v*3]=tv.x;sk[v*3+1]=tv.y;sk[v*3+2]=tv.z;}
   const L=(A,i,j)=>Math.hypot(A[i*3]-A[j*3],A[i*3+1]-A[j*3+1],A[i*3+2]-A[j*3+2]);
   for(const t of tris){const i=I[t],j=I[t+1],k=I[t+2];const r0=Math.max(L(sk,i,j)/(L(rest,i,j)+1e-6),L(sk,j,k)/(L(rest,j,k)+1e-6),L(sk,k,i)/(L(rest,k,i)+1e-6));if(r0>1.9){bad[i]=bad[j]=bad[k]=1;}}}
  for(const b of BONES)bones[b].quaternion.copy(base[b]);grp.updateMatrixWorld(true);
  const adj=new Map();const ad=(a,b)=>{let l=adj.get(a);if(!l)adj.set(a,l=[]);l.push(b);};for(const t of tris){const i=I[t],j=I[t+1],k=I[t+2];ad(i,j);ad(i,k);ad(j,i);ad(j,k);ad(k,i);ad(k,j);}const nb=v=>adj.get(v)||[];
  let m=bad;for(let it=0;it<1;it++){const nm=new Uint8Array(m);for(const v of zone)if(m[v])for(const u of nb(v))nm[u]=1;m=nm;}
  let cnt=0;const NN=G.attributes.normal;for(const v of zone)if(m[v]){const nx=NN.getX(v),ny=NN.getY(v),x=rest[v*3];const under=ny<-.2||(x<0?nx>.2:nx<-.2);FM.setX(v,Math.min(FM.getX(v),bad[v]?.55:.8));cnt++;}for(let it=0;it<4;it++){const fa=FM.array,fb=new Float32Array(fa);for(const v of zone){const L2=nb(v);if(!L2.length)continue;let s2=fa[v];for(const u of L2)s2+=fa[u];const av=s2/(L2.length+1);if(fa[v]>.05)fb[v]=Math.min(fa[v]<1?fa[v]:1,av)*.5+fa[v]*.5;}fa.set(fb);}FM.needsUpdate=true;
  if(CO){const c=CO.array;const gd=v=>c[v*3+2]<c[v*3]*.6;for(let it=0;it<3;it++)for(const v of zone){if(!m[v]||gd(v))continue;let R=0,Gc=0,B=0,k=0,t=0;for(const u of nb(v)){t++;if(!gd(u))continue;R+=c[u*3];Gc+=c[u*3+1];B+=c[u*3+2];k++;}if(k&&k>=t*.5){c[v*3]=R/k;c[v*3+1]=Gc/k;c[v*3+2]=B/k;}}for(let it=0;it<3;it++){const d=new Float32Array(c);for(const v of zone){if(!m[v]||!gd(v))continue;let R=c[v*3],Gc=c[v*3+1],B=c[v*3+2],kk=1;for(const u of nb(v)){if(!gd(u))continue;R+=c[u*3];Gc+=c[u*3+1];B+=c[u*3+2];kk++;}d[v*3]=R/kk;d[v*3+1]=Gc/kk;d[v*3+2]=B/kk;}c.set(d);}CO.needsUpdate=true;}
  G.userData.stretchCount=cnt;}}
 grp.updateMatrixWorld(true);const fy=Math.min(new THREE.Vector3().setFromMatrixPosition(bones.ftL.matrixWorld).y,new THREE.Vector3().setFromMatrixPosition(bones.ftR.matrixWorld).y);const lift=.052-fy;
 const root=new THREE.Group();root.name='skyskipper_rig';const lean=new THREE.Group();lean.position.y=.25;grp.position.y=-.25+lift;root.add(lean);lean.add(grp);
 const q=new THREE.Quaternion(),e=new THREE.Euler();
 const SP={earL:[0,0],earR:[0,0],earL2:[0,0],earR2:[0,0],tail:[0,0],head:[0,0],lagZ:[0,0],shLx:[0,0],shRx:[0,0],shLz:[0,0],shRz:[0,0],hL:[0,0],hR:[0,0]};let armInit=false;let lastY=null,lastRy=null,lastT=performance.now(),prevP=null,blendFrom=null,blendT0=0,lastClip=null;
 const spring=(s,tgt,k,c,dt)=>{s[1]+=((tgt-s[0])*k-s[1]*c)*dt;s[0]+=s[1]*dt;return s[0];};
 const rig={root,bones,coins:[held.k],
  play(p,clip){if(clip!==lastClip){if(prevP&&lastClip!==null){blendFrom=prevP;blendT0=performance.now();}lastClip=clip;}let q=p;if(blendFrom){const w=Math.min(1,(performance.now()-blendT0)/260);const e2=w*w*(3-2*w);q=blendPose(blendFrom,p,e2);if(w>=1)blendFrom=null;}prevP=q;this.set(q);},
  set(p){const now=performance.now(),dt=Math.min(.05,(now-lastT)/1000)||.016;lastT=now;
   const y=(p.y||0)+(p.sq||0)*.3,vy=lastY==null?0:(y-lastY)/dt;lastY=y;const ry=(root.parent&&root.parent.rotation?root.parent.rotation.y:0)+(p.ry||0),wy=lastRy==null?0:Math.atan2(Math.sin(ry-lastRy),Math.cos(ry-lastRy))/dt;lastRy=ry;
   const fl=spring(SP.earL,Math.max(-.6,Math.min(.6,-vy*.9)),160,11,dt),fr=spring(SP.earR,Math.max(-.6,Math.min(.6,-vy*.9)),150,10,dt);
   const tw=spring(SP.earL2,Math.max(-.5,Math.min(.5,-wy*.12)),120,9,dt),tw2=spring(SP.earR2,Math.max(-.5,Math.min(.5,-wy*.12)),110,8,dt);
   const tl=spring(SP.tail,Math.max(-.5,Math.min(.5,-vy*.6)),200,12,dt),hd=spring(SP.head,Math.max(-.25,Math.min(.25,vy*.18)),220,16,dt);
   for(const b of BONES)bones[b].quaternion.copy(base[b]);
   const off=Object.assign({},p.b||{});const put=(b,x,y,z)=>{const o=off[b]||[0,0,0];off[b]=[o[0]+(x||0),o[1]+(y||0),o[2]+(z||0)];};
   put('head',(p.hx||0)+hd,p.hy,p.hz);put('earL',(p.elx||0)+fl,tw*.4,p.elz);put('earR',(p.erx??p.elx??0)+fr,tw2*.4,p.erz??-(p.elz||0));put('earL2',fl*.7,0,tw*.6);put('earR2',fr*.7,0,-tw2*.6);put('tail',tl,Math.sin(now/260)*.12,0);
   {const g=(b,i)=>(off[b]||[0,0,0])[i];if(!armInit){SP.shLx[0]=g('shL',0);SP.shRx[0]=g('shR',0);SP.shLz[0]=g('shL',2);SP.shRz[0]=g('shR',2);armInit=true;}
    const sLx=spring(SP.shLx,g('shL',0),240,22,dt),sRx=spring(SP.shRx,g('shR',0),260,24,dt),sLz=spring(SP.shLz,g('shL',2),240,22,dt),sRz=spring(SP.shRz,g('shR',2),260,24,dt);
    const lagL=Math.max(-.5,Math.min(.5,sLx-g('shL',0))),lagR=Math.max(-.35,Math.min(.35,sRx-g('shR',0)));
    const wL=spring(SP.hL,lagL,120,11,dt),wR=spring(SP.hR,lagR,120,11,dt);
    const shLx=g('shL',0)+lagL*.35,shLc=Math.max(-1.2,shLx),exL=shLx-shLc;off.shL=[shLc,g('shL',1),g('shL',2)+(sLz-g('shL',2))*.4];off.shR=[Math.max(-1.45,g('shR',0)+lagR*.3),g('shR',1),g('shR',2)+(sRz-g('shR',2))*.4];
    const elb=(v,l)=>Math.max(-2.3,Math.min(-.06,v-Math.abs(l)*.45));off.elL=[elb(g('elL',0)-.08+exL*.7,lagL),g('elL',1),g('elL',2)];off.elR=[Math.max(-2.3,Math.min(1.5,g('elR',0)-.08-Math.abs(lagR)*.45)),g('elR',1),g('elR',2)];
    off.haL=[Math.max(-1.1,Math.min(.5,g('haL',0)+wL*.6)),g('haL',1),g('haL',2)+Math.sin(now/900)*.03];off.haR=[Math.max(-.9,Math.min(.4,g('haR',0)+wR*.3)),g('haR',1),g('haR',2)];}
   for(const b in off){if(!bones[b])continue;const o=off[b];q.setFromEuler(e.set(o[0],o[1],o[2],'YXZ'));bones[b].quaternion.premultiply(bones[b].parent.getWorldQuaternion?q:q);}
   const ey=p.eye??1,ew=p.eyeW??1;eyes.forEach(k=>k.scale.set(k.userData.s0.x*ew,k.userData.s0.y*ey,k.userData.s0.z));
   root.position.set(p.x||0,p.y||0,p.z||0);root.rotation.set(0,p.ry||0,0);lean.rotation.set(p.rx||0,0,p.rz||0);const sq=p.sq||0;lean.scale.set(1-sq*.5,1+sq,1-sq*.5);
   const k=held.k;if(!k.userData.s0)k.userData.s0=k.scale.clone();k.scale.copy(k.userData.s0).multiplyScalar(p.coin??1);if(p.coinSpin!=null)k.rotation.y=p.coinSpin;k.visible=p.coinOff?false:true;}};
 return rig;}
// ---------- expressions ----------
export const EXPR={
 happy:{label:'Cheeky',hz:-.12,hx:.04,elx:-.15,elz:.18,erx:-.05,erz:-.05,b:{shR:[.05,0,.05],elR:[-.25,0,0],shL:[.1,0,-.25],elL:[-.3,0,0]}},
 focus:{label:'Focused',hx:.14,elx:-.55,elz:.08,eye:.62,eyeW:1.04,b:{shL:[-.4,0,-.2],shR:[.08,0,.05],elL:[-.8,0,0],elR:[-.06,0,0]}},
 startled:{label:'Startled',hx:-.12,elx:.25,elz:-.05,eye:1.18,eyeW:1.1,b:{shL:[-.3,0,-.9],shR:[.15,0,.35],elL:[-.5,0,0],elR:[-.06,0,0]}},
 caught:{label:'Caught',hx:.28,hz:.06,elx:.1,elz:.9,erz:-.9,eye:.7,b:{shL:[.1,0,.15],shR:[.1,0,-.15],chest:[.15,0,0]}}};
// ---------- helpers ----------
const ease=x=>x<.5?2*x*x:1-Math.pow(-2*x+2,2)/2;const bump=(x,a,b)=>x<a||x>b?0:Math.sin((x-a)/(b-a)*Math.PI);
const blink=(t,per,off=0)=>(((t+off)%per)/per)>.96?.12:1;const cyc=(t,l)=>(t%l)/l;const TAU=Math.PI*2;
// gait: phase ph (0..1), amplitudes; returns bone offsets for legs + arms
function gait(ph,A={}){const s=Math.sin(ph*TAU),c=Math.cos(ph*TAU);const L=A.leg??.5,K=A.knee??.8,R=A.arm??.45;
 const leg=(sg)=>{const ss=s*sg,cc=c*sg;const th=-L*ss;const sw=Math.max(0,cc);const kn=.1+K*sw*sw*(3-2*sw)+.12*Math.max(0,-cc)*Math.max(0,-ss);const roll=.32*Math.max(0,ss)*Math.max(0,-cc)-.28*Math.max(0,-ss)*Math.max(0,-cc);return[[th,0,0],[kn,0,0],[-(th+kn)*.72+roll+(A.toe??0)*Math.max(0,-cc),0,0]];};
 const[tL,kL,fL]=leg(1),[tR,kR,fR]=leg(-1);const b={thL:tL,knL:kL,ftL:fL,thR:tR,knR:kR,ftR:fR};
 if(R){const sa=Math.sin((ph-.06)*TAU),se=Math.sin((ph-.16)*TAU);b.shL=[R*sa*(sa>0?.55:1)+(A.armX||0),-.06*sa,-(A.armOut||0)-.16-.12*Math.max(0,sa)];const RK=A.armRk??.3;b.shR=[-R*RK*sa+.16+(A.armX||0)*RK,0,(A.armOut||0)*RK+.05];b.elL=[-(A.elb??.35)-Math.max(0,-se)*.34-.05,0,0];b.elR=[-.22-Math.max(0,se)*.08,0,0];b.haL=[-.1+.16*se,0,.04*se];b.haR=[-.08,0,0];}
 const sway=Math.sin(ph*TAU)*(A.sway??.045);b.hips=[0,s*(A.twist??.08),sway];b.chest=[A.lean||0,-s*(A.twist??.08)*1.2,-sway*1.4];return b;}
export function blendPose(a,b,w){const o={};const keys=new Set([...Object.keys(a),...Object.keys(b)]);for(const k of keys){if(k==='b')continue;const va=a[k],vb=b[k];if(typeof va==='number'||typeof vb==='number'){const da=k==='eye'||k==='eyeW'||k==='coin'?1:0;o[k]=(va??da)+((vb??da)-(va??da))*w;}else o[k]=w<.5?va:vb;}o.b={};const bk=new Set([...Object.keys(a.b||{}),...Object.keys(b.b||{})]);for(const k of bk){const x=(a.b||{})[k]||[0,0,0],y=(b.b||{})[k]||[0,0,0];o.b[k]=[x[0]+(y[0]-x[0])*w,x[1]+(y[1]-x[1])*w,x[2]+(y[2]-x[2])*w];}if(a.coinSpin!=null&&b.coinSpin!=null)o.coinSpin=b.coinSpin;return o;}
const merge=(...o)=>{const r={};for(const m of o)for(const k in m){const a=r[k]||[0,0,0],v=m[k];r[k]=[a[0]+v[0],a[1]+v[1],a[2]+v[2]];}return r;};
export const CLIPS={
 idle:{label:'Idle',len:4,f:t=>{const b=Math.sin(t*Math.PI)*.5+.5;const tw=bump(t%4,2.6,2.9);return{sq:b*.014,hx:Math.sin(t*1.6)*.03,hz:Math.sin(t*.8)*.05,elx:-.1-tw*.35,elz:.08,erx:-.05,erz:-.06,eye:blink(t,4,.5),coinSpin:t*2,
  b:{chest:[-b*.03,0,0],shL:[Math.sin(t*1.3)*.05-b*.03,0,-.06-b*.03],shR:[Math.sin(t*1.3+1)*.04,0,-.02],elR:[-.18,0,0],elL:[-.22-b*.05,0,0],haL:[Math.sin(t*1.1)*.06,0,0]}};}},
 idle2:{label:'Idle 2',len:5,f:t=>{const u=cyc(t,5);const look=u<.3?ease(u/.3):u<.6?1:u<.8?1-ease((u-.6)/.2)*2:-1+ease((u-.8)/.2);const scr=bump(u,.3,.58);return{hy:look*.45,hz:look*.08+scr*.15,elx:-.05+scr*.3,elz:.1,erz:-.1-bump(u,.62,.72)*.5,eye:blink(t,2.5,.2),coinSpin:t*2,
  b:{hips:[0,0,look*.05],thL:[0,0,look*.04],thR:[0,0,look*.04],shL:[-scr*2.5,0,-scr*.5],elL:[-scr*1.4+Math.sin(t*20)*scr*.15,0,0],shR:[0,0,0],elR:[-.06,0,0]}};}},
 walk:{label:'Walk',len:.92,f:t=>{const ph=cyc(t,.92);const bob=Math.abs(Math.cos(ph*TAU)),dip=Math.pow(1-bob,3);return{y:bob*.016-dip*.01,sq:-dip*.018,rx:.05,rz:Math.sin(ph*TAU)*.025,hz:Math.sin(ph*TAU)*.03,hx:-.02-bob*.03,hy:Math.sin(ph*TAU)*.05,elx:.02,elz:.1,eye:blink(t,3.3),coinSpin:t*3,b:gait(ph,{leg:.48,knee:.8,arm:.42})};}},
 run:{label:'Run',len:.5,f:t=>{const ph=cyc(t,.5);const fly=Math.abs(Math.sin(ph*TAU)),land=Math.pow(1-fly,4);return{y:.015+fly*.055,sq:fly*.03-land*.06,rx:.26+land*.05,rz:Math.sin(ph*TAU)*.03,hx:-.12,elx:-.62,elz:.04,coinSpin:t*8,b:gait(ph,{leg:.85,knee:1.35,arm:.9,elb:1.15,lean:.05,twist:.12,toe:.45,sway:.02})};}},
 carry:{label:'Carry',len:1.1,f:t=>{const ph=cyc(t,1.1);const bob=Math.abs(Math.cos(ph*TAU));return{y:bob*.012,sq:-Math.pow(1-bob,2)*.035,rx:-.04,rz:Math.sin(ph*TAU)*.07,hx:.06,elx:-.3,elz:.14,eye:blink(t,2.2,.4),coin:1.4,coinSpin:0,b:merge(gait(ph,{leg:.35,knee:.65,arm:0,twist:.04,sway:.07}),{shL:[-.55,.2,.5],elL:[-1.05,0,0],haL:[-.3,0,0],shR:[.12,0,-.08],elR:[-.06,0,0],chest:[-.08,0,0]})};}},
 climb:{label:'Climb',len:1.4,f:t=>{const ph=cyc(t,1.4);const s=Math.sin(ph*TAU),c=Math.cos(ph*TAU);return{y:.05+ph*.06,rx:-.2,hx:-.28,elx:-.4,elz:.1,coinOff:true,b:{shL:[-1.55+.12*s,0,-.3],elL:[-1.25-.5*Math.max(0,-s),0,0],haL:[-.7,0,0],shR:[-1.55-.12*s,0,.3],elR:[-.1-.2*Math.max(0,s),0,0],haR:[-.7,0,0],thL:[-.9-.45*s,0,-.1],knL:[1.1+.4*s,0,0],ftL:[-.4,0,0],thR:[-.9+.45*s,0,.1],knR:[1.1-.4*s,0,0],ftR:[-.4,0,0],hips:[0,0,c*.06]}};}},
 leap:{label:'Leap',len:1.6,f:t=>{const u=cyc(t,1.6);const cr=bump(u,0,.2)+bump(u,.8,.98),air=bump(u,.16,.82);const tuck=bump(u,.3,.7);return{y:air*.36-cr*.05,z:air*.08,sq:-cr*.1+air*.06,rx:-cr*.1+air*.2,hx:cr*.15-air*.12,elx:.5*air-.2*cr,elz:.1,eye:1-cr*.25,coinSpin:t*8,
  b:{thL:[-1.1*cr-1.2*tuck+.4*air,0,0],knL:[1.5*cr+1.6*tuck,0,0],ftL:[-.4*cr,0,0],thR:[-1.1*cr-1.2*tuck+.4*air,0,0],knR:[1.5*cr+1.6*tuck,0,0],ftR:[-.4*cr,0,0],shL:[-1.7*air+.6*cr,0,-.4*air-.1*cr],shR:[-1.7*air+.6*cr,0,.4*air+.1*cr],elL:[-.8*air-.5*cr,0,0],elR:[-.8*air-.5*cr,0,0],haL:[.3*air-.3*cr,0,0],haR:[.2*air,0,0],chest:[.2*cr,0,0]}};}},
 slide:{label:'Slide',len:1.6,f:t=>{const u=cyc(t,1.6);const go=ease(Math.min(1,u/.7));const wob=Math.sin(t*9)*.06*(1-go);return{z:-.25+go*.5,rx:-.18,rz:wob,hx:-.1,elx:-.75,elz:.02,eye:1.1,eyeW:1.05,sq:-.05,coinSpin:t*5,b:{thR:[-.85,0,.1],knR:[.25,0,0],ftR:[.5,0,0],thL:[.35,0,-.1],knL:[.95,0,0],ftL:[-.3,0,0],shL:[-.35,.1,-1.15+wob*3],shR:[.25,0,.3-wob*2],elL:[-.4,0,0],elR:[-.06,0,0],haL:[.25+wob*2,0,0],haR:[.1,0,0]}};}},
 wade:{label:'Wade',len:2.2,f:t=>{const ph=cyc(t,2.2);const w=Math.sin(ph*TAU);return{y:-.09,rx:.1,rz:w*.08,hz:-w*.06,hx:-.05,elx:.05,elz:.2,erz:-.2,eye:.85,coinSpin:t,b:merge(gait(ph,{leg:.3,knee:1,arm:0,twist:.05}),{shL:[-.35,0,-.8+w*.12],shR:[-.3,0,.35+w*.12],elL:[-.85,0,0],elR:[1.25,0,0],haL:[.3+w*.15,0,0],haR:[.2-w*.15,0,0]})};}},
 ability:{label:'Ability',len:1.4,f:t=>{const u=cyc(t,.35);const hop=Math.sin(u*Math.PI);const sc=Math.sin(t*TAU/.35);return{y:hop*.05,sq:hop*.04-(1-hop)*.04,rx:.12,rz:Math.sin(t*14)*.03,hx:.3,hz:.12,elx:-.3+Math.sin(t*9)*.12,elz:.12,coin:1.3,coinSpin:t*14,eye:.8,
  b:{shR:[.25+.25*sc,.15,-.05],elR:[.45+.25*sc,0,0],shL:[-.9-.35*sc,0,.55],elL:[-1.2-.4*sc,0,0],chest:[.15,-.25,0],thL:[-.15*hop,0,0],thR:[-.15*hop,0,0]}};}},
 hit:{label:'Hit',len:1.2,f:t=>{const u=cyc(t,1.2);const k=bump(u,0,.22),rec=u>.22?1-ease(Math.min(1,(u-.22)/.6)):1;return{z:-k*.08,y:k*.03,rx:-.3*k*rec,rz:Math.sin(u*40)*.05*rec,hx:-.25*k,elx:.6*k,elz:.3*rec,erz:-.3*rec,eye:u<.4?.15:1,sq:-k*.08,
  b:{shL:[-.6*rec,0,-1.1*rec],shR:[.15*rec,0,.15*rec],elL:[-.4,0,0],elR:[-.1,0,0],thL:[.35*rec,0,0],knL:[.5*rec,0,0],thR:[-.3*rec,0,0],chest:[-.25*k,0,0]}};}},
 ko:{label:'Knocked out',len:2.6,f:t=>{const u=Math.min(1,cyc(t,2.6)/.55);const e=ease(u);return{rz:e*1.3,y:-e*.03,x:e*.1,hx:e*.3,hz:e*.25,elx:.2,elz:e,erz:-e*.3,eye:1-e*.88,
  b:{shL:[-.3*e,0,-1.4*e],shR:[.4*e,0,.15*e],elL:[-.3*e,0,0],elR:[.75*e,0,0],thL:[-.5*e,0,-.2*e],knL:[.8*e,0,0],thR:[-.2*e,0,.3*e],knR:[.4*e,0,0]}};}},
 celebrate:{label:'Celebrate',len:1.8,f:t=>{const u=cyc(t,1.8);const j1=bump(u,0,.4),j2=bump(u,.45,.95);const air=j1+j2;return{y:j1*.18+j2*.3,ry:ease(Math.min(1,Math.max(0,(u-.45)/.5)))*TAU,sq:air*.06-bump(u,.38,.47)*.1-bump(u,.93,1)*.1,hz:Math.sin(t*6)*.1,elx:.2,elz:.25,erz:-.25,eye:u>.2&&u<.3?.2:1,coinSpin:t*10,
  b:{shL:[-1.75+Math.sin(t*9)*.08,.25,-.5],shR:[-1.75-Math.sin(t*9)*.08,-.25,.5],elL:[-1.05,0,0],elR:[-.08,0,0],haL:[Math.sin(t*9+1)*.35,0,0],haR:[-Math.sin(t*9+1)*.25,0,0],thL:[-.9*air,0,0],knL:[1.3*air,0,0],thR:[-.9*air,0,0],knR:[1.3*air,0,0]}};}},
 nap:{label:'Nap',len:4,f:t=>{const b=Math.sin(t*TAU/4)*.5+.5;return{y:-.1,sq:-.05+b*.03,rx:.1,hx:.42+b*.04,hz:.15,elx:.2,elz:.95,erz:-.8,eye:.1,coinOff:true,
  b:{thL:[-1.45,0,-.25],knL:[1.9,0,0],ftL:[-.3,0,0],thR:[-1.45,0,.25],knR:[1.9,0,0],ftR:[-.3,0,0],shL:[-.7,0,.35],elL:[-1.2,0,0],shR:[-.1,0,-.35],elR:[.25,0,0],chest:[.3+b*.04,0,0]}};}},
 work:{label:'Work loop',len:1.6,f:t=>{const u=cyc(t,1.6);const dip=bump(u,.05,.45),lift=bump(u,.45,.8);return{y:lift*.03-dip*.04,sq:-dip*.06+lift*.04,hx:dip*.3-lift*.1,elx:-.2*dip,elz:.1,coin:1+lift*.35,coinSpin:t*4,eye:u>.82&&u<.88?.15:1,
  b:{chest:[.55*dip-.1*lift,0,0],hips:[.2*dip,0,0],shL:[-1.2*dip-2*lift,0,-.22],shR:[-.35*dip-.2*lift,0,.05],elL:[-.35-.3*lift,0,0],elR:[-.1,0,0],haL:[-.3*dip+.2*lift,0,0],haR:[-.1,0,0],thL:[-.5*dip,0,0],knL:[.8*dip,0,0],thR:[-.5*dip,0,0],knR:[.8*dip,0,0]}};}}};
