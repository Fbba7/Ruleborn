import * as THREE from 'three';
// Shared sculpt + rig pipeline for Ruleborn creatures (same method as Skyskipper: SDF clay volume -> surface nets -> painted + baked AO -> fur shells -> skinned rig)
const v3=(x,y,z)=>new THREE.Vector3(x,y,z);
export const clamp=(x,a,b)=>x<a?a:x>b?b:x;
export const smin=(a,b,k)=>{const h=clamp(.5+.5*(b-a)/k,0,1);return b+(a-b)*h-k*h*(1-h);};
export const smax=(a,b,k)=>-smin(-a,-b,k);
export const sstep=(a,b,x)=>{const t=clamp((x-a)/(b-a),0,1);return t*t*(3-2*t);};
const hash=(x,y,z)=>{let h=Math.sin(x*127.1+y*311.7+z*74.7)*43758.5453;return h-Math.floor(h);};
export const vnoise=(x,y,z)=>{const xi=Math.floor(x),yi=Math.floor(y),zi=Math.floor(z),xf=x-xi,yf=y-yi,zf=z-zi;const u=xf*xf*(3-2*xf),v=yf*yf*(3-2*yf),w=zf*zf*(3-2*zf);const L=(a,b,t)=>a+(b-a)*t;
 return L(L(L(hash(xi,yi,zi),hash(xi+1,yi,zi),u),L(hash(xi,yi+1,zi),hash(xi+1,yi+1,zi),u),v),L(L(hash(xi,yi,zi+1),hash(xi+1,yi,zi+1),u),L(hash(xi,yi+1,zi+1),hash(xi+1,yi+1,zi+1),u),v),w);};
const SHW=(()=>{for(const w of[window.top,window.parent]){try{if(w&&w.document)return w;}catch(e){}}return window;})();
const TOPW=(()=>{try{return window.top.Float32Array?window.top:window}catch(e){return window}})();
const cacheArr=a=>new (SHW[a.constructor.name]||globalThis[a.constructor.name])(a);
const fromCache=a=>new globalThis[a.constructor.name](a);
export function makeSculpt(def){
 const prims=[];
 const frame=(pos,rot)=>{const m=new THREE.Matrix4().compose(pos,new THREE.Quaternion().setFromEuler(new THREE.Euler(...(rot||[0,0,0]))),v3(1,1,1));return m.clone().invert().elements;};
 const E=(name,c,r,rot,k=.035,op='u')=>{const e=frame(v3(...c),rot);prims.push({name,k,op,c,R:Math.max(...r),f:(x,y,z)=>{const a=e[0]*x+e[4]*y+e[8]*z+e[12],b=e[1]*x+e[5]*y+e[9]*z+e[13],d=e[2]*x+e[6]*y+e[10]*z+e[14];const k0=Math.hypot(a/r[0],b/r[1],d/r[2]),k1=Math.hypot(a/(r[0]*r[0]),b/(r[1]*r[1]),d/(r[2]*r[2]));return k1<1e-9?-Math.min(...r):k0*(k0-1)/k1;}});};
 const C=(name,a,b,ra,rb,k=.03,op='u')=>{const A=v3(...a),B=v3(...b),ba=B.clone().sub(A),l2=ba.lengthSq(),rr=ra-rb,a2=l2-rr*rr,il2=1/l2;prims.push({name,k,op,c:[(a[0]+b[0])/2,(a[1]+b[1])/2,(a[2]+b[2])/2],R:Math.sqrt(l2)/2+Math.max(ra,rb),f:(x,y,z)=>{const px=x-A.x,py=y-A.y,pz=z-A.z;const y0=px*ba.x+py*ba.y+pz*ba.z,z0=y0-l2;const xx=px*l2-ba.x*y0,xy=py*l2-ba.y*y0,xz=pz*l2-ba.z*y0;const x2=xx*xx+xy*xy+xz*xz,y2=y0*y0*l2,z2=z0*z0*l2;const kk=Math.sign(rr)*rr*rr*x2;
  if(Math.sign(z0)*a2*z2>kk)return Math.sqrt(x2+z2)*il2-rb;if(Math.sign(y0)*a2*y2<kk)return Math.sqrt(x2+y2)*il2-ra;return(Math.sqrt(x2*a2*il2)+y0*rr)*il2-ra;}});};
 const along=(a,b,spin=0)=>{const d=v3(b[0]-a[0],b[1]-a[1],b[2]-a[2]).normalize();const q=new THREE.Quaternion().setFromUnitVectors(v3(0,1,0),d);if(spin)q.premultiply(new THREE.Quaternion().setFromAxisAngle(d,spin));const e=new THREE.Euler().setFromQuaternion(q);return[e.x,e.y,e.z];};
 const api={E,C,along,v3,sstep,vnoise,clamp,prims,THREE};
 def.sculpt(api);
 const PD={};for(const p of prims)PD[p.name]=p;
 const dist=(n,x,y,z)=>PD[n]?PD[n].f(x,y,z):1;api.dist=dist;
 const minD=(re,x,y,z)=>{let m=1;for(const p of prims)if(p.op!=='s'&&re.test(p.name)){const dx=x-p.c[0],dy=y-p.c[1],dz=z-p.c[2];if(Math.sqrt(dx*dx+dy*dy+dz*dz)-p.R>m)continue;const d=p.f(x,y,z);if(d<m)m=d;}return m;};api.minD=minD;
 function sdf(x,y,z){let d=1e9;for(let i=0;i<prims.length;i++){const p=prims[i];const dx=x-p.c[0],dy=y-p.c[1],dz=z-p.c[2];const bound=Math.sqrt(dx*dx+dy*dy+dz*dz)-p.R;
   if(p.op==='s'){if(bound<.06)d=smax(d,-p.f(x,y,z),p.k);continue;}const di=bound>.09?bound:p.f(x,y,z);d=d>5?di:smin(d,di,p.k);}
  if(d<.03&&def.disp)d=def.disp(x,y,z,d,api);return d;}
 api.sdf=sdf;
 function mesh(h){const b0=def.box[0],b1=def.box[1];const nx=Math.ceil((b1[0]-b0[0])/h)+1,ny=Math.ceil((b1[1]-b0[1])/h)+1,nz=Math.ceil((b1[2]-b0[2])/h)+1;
  const V=new Float32Array(nx*ny*nz);const id=(i,j,k)=>i+nx*(j+ny*k);
  for(let k=0;k<nz;k++)for(let j=0;j<ny;j++)for(let i=0;i<nx;i++)V[id(i,j,k)]=sdf(b0[0]+i*h,b0[1]+j*h,b0[2]+k*h);
  const vi=new Int32Array(nx*ny*nz).fill(-1);const pos=[];
  const cr=[[0,0,0],[1,0,0],[0,1,0],[1,1,0],[0,0,1],[1,0,1],[0,1,1],[1,1,1]];const ed=[[0,1],[2,3],[4,5],[6,7],[0,2],[1,3],[4,6],[5,7],[0,4],[1,5],[2,6],[3,7]];const cv=new Float32Array(8);
  for(let k=0;k<nz-1;k++)for(let j=0;j<ny-1;j++)for(let i=0;i<nx-1;i++){let m=0;for(let c=0;c<8;c++){const q=V[id(i+cr[c][0],j+cr[c][1],k+cr[c][2])];cv[c]=q;if(q<0)m|=1<<c;}if(m===0||m===255)continue;
   let sx=0,sy=0,sz=0,n=0;for(const[a,b]of ed){const va=cv[a],vb=cv[b];if((va<0)===(vb<0))continue;const t=va/(va-vb);sx+=cr[a][0]+(cr[b][0]-cr[a][0])*t;sy+=cr[a][1]+(cr[b][1]-cr[a][1])*t;sz+=cr[a][2]+(cr[b][2]-cr[a][2])*t;n++;}
   vi[id(i,j,k)]=pos.length/3;pos.push(b0[0]+(i+sx/n)*h,b0[1]+(j+sy/n)*h,b0[2]+(k+sz/n)*h);}
  const ind=[];const quad=(a,b,c,d,f)=>{if(a<0||b<0||c<0||d<0)return;if(!f)ind.push(a,c,b,a,d,c);else ind.push(a,b,c,a,c,d);};
  for(let k=1;k<nz-1;k++)for(let j=1;j<ny-1;j++)for(let i=1;i<nx-1;i++){const v0=V[id(i,j,k)]<0;
   if((V[id(i+1,j,k)]<0)!==v0)quad(vi[id(i,j-1,k-1)],vi[id(i,j,k-1)],vi[id(i,j,k)],vi[id(i,j-1,k)],v0);
   if((V[id(i,j+1,k)]<0)!==v0)quad(vi[id(i-1,j,k-1)],vi[id(i-1,j,k)],vi[id(i,j,k)],vi[id(i,j,k-1)],v0);
   if((V[id(i,j,k+1)]<0)!==v0)quad(vi[id(i-1,j-1,k)],vi[id(i,j-1,k)],vi[id(i,j,k)],vi[id(i-1,j,k)],v0);}
  const g=new THREE.BufferGeometry();g.setAttribute('position',new THREE.Float32BufferAttribute(pos,3));g.setIndex(ind);
  const nrm=new Float32Array(pos.length);const e=.0025;for(let q=0;q<pos.length;q+=3){const x=pos[q],y=pos[q+1],z=pos[q+2];const a=sdf(x+e,y,z)-sdf(x-e,y,z),b=sdf(x,y+e,z)-sdf(x,y-e,z),c=sdf(x,y,z+e)-sdf(x,y,z-e);const l=Math.hypot(a,b,c)||1;nrm[q]=a/l;nrm[q+1]=b/l;nrm[q+2]=c/l;}
  g.setAttribute('normal',new THREE.BufferAttribute(nrm,3));return g;}
 const WARM=new THREE.Color(def.warm||0xA0401A);
 function paint(g){const p=g.attributes.position.array,n=g.attributes.normal.array;const col=new Float32Array(p.length),fm=new Float32Array(p.length/3);const c=new THREE.Color(),t=new THREE.Color();
  for(let q=0,vi=0;q<p.length;q+=3,vi++){const x=p[q],y=p[q+1],z=p[q+2],nx=n[q],ny=n[q+1],nz=n[q+2];
   let ao=0,w=1;for(let s=1;s<=5;s++){const h2=s*.012;ao+=w*(h2-sdf(x+nx*h2,y+ny*h2,z+nz*h2));w*=.6;}ao=clamp(1-ao*5.5,0,1);
   const f=def.paint(x,y,z,nx,ny,nz,ao,c,api);
   t.copy(c).lerp(WARM,(1-ao)*(def.aoWarm??.18));c.copy(t).multiplyScalar(.82+.18*ao);
   {const na=def.noiseAmt??1;if(na)c.offsetHSL((vnoise(x*30,y*30,z*30)-.5)*.02*na,0,(vnoise(x*60,y*60,z*60)-.5)*.045*na);}
   col[q]=c.r;col[q+1]=c.g;col[q+2]=c.b;fm[vi]=f;}
  g.setAttribute('color',new THREE.BufferAttribute(col,3));g.setAttribute('furMask',new THREE.BufferAttribute(fm,1));}
 const cache=()=>{const k='__rb_'+def.name;for(const w of[window.top,window.parent]){try{if(w&&w.document)return w[k]||(w[k]={});}catch(e){}}return window[k]||(window[k]={});};
 function loadBaked(url,res){const C=cache(),K='g'+res;if(C[K])return Promise.resolve();if(C['p'+K])return C['p'+K].then(()=>C[K]?0:(C['O'+K]?waitLock(C,K):(C['O'+K]=1,0)));
  const pr=fetch(new URL(url,location.href)).then(r=>{if(!r.ok)throw 0;return r.arrayBuffer();}).then(ab=>{if(C[K])return;const hl=new Uint32Array(ab,0,1)[0];const hdr=JSON.parse(new TextDecoder().decode(new Uint8Array(ab,4,hl)));const base=4+hl+((4-(4+hl)%4)%4);const a={};let i,si,sw;for(const t of hdr.attrs){const arr=cacheArr(new globalThis[t.type](ab,base+t.off,t.len));if(t.name==='index')i=arr;else if(t.name==='skinIndex')si=arr;else if(t.name==='skinWeight')sw=arr;else a[t.name]=[arr,t.item];}C[K]={a,i,si,sw};}).catch(()=>{});C['p'+K]=pr;return pr.then(()=>C[K]?0:(C['O'+K]?waitLock(C,K):(C['O'+K]=1,0)));}
 const waitLock=(C,K)=>new Promise(r=>{if(C[K])return r();(C['r'+K]=C['r'+K]||[]).push(r);});
 function serialize(g){const order=['position','normal','color','furMask','skinIndex','skinWeight'].filter(n=>g.attributes[n]);const parts=[],attrs=[];let off=0;for(const n of order){const a=g.attributes[n].array;attrs.push({name:n,type:a.constructor.name,item:g.attributes[n].itemSize,off,len:a.length});parts.push(a);off+=a.byteLength;off+=(4-off%4)%4;}
  const ia=g.index.array;attrs.push({name:'index',type:ia.constructor.name,item:1,off,len:ia.length});parts.push(ia);off+=ia.byteLength;const hdr=new TextEncoder().encode(JSON.stringify({attrs}));const hl=hdr.length;const base=4+hl+((4-(4+hl)%4)%4);const buf=new ArrayBuffer(base+off);new Uint32Array(buf,0,1)[0]=hl;new Uint8Array(buf,4,hl).set(hdr);attrs.forEach((t,k)=>{new Uint8Array(buf,base+t.off,parts[k].byteLength).set(new Uint8Array(parts[k].buffer,parts[k].byteOffset,parts[k].byteLength));});return buf;}
 const rimize=(m,rim,wrap=.35)=>{m.onBeforeCompile=sh=>{sh.uniforms.uRim={value:new THREE.Color(rim)};sh.fragmentShader=sh.fragmentShader.replace('#include <common>','#include <common>\nuniform vec3 uRim;').replace('#include <opaque_fragment>','vec3 Vd=normalize(vViewPosition);float fr=pow(1.0-clamp(dot(normalize(normal),Vd),0.0,1.0),3.0);\n float side=smoothstep(-0.2,0.6,normal.x*0.8+normal.y*0.4);\n outgoingLight+=uRim*fr*side*0.9+diffuseColor.rgb*vec3(1.0,0.55,0.35)*'+wrap.toFixed(2)+'*fr*0.6;\n#include <opaque_fragment>');};return m;};
 api.rimize=rimize;
 const FUR=Object.assign({len:.0045,dens:[900,700,900],shells:4},def.fur||{});
 function furShellMat(layer,N){const m=new THREE.MeshStandardMaterial({vertexColors:true,roughness:.9});m.onBeforeCompile=sh=>{sh.uniforms.uL={value:layer/N};sh.vertexShader=sh.vertexShader.replace('#include <common>','#include <common>\nattribute float furMask;uniform float uL;varying float vM;varying vec3 vP;').replace('#include <begin_vertex>','#include <begin_vertex>\n transformed+=normal*uL*'+FUR.len.toFixed(4)+';vM=furMask;vP=position;');
  sh.fragmentShader=sh.fragmentShader.replace('#include <common>','#include <common>\nuniform float uL;varying float vM;varying vec3 vP;\nfloat h3(vec3 p){p=fract(p*0.3183099+.1);p*=17.0;return fract(p.x*p.y*p.z*(p.x+p.y+p.z));}').replace('void main() {','void main() {\n if(vM<0.02||uL>vM+0.001)discard;'+(FUR.strand?'vec3 fl=normalize(vec3('+FUR.strand.map(v=>v.toFixed(2)).join(',')+'));vec3 sp=vP+fl*uL*'+(FUR.len*2.2).toFixed(4)+';float al=dot(sp,fl);vec3 pe=sp-fl*al;vec3 q=vec3(pe.x*'+FUR.dens[0].toFixed(1)+',al*'+(FUR.dens[1]*.18).toFixed(1)+',pe.z*'+FUR.dens[2].toFixed(1)+')+vec3(0.,h3(floor(pe*'+FUR.dens[0].toFixed(1)+'))*7.,0.);float hn=h3(floor(q));float cl=h3(floor(pe*'+(FUR.dens[0]*.12).toFixed(1)+'));hn=mix(hn,hn*.6+cl*.4,.5);if(hn<uL*1.08)discard;':'float hn=h3(floor(vP*vec3('+FUR.dens.map(v=>v.toFixed(1)).join(',')+')));if(hn<uL*1.05)discard;')).replace('#include <opaque_fragment>',(FUR.strand?'outgoingLight*=mix(0.7,1.18,uL*uL*.6+uL*.4);':'outgoingLight*=mix(0.85,1.15,uL);')+'\n#include <opaque_fragment>');};return m;}
 function build(opt={}){const res=opt.res||def.res||.0078;const grp=new THREE.Group();grp.name=def.name;const C=cache(),K='g'+res;let g;
  if(C[K]){const d=C[K];g=new THREE.BufferGeometry();for(const n in d.a)g.setAttribute(n,new THREE.BufferAttribute(fromCache(d.a[n][0]),d.a[n][1]));g.setIndex(new THREE.BufferAttribute(fromCache(d.i),1));g.computeBoundingSphere();}
  else{g=mesh(res);paint(g);const a={};for(const n in g.attributes)a[n]=[cacheArr(g.attributes[n].array),g.attributes[n].itemSize];C[K]={a,i:cacheArr(g.index.array)};const rs=C['r'+K];if(rs){C['r'+K]=null;rs.forEach(f=>{try{f();}catch(e){}});}}
  g.userData.ck=K;
  const body=new THREE.Mesh(g,rimize(new THREE.MeshPhysicalMaterial(Object.assign({vertexColors:true,roughness:.8,sheen:.5,sheenRoughness:.5,sheenColor:new THREE.Color(def.sheen||0xFFE8C0)},def.bodyMat||{})),def.rim||0x9FD4FF));if(def.vcGlow){const bm=body.material,prev=bm.onBeforeCompile;bm.onBeforeCompile=(sh,r)=>{prev&&prev(sh,r);sh.fragmentShader=sh.fragmentShader.replace('#include <emissivemap_fragment>','#include <emissivemap_fragment>\n totalEmissiveRadiance += vColor.rgb*smoothstep(.3,.65,vColor.r-vColor.b)*'+def.vcGlow.toFixed(2)+';');};bm.customProgramCacheKey=()=>'vcg'+def.name;}body.name='body';body.castShadow=true;body.receiveShadow=true;grp.add(body);
  const N=opt.shells??FUR.shells;for(let l=1;l<=N;l++){const s=new THREE.Mesh(g,furShellMat(l,N+1));s.name='fur_shell_'+l;grp.add(s);}
  const acc=def.accessories(api);acc.name='accessories';grp.add(acc);grp.userData.tris=g.index.count/3;grp.traverse(o=>{o.userData.sculpt=true;});return grp;}
 function partDists(x,y,z){const o=[];for(const p of prims){if(p.op==='s')continue;const dx=x-p.c[0],dy=y-p.c[1],dz=z-p.c[2];if(Math.sqrt(dx*dx+dy*dy+dz*dz)-p.R>.07)continue;o.push([p.name,p.f(x,y,z)]);}return o;}
 return{build,loadBaked,partDists,mesh,paint,serialize,cache,api,sdf};}
// ---------------- rig ----------------
export const ease=x=>x<.5?2*x*x:1-Math.pow(-2*x+2,2)/2;export const bump=(x,a,b)=>x<a||x>b?0:Math.sin((x-a)/(b-a)*Math.PI);
export const blink=(t,per,off=0)=>(((t+off)%per)/per)>.96?.12:1;export const cyc=(t,l)=>(t%l)/l;export const TAU=Math.PI*2;
export const merge=(...o)=>{const r={};for(const m of o)for(const k in m){const a=r[k]||[0,0,0],v=m[k];r[k]=[a[0]+v[0],a[1]+v[1],a[2]+v[2]];}return r;};
export function gait(ph,A={}){const s=Math.sin(ph*TAU),c=Math.cos(ph*TAU);const L=A.leg??.5,K=A.knee??.8,R=A.arm??.45;
 const leg=(sg)=>{const ss=s*sg,cc=c*sg;const th=-L*ss;const sw=Math.max(0,cc);const kn=.1+K*sw*sw*(3-2*sw)+.12*Math.max(0,-cc)*Math.max(0,-ss);const roll=.32*Math.max(0,ss)*Math.max(0,-cc)-.28*Math.max(0,-ss)*Math.max(0,-cc);return[[th,0,0],[kn,0,0],[-(th+kn)*.72+roll+(A.toe??0)*Math.max(0,-cc),0,0]];};
 const[tL,kL,fL]=leg(1),[tR,kR,fR]=leg(-1);const b={thL:tL,knL:kL,ftL:fL,thR:tR,knR:kR,ftR:fR};
 if(R){const sa=Math.sin((ph-.06)*TAU),se=Math.sin((ph-.16)*TAU);const o=A.armOut||0;b.shL=[R*sa+(A.armX||0),-.06*sa,-o-.04*Math.max(0,sa)];b.shR=[-R*sa+(A.armX||0),.06*sa,o+.04*Math.max(0,-sa)];b.elL=[-(A.elb??.3)-Math.max(0,-se)*.3,0,0];b.elR=[-(A.elb??.3)-Math.max(0,se)*.3,0,0];b.haL=[-.1+.14*se,0,0];b.haR=[-.1-.14*se,0,0];}
 const sway=Math.sin(ph*TAU)*(A.sway??.045);b.hips=[0,s*(A.twist??.08),sway];b.chest=[A.lean||0,-s*(A.twist??.08)*1.2,-sway*1.4];return b;}
export function blendPose(a,b,w){const o={};const keys=new Set([...Object.keys(a),...Object.keys(b)]);for(const k of keys){if(k==='b')continue;const va=a[k],vb=b[k];if(typeof va==='number'||typeof vb==='number'){const da=k==='eye'||k==='eyeW'?1:0;o[k]=(va??da)+((vb??da)-(va??da))*w;}else o[k]=w<.5?va:vb;}o.b={};const bk=new Set([...Object.keys(a.b||{}),...Object.keys(b.b||{})]);for(const k of bk){const x=(a.b||{})[k]||[0,0,0],y=(b.b||{})[k]||[0,0,0];o.b[k]=[x[0]+(y[0]-x[0])*w,x[1]+(y[1]-x[1])*w,x[2]+(y[2]-x[2])*w];}return o;}
export function makeRigKit(S,cfg){const J=cfg.J,BONES=Object.keys(J),TIP=cfg.TIP||{},TORSO=cfg.TORSO;const V=a=>new THREE.Vector3(...a);
 const segD=(x,y,z,a,b)=>{const ax=b[0]-a[0],ay=b[1]-a[1],az=b[2]-a[2];const px=x-a[0],py=y-a[1],pz=z-a[2];let t=(px*ax+py*ay+pz*az)/(ax*ax+ay*ay+az*az);t=t<0?0:t>1?1:t;const dx=px-ax*t,dy=py-ay*t,dz=pz-az*t;return Math.sqrt(dx*dx+dy*dy+dz*dz);};
 function skinGeo(g){if(g.userData.skinned)return;const SC=S.cache(),SK=g.userData.ck&&SC[g.userData.ck];if(SK&&SK.si){g.setAttribute('skinIndex',new THREE.Uint16BufferAttribute(fromCache(SK.si),4));g.setAttribute('skinWeight',new THREE.Float32BufferAttribute(fromCache(SK.sw),4));g.userData.skinned=true;return;}
  if(g.attributes.skinIndex){g.userData.skinned=true;return;}
  const P=g.attributes.position,n=P.count,NB=BONES.length;const bi=Object.fromEntries(BONES.map((b,i)=>[b,i]));const W=new Float32Array(n*NB);const lock=new Uint8Array(n);
  for(let v=0;v<n;v++){const x=P.getX(v),y=P.getY(v),z=P.getZ(v);let best=null,bd=1e9;for(const[name,d]of S.partDists(x,y,z))if(d<bd){bd=d;best=name;}let b=best&&best.includes(':')?best.split(':')[0]:'T';if(b!=='T'&&!(b in bi))b='T';
   if(b==='T'){let tot=0;const w={};for(const k in TORSO){const[A,B,rad]=TORSO[k];w[k]=Math.exp(-segD(x,y,z,A,B)/rad*7);tot+=w[k];}for(const k in w)W[v*NB+bi[k]]=w[k]/tot;}else{W[v*NB+bi[b]]=1;if(cfg.rigid&&cfg.rigid.includes(b))lock[v]=1;}}
  const I=g.index.array,adj=Array.from({length:n},()=>[]);for(let i=0;i<I.length;i+=3){const a=I[i],b=I[i+1],c=I[i+2];adj[a].push(b,c);adj[b].push(a,c);adj[c].push(a,b);}
  let A=W,B=new Float32Array(n*NB);for(let it=0;it<(cfg.smooth??5);it++){for(let v=0;v<n;v++){const nb=adj[v];const o=v*NB;if(lock[v]||!nb.length){for(let k=0;k<NB;k++)B[o+k]=A[o+k];continue;}for(let k=0;k<NB;k++){let s=0;for(const u of nb)s+=A[u*NB+k];B[o+k]=A[o+k]*.5+.5*s/nb.length;}}const t=A;A=B;B=t;}
  const si=new Uint16Array(n*4),sw=new Float32Array(n*4);for(let v=0;v<n;v++){const o=v*NB;const ids=[...Array(NB).keys()].sort((p,q)=>A[o+q]-A[o+p]).slice(0,4);let tot=0;for(const k of ids)tot+=A[o+k];ids.forEach((k,j)=>{si[v*4+j]=k;sw[v*4+j]=tot?A[o+k]/tot:(j?0:1);});}
  g.setAttribute('skinIndex',new THREE.Uint16BufferAttribute(si,4));g.setAttribute('skinWeight',new THREE.Float32BufferAttribute(sw,4));g.userData.skinned=true;if(SK){SK.si=cacheArr(si);SK.sw=cacheArr(sw);}}
 function stripUD(root){const saved=[];root.traverse(o=>{saved.push([o,o.userData]);const u={};for(const k in o.userData){const v=o.userData[k];if(v===null||typeof v!=='object')u[k]=v;}o.userData=u;});return()=>saved.forEach(([o,u])=>o.userData=u);}
 function makeRig(src){const g=src.getObjectByName('body').geometry;skinGeo(g);
  const restore=stripUD(src);const grp=src.clone(true);restore();
  const bones={};for(const b of BONES){const o=new THREE.Bone();o.name=b;bones[b]=o;}for(const b of BONES){const[p,w]=J[b];if(p){bones[p].add(bones[b]);bones[b].position.copy(V(w).sub(V(J[p][1])));}else bones[b].position.set(...w);}
  const skel=new THREE.Skeleton(BONES.map(b=>bones[b]));const meshes=[];
  for(const o of [...grp.children]){if(o.isMesh&&(o.name==='body'||o.name.startsWith('fur_shell'))){const sm=new THREE.SkinnedMesh(o.geometry,o.name==='body'?(()=>{const m=o.material.clone();m.onBeforeCompile=o.material.onBeforeCompile;if(o.material.customProgramCacheKey)m.customProgramCacheKey=o.material.customProgramCacheKey;m.side=THREE.DoubleSide;m.shadowSide=THREE.FrontSide;return m;})():o.material);sm.name=o.name;sm.castShadow=o.castShadow;sm.receiveShadow=o.receiveShadow;sm.frustumCulled=false;grp.remove(o);grp.add(sm);meshes.push(sm);}}
  meshes[0].add(bones.root);meshes.forEach(m=>m.bind(skel));grp.updateMatrixWorld(true);
  const acc=grp.getObjectByName('accessories');const fx=[];if(acc)for(const ch of [...acc.children]){const b=ch.userData.bone&&bones[ch.userData.bone]?ch.userData.bone:'chest';bones[b].attach(ch);}
  const spn=[];grp.traverse(o=>{if(o.userData.fx){o.userData.s0=o.scale.clone();fx.push(o);}if(o.userData.spin){const ax=o.userData.spinAx||'z';o.userData.r0=o.rotation[ax];spn.push(o);}});
  const eyes=['eye_L','eye_R'].map(n=>grp.getObjectByName(n)).filter(Boolean);eyes.forEach(e=>e.userData.s0=e.scale.clone());
  for(const[a,ch,t]of (cfg.AIM||[])){const Ab=bones[a];Ab.updateMatrixWorld(true);const pa=new THREE.Vector3().setFromMatrixPosition(Ab.matrixWorld);let pc;if(ch==='TIP'){pc=V(TIP[a]).sub(V(J[a][1])).applyQuaternion(Ab.getWorldQuaternion(new THREE.Quaternion())).add(pa);}else{bones[ch].updateMatrixWorld(true);pc=new THREE.Vector3().setFromMatrixPosition(bones[ch].matrixWorld);}
   const cur=pc.sub(pa).normalize(),tgt=V(t).normalize();const pq=Ab.parent.getWorldQuaternion(new THREE.Quaternion());const wq=Ab.getWorldQuaternion(new THREE.Quaternion());const nq=new THREE.Quaternion().setFromUnitVectors(cur,tgt).multiply(wq);Ab.quaternion.copy(pq.invert().multiply(nq));Ab.updateMatrixWorld(true);}
  if(cfg.hipTilt)bones.hips.quaternion.premultiply(new THREE.Quaternion().setFromEuler(new THREE.Euler(cfg.hipTilt,0,0)));
  const base={};for(const b of BONES)base[b]=bones[b].quaternion.clone();
  grp.updateMatrixWorld(true);const fy=Math.min(...(cfg.feet||['ftL','ftR']).map(b=>{const tp=TIP[b]?V(TIP[b]).sub(V(J[b][1])).applyQuaternion(bones[b].getWorldQuaternion(new THREE.Quaternion())).add(new THREE.Vector3().setFromMatrixPosition(bones[b].matrixWorld)):new THREE.Vector3().setFromMatrixPosition(bones[b].matrixWorld);return tp.y;}));const lift=(cfg.floor??.01)-fy;
  const root=new THREE.Group();root.name=S.api?cfg.name+'_rig':'rig';const lean=new THREE.Group();lean.position.y=cfg.pivot??.25;grp.position.y=-(cfg.pivot??.25)+lift;root.add(lean);lean.add(grp);
  const q=new THREE.Quaternion(),e=new THREE.Euler();const SPR=(cfg.springs||[]).map(s=>({s,v:[0,0]}));const AL={L:[0,0],R:[0,0]};let armInit=false;
  let lastY=null,lastRy=null,lastZ=null,lastT=performance.now(),prevP=null,blendFrom=null,blendT0=0,lastClip=null;
  const spring=(s,tgt,k,c,dt)=>{s[1]+=((tgt-s[0])*k-s[1]*c)*dt;s[0]+=s[1]*dt;return s[0];};
  const rig={root,bones,coins:[],
   play(p,clip){if(clip!==lastClip){if(prevP&&lastClip!==null){blendFrom=prevP;blendT0=performance.now();}lastClip=clip;}let qq=p;if(blendFrom){const w=Math.min(1,(performance.now()-blendT0)/280);qq=blendPose(blendFrom,p,w*w*(3-2*w));if(w>=1)blendFrom=null;}prevP=qq;this.set(qq);},
   set(p){const now=performance.now(),dt=Math.min(.05,(now-lastT)/1000)||.016;lastT=now;
    const y=(p.y||0)+(p.sq||0)*.3,vy=lastY==null?0:(y-lastY)/dt;lastY=y;const ry=(root.parent&&root.parent.rotation?root.parent.rotation.y:0)+(p.ry||0),wy=lastRy==null?0:Math.atan2(Math.sin(ry-lastRy),Math.cos(ry-lastRy))/dt;lastRy=ry;const zz=(p.z||0)+(p.fwd||0),vz=lastZ==null?0:(zz-lastZ)/dt;lastZ=zz;
    for(const b of BONES)bones[b].quaternion.copy(base[b]);
    const off=Object.assign({},p.b||{});const put=(b,x,y2,z)=>{if(!bones[b])return;const o=off[b]||[0,0,0];off[b]=[o[0]+(x||0),o[1]+(y2||0),o[2]+(z||0)];};
    put('head',p.hx,p.hy,p.hz);put('earL',p.elx,0,p.elz);put('earR',p.erx??p.elx,0,p.erz??-(p.elz||0));
    const SRC={vy,wy,vz,t:now/1000};for(const o of SPR){const[b,src,gain,k,c,ax,lim,wob]=o.s;const tg=clamp((src==='t'?Math.sin(SRC.t*(wob||3)):SRC[src])*gain,-lim,lim);const v=spring(o.v,tg,k,c,dt);const a=[0,0,0];a[ax]=v;put(b,a[0],a[1],a[2]);}
    if(cfg.armLag!==false){const gx=(b)=>(off[b]||[0,0,0])[0];if(!armInit){AL.L[0]=gx('shL');AL.R[0]=gx('shR');armInit=true;}for(const sd of['L','R']){const sh='sh'+sd,el='el'+sd;if(!bones[sh])continue;const tg=gx(sh);const s=spring(AL[sd],tg,230,21,dt);const lag=clamp(s-tg,-.4,.4);const o=off[sh]||[0,0,0];off[sh]=[clamp(o[0]+lag*.3,cfg.shMin??-1.6,cfg.shMax??1.2),o[1],o[2]];const oe=off[el]||[0,0,0];off[el]=[clamp(oe[0]-Math.abs(lag)*.35,-2.3,cfg.elMax??-.02),oe[1],oe[2]];}}
    for(const b in off){if(!bones[b])continue;const o=off[b];q.setFromEuler(e.set(o[0],o[1],o[2],'YXZ'));bones[b].quaternion.premultiply(q);}
    const ey=p.eye??1,ew=p.eyeW??1;eyes.forEach(k=>k.scale.set(k.userData.s0.x*ew,k.userData.s0.y*ey,k.userData.s0.z));
    {const tt=performance.now()/1000;for(const o of spn){const ax=o.userData.spinAx||'z',sp=o.userData.spin;o.rotation[ax]=o.userData.r0+(typeof sp==='number'?tt*sp:Math.sin(tt*sp[0])*sp[1]);}}for(const o of fx){const k=p[o.userData.fx]||0;const m=o.userData.fxMode||'grow';if(m==='grow'){const s=(o.userData.fxBase??1)+k*(o.userData.fxGain??.6);o.scale.copy(o.userData.s0).multiplyScalar(Math.max(.001,s));}else if(m==='show'){o.visible=k>.01;o.scale.set(o.userData.s0.x*Math.max(.001,k),o.userData.s0.y*Math.max(.001,k),o.userData.s0.z*Math.max(.001,k));}else if(m==='hide'){o.visible=k<.5;}}
    root.position.set(p.x||0,p.y||0,p.z||0);root.rotation.set(0,p.ry||0,0);lean.rotation.set(p.rx||0,0,p.rz||0);const sq=p.sq||0;lean.scale.set(1-sq*.5,1+sq,1-sq*.5);}};
  return rig;}
 return{makeRig,skinGeo};}
// ---------- standard 15-clip set, tuned per body (w: 0 light .. 1 heavy) ----------
export function stdClips(o={}){const w=o.w??.3,lt=1-w*.65,sl=1+w*.5,A=o.arm??.42;const X=o.x||{};
 const C={
 idle:{label:'Idle',len:4,f:t=>{const b=Math.sin(t*Math.PI*.9/sl)*.5+.5;return{sq:b*.014*lt,hx:Math.sin(t*1.4)*.03,hz:Math.sin(t*.7)*.05,elx:-.08-bump(t%4,2.6,2.9)*.35,elz:.06,eye:blink(t,4,.5),b:{chest:[-b*.03,0,0],shL:[Math.sin(t*1.3)*.04,0,-.03-b*.03],shR:[Math.sin(t*1.3+1)*.04,0,.03+b*.03],elL:[-.2-b*.05,0,0],elR:[-.2-b*.05,0,0]}};}},
 idle2:{label:'Idle 2',len:5,f:t=>{const u=cyc(t,5);const look=u<.3?ease(u/.3):u<.6?1:u<.8?1-ease((u-.6)/.2)*2:-1+ease((u-.8)/.2);return{hy:look*.5,hz:look*.08,elx:-.05,elz:.1,eye:blink(t,2.5,.2),b:{hips:[0,look*.08,0],shL:[0,0,-.05],shR:[0,0,.05],elL:[-.2,0,0],elR:[-.2,0,0]}};}},
 walk:{label:'Walk',len:.92*sl,f:t=>{const ph=cyc(t,.92*sl);const bob=Math.abs(Math.cos(ph*TAU)),dip=Math.pow(1-bob,3);return{y:(bob*.016-dip*.01)*lt,sq:-dip*.018,rx:.05,rz:Math.sin(ph*TAU)*(.025+w*.03),hz:Math.sin(ph*TAU)*.03,hx:-.02-bob*.03,hy:Math.sin(ph*TAU)*.05,elz:.1,eye:blink(t,3.3),b:gait(ph,{leg:.45,knee:.75,arm:A,sway:.045+w*.03})};}},
 run:{label:'Run',len:.5*sl,f:t=>{const ph=cyc(t,.5*sl);const fly=Math.abs(Math.sin(ph*TAU)),land=Math.pow(1-fly,4);return{y:.015+fly*.055*lt,sq:fly*.03-land*.06,rx:.24+land*.05,rz:Math.sin(ph*TAU)*.03,hx:-.12,elx:-.5,elz:.04,b:gait(ph,{leg:.8,knee:1.3,arm:A*2,elb:1.05,lean:.05,twist:.12,toe:.4,sway:.02})};}},
 carry:{label:'Carry',len:1.1*sl,f:t=>{const ph=cyc(t,1.1*sl);const bob=Math.abs(Math.cos(ph*TAU));return{y:bob*.012*lt,sq:-Math.pow(1-bob,2)*.035,rx:-.04,rz:Math.sin(ph*TAU)*.07,hx:.06,elx:-.3,elz:.14,eye:blink(t,2.2,.4),b:merge(gait(ph,{leg:.33,knee:.6,arm:0,twist:.04,sway:.07}),{shL:[-.75,.25,.35],elL:[-1.1,0,0],shR:[-.75,-.25,-.35],elR:[-1.1,0,0],chest:[-.08,0,0]})};}},
 climb:{label:'Climb',len:1.4*sl,f:t=>{const ph=cyc(t,1.4*sl);const s=Math.sin(ph*TAU),c=Math.cos(ph*TAU);return{y:.05+ph*.06,rx:-.2,hx:-.28,elx:-.4,elz:.1,b:{shL:[-1.4+.14*s,0,-.25],elL:[-1.1-.5*Math.max(0,-s),0,0],shR:[-1.4-.14*s,0,.25],elR:[-1.1-.5*Math.max(0,s),0,0],thL:[-.9-.45*s,0,-.1],knL:[1.1+.4*s,0,0],ftL:[-.4,0,0],thR:[-.9+.45*s,0,.1],knR:[1.1-.4*s,0,0],ftR:[-.4,0,0],hips:[0,0,c*.06]}};}},
 leap:{label:'Leap',len:1.6*sl,f:t=>{const u=cyc(t,1.6*sl);const cr=bump(u,0,.2)+bump(u,.8,.98),air=bump(u,.16,.82),tuck=bump(u,.3,.7);return{y:air*.36*lt-cr*.05,z:air*.08,sq:-cr*.1+air*.06,rx:-cr*.1+air*.2,hx:cr*.15-air*.12,elx:.5*air-.2*cr,elz:.1,eye:1-cr*.25,b:{thL:[-1.1*cr-1.1*tuck+.4*air,0,0],knL:[1.5*cr+1.5*tuck,0,0],ftL:[-.4*cr,0,0],thR:[-1.1*cr-1.1*tuck+.4*air,0,0],knR:[1.5*cr+1.5*tuck,0,0],ftR:[-.4*cr,0,0],shL:[-1.5*air+.6*cr,0,-.4*air],shR:[-1.5*air+.6*cr,0,.4*air],elL:[-.7*air-.4*cr,0,0],elR:[-.7*air-.4*cr,0,0],chest:[.2*cr,0,0]}};}},
 slide:{label:'Slide',len:1.6,f:t=>{const u=cyc(t,1.6);const go=ease(Math.min(1,u/.7));const wob=Math.sin(t*9)*.06*(1-go);return{z:-.25+go*.5,rx:-.18,rz:wob,hx:-.1,elx:-.7,elz:.02,eye:1.1,eyeW:1.05,sq:-.05,b:{thR:[-.85,0,.1],knR:[.25,0,0],ftR:[.5,0,0],thL:[.35,0,-.1],knL:[.95,0,0],ftL:[-.3,0,0],shL:[-.3,.1,-1+wob*3],shR:[-.3,-.1,1-wob*3],elL:[-.35,0,0],elR:[-.35,0,0]}};}},
 wade:{label:'Wade',len:2.2*sl,f:t=>{const ph=cyc(t,2.2*sl);const s=Math.sin(ph*TAU);return{y:-.09,rx:.1,rz:s*.08,hz:-s*.06,hx:-.05,elz:.2,erz:-.2,eye:.85,b:merge(gait(ph,{leg:.3,knee:1,arm:0,twist:.05}),{shL:[-.35,0,-.75+s*.12],shR:[-.35,0,.75+s*.12],elL:[-.8,0,0],elR:[-.8,0,0]})};}},
 hit:{label:'Hit',len:1.2,f:t=>{const u=cyc(t,1.2);const k=bump(u,0,.22),rec=u>.22?1-ease(Math.min(1,(u-.22)/.6)):1;return{z:-k*.08*lt,y:k*.03*lt,rx:-.3*k*rec,rz:Math.sin(u*40)*.05*rec,hx:-.25*k,elx:.6*k,elz:.3*rec,erz:-.3*rec,eye:u<.4?.15:1,sq:-k*.08,b:{shL:[-.5*rec,0,-.9*rec],shR:[-.5*rec,0,.9*rec],elL:[-.4,0,0],elR:[-.4,0,0],thL:[.35*rec,0,0],knL:[.5*rec,0,0],thR:[-.3*rec,0,0],chest:[-.25*k,0,0]}};}},
 ko:{label:'Knocked out',len:2.6,f:t=>{const e2=ease(Math.min(1,cyc(t,2.6)/.55));return{rz:e2*1.3,y:-e2*.03,x:e2*.1,hx:e2*.3,hz:e2*.25,elx:.2,elz:e2,erz:-e2*.3,eye:1-e2*.88,b:{shL:[-.3*e2,0,-1.3*e2],shR:[.3*e2,0,.5*e2],elL:[-.3*e2,0,0],elR:[-.2*e2,0,0],thL:[-.5*e2,0,-.2*e2],knL:[.8*e2,0,0],thR:[-.2*e2,0,.3*e2],knR:[.4*e2,0,0]}};}},
 celebrate:{label:'Celebrate',len:1.8,f:t=>{const u=cyc(t,1.8);const j1=bump(u,0,.4),j2=bump(u,.45,.95),air=j1+j2;return{y:(j1*.18+j2*.3)*lt,ry:ease(clamp((u-.45)/.5,0,1))*TAU,sq:air*.06-bump(u,.38,.47)*.1-bump(u,.93,1)*.1,hz:Math.sin(t*6)*.1,elx:.2,elz:.25,erz:-.25,eye:u>.2&&u<.3?.2:1,b:{shL:[-1.5+Math.sin(t*9)*.1,.25,-.55],shR:[-1.5-Math.sin(t*9)*.1,-.25,.55],elL:[-.9,0,0],elR:[-.9,0,0],thL:[-.9*air,0,0],knL:[1.3*air,0,0],thR:[-.9*air,0,0],knR:[1.3*air,0,0]}};}},
 nap:{label:'Nap',len:4,f:t=>{const b=Math.sin(t*TAU/4)*.5+.5;return{y:-.1,sq:-.05+b*.03,rx:.1,hx:.42+b*.04,hz:.15,elx:.2,elz:.9,erz:-.8,eye:.1,b:{thL:[-1.45,0,-.25],knL:[1.9,0,0],ftL:[-.3,0,0],thR:[-1.45,0,.25],knR:[1.9,0,0],ftR:[-.3,0,0],shL:[-.7,0,.35],elL:[-1.1,0,0],shR:[-.7,0,-.35],elR:[-1.1,0,0],chest:[.3+b*.04,0,0]}};}},
 work:{label:'Work loop',len:1.6*sl,f:t=>{const u=cyc(t,1.6*sl);const dip=bump(u,.05,.45),lift=bump(u,.45,.8);return{y:(lift*.03-dip*.04)*lt,sq:-dip*.06+lift*.04,hx:dip*.3-lift*.1,elx:-.2*dip,elz:.1,eye:u>.82&&u<.88?.15:1,b:{chest:[.5*dip-.1*lift,0,0],hips:[.2*dip,0,0],shL:[-1.1*dip-1.2*lift,0,-.2],shR:[-1.1*dip-1.2*lift,0,.2],elL:[-.35-.3*lift,0,0],elR:[-.35-.3*lift,0,0],thL:[-.5*dip,0,0],knL:[.8*dip,0,0],thR:[-.5*dip,0,0],knR:[.8*dip,0,0]}};}}};
 for(const k in X)C[k]=X[k];return C;}
