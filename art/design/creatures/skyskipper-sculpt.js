import * as THREE from 'three';
let RESV=.0072;
// ---------- math ----------
const v3=(x,y,z)=>new THREE.Vector3(x,y,z);
const clamp=(x,a,b)=>x<a?a:x>b?b:x;
const smin=(a,b,k)=>{const h=clamp(.5+.5*(b-a)/k,0,1);return b+(a-b)*h-k*h*(1-h);};
const smax=(a,b,k)=>-smin(-a,-b,k);
const sstep=(a,b,x)=>{const t=clamp((x-a)/(b-a),0,1);return t*t*(3-2*t);};
const hash=(x,y,z)=>{let h=Math.sin(x*127.1+y*311.7+z*74.7)*43758.5453;return h-Math.floor(h);};
const vnoise=(x,y,z)=>{const xi=Math.floor(x),yi=Math.floor(y),zi=Math.floor(z),xf=x-xi,yf=y-yi,zf=z-zi;const u=xf*xf*(3-2*xf),v=yf*yf*(3-2*yf),w=zf*zf*(3-2*zf);const L=(a,b,t)=>a+(b-a)*t;
 return L(L(L(hash(xi,yi,zi),hash(xi+1,yi,zi),u),L(hash(xi,yi+1,zi),hash(xi+1,yi+1,zi),u),v),L(L(hash(xi,yi,zi+1),hash(xi+1,yi,zi+1),u),L(hash(xi,yi+1,zi+1),hash(xi+1,yi+1,zi+1),u),v),w);};
// ---------- primitives (with local frames) ----------
const prims=[];
const frame=(pos,rot,scl)=>{const m=new THREE.Matrix4().compose(pos,new THREE.Quaternion().setFromEuler(new THREE.Euler(...(rot||[0,0,0]))),v3(1,1,1));const inv=m.clone().invert();const s=scl||[1,1,1];return{inv:inv.elements,s,ms:Math.min(...s)};};
const toLocal=(F,x,y,z)=>{const e=F.inv;return[(e[0]*x+e[4]*y+e[8]*z+e[12])/F.s[0],(e[1]*x+e[5]*y+e[9]*z+e[13])/F.s[1],(e[2]*x+e[6]*y+e[10]*z+e[14])/F.s[2]];};
// ellipsoid (approx, Inigo Quilez)
const E=(name,c,r,rot,k=.035,op='u')=>{const F=frame(v3(...c),rot);const R=Math.max(...r);prims.push({name,k,op,c,R,f:(x,y,z)=>{const[a,b,d]=toLocal(F,x,y,z);const k0=Math.hypot(a/r[0],b/r[1],d/r[2]),k1=Math.hypot(a/(r[0]*r[0]),b/(r[1]*r[1]),d/(r[2]*r[2]));return k1<1e-9?-Math.min(...r):k0*(k0-1)/k1;},F});};
// round cone between two points (limb), optional flatten scale
const C=(name,a,b,ra,rb,k=.03,op='u')=>{const A=v3(...a),B=v3(...b),ba=B.clone().sub(A),l2=ba.lengthSq(),rr=ra-rb,a2=l2-rr*rr,il2=1/l2;const c=[(a[0]+b[0])/2,(a[1]+b[1])/2,(a[2]+b[2])/2];
 prims.push({name,k,op,c,R:Math.sqrt(l2)/2+Math.max(ra,rb),f:(x,y,z)=>{const px=x-A.x,py=y-A.y,pz=z-A.z;const y0=px*ba.x+py*ba.y+pz*ba.z,z0=y0-l2;const xx=(px*l2-ba.x*y0),xy=(py*l2-ba.y*y0),xz=(pz*l2-ba.z*y0);const x2=xx*xx+xy*xy+xz*xz,y2=y0*y0*l2,z2=z0*z0*l2;const kk=Math.sign(rr)*rr*rr*x2;
  if(Math.sign(z0)*a2*z2>kk)return Math.sqrt(x2+z2)*il2-rb;if(Math.sign(y0)*a2*y2<kk)return Math.sqrt(x2+y2)*il2-ra;return(Math.sqrt(x2*a2*il2)+y0*rr)*il2-ra;}});};
// flat leaf (ear): ellipsoid chain in a flattened frame
// ---------- SCULPT: mid-leap Carrier, chibi proportions (units ~ metres before final scale) ----------
// body
E('belly',[0,.43,.02],[.165,.19,.15],[.25,0,0],.05);
E('chest',[0,.54,.06],[.13,.11,.12],[.35,0,0],.06);
E('neck',[0,.62,.08],[.09,.06,.08],null,.05);
// head: big, forward
E('skull',[0,.76,.07],[.2,.185,.18],[-.1,0,0],.05);
E('jowl',[0,.688,.12],[.155,.09,.12],null,.06);
E('muzzle',[0,.67,.225],[.095,.072,.075],[-.15,0,0],.04);
for(const s of[-1,1]){E('cheek'+s,[s*.125,.66,.14],[.075,.06,.07],null,.05);E('whiskpad'+s,[s*.04,.655,.275],[.042,.034,.032],null,.02);}
for(const s of[-1,1])E('brow'+s,[s*.086,.832,.226],[.04,.012,.022],[.1,s*.38,-s*.14],.03);
E('nose',[0,.7,.3],[.03,.022,.02],[-.3,0,0],.015);
for(const s of[-1,1])E('socket'+s,[s*.084,.748,.23],[.05,.05,.04],[0,s*.38,0],.018,'s');
E('mouthcut',[0,.72,0],[.001,.001,.001],null,.001,'s');E('smirkcheek',[.078,.668,.232],[.042,.032,.036],null,.03);
// ears (flattened, swept back)
const EARS={},EARTIP={};for(const s of[-1,1]){const pts=s>0?[[.066,.9,.01],[.098,1.02,-.04],[.12,1.135,-.072],[.13,1.235,-.088]]:[[-.066,.9,.01],[-.105,1.02,-.04],[-.142,1.13,-.08],[-.178,1.215,-.14]];const W=[.05,.068,.058,.02];EARS[s]=[];EARTIP[s]=pts[3];
 for(let i=0;i<3;i++){const a=v3(...pts[i]),b=v3(...pts[i+1]);const d=b.clone().sub(a);const L=d.length();d.normalize();const q=new THREE.Quaternion().setFromUnitVectors(v3(0,1,0),d);q.premultiply(new THREE.Quaternion().setFromAxisAngle(d,s*-.45));const eu=new THREE.Euler().setFromQuaternion(q);const c=a.clone().add(b).multiplyScalar(.5);const w=(W[i]+W[i+1])/2;const nm='ear'+s+i;E(nm,[c.x,c.y,c.z],[w,L*.64,.022],[eu.x,eu.y,eu.z],.03);EARS[s].push(nm);const fz=v3(0,0,1).applyQuaternion(q);E('earcut'+s+i,[c.x+fz.x*.018,c.y+fz.y*.018,c.z+fz.z*.018],[w*.6,L*.56,.012],[eu.x,eu.y,eu.z],.014,'s');}}
// arms: right raised holding coin, left swung back
C('armR1',[.12,.57,.05],[.185,.47,.13],.05,.044,.017);C('armR2',[.185,.47,.13],[.205,.455,.27],.044,.036,.025);E('wristR',[.205,.456,.272],[.034,.032,.03],null,.02);E('pawR',[.208,.463,.3],[.045,.039,.046],[-.2,0,0],.02);
for(let k=0;k<3;k++){const x=.19+k*.02;C('finger1'+k,[x,.48,.326],[x+.001,.506,.342],.0172,.016,.012);C('finger1'+k+'t',[x+.001,.506,.342],[x+.001,.522,.3455],.016,.0138,.01);E('fingerpad1'+k,[x+.001,.52,.344],[.0128,.012,.0122],null,.008);}for(let k=0;k<2;k++)E('fgap1'+k,[.2+k*.02,.514,.357],[.0028,.018,.012],null,.0028,'s');C('thumb1',[.244,.466,.31],[.25,.49,.317],.0178,.0155,.012);C('thumb1t',[.25,.49,.317],[.242,.51,.32],.0155,.0135,.01);
C('armL1',[-.12,.56,.03],[-.22,.5,-.04],.05,.044,.018);C('armL2',[-.22,.5,-.04],[-.29,.44,.0],.044,.036,.03);E('wristL',[-.288,.442,0],[.033,.031,.031],null,.02);E('pawL',[-.302,.435,.01],[.045,.038,.046],[0,0,.3],.02);
for(let k=0;k<3;k++){const zb=.01+(k-1)*.021,zm=.012+(k-1)*.03,zt=.013+(k-1)*.036;const zm2=.012+(k-1)*.025,zt2=.013+(k-1)*.028;C('finger-1'+k,[-.324,.426,zb],[-.342,.412-k*.003,zm2],.0168,.0156,.012);C('finger-1'+k+'t',[-.342,.412-k*.003,zm2],[-.352,.4-k*.004,zt2],.0156,.0134,.01);}for(let k=0;k<2;k++)E('fgap-1'+k,[-.345,.414,.012+(k-.5)*.025],[.017,.011,.0028],null,.0028,'s');C('thumb-1',[-.306,.452,.038],[-.318,.458,.062],.0162,.014,.012);C('thumb-1t',[-.318,.458,.062],[-.328,.454,.074],.014,.0122,.01);

// legs: right forward, left back (leap)
E('haunchR',[.085,.33,.03],[.1,.11,.12],[.4,0,0],.05);C('shinR',[.09,.28,.1],[.1,.2,.17],.058,.046,.04);E('heelRtuft',[.1,.198,.185],[.05,.034,.05],null,.03);E('footR',[.1,.152,.262],[.058,.036,.148],[-.3,0,0],.036);
E('haunchL',[-.085,.33,-.03],[.1,.11,.12],[-.3,0,0],.05);C('shinL',[-.09,.28,-.1],[-.1,.22,-.18],.056,.045,.04);E('heelLtuft',[-.1,.232,-.212],[.048,.033,.048],null,.03);E('footL',[-.1,.198,-.2],[.055,.036,.132],[.35,0,0],.036);
for(let k=0;k<4;k++){const o=(k-1.5)*.022;E('toeR'+k,[.1+o,.142,.366],[.0205,.0172,.024],null,.014);E('toeL'+k,[-.1+o*.96,.16,-.094],[.02,.0168,.023],[.35,0,0],.014);}for(let k=0;k<3;k++){const o=(k-1)*.022;E('tgapR'+k,[.1+o,.158,.382],[.0032,.016,.021],null,.0028,'s');E('tgapL'+k,[-.1+o*.96,.176,-.082],[.0032,.016,.021],[.35,0,0],.0028,'s');}E('heelL',[-.1,.25,-.302],[.034,.03,.034],null,.03);E('heelR',[.1,.148,.138],[.038,.032,.04],null,.03);
// tail
E('tail',[0,.37,-.16],[.07,.066,.066],null,.04);for(let k=0;k<5;k++){const a=k*1.26;E('tailb'+k,[Math.cos(a)*.045,.37+Math.sin(a)*.045,-.19],[.035,.035,.035],null,.03);}
for(const s of[-1,1]){E('tuftC'+s+'a',[s*.2,.655,.11],[.04,.022,.03],[0,0,s*-.5],.03);E('tuftC'+s+'b',[s*.195,.63,.1],[.034,.019,.027],[0,0,s*-.9],.03);}
E('tuftH0',[0,.948,.1],[.03,.04,.028],[.4,0,0],.03);E('tuftH1',[-.032,.936,.082],[.026,.034,.026],[.3,0,.45],.03);E('tuftH2',[.032,.936,.082],[.026,.034,.026],[.3,0,-.45],.03);
E('chestFluff',[0,.585,.168],[.07,.04,.035],[.3,0,0],.04);
// ---------- SDF ----------
const P2=prims;
function sdf(x,y,z){let d=1e9,dA=1e9,cut=-1e9;const sep=APOSE!==0;for(let i=0;i<P2.length;i++){const p=P2[i];const dx=x-p.c[0],dy=y-p.c[1],dz=z-p.c[2];const bound=Math.sqrt(dx*dx+dy*dy+dz*dz)-p.R;const arm=sep&&p.side;
  if(p.op==='s'){if(bound<.06){const di=p.f(x,y,z);if(arm)dA=smax(dA,-di,p.k);else d=smax(d,-di,p.k);}continue;}
  const di=bound>.09?bound:p.f(x,y,z);if(arm)dA=dA>5?di:smin(dA,di,p.k);else d=d>5?di:smin(d,di,p.k);}
 if(sep&&dA<5){const kJ=.002+.02*(1-sstep(.572,.608,y));d=d>5?dA:smin(d,dA,kJ);}
 // fur clumps on cheeks, chest, tail, head top
 if(d<.02){const n=vnoise(x*26,y*26,z*26)*.7+vnoise(x*70,y*70,z*70)*.3;d-=(n-.5)*.0035;}
 return d;}
// A-pose support (rig bake only): arm chains rotate outward about the shoulders
const SHO={R:[.12,.57,.05],L:[-.12,.56,.03]};let APOSE=0;
const armSide=n=>/^(armR|wristR|pawR|finger1|fingerpad1|thumb1|fgap1)/.test(n)?'R':/^(armL|wristL|pawL|finger-1|fingerpad-1|thumb-1|fgap-1)/.test(n)?'L':null;
const rotZ=(p,o,a)=>{const c=Math.cos(a),s=Math.sin(a),x=p[0]-o[0],y=p[1]-o[1];return[o[0]+x*c-y*s,o[1]+x*s+y*c,p[2]];};
for(const p of P2){const sd=armSide(p.name);if(!sd)continue;p.side=sd;p.c0=p.c.slice();const f0=p.f;p.f=(x,y,z)=>{if(!APOSE)return f0(x,y,z);const a=p.side==='R'?-APOSE:APOSE;const q=rotZ([x,y,z],SHO[p.side],a);return f0(q[0],q[1],q[2]);};}
export function setAPose(a){APOSE=a;for(const p of P2){if(!p.side)continue;p.c=APOSE?rotZ(p.c0,SHO[p.side],p.side==='R'?APOSE:-APOSE):p.c0.slice();}}
export function aposeRot(v,side){if(!APOSE)return v;return rotZ(v,SHO[side],side==='R'?APOSE:-APOSE);}
export function getAPose(){return APOSE;}
const PD={};for(const p of P2)PD[p.name]=p;
const dist=(n,x,y,z)=>PD[n].f(x,y,z);
// ---------- surface nets ----------
function mesh(){const b0=[-.42,.08,-.42],b1=[.42,1.42,.44],h=RESV;const nx=Math.ceil((b1[0]-b0[0])/h)+1,ny=Math.ceil((b1[1]-b0[1])/h)+1,nz=Math.ceil((b1[2]-b0[2])/h)+1;
 const V=new Float32Array(nx*ny*nz);const id=(i,j,k)=>i+nx*(j+ny*k);
 for(let k=0;k<nz;k++)for(let j=0;j<ny;j++)for(let i=0;i<nx;i++)V[id(i,j,k)]=sdf(b0[0]+i*h,b0[1]+j*h,b0[2]+k*h);
 const vi=new Int32Array(nx*ny*nz).fill(-1);const pos=[];
 const corners=[[0,0,0],[1,0,0],[0,1,0],[1,1,0],[0,0,1],[1,0,1],[0,1,1],[1,1,1]];const edges=[[0,1],[2,3],[4,5],[6,7],[0,2],[1,3],[4,6],[5,7],[0,4],[1,5],[2,6],[3,7]];
 for(let k=0;k<nz-1;k++)for(let j=0;j<ny-1;j++)for(let i=0;i<nx-1;i++){let m=0;const cv=[];for(let c=0;c<8;c++){const q=V[id(i+corners[c][0],j+corners[c][1],k+corners[c][2])];cv.push(q);if(q<0)m|=1<<c;}if(m===0||m===255)continue;
  let sx=0,sy=0,sz=0,n=0;for(const[a,b]of edges){const va=cv[a],vb=cv[b];if((va<0)===(vb<0))continue;const t=va/(va-vb);sx+=corners[a][0]+(corners[b][0]-corners[a][0])*t;sy+=corners[a][1]+(corners[b][1]-corners[a][1])*t;sz+=corners[a][2]+(corners[b][2]-corners[a][2])*t;n++;}
  vi[id(i,j,k)]=pos.length/3;pos.push(b0[0]+(i+sx/n)*h,b0[1]+(j+sy/n)*h,b0[2]+(k+sz/n)*h);}
 const ind=[];const quad=(a,b,c,d,flip)=>{if(a<0||b<0||c<0||d<0)return;if(!flip)ind.push(a,c,b,a,d,c);else ind.push(a,b,c,a,c,d);};
 for(let k=1;k<nz-1;k++)for(let j=1;j<ny-1;j++)for(let i=1;i<nx-1;i++){const v0=V[id(i,j,k)]<0;
  if(i<nx-1&&(V[id(i+1,j,k)]<0)!==v0)quad(vi[id(i,j-1,k-1)],vi[id(i,j,k-1)],vi[id(i,j,k)],vi[id(i,j-1,k)],v0);
  if(j<ny-1&&(V[id(i,j+1,k)]<0)!==v0)quad(vi[id(i-1,j,k-1)],vi[id(i-1,j,k)],vi[id(i,j,k)],vi[id(i,j,k-1)],v0);
  if(k<nz-1&&(V[id(i,j,k+1)]<0)!==v0)quad(vi[id(i-1,j-1,k)],vi[id(i,j-1,k)],vi[id(i,j,k)],vi[id(i-1,j,k)],v0);}
 const g=new THREE.BufferGeometry();g.setAttribute('position',new THREE.Float32BufferAttribute(pos,3));g.setIndex(ind);
 // gradient normals
 const nrm=new Float32Array(pos.length);const e=.0025;for(let q=0;q<pos.length;q+=3){const x=pos[q],y=pos[q+1],z=pos[q+2];let a=sdf(x+e,y,z)-sdf(x-e,y,z),b=sdf(x,y+e,z)-sdf(x,y-e,z),c=sdf(x,y,z+e)-sdf(x,y,z-e);const l=Math.hypot(a,b,c)||1;nrm[q]=a/l;nrm[q+1]=b/l;nrm[q+2]=c/l;}
 g.setAttribute('normal',new THREE.BufferAttribute(nrm,3));return g;}
// ---------- painted colours + baked AO ----------
const COL={fur:new THREE.Color(0xF2B43C),furLight:new THREE.Color(0xFFD978),shade:new THREE.Color(0xC27A22),tip:new THREE.Color(0xB86A1E),cream:new THREE.Color(0xFFF2DE),sky:new THREE.Color(0x86CCF2),skin:new THREE.Color(0xF2A7A0),mouth:new THREE.Color(0x5A1626),nose:new THREE.Color(0xC87078),sole:new THREE.Color(0xB56E26),pad:new THREE.Color(0xE8969A),warm:new THREE.Color(0xA0401A)};
const PADS=[];for(let k=0;k<4;k++){const o=(k-1.5)*.022;PADS.push([.1+o,.128,.37,.011],[-.1+o*.96,.144,-.1,.0108]);}PADS.push([.1,.118,.285,.03],[.1,.12,.16,.022],[-.1,.162,-.172,.028],[-.1,.215,-.296,.02]);
const CREAM=P2.filter(p=>/^(paw|finger|thumb|toe|tail)/.test(p.name)).map(p=>p.name);
function paint(g){const p=g.attributes.position.array,n=g.attributes.normal.array;const col=new Float32Array(p.length),fm=new Float32Array(p.length/3);const c=new THREE.Color(),t=new THREE.Color();
 for(let q=0,vi=0;q<p.length;q+=3,vi++){const x=p[q],y=p[q+1],z=p[q+2],nx=n[q],ny=n[q+1],nz=n[q+2];
  c.copy(COL.fur).lerp(COL.furLight,sstep(.55,1.15,y)*.35+sstep(.2,.9,ny)*.3);
  const cr=Math.min(dist('muzzle',x,y,z),dist('whiskpad-1',x,y,z),dist('whiskpad1',x,y,z));c.lerp(COL.cream,sstep(.02,-.005,cr));
  const bel=Math.hypot((x)/.12,(y-.47)/.16,(z-.17)/.09);c.lerp(COL.cream,sstep(1.05,.85,bel));
  {let dm=1;for(const k of CREAM){const d=dist(k,x,y,z);if(d<dm)dm=d;}const hf=sstep(.034,-.004,dm);c.lerp(t.copy(COL.furLight).lerp(COL.cream,.55),sstep(.034,.012,dm)*.9).lerp(COL.cream,sstep(.014,-.004,dm));}
  // ears: inner skin on the front face, darker tips
  for(const s of[-1,1]){const de=Math.min(...EARS[s].map(n=>dist(n,x,y,z)));if(de<.012){const ci=Math.min(...EARS[s].map((n,i)=>dist('earcut'+s+i,x,y,z)));const inner=sstep(.007,.001,ci);const tp=EARTIP[s];const tv=sstep(.075,.03,Math.hypot(x-tp[0],y-tp[1],z-tp[2]));c.lerp(COL.skin,inner*(1-tv)*.85);c.lerp(COL.tip,tv*.92);}}
  const dm=dist('mouthcut',x,y,z);const inMouth=sstep(.006,-.004,dm);c.lerp(COL.mouth,inMouth);c.lerp(COL.nose,sstep(.008,-.002,dist('nose',x,y,z)));
  {const fs=Math.min(dist('footR',x,y,z),dist('footL',x,y,z));const under=sstep(.1,-.45,ny);c.lerp(COL.cream,sstep(.006,-.004,fs)*under*.9);for(const P of PADS){const d=Math.hypot(x-P[0],y-P[1],z-P[2]);if(d<P[3])c.lerp(COL.pad,sstep(P[3],P[3]*.62,d)*sstep(.25,-.3,ny));}}
  // baked AO + curvature from SDF
  let ao=0,w=1;for(let s=1;s<=5;s++){const h2=s*.012;ao+=w*(h2-sdf(x+nx*h2,y+ny*h2,z+nz*h2));w*=.6;}ao=clamp(1-ao*5.5,0,1);
  // painterly: shadows warmer & more saturated
  t.copy(c).lerp(COL.warm,(1-ao)*.2);c.copy(t).multiplyScalar(.8+.2*ao);
  c.offsetHSL((vnoise(x*30,y*30,z*30)-.5)*.02,0,(vnoise(x*60,y*60,z*60)-.5)*.05);
  col[q]=c.r;col[q+1]=c.g;col[q+2]=c.b;fm[vi]=inMouth>.5?0:1;}
 g.setAttribute('color',new THREE.BufferAttribute(col,3));g.setAttribute('furMask',new THREE.BufferAttribute(fm,1));}
// ---------- materials ----------
const rimize=(m,rim=0x9FD4FF,wrap=.35)=>{m.onBeforeCompile=sh=>{sh.uniforms.uRim={value:new THREE.Color(rim)};sh.fragmentShader=sh.fragmentShader.replace('#include <common>','#include <common>\nuniform vec3 uRim;').replace('#include <opaque_fragment>','vec3 Vd=normalize(vViewPosition);float fr=pow(1.0-clamp(dot(normalize(normal),Vd),0.0,1.0),3.0);\n float side=smoothstep(-0.2,0.6,normal.x*0.8+normal.y*0.4);\n outgoingLight+=uRim*fr*side*0.9+diffuseColor.rgb*vec3(1.0,0.55,0.35)*'+wrap.toFixed(2)+'*fr*0.6;\n#include <opaque_fragment>');};return m;};
function furShellMat(layer,N){const m=new THREE.MeshStandardMaterial({vertexColors:true,roughness:.9});m.onBeforeCompile=sh=>{sh.uniforms.uL={value:layer/N};sh.vertexShader=sh.vertexShader.replace('#include <common>','#include <common>\nattribute float furMask;uniform float uL;varying float vM;varying vec3 vP;').replace('#include <begin_vertex>','#include <begin_vertex>\n transformed+=normal*uL*0.0045;vM=furMask;vP=position;');
 sh.fragmentShader=sh.fragmentShader.replace('#include <common>','#include <common>\nuniform float uL;varying float vM;varying vec3 vP;\nfloat h3(vec3 p){p=fract(p*0.3183099+.1);p*=17.0;return fract(p.x*p.y*p.z*(p.x+p.y+p.z));}').replace('void main() {','void main() {\n if(vM<0.02||uL>vM+0.001)discard;float hn=h3(floor(vP*vec3(900.0,700.0,900.0)));if(hn<uL*1.05)discard;').replace('#include <opaque_fragment>','outgoingLight*=mix(0.85,1.15,uL);\n#include <opaque_fragment>');};return m;}
// ---------- accessories (separate meshes) ----------
function accessories(){const G=new THREE.Group();const PB=(c,o={})=>new THREE.MeshPhysicalMaterial(Object.assign({color:c,roughness:.5},o));const add=(geo,m,p,r,s,par=G)=>{const o=new THREE.Mesh(geo,m);if(p)o.position.set(...p);if(r)o.rotation.set(...r);if(s)o.scale.set(...s);o.castShadow=true;o.receiveShadow=true;par.add(o);return o;};
 // eyes: glossy, amber iris, big highlight, set under the brow
 const irisC=document.createElement('canvas');irisC.width=irisC.height=256;{const x=irisC.getContext('2d');x.fillStyle='#3A1A06';x.fillRect(0,0,256,256);const g=x.createRadialGradient(128,128,0,128,128,128);g.addColorStop(0,'#120806');g.addColorStop(.5,'#120806');g.addColorStop(.58,'#4A2410');g.addColorStop(.85,'#9A5A1C');g.addColorStop(1,'#2A1408');x.fillStyle=g;x.beginPath();x.arc(128,128,128,0,6.28);x.fill();for(let i=0;i<40;i++){const a=Math.random()*6.28;x.strokeStyle='rgba(255,200,110,'+(.05+Math.random()*.12)+')';x.lineWidth=2;x.beginPath();x.moveTo(128+Math.cos(a)*60,128+Math.sin(a)*60);x.lineTo(128+Math.cos(a)*118,128+Math.sin(a)*118);x.stroke();}}
 const irisT=new THREE.CanvasTexture(irisC);irisT.colorSpace=THREE.SRGBColorSpace;
 const irisM=PB(0xffffff,{map:irisT,roughness:.2});for(const s of[-1,1]){const e=new THREE.Group();e.name=s<0?'eye_L':'eye_R';e.position.set(s*.078,.748,.206);e.rotation.set(-.08,s*.32,0);e.scale.set(1,1.08,.82);G.add(e);
  add(new THREE.SphereGeometry(.05,40,28),PB(0xFBF1E2,{roughness:.3,clearcoat:.8,clearcoatRoughness:.12}),[0,0,0],null,null,e);
  const ig=new THREE.SphereGeometry(.036,40,24,0,Math.PI*2,0,Math.PI*.5);ig.rotateX(Math.PI/2);{const uv=ig.attributes.uv,p=ig.attributes.position;for(let i=0;i<p.count;i++){uv.setXY(i,.5+p.getX(i)/.072,.5+p.getY(i)/.072);}}
  add(ig,irisM,[s*-.003,-.004,.03],null,[1.05,1.15,1],e);
  add(new THREE.SphereGeometry(.058,40,28),PB(0xffffff,{transparent:true,opacity:.08,roughness:0,clearcoat:1,clearcoatRoughness:0,depthWrite:false}),[0,0,.0],null,[1,1,.93],e).castShadow=false;
  const lidM=PB(0xECAA3E,{roughness:.85,sheen:.5,sheenColor:new THREE.Color(0xFFE8C0)}),lashM=PB(0x2A160C,{roughness:.6});const lid=new THREE.Group();lid.rotation.set(-.35,0,s*.1);lid.visible=false;e.add(lid);add(new THREE.SphereGeometry(.0595,40,16,0,Math.PI*2,0,Math.PI*.4),lidM,null,null,null,lid);{const rr2=.0595*Math.sin(Math.PI*.4),yy=.0595*Math.cos(Math.PI*.4);add(new THREE.TorusGeometry(rr2,.0022,8,48),lashM,[0,yy,0],[Math.PI/2,0,0],null,lid);}
    const lo=new THREE.Group();lo.rotation.set(-.25,0,0);lo.visible=false;e.add(lo);add(new THREE.SphereGeometry(.0585,40,8,0,Math.PI*2,Math.PI*.8,Math.PI*.2),PB(0xF8D08C,{roughness:.85}),null,null,null,lo);e.userData.lid=lid;
  for(const [r,x,y] of[[.0085,-.012,.018],[.004,.013,-.012]]){const sp=new THREE.Mesh(new THREE.SphereGeometry(r,12,8),new THREE.MeshBasicMaterial({color:0xffffff}));sp.position.set(x*.9,y+.004,.047);e.add(sp);}}
 // teeth + tongue
 
 {const proj=(x,y)=>{let z=.42;for(let i=0;i<200;i++){const d=sdf(x,y,z);if(d<.0005)break;z-=Math.max(d*.8,.0008);}const e=.002;const nx=sdf(x+e,y,z)-sdf(x-e,y,z),ny=sdf(x,y+e,z)-sdf(x,y-e,z),nz=sdf(x,y,z+e)-sdf(x,y,z-e);const l=Math.hypot(nx,ny,nz)||1;return v3(x+nx/l*.0025,y+ny/l*.0025,z+nz/l*.0025);};
  const mM=PB(0x3A1A12,{roughness:.6});const line=(pts,r)=>add(new THREE.TubeGeometry(new THREE.CatmullRomCurve3(pts.map(([x,y])=>proj(x,y))),24,r,6),mM);
  line([[0,.69],[0,.676],[0,.662]],.0026);line([[0,.662],[-.018,.651],[-.036,.652],[-.05,.66]],.0028);line([[0,.662],[.02,.65],[.042,.655],[.06,.672]],.0028);
  const cr=add(new THREE.SphereGeometry(.004,8,6),mM);cr.position.copy(proj(.062,.675));
  const chv=PB(0x5AB4EC,{roughness:.5,sheen:.6});add(new THREE.TubeGeometry(new THREE.CatmullRomCurve3([proj(-.05,.905),proj(-.025,.888),proj(0,.872),proj(.025,.888),proj(.05,.905)],false,'catmullrom',.1),24,.011,8),chv).name='motion_chevron';}
 // whiskers
 const wm=PB(0xFFF6E6,{roughness:.4});for(const s of[-1,1])for(let k=0;k<3;k++){const y0=.665-k*.012;const cu=new THREE.CatmullRomCurve3([v3(s*.06,y0,.29),v3(s*.14,y0+.01-k*.008,.28),v3(s*.24,y0-.004-k*.02,.24)]);add(new THREE.TubeGeometry(cu,12,.0022,5),wm);}
 // chevron on forehead
 {const brass=PB(0xD9B86A,{metalness:1,roughness:.3}),leather=PB(0x5A3420,{roughness:.7}),glass=PB(0xA8E6F4,{roughness:.04,metalness:.1,clearcoat:1,clearcoatRoughness:0,transparent:true,opacity:.72});
  const gg=new THREE.Group();gg.name='goggles';gg.visible=false;gg.position.set(0,.884,.214);gg.rotation.set(-.6,0,0);G.add(gg);
  for(const s of[-1,1]){add(new THREE.CylinderGeometry(.037,.034,.024,28,1,true),leather,[s*.05,0,-.008],[Math.PI/2,0,0],null,gg);add(new THREE.TorusGeometry(.036,.0105,12,36),brass,[s*.05,0,.004],null,null,gg);const ln=add(new THREE.SphereGeometry(.033,28,12,0,Math.PI*2,0,Math.PI*.3),glass,[s*.05,0,-.018],[Math.PI/2,0,0],[1,1,1],gg);ln.castShadow=false;const gl=new THREE.Mesh(new THREE.CircleGeometry(.008,12),new THREE.MeshBasicMaterial({color:0xffffff,transparent:true,opacity:.8}));gl.position.set(s*.05-.012,.012,.017);gg.add(gl);}
  add(new THREE.BoxGeometry(.03,.012,.012),brass,[0,0,.002],null,null,gg);
  const sp=add(new THREE.TorusGeometry(.176,.0125,8,64),leather,[0,.85,.068],[Math.PI/2-.26,0,0],[1.02,1,.9]);sp.name='goggle_strap';sp.visible=false;}
 {const sc=document.createElement('canvas');sc.width=256;sc.height=32;const x=sc.getContext('2d');x.fillStyle='#4FA8E0';x.fillRect(0,0,256,32);x.fillStyle='rgba(255,255,255,.12)';for(let i=0;i<256;i+=6)x.fillRect(i,0,2,32);x.fillStyle='#F2C45C';x.fillRect(206,0,8,32);x.fillRect(222,0,4,32);const st=new THREE.CanvasTexture(sc);st.colorSpace=THREE.SRGBColorSpace;
  const scarfM=rimize(PB(0xffffff,{map:st,roughness:.85,sheen:.6,sheenColor:new THREE.Color(0xDFF4FF),side:THREE.DoubleSide}));const knotM=rimize(PB(0x4FA8E0,{roughness:.85,sheen:.6,sheenColor:new THREE.Color(0xDFF4FF)}));
  const kn=add(new THREE.TorusGeometry(.132,.046,14,48),knotM,[0,.585,.07],[Math.PI/2-.26,0,0],[1.1,1,1]);kn.name='scarf';add(new THREE.SphereGeometry(.042,16,12),knotM,[-.075,.57,.18],null,[1.1,.85,.9]);add(new THREE.SphereGeometry(.036,16,12),knotM,[-.1,.585,.03],null,[1,.9,1.1]);
  const ribbon=(pts,w0,w1,tw)=>{const cu=new THREE.CatmullRomCurve3(pts.map(p=>v3(...p)));const N=48,pos=[],uv=[],idx=[];for(let i=0;i<=N;i++){const u=i/N,p=cu.getPoint(u),t=cu.getTangent(u);const sd=new THREE.Vector3().crossVectors(t,v3(1,0,0)).normalize().applyAxisAngle(t,tw*Math.sin(u*3.2));const w=(w0+(w1-w0)*u)/2;pos.push(p.x+sd.x*w,p.y+sd.y*w,p.z+sd.z*w,p.x-sd.x*w,p.y-sd.y*w,p.z-sd.z*w);uv.push(u,0,u,1);if(i<N){const k=i*2;idx.push(k,k+1,k+2,k+1,k+3,k+2);}}const g=new THREE.BufferGeometry();g.setAttribute('position',new THREE.Float32BufferAttribute(pos,3));g.setAttribute('uv',new THREE.Float32BufferAttribute(uv,2));g.setIndex(idx);g.computeVertexNormals();return g;};
  const t1=add(ribbon([[-.09,.585,.03],[-.19,.575,-.01],[-.3,.6,-.05],[-.41,.575,-.09],[-.51,.61,-.12]],.072,.058,.45),scarfM);t1.name='scarf_tail';
  const t2=add(ribbon([[-.08,.57,.02],[-.17,.54,-.03],[-.27,.555,-.07],[-.37,.525,-.1]],.062,.05,-.55),scarfM);t2.name='scarf_tail_2';G.userData.scarf=[t1,t2];[kn,t1,t2].forEach(o=>o.visible=false);G.children.filter(o=>o.material===knotM).forEach(o=>o.visible=false);}
 // satchel: canvas bag with leather flap, swinging back from left hip
 const weave=(()=>{const c=document.createElement('canvas');c.width=c.height=256;const x=c.getContext('2d');x.fillStyle='#808080';x.fillRect(0,0,256,256);for(let i=0;i<256;i+=4){x.fillStyle=i%8?'#9a9a9a':'#666';x.fillRect(i,0,2,256);x.fillRect(0,i,256,2);}const t=new THREE.CanvasTexture(c);t.wrapS=t.wrapT=THREE.RepeatWrapping;t.repeat.set(5,5);return t;})();
 const sat=new THREE.Group();sat.name='satchel';sat.position.set(.235,.36,.07);sat.rotation.set(.1,1.0,-.18);sat.scale.setScalar(.72);G.add(sat);
 const rr=(w,h,r)=>{const sh=new THREE.Shape();const x=-w/2,y=-h/2;sh.moveTo(x+r,y);sh.lineTo(x+w-r,y);sh.quadraticCurveTo(x+w,y,x+w,y+r);sh.lineTo(x+w,y+h-r);sh.quadraticCurveTo(x+w,y+h,x+w-r,y+h);sh.lineTo(x+r,y+h);sh.quadraticCurveTo(x,y+h,x,y+h-r);sh.lineTo(x,y+r);sh.quadraticCurveTo(x,y,x+r,y);return sh;};
 const bg=new THREE.ExtrudeGeometry(rr(.26,.22,.08),{depth:.09,bevelEnabled:true,bevelThickness:.045,bevelSize:.04,bevelSegments:10,curveSegments:18});bg.translate(0,0,-.045);{const p=bg.attributes.position;for(let i=0;i<p.count;i++){const y=p.getY(i),z=p.getZ(i);p.setZ(i,z*(1+.35*Math.max(0,1-Math.abs(y)/.16)));p.setX(i,p.getX(i)*(1+.08*Math.max(0,-y/.15)));}bg.computeVertexNormals();}
 add(bg,rimize(PB(0x6FB8E6,{roughness:.9,bumpMap:weave,bumpScale:2,sheen:.4,sheenColor:new THREE.Color(0xFFE4C0)})),null,null,null,sat);
 add(new THREE.ExtrudeGeometry(rr(.27,.13,.06),{depth:.012,bevelEnabled:true,bevelThickness:.01,bevelSize:.01,bevelSegments:5,curveSegments:14}),PB(0x6E4326,{roughness:.55,clearcoat:.2}),[0,.065,.105],[.12,0,0],null,sat);
 add(new THREE.BoxGeometry(.036,.03,.014),PB(0xD9B86A,{metalness:1,roughness:.3}),[0,.02,.13],null,null,sat);
 {const cu=new THREE.CurvePath();const a=v3(-.035,.08,.132),b=v3(0,.055,.14),c=v3(.035,.08,.132);cu.add(new THREE.LineCurve3(a,b));cu.add(new THREE.LineCurve3(b,c));add(new THREE.TubeGeometry(cu,16,.008,8),PB(0xF2B43C,{roughness:.5}),null,null,null,sat);}
 // strap across the chest
 {const cu=new THREE.CatmullRomCurve3([v3(-.12,.645,.0),v3(-.1,.635,.125),v3(-.02,.565,.198),v3(.09,.475,.19),v3(.18,.43,.13),v3(.22,.42,.1)]);const st=add(new THREE.TubeGeometry(cu,48,.016,8),PB(0x7A4A2A,{roughness:.6}));st.name='strap';add(new THREE.TorusGeometry(.018,.006,10,20),PB(0xD9B86A,{metalness:1,roughness:.3}),[-.02,.565,.205],[0,0,-.6]);}
 // coins: one held high, a stream flying from the satchel
 const coinM=PB(0xF2C45C,{metalness:1,roughness:.28,emissive:0x3A2A08,emissiveIntensity:.2});const coinD=PB(0xC8962E,{metalness:1,roughness:.4});const coins=[];
 const prof=[[0,-.0045],[.028,-.0045],[.032,-.0032],[.035,-.0062],[.0405,-.0055],[.042,0],[.0405,.0055],[.035,.0062],[.032,.0032],[.028,.0045],[0,.0045]].map(([x,y])=>new THREE.Vector2(x,y));const coinG=new THREE.LatheGeometry(prof,40);
 const star=new THREE.Shape();for(let i=0;i<10;i++){const a=i/10*Math.PI*2-Math.PI/2,r=i%2?.009:.021;const x=Math.cos(a)*r,y=Math.sin(a)*r;i?star.lineTo(x,y):star.moveTo(x,y);}star.closePath();const starG=new THREE.ExtrudeGeometry(star,{depth:.0022,bevelEnabled:true,bevelThickness:.0008,bevelSize:.0008,bevelSegments:2});starG.rotateX(-Math.PI/2);
 const mkCoin=(p,r,s)=>{const g=new THREE.Group();g.name='coin';const m=new THREE.Mesh(coinG,coinM);m.castShadow=true;g.add(m);for(const sg of[1,-1]){const st=new THREE.Mesh(starG,coinM);st.position.y=sg*.0036;if(sg<0)st.rotation.x=Math.PI;g.add(st);}const rim=new THREE.Mesh(new THREE.TorusGeometry(.0385,.0012,6,48),coinD);rim.rotation.x=Math.PI/2;g.add(rim);g.position.set(...p);g.rotation.set(...r);g.scale.setScalar(s);G.add(g);return g;};
 coins.push(mkCoin([.212,.549,.334],[1.5,0,0],1.12));
 for(let i=0;i<6;i++){const u=i/5;const c=mkCoin([.28+u*.12,.46+u*.36+Math.sin(u*3)*.05,-.02-u*.22],[Math.random()*3,Math.random()*3,0],.8);c.userData.base=c.position.clone();c.userData.ph=i;coins.push(c);}
 G.userData.coins=coins;return G;}

export function partDists(x,y,z){const o=[];for(const p of P2){if(p.op==='s')continue;const dx=x-p.c[0],dy=y-p.c[1],dz=z-p.c[2];if(Math.sqrt(dx*dx+dy*dy+dz*dz)-p.R>.07)continue;o.push([p.name,p.f(x,y,z)]);}return o;}
export function skyCache(){try{const w=window.top;return w.__skyCache||(w.__skyCache={});}catch(e){return window.__skyCache||(window.__skyCache={});}}
const TOPW=(()=>{try{return window.top.Float32Array?window.top:window}catch(e){return window}})();
export function cacheArr(a){return new (TOPW[a.constructor.name]||globalThis[a.constructor.name])(a);}
export function fromCache(a){return new globalThis[a.constructor.name](a);}
export function loadBaked(url,res){const C=skyCache(),K='g'+res;if(C[K])return Promise.resolve();if(C['p'+K])return C['p'+K];
 const pr=fetch(new URL(url,location.href)).then(r=>r.arrayBuffer()).then(ab=>{if(C[K])return;const hl=new Uint32Array(ab,0,1)[0];const hdr=JSON.parse(new TextDecoder().decode(new Uint8Array(ab,4,hl)));const base=4+hl+((4-(4+hl)%4)%4);const a={};let i,si,sw;for(const t of hdr.attrs){const arr=cacheArr(new globalThis[t.type](ab,base+t.off,t.len));if(t.name==='index')i=arr;else if(t.name==='skinIndex')si=arr;else if(t.name==='skinWeight')sw=arr;else a[t.name]=[arr,t.item];}C[K]={a,i,si,sw};}).catch(()=>{});C['p'+K]=pr;return pr;}
export function buildSkyskipper(opt={}){RESV=opt.res||.0072;const grp=new THREE.Group();grp.name='skyskipper';
 const C=skyCache(),K='g'+RESV;let g;
 if(C[K]){const d=C[K];g=new THREE.BufferGeometry();for(const n in d.a)g.setAttribute(n,new THREE.BufferAttribute(fromCache(d.a[n][0]),d.a[n][1]));g.setIndex(new THREE.BufferAttribute(fromCache(d.i),1));g.computeBoundingSphere();g.computeBoundingBox();}
 else{g=mesh();paint(g);const a={};for(const n in g.attributes)a[n]=[cacheArr(g.attributes[n].array),g.attributes[n].itemSize];C[K]={a,i:cacheArr(g.index.array)};}
 g.userData.ck=K;
 const body=new THREE.Mesh(g,rimize(new THREE.MeshPhysicalMaterial({vertexColors:true,roughness:.8,sheen:.5,sheenRoughness:.5,sheenColor:new THREE.Color(0xFFE8C0)})));body.name='body';body.castShadow=true;body.receiveShadow=true;grp.add(body);
 {const om=new THREE.MeshBasicMaterial({color:0x1A0C14,side:THREE.BackSide});om.onBeforeCompile=sh=>{sh.vertexShader=sh.vertexShader.replace('#include <begin_vertex>','#include <begin_vertex>\n transformed+=normal*0.0075;');};const ol=new THREE.Mesh(g,om);ol.name='outline';ol.visible=false;grp.add(ol);}
 const N=opt.shells??4;for(let l=1;l<=N;l++){const s=new THREE.Mesh(g,furShellMat(l,N+1));s.name='fur_shell_'+l;grp.add(s);}
 const acc=accessories();if(APOSE){const pr=aposeRot([.23,.49,.33],'R');acc.traverse(o=>{if(o.name!=='coin')return;const d=Math.hypot(o.position.x-.23,o.position.y-.49,o.position.z-.33);if(d>.14)return;const q=aposeRot([o.position.x,o.position.y,o.position.z],'R');o.position.set(q[0],q[1],q[2]);o.rotateOnWorldAxis(new THREE.Vector3(0,0,1),APOSE);});}grp.userData.apose=APOSE;grp.add(acc);grp.userData.coins=acc.userData.coins;grp.userData.tris=g.index.count/3;grp.traverse(o=>{o.userData.sculpt=true;});return grp;}
