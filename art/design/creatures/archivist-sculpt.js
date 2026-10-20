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
// ---------- SCULPT: The Archivist · tall old keeper (1 unit ≈ 1.3 m) · faces +Z · character's right = +x ----------
// robe
E('robeHem',[0,.19,-.01],[.325,.19,.29],null,.09);
E('robeLow',[0,.43,0],[.25,.24,.222],null,.09);
E('waist',[0,.66,.01],[.212,.15,.184],null,.08);
E('belly',[0,.77,.04],[.2,.15,.172],null,.08);
E('chest',[0,.9,0],[.232,.14,.178],null,.07);
E('shoulders',[0,.975,-.01],[.26,.075,.17],null,.06);
E('collar',[0,1.045,-.005],[.15,.05,.13],null,.03);E('hood',[0,1.0,-.15],[.2,.105,.065],[-.3,0,0],.05);E('hood2',[0,.93,-.175],[.13,.07,.045],[-.2,0,0],.04);
[.55,1.15,1.8,2.4,3.14159,-.55,-1.15,-1.8,-2.4].forEach((a,i)=>C('fold'+i,[Math.sin(a)*.27,.52,Math.cos(a)*.235],[Math.sin(a)*.3,.16,Math.cos(a)*.264],.014,.022,.055));
E('hemcut',[0,-.5,0],[1.2,.585,1.2],null,.015,'s');
for(const s of[-1,1]){E('shoe'+s,[s*.1,.05,.2],[.062,.042,.1],[0,s*.15,0],.02);C('toe'+s,[s*.102,.058,.28],[s*.11,.098,.316],.026,.013,.02);}
// head
E('skull',[0,1.25,0],[.135,.145,.14],null,.05);
E('crown',[0,1.3,-.015],[.12,.1,.12],null,.04);
E('face',[0,1.2,.07],[.1,.1,.08],null,.05);
for(const s of[-1,1])E('cheek'+s,[s*.068,1.168,.088],[.058,.052,.054],null,.04);
E('nose',[0,1.18,.165],[.034,.038,.036],[-.2,0,0],.018);for(const s of[-1,1])E('nostril'+s,[s*.021,1.162,.148],[.016,.013,.015],null,.012);
C('bridge',[0,1.238,.128],[0,1.198,.152],.015,.019,.02);
for(const s of[-1,1])E('browridge'+s,[s*.052,1.252,.126],[.04,.014,.02],[0,s*.3,0],.02);for(const s of[-1,1])E('bag'+s,[s*.05,1.198,.132],[.028,.012,.016],[0,0,s*.15],.012);
for(const s of[-1,1])E('socket'+s,[s*.05,1.224,.13],[.031,.026,.021],null,.012,'s');
for(const s of[-1,1])E('ear'+s,[s*.138,1.195,-.005],[.022,.048,.034],[0,s*-.3,0],.02);
for(const s of[-1,1]){E('hairS'+s,[s*.124,1.232,-.03],[.038,.07,.07],[0,0,s*.22],.035);E('hairT'+s,[s*.11,1.292,-.045],[.03,.036,.05],[0,0,s*.55],.03);E('hairW'+s,[s*.136,1.188,-.05],[.026,.04,.05],[0,0,s*-.15],.025);}
E('hairB',[0,1.215,-.098],[.112,.078,.056],null,.035);
for(const s of[-1,1])E('brow'+s,[s*.056,1.262,.128],[.043,.016,.022],[0,s*.3,s*-.32],.012);
for(const s of[-1,1])E('stache'+s,[s*.043,1.122,.162],[.054,.02,.027],[0,s*.35,s*-.42],.015);
E('beard1',[0,1.06,.11],[.115,.075,.085],null,.04);
E('beard2',[0,.985,.18],[.1,.1,.065],null,.04);
E('beard3',[0,.885,.215],[.07,.08,.048],null,.035);
E('beard4',[0,.8,.25],[.038,.05,.032],[.15,0,0],.03);
// arms · sculpted away from the body (staff planted at his right, left palm up under the book)
C('slR1',[.2,.99,-.005],[.39,.8,.03],.075,.082,.03);C('slR2',[.39,.8,.03],[.44,.71,.115],.08,.094,.035);E('drapeR',[.43,.675,.06],[.05,.07,.055],null,.045);{const a=[.39,.8,.03],b=[.44,.71,.115];const d=[b[0]-a[0],b[1]-a[1],b[2]-a[2]];const l=Math.hypot(...d);E('cuffcutR',[b[0]+d[0]/l*.05,b[1]+d[1]/l*.05,b[2]+d[2]/l*.05],[.074,.074,.074],null,.012,'s');}
{const AX=.47,AZ=.185,SR=.028;const P=(th,rr,y)=>[AX+Math.cos(th*Math.PI/180)*rr,y,AZ+Math.sin(th*Math.PI/180)*rr];
 C('wristR',[.445,.712,.118],[.446,.7,.142],.023,.021,.008);
 E('handR',P(-118,SR+.016,.688),[.02,.04,.022],[0,.4,0],.01);E('handRk',P(-52,SR+.012,.688),[.014,.04,.013],[0,-.6,0],.008);
 for(let k=0;k<4;k++){const y=.713-k*.0205,r0=.0118-k*.0004,rr=SR+r0+.0015;const q=[P(-40,rr,y),P(15,rr,y-.001),P(68,rr,y-.002),P(112,rr-.001,y-.003)];C('fgR'+k,q[0],q[1],r0,r0*.95,.003);C('fgR'+k+'b',q[1],q[2],r0*.95,r0*.9,.003);C('fgR'+k+'t',q[2],q[3],r0*.9,r0*.8,.003);}
 {const rr=SR+.012;C('tbR',P(-150,rr,.714),P(-198,rr+.001,.726),.0128,.0118,.005);C('tbR2',P(-198,rr+.001,.726),P(-252,rr+.001,.725),.0118,.0102,.004);}}
C('slL1',[-.2,.99,-.005],[-.39,.8,0],.075,.082,.03);C('slL2',[-.39,.8,0],[-.382,.776,.14],.08,.094,.035);E('drapeL',[-.4,.72,.05],[.05,.075,.06],null,.045);{const a=[-.39,.8,0],b=[-.382,.776,.14];const d=[b[0]-a[0],b[1]-a[1],b[2]-a[2]];const l=Math.hypot(...d);E('cuffcutL',[b[0]+d[0]/l*.05,b[1]+d[1]/l*.05,b[2]+d[2]/l*.05],[.074,.074,.074],null,.012,'s');}
C('wristL',[-.382,.776,.15],[-.38,.774,.2],.023,.021,.008);
E('handL',[-.378,.772,.238],[.043,.017,.042],[0,0,.15],.012);E('handLp',[-.378,.764,.232],[.034,.01,.03],[0,0,.15],.01);
for(let k=0;k<4;k++){const x=-.409+k*.0195,r0=k===3?.0092:.0104;const zb=.268-Math.abs(k-1.3)*.004;C('fgL'+k,[x,.777,zb],[x-.001,.783,zb+.024],r0,r0*.95,.004);C('fgL'+k+'t',[x-.001,.783,zb+.024],[x-.002,.797,zb+.035],r0*.95,r0*.82,.004);}
C('tbL',[-.336,.774,.222],[-.32,.782,.246],.0105,.0095,.005);C('tbL2',[-.32,.782,.246],[-.312,.794,.26],.0095,.0082,.004);
// ---------- SDF (arms blend into the body only at the shoulder) ----------
const P2=prims;const ARM=/^(slR|slL|drape|cuffcut|wrist|hand|fgR|fgL|tbR|tbL)/;for(const p of P2)p.arm=ARM.test(p.name);
function sdf(x,y,z){let d=1e9,dA=1e9;for(let i=0;i<P2.length;i++){const p=P2[i];const dx=x-p.c[0],dy=y-p.c[1],dz=z-p.c[2];const bound=Math.sqrt(dx*dx+dy*dy+dz*dz)-p.R;
  if(p.op==='s'){if(bound<.06){const di=p.f(x,y,z);if(p.arm)dA=smax(dA,-di,p.k);else d=smax(d,-di,p.k);}continue;}
  const di=bound>.09?bound:p.f(x,y,z);if(p.arm)dA=dA>5?di:smin(dA,di,p.k);else d=d>5?di:smin(d,di,p.k);}
 if(dA<5){const kJ=.004+.04*sstep(.9,.975,y);d=d>5?dA:smin(d,dA,kJ);}
 if(d<.015){d-=(vnoise(x*40,y*40,z*40)-.5)*.0016;}
 return d;}
const PD={};for(const p of P2)PD[p.name]=p;
const dist=(n,x,y,z)=>PD[n].f(x,y,z);
export function partDists(x,y,z){const o=[];for(const p of P2){if(p.op==='s')continue;const dx=x-p.c[0],dy=y-p.c[1],dz=z-p.c[2];if(Math.sqrt(dx*dx+dy*dy+dz*dz)-p.R>.08)continue;o.push([p.name,p.f(x,y,z)]);}return o;}
// ---------- surface nets with coarse pruning ----------
function mesh(){const b0=[-.58,.02,-.4],b1=[.58,1.44,.4],h=RESV;const nx=Math.ceil((b1[0]-b0[0])/h)+1,ny=Math.ceil((b1[1]-b0[1])/h)+1,nz=Math.ceil((b1[2]-b0[2])/h)+1;
 const S=4,H=h*S,cx=Math.ceil(nx/S)+1,cy=Math.ceil(ny/S)+1,cz=Math.ceil(nz/S)+1;const CV=new Float32Array(cx*cy*cz);for(let k=0;k<cz;k++)for(let j=0;j<cy;j++)for(let i=0;i<cx;i++)CV[i+cx*(j+cy*k)]=sdf(b0[0]+i*H,b0[1]+j*H,b0[2]+k*H);
 const V=new Float32Array(nx*ny*nz);const id=(i,j,k)=>i+nx*(j+ny*k);
 for(let k=0;k<nz;k++)for(let j=0;j<ny;j++)for(let i=0;i<nx;i++){const cv=CV[Math.round(i/S)+cx*(Math.round(j/S)+cy*Math.round(k/S))];V[id(i,j,k)]=Math.abs(cv)>H*1.6?cv:sdf(b0[0]+i*h,b0[1]+j*h,b0[2]+k*h);}
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
const COL={robe:new THREE.Color(0x3C1C82),robeLight:new THREE.Color(0x5A38AE),robeDark:new THREE.Color(0x1C0C48),gold:new THREE.Color(0xE8B64E),goldDark:new THREE.Color(0x8E5E1C),skin:new THREE.Color(0xF1C4A0),rosy:new THREE.Color(0xE38E7E),hair:new THREE.Color(0xF7F3EC),hairShade:new THREE.Color(0xC9C0BC),shoe:new THREE.Color(0x5A3422),shoeLight:new THREE.Color(0x8E5C38),warm:new THREE.Color(0x5A2A7A),warmSkin:new THREE.Color(0xB8604A)};
const G_SKIN=P2.filter(p=>/^(skull|crown|face|cheek|nose|nostril|bridge|browridge|bag|ear|wrist|hand|fgR|fgL|tbR|tbL)/.test(p.name)).map(p=>p.name);
const G_HAIR=P2.filter(p=>/^(hairS|hairT|hairW|hairB|brow-|brow1|stache|beard)/.test(p.name)).map(p=>p.name);
const G_SHOE=P2.filter(p=>/^(shoe|toe)/.test(p.name)).map(p=>p.name);
const G_ROBE=P2.filter(p=>p.op!=='s'&&!G_SKIN.includes(p.name)&&!G_HAIR.includes(p.name)&&!G_SHOE.includes(p.name)).map(p=>p.name);
const minD=(G,x,y,z)=>{let m=1;for(const n of G){const p=PD[n];const dx=x-p.c[0],dy=y-p.c[1],dz=z-p.c[2];if(Math.sqrt(dx*dx+dy*dy+dz*dz)-p.R>m)continue;const d=p.f(x,y,z);if(d<m)m=d;}return m;};
const segU=(a,b,x,y,z)=>{const ax=b[0]-a[0],ay=b[1]-a[1],az=b[2]-a[2];return((x-a[0])*ax+(y-a[1])*ay+(z-a[2])*az)/(ax*ax+ay*ay+az*az);};
function paint(g){const p=g.attributes.position.array,n=g.attributes.normal.array;const col=new Float32Array(p.length),fm=new Float32Array(p.length/3);const c=new THREE.Color(),t=new THREE.Color(),s=new THREE.Color();
 for(let q=0,vi=0;q<p.length;q+=3,vi++){const x=p[q],y=p[q+1],z=p[q+2],nx=n[q],ny=n[q+1],nz=n[q+2];
  const dS=minD(G_SKIN,x,y,z),dH=minD(G_HAIR,x,y,z),dF=minD(G_SHOE,x,y,z),dR=minD(G_ROBE,x,y,z);
  // robe: velvet violet, lighter at the shoulders, deeper toward the hem
  c.copy(COL.robe).lerp(COL.robeLight,sstep(.6,1.05,y)*.25+sstep(0,.9,ny)*.15).lerp(COL.robeDark,sstep(.5,.1,y)*.35+sstep(.1,-.6,ny)*.2);
  let trim=0,line=0,inner=0;const onRobe=dR<=Math.min(dS,dH,dF)+.003;
  trim=Math.max(trim,sstep(.152,.146,y));line=Math.max(line,sstep(.006,0,Math.abs(y-.162)));
  if(z>.05&&y<.645){const ax=Math.abs(x);trim=Math.max(trim,sstep(.026,.02,ax));line=Math.max(line,sstep(.005,0,Math.abs(ax-.031))*sstep(.64,.6,y));}
  {const dh=Math.min(dist('hood',x,y,z),dist('hood2',x,y,z));if(dh<.008&&z<-.12){const hp=Math.hypot(x/.2,(y-.98)/.13);trim=Math.max(trim,sstep(.86,.92,hp));}}
  {const dc=dist('collar',x,y,z);if(dc<.012&&y>1.05)trim=Math.max(trim,sstep(1.056,1.066,y));}
  for(const[a,b,nm]of[[[.39,.8,.03],[.44,.71,.115],'slR2'],[[-.39,.8,0],[-.382,.776,.14],'slL2']]){if(dist(nm,x,y,z)>.014)continue;const u=segU(a,b,x,y,z);if(u>.8)trim=Math.max(trim,sstep(.84,.88,u));{const ax=b[0]-a[0],ay=b[1]-a[1],az=b[2]-a[2],l=Math.hypot(ax,ay,az);const px=x-a[0]-ax*u,py=y-a[1]-ay*u,pz=z-a[2]-az*u;const rad=Math.hypot(px,py,pz);if(u>.9&&rad<.074)inner=Math.max(inner,sstep(.074,.06,rad));}if(u>.78&&u<.86)line=Math.max(line,sstep(.02,0,Math.abs(u-.82))*.9);}
  if(y>.19&&y<.6){const a=Math.atan2(x,z);const ca=Math.floor(a*6),cy=Math.floor(y*18);const hh=hash(ca,cy,3.1);if(hh>.8){const ua=(a*6-ca)-.5,uy=(y*18-cy)-.5;const r=Math.hypot(ua,uy*1.2);trim=Math.max(trim,sstep(.16,.08,r)*.95);}}
  if(!onRobe){trim=0;line=0;inner=0;}c.lerp(COL.gold,trim);c.lerp(COL.goldDark,line*.75);c.lerp(t.copy(COL.robeDark).multiplyScalar(.55),inner);
  if(trim>.5)c.offsetHSL(0,0,(vnoise(x*120,y*120,z*120)-.5)*.08);
  // skin, hair, shoes by nearest part
  const wS=sstep(.004,-.006,dS-Math.min(dR,dH,dF)),wH=sstep(.004,-.006,dH-Math.min(dR,dS,dF)),wF=sstep(.004,-.006,dF-Math.min(dR,dS,dH));
  if(wS>0){t.copy(COL.skin);const dc=Math.min(dist('cheek-1',x,y,z),dist('cheek1',x,y,z));t.lerp(COL.rosy,sstep(.03,-.01,dc)*.45*sstep(-.2,.6,nz));t.lerp(COL.rosy,sstep(.02,-.012,dist('nose',x,y,z))*sstep(.17,.2,z)*.55);
   const de=Math.min(dist('ear-1',x,y,z),dist('ear1',x,y,z));t.lerp(COL.warmSkin,sstep(.01,-.01,de)*.25);
   {if(y<.9){t.lerp(COL.warmSkin,.28);let dm=1;for(let q2=0;q2<3;q2++){dm=Math.min(dm,Math.abs(dist('fgR'+q2,x,y,z)-dist('fgR'+(q2+1),x,y,z)),Math.abs(dist('fgL'+q2,x,y,z)-dist('fgL'+(q2+1),x,y,z)));}t.lerp(COL.warmSkin,sstep(.004,0,dm)*.45);t.lerp(COL.rosy,sstep(.012,-.004,Math.min(dist('handRk',x,y,z),dist('tbR',x,y,z),dist('tbL',x,y,z)))*.18);}}if(y>1.3)t.offsetHSL(0,-.03,.03);if(z>.08&&y>1.27&&y<1.32){const wl=Math.min(Math.abs(y-1.284-x*x*1.2),Math.abs(y-1.302-x*x*1.2));t.lerp(COL.warmSkin,sstep(.0025,0,wl)*.3*sstep(.09,.02,Math.abs(x)));}c.lerp(t,wS);}
  if(wH>0){t.copy(COL.hair).lerp(COL.hairShade,sstep(.3,-.7,ny)*.5);const isBeard=/beard|stache/.test('')?0:1;t.offsetHSL(0,0,(vnoise(x*50,y*50,z*50)-.5)*.06);c.lerp(t,wH);
   const db=Math.min(dist('beard1',x,y,z),dist('beard2',x,y,z),dist('beard3',x,y,z),dist('beard4',x,y,z),dist('stache-1',x,y,z),dist('stache1',x,y,z));const br=Math.min(dist('brow-1',x,y,z),dist('brow1',x,y,z));
   fm[vi]=wH*(db<.004?1:br<.004?.55:.8);}
  if(wF>0){t.copy(COL.shoe).lerp(COL.shoeLight,sstep(-.2,.9,ny)*.35);c.lerp(t,wF);}
  // baked AO + painterly shading
  let ao=0,w=1;for(let s2=1;s2<=5;s2++){const h2=s2*.014;ao+=w*(h2-sdf(x+nx*h2,y+ny*h2,z+nz*h2));w*=.6;}ao=clamp(1-ao*5,0,1);
  t.copy(c).lerp(wS>.5?COL.warmSkin:COL.warm,(1-ao)*.22);c.copy(t).multiplyScalar(.78+.22*ao);
  c.offsetHSL((vnoise(x*30,y*30,z*30)-.5)*.012,0,(vnoise(x*70,y*70,z*70)-.5)*.035);
  col[q]=c.r;col[q+1]=c.g;col[q+2]=c.b;}
 g.setAttribute('color',new THREE.BufferAttribute(col,3));g.setAttribute('furMask',new THREE.BufferAttribute(fm,1));}
// ---------- materials ----------
const rimize=(m,rim=0x9FD4FF,wrap=.35)=>{m.onBeforeCompile=sh=>{sh.uniforms.uRim={value:new THREE.Color(rim)};sh.fragmentShader=sh.fragmentShader.replace('#include <common>','#include <common>\nuniform vec3 uRim;').replace('#include <opaque_fragment>','vec3 Vd=normalize(vViewPosition);float fr=pow(1.0-clamp(dot(normalize(normal),Vd),0.0,1.0),3.0);\n float side=smoothstep(-0.2,0.6,normal.x*0.8+normal.y*0.4);\n outgoingLight+=uRim*fr*side*0.9+diffuseColor.rgb*vec3(1.0,0.55,0.35)*'+wrap.toFixed(2)+'*fr*0.6;\n#include <opaque_fragment>');};return m;};
function hairShellMat(layer,N){const m=new THREE.MeshStandardMaterial({vertexColors:true,roughness:.85});m.onBeforeCompile=sh=>{sh.uniforms.uL={value:layer/N};sh.vertexShader=sh.vertexShader.replace('#include <common>','#include <common>\nattribute float furMask;uniform float uL;varying float vM;varying vec3 vP;').replace('#include <begin_vertex>','#include <begin_vertex>\n transformed+=normal*uL*0.0085*furMask;transformed.y-=uL*uL*0.004*furMask;vM=furMask;vP=position;');
 sh.fragmentShader=sh.fragmentShader.replace('#include <common>','#include <common>\nuniform float uL;varying float vM;varying vec3 vP;\nfloat h3(vec3 p){p=fract(p*0.3183099+.1);p*=17.0;return fract(p.x*p.y*p.z*(p.x+p.y+p.z));}').replace('void main() {','void main() {\n if(vM<0.02||uL>vM+0.001)discard;float hn=h3(floor(vP*vec3(700.0,260.0,700.0)));if(hn<uL*1.02)discard;').replace('#include <opaque_fragment>','outgoingLight*=mix(0.9,1.12,uL);\n#include <opaque_fragment>');};return m;}
// ---------- accessories ----------
const cv=(w,h,fn)=>{const c=document.createElement('canvas');c.width=w;c.height=h;fn(c.getContext('2d'),w,h);const t=new THREE.CanvasTexture(c);t.colorSpace=THREE.SRGBColorSpace;t.anisotropy=8;return t;};
function pageTex(seed=1,glow=false){return cv(256,352,(x,w,h)=>{x.fillStyle=glow?'#FFF1CC':'#F4E6C4';x.fillRect(0,0,w,h);const g=x.createRadialGradient(w/2,h/2,20,w/2,h/2,w*.8);g.addColorStop(0,'rgba(255,255,255,0)');g.addColorStop(1,'rgba(160,110,50,.28)');x.fillStyle=g;x.fillRect(0,0,w,h);
 let r=seed*9.7;const rnd=()=>{r=(r*16807)%2147483647;return(r%1000)/1000;};x.strokeStyle='rgba(90,60,40,.55)';x.lineWidth=3;
 for(let i=0;i<16;i++){const y=36+i*18;if(i===5||i===6)continue;let cx=24;while(cx<w-24){const l=8+rnd()*30;x.beginPath();x.moveTo(cx,y);x.lineTo(Math.min(w-24,cx+l),y);x.stroke();cx+=l+7;}}
 x.strokeStyle='rgba(120,70,160,.7)';x.lineWidth=3;x.beginPath();x.arc(w/2,138,22,0,Math.PI*2);x.stroke();x.beginPath();x.moveTo(w/2-30,138);x.lineTo(w/2+30,138);x.moveTo(w/2,108);x.lineTo(w/2,168);x.stroke();
 x.fillStyle='rgba(176,110,40,.85)';x.font='bold 30px serif';x.fillText('Ꝥ',22,34);});}
function accessories(){const G=new THREE.Group();G.name='accessories';const PB=(c,o={})=>new THREE.MeshPhysicalMaterial(Object.assign({color:c,roughness:.5},o));const add=(geo,m,p,r,s,par)=>{const o=new THREE.Mesh(geo,m);if(p)o.position.set(...p);if(r)o.rotation.set(...r);if(s)o.scale.set(...s);o.castShadow=true;o.receiveShadow=true;(par||G).add(o);return o;};
 const gl=cv(64,64,(x)=>{const g=x.createRadialGradient(32,32,0,32,32,32);g.addColorStop(0,'rgba(255,245,210,1)');g.addColorStop(.35,'rgba(255,200,110,.6)');g.addColorStop(1,'rgba(255,170,60,0)');x.fillStyle=g;x.fillRect(0,0,64,64);});
 const brass=PB(0xD8B25E,{metalness:1,roughness:.28}),brassD=PB(0xA67C32,{metalness:1,roughness:.4});
 // eyes: kind grey-blue, heavy upper lids
 const irisT=cv(128,128,(x,w)=>{const g=x.createRadialGradient(64,64,0,64,64,64);g.addColorStop(0,'#101018');g.addColorStop(.32,'#141420');g.addColorStop(.36,'#46647E');g.addColorStop(.7,'#7C9CB8');g.addColorStop(.9,'#3C5068');g.addColorStop(1,'#20283A');x.fillStyle=g;x.fillRect(0,0,128,128);x.strokeStyle='rgba(200,225,240,.25)';x.lineWidth=1.2;for(let i=0;i<48;i++){const a=i/48*Math.PI*2;x.beginPath();x.moveTo(64+Math.cos(a)*24,64+Math.sin(a)*24);x.lineTo(64+Math.cos(a)*54,64+Math.sin(a)*54);x.stroke();}});
 const skinM=PB(0xEDBE98,{roughness:.6,sheen:.4,sheenColor:new THREE.Color(0xFFE0C8)});
 for(const s of[-1,1]){const e=new THREE.Group();e.name=s<0?'eye_L':'eye_R';e.position.set(s*.05,1.222,.128);G.add(e);
  add(new THREE.SphereGeometry(.0245,32,20),PB(0xF8F0E6,{roughness:.3,clearcoat:.8,clearcoatRoughness:.1}),[0,0,0],null,null,e);
  const ig=new THREE.SphereGeometry(.0249,32,12,0,Math.PI*2,0,Math.PI*.3);ig.rotateX(Math.PI/2);{const uv=ig.attributes.uv,p=ig.attributes.position;for(let i=0;i<p.count;i++)uv.setXY(i,.5+p.getX(i)/.03,.5+p.getY(i)/.03);}
  add(ig,PB(0xffffff,{map:irisT,roughness:.18,clearcoat:1}),[s*-.002,-.002,.0],[0,s*-.08,0],null,e);
  const hl=new THREE.Mesh(new THREE.SphereGeometry(.0042,10,8),new THREE.MeshBasicMaterial({color:0xffffff}));hl.position.set(.007,.008,.022);e.add(hl);
  const lid=add(new THREE.SphereGeometry(.0262,32,12,0,Math.PI*2,0,Math.PI*.5),skinM,[0,0,0],null,null,e);lid.name='lid';const lr=new THREE.Group();lr.name='lidR';e.add(lr);lr.add(lid);lr.rotation.x=-.45;e.userData.lid=lr;
}
 // spectacles
 {const sp=new THREE.Group();sp.name='spectacles';G.add(sp);const glass=new THREE.MeshPhysicalMaterial({color:0xE8F4FF,roughness:.02,transparent:true,opacity:.14,clearcoat:1,depthWrite:false});
  for(const s of[-1,1]){add(new THREE.TorusGeometry(.031,.0034,10,44),brass,[s*.051,1.222,.166],null,null,sp);add(new THREE.CircleGeometry(.031,40),glass,[s*.051,1.222,.165],null,null,sp).castShadow=false;
   add(new THREE.TubeGeometry(new THREE.CatmullRomCurve3([new THREE.Vector3(s*.082,1.228,.162),new THREE.Vector3(s*.12,1.232,.11),new THREE.Vector3(s*.138,1.225,.03),new THREE.Vector3(s*.14,1.2,-.005)]),20,.0022,6),brass,null,null,null,sp);}
  add(new THREE.TubeGeometry(new THREE.CatmullRomCurve3([new THREE.Vector3(-.021,1.227,.169),new THREE.Vector3(0,1.236,.175),new THREE.Vector3(.021,1.227,.169)]),12,.0026,6),brass,null,null,null,sp);}
 // staff with a page-lantern
 {const st=new THREE.Group();st.name='staff';st.position.set(.47,0,.185);G.add(st);
  const woodT=cv(64,512,(x,w,h)=>{x.fillStyle='#6E4428';x.fillRect(0,0,w,h);for(let i=0;i<90;i++){x.strokeStyle=Math.random()<.5?'rgba(40,20,10,.35)':'rgba(170,110,70,.25)';x.lineWidth=1+Math.random()*2;const xx=Math.random()*w;x.beginPath();x.moveTo(xx,0);x.bezierCurveTo(xx+6,h*.3,xx-6,h*.6,xx+3,h);x.stroke();}});
  const pr=[];for(let i=0;i<=60;i++){const y=i/60*1.44;let r=.025+.003*Math.sin(y*11)+.007*Math.exp(-Math.pow((y-.36)/.03,2))+.006*Math.exp(-Math.pow((y-1.02)/.03,2))+.006*sstep(1.38,1.44,y);if(i===0)r=0;pr.push(new THREE.Vector2(r,y));}pr.push(new THREE.Vector2(0,1.44));
  const sh=add(new THREE.LatheGeometry(pr,18),PB(0xffffff,{map:woodT,roughness:.7,sheen:.3}),null,null,null,st);sh.name='staff_wood';
  add(new THREE.CylinderGeometry(.027,.022,.04,16),brassD,[0,.02,0],null,null,st);
  add(new THREE.CylinderGeometry(.036,.031,.045,18),brass,[0,1.46,0],null,null,st);add(new THREE.TorusGeometry(.036,.006,8,24),brass,[0,1.44,0],[Math.PI/2,0,0],null,st);
  for(let k=0;k<4;k++){const a=k*Math.PI/2+.4;const pts=[];for(let i=0;i<=12;i++){const u=i/12;const r=.016+.058*Math.sin(u*Math.PI)*(1-.25*u);pts.push(new THREE.Vector3(Math.cos(a)*r,1.475+u*.21,Math.sin(a)*r));}add(new THREE.TubeGeometry(new THREE.CatmullRomCurve3(pts),24,.0042,6),brass,null,null,null,st);}
  add(new THREE.SphereGeometry(.016,14,10),brass,[0,1.694,0],null,null,st);add(new THREE.TorusGeometry(.014,.004,8,20),brass,[0,1.717,0],null,null,st);
  const pt=pageTex(3,true);const pm=new THREE.MeshStandardMaterial({map:pt,emissive:0xFFC870,emissiveMap:pt,emissiveIntensity:1.4,side:THREE.DoubleSide,roughness:.9});
  const lp=new THREE.Group();lp.name='lantern_page';lp.position.set(0,1.582,0);lp.scale.setScalar(1.35);st.add(lp);for(let k=0;k<3;k++){const pg=new THREE.PlaneGeometry(.05,.07,6,1);const P=pg.attributes.position;for(let i=0;i<P.count;i++)P.setZ(i,Math.cos(P.getX(i)/.05*Math.PI)*.006);pg.computeVertexNormals();const m=new THREE.Mesh(pg,pm);m.rotation.y=k*Math.PI/3;lp.add(m);}
  const spr=new THREE.Sprite(new THREE.SpriteMaterial({map:gl,transparent:true,depthWrite:false,blending:THREE.AdditiveBlending,opacity:.85}));spr.scale.setScalar(.34);spr.position.set(0,1.582,0);spr.name='lantern_glow';st.add(spr);
  const li=new THREE.PointLight(0xFFCF8A,1.1,1.8,1.6);li.position.set(0,1.582,0);li.name='lantern_light';st.add(li);
  const rbM=new THREE.MeshStandardMaterial({map:pageTex(7),side:THREE.DoubleSide,roughness:.9});st.userData.ribbons=[];
  for(const[a,len]of[[.6,.13],[2.4,.1]]){const rg=new THREE.PlaneGeometry(.022,len,1,8);rg.translate(0,-len/2,0);const m=new THREE.Mesh(rg,rbM);m.position.set(Math.cos(a)*.03,1.455,Math.sin(a)*.03);m.rotation.y=-a+Math.PI/2;m.castShadow=true;st.add(m);st.userData.ribbons.push(m);}
  st.userData.glow=spr;st.userData.light=li;st.userData.page=lp;}
 // the floating book, pages turning by themselves
 {const bk=new THREE.Group();bk.name='book';bk.position.set(-.385,.975,.275);bk.rotation.set(.5,.3,-.22);bk.scale.setScalar(1.45);G.add(bk);
  const leather=PB(0x3E2270,{roughness:.62,sheen:.5,sheenColor:new THREE.Color(0xB89CFF)}),paper=PB(0xF1E2C0,{roughness:.9});
  const rr=(w,h,r)=>{const s=new THREE.Shape();const x=-w/2,y=-h/2;s.moveTo(x+r,y);s.lineTo(x+w-r,y);s.quadraticCurveTo(x+w,y,x+w,y+r);s.lineTo(x+w,y+h-r);s.quadraticCurveTo(x+w,y+h,x+w-r,y+h);s.lineTo(x+r,y+h);s.quadraticCurveTo(x,y+h,x,y+h-r);s.lineTo(x,y+r);s.quadraticCurveTo(x,y,x+r,y);return s;};
  const cov=new THREE.ExtrudeGeometry(rr(.12,.16,.012),{depth:.006,bevelEnabled:true,bevelThickness:.002,bevelSize:.002,bevelSegments:2});cov.rotateX(-Math.PI/2);
  for(const s of[-1,1]){const c=add(cov,leather,[s*.062,-.012,0],[0,0,s*-.06],null,bk);for(const[cx,cz]of[[.05,.07],[.05,-.07]]){add(new THREE.BoxGeometry(.02,.004,.02),brass,[s*(.062+cx),-.006,cz],[0,Math.PI/4,0],null,bk);}
   const pgT=pageTex(s>0?2:5);const pgG=new THREE.PlaneGeometry(.108,.148,10,1);pgG.rotateX(-Math.PI/2);const P=pgG.attributes.position;for(let i=0;i<P.count;i++){const u=Math.abs(P.getX(i))/.054;P.setY(i,.012+Math.sin(u*Math.PI*.5)*.006);}pgG.computeVertexNormals();
   add(new THREE.BoxGeometry(.106,.012,.146),paper,[s*.058,-.002,0],null,null,bk);add(pgG,PB(0xffffff,{map:pgT,roughness:.9}),[s*.058,0,0],null,null,bk);}
  add(new THREE.CylinderGeometry(.01,.01,.162,10),leather,[0,-.012,0],[Math.PI/2,0,0],null,bk);
  const fl=[];const flM=new THREE.MeshStandardMaterial({map:pageTex(9),roughness:.9,side:THREE.DoubleSide});for(let i=0;i<3;i++){const g=new THREE.PlaneGeometry(.106,.146,12,1);g.rotateX(-Math.PI/2);g.translate(.053,0,0);const pos0=g.attributes.position.array.slice();const pv=new THREE.Group();pv.position.set(0,.016+i*.0015,0);bk.add(pv);const m=new THREE.Mesh(g,flM);m.castShadow=true;pv.add(m);fl.push({pv,g,pos0});}
  bk.userData.flip=fl;
  const gl2=cv(64,64,(x)=>{const g=x.createRadialGradient(32,32,0,32,32,32);g.addColorStop(0,'rgba(210,190,255,.9)');g.addColorStop(1,'rgba(140,108,240,0)');x.fillStyle=g;x.fillRect(0,0,64,64);});
  const halo=new THREE.Sprite(new THREE.SpriteMaterial({map:gl2,transparent:true,depthWrite:false,blending:THREE.AdditiveBlending,opacity:.55}));halo.scale.setScalar(.34);halo.position.set(0,.03,0);bk.add(halo);bk.userData.halo=halo;
  const motes=[];const mm=new THREE.SpriteMaterial({map:gl,transparent:true,depthWrite:false,blending:THREE.AdditiveBlending,color:0xFFE9B0});for(let i=0;i<7;i++){const m=new THREE.Sprite(mm.clone());m.scale.setScalar(.018);m.userData.ph=i/7;m.userData.a=i*2.3;bk.add(m);motes.push(m);}bk.userData.motes=motes;}
 // gold rope sash with tassels
 {const sa=new THREE.Group();sa.name='sash';G.add(sa);const ropeT=cv(256,32,(x,w,h)=>{x.fillStyle='#808080';x.fillRect(0,0,w,h);for(let i=-8;i<40;i++){x.strokeStyle='rgba(30,30,30,.6)';x.lineWidth=3;x.beginPath();x.moveTo(i*8,0);x.lineTo(i*8+16,h);x.stroke();}});ropeT.wrapS=THREE.RepeatWrapping;ropeT.repeat.set(12,1);
  const rope=PB(0xE0AE4A,{metalness:.55,roughness:.4,bumpMap:ropeT,bumpScale:3});const tg=new THREE.TorusGeometry(1,.09,12,96);tg.rotateX(Math.PI/2);tg.scale(.22,.24,.196);add(tg,rope,[0,.655,.012],null,null,sa);
  add(new THREE.SphereGeometry(.028,16,12),rope,[.12,.645,.2],null,[1,.8,.8],sa);
  for(const[dx,len]of[[0,.2],[.03,.16]]){const cu=new THREE.CatmullRomCurve3([new THREE.Vector3(.11+dx*.3,.64,.19),new THREE.Vector3(.12+dx,.56,.215),new THREE.Vector3(.125+dx,.64-len,.228)]);add(new THREE.TubeGeometry(cu,16,.007,6),rope,null,null,null,sa);const e=cu.getPoint(1);add(new THREE.ConeGeometry(.014,.028,10),rope,[e.x,e.y-.006,e.z],[Math.PI,0,0],null,sa);add(new THREE.CylinderGeometry(.013,.017,.045,12,1,true),PB(0xE8B84E,{roughness:.8,side:THREE.DoubleSide}),[e.x,e.y-.04,e.z],null,null,sa);}}
 // a loose glowing page (the one he catches in the opening)
 {const pt=pageTex(11,true);const g=new THREE.PlaneGeometry(.07,.095,8,1);const P=g.attributes.position;for(let i=0;i<P.count;i++)P.setZ(i,Math.sin(P.getX(i)/.07*Math.PI)*.008);g.computeVertexNormals();const m=new THREE.Mesh(g,new THREE.MeshStandardMaterial({map:pt,emissive:0xFFC870,emissiveMap:pt,emissiveIntensity:1.1,side:THREE.DoubleSide}));m.name='loose_page';m.visible=false;G.add(m);}
 return G;}
export function setFlip(bk,i,u){const f=bk.userData.flip[i];const a=Math.PI*u;f.pv.rotation.z=a;const P=f.g.attributes.position,p0=f.pos0;const bend=Math.sin(u*Math.PI);for(let v=0;v<P.count;v++){const x=p0[v*3];P.setY(v,p0[v*3+1]+Math.sin(x/.106*Math.PI*.9)*.03*bend);}P.needsUpdate=true;}
// ---------- cache + build ----------
export function arcCache(){try{const w=window.top;return w.__arcCache||(w.__arcCache={});}catch(e){return window.__arcCache||(window.__arcCache={});}}
const TOPW=(()=>{try{return window.top.Float32Array?window.top:window}catch(e){return window}})();
export function cacheArr(a){return new (TOPW[a.constructor.name]||globalThis[a.constructor.name])(a);}
export function fromCache(a){return new globalThis[a.constructor.name](a);}
export function loadBaked(url,res){const C=arcCache(),K='g'+res;if(C[K])return Promise.resolve();if(C['p'+K])return C['p'+K];
 const pr=fetch(new URL(url,location.href)).then(r=>{if(!r.ok)throw 0;return r.arrayBuffer();}).then(ab=>{if(C[K])return;const hl=new Uint32Array(ab,0,1)[0];const hdr=JSON.parse(new TextDecoder().decode(new Uint8Array(ab,4,hl)));const base=4+hl+((4-(4+hl)%4)%4);const a={};let i,si,sw;for(const t of hdr.attrs){const arr=cacheArr(new globalThis[t.type](ab,base+t.off,t.len));if(t.name==='index')i=arr;else if(t.name==='skinIndex')si=arr;else if(t.name==='skinWeight')sw=arr;else a[t.name]=[arr,t.item];}C[K]={a,i,si,sw};}).catch(()=>{});C['p'+K]=pr;return pr;}
export {mesh,paint};export function setRes(r){RESV=r;}
export function buildArchivist(opt={}){RESV=opt.res||.0072;const grp=new THREE.Group();grp.name='archivist';
 const C=arcCache(),K='g'+RESV;let g;
 if(C[K]){const d=C[K];g=new THREE.BufferGeometry();for(const n in d.a)g.setAttribute(n,new THREE.BufferAttribute(fromCache(d.a[n][0]),d.a[n][1]));g.setIndex(new THREE.BufferAttribute(fromCache(d.i),1));g.computeBoundingSphere();g.computeBoundingBox();}
 else{g=mesh();paint(g);const a={};for(const n in g.attributes)a[n]=[cacheArr(g.attributes[n].array),g.attributes[n].itemSize];C[K]={a,i:cacheArr(g.index.array)};}
 g.userData.ck=K;
 const body=new THREE.Mesh(g,rimize(new THREE.MeshPhysicalMaterial({vertexColors:true,roughness:.82,sheen:.55,sheenRoughness:.5,sheenColor:new THREE.Color(0x9C7CF0)}),0xB8A4FF,.22));body.name='body';body.castShadow=true;body.receiveShadow=true;grp.add(body);
 const N=opt.shells??5;for(let l=1;l<=N;l++){const s=new THREE.Mesh(g,hairShellMat(l,N+1));s.name='hair_shell_'+l;s.castShadow=false;grp.add(s);}
 grp.add(accessories());grp.userData.tris=g.index.count/3;return grp;}
