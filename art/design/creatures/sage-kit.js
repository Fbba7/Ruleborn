import * as THREE from 'three';
import {sstep,vnoise,TAU} from './creature-kit.js';
// ============ shared humanoid body for the Sages (sculpt + joint map + region painter) ============
// template: ~1.18 m to the crown at k=1; faces +Z; character's right = +x; parts are named 'bone:part'
export const mir=(p,s)=>[p[0]*s,p[1],p[2]];
export function sageFrame(o={}){const k=o.k??1,H=o.head??1,LG=o.leg??1;const Y=y=>y<.52?y*LG:y-(1-LG)*.52;const P=(x,y,z)=>[x*k,Y(y)*k,z*k];const hy=o.hy??1.04;const HP=(x,y,z)=>[x*H*k,(Y(hy)+(y-hy)*H)*k,z*H*k];
 const sw=o.shW??.17,sy=o.shY??.855;
 const j={k,H,P,HP,hy:Y(hy)*k,
  sh:s=>P(s*sw,sy,0),el:s=>P(s*(sw+.05),.665,.015),wr:s=>P(s*(sw+.07),.49,.03),
  hip:s=>P(s*.072,.52,0),kn:s=>P(s*.078,.3,.012),an:s=>P(s*.078,.085,0)};
 const J={root:[null,[0,0,0]],hips:['root',P(0,.54,0)],chest:['hips',P(0,.76,0)],head:['chest',P(0,.93,0)],earL:['head',HP(0,hy+.16,-.02)],earR:['head',HP(-.08,hy+.06,-.1)],
  shL:['chest',j.sh(-1)],elL:['shL',j.el(-1)],haL:['elL',j.wr(-1)],shR:['chest',j.sh(1)],elR:['shR',j.el(1)],haR:['elR',j.wr(1)],
  thL:['hips',j.hip(-1)],knL:['thL',j.kn(-1)],ftL:['knL',j.an(-1)],thR:['hips',j.hip(1)],knR:['thR',j.kn(1)],ftR:['knR',j.an(1)],tail:['hips',P(0,.5,-.12)]};
 const TIP={haL:P(-(sw+.075),.37,.045),haR:P(sw+.075,.37,.045),ftL:P(-.08,.01,.13),ftR:P(.08,.01,.13)};
 const TORSO={hips:[P(0,.36,0),P(0,.62,0),.17*k],chest:[P(0,.6,0),P(0,.92,0),.2*k],head:[P(0,.92,0),HP(0,hy+.16,0),.15*k*H]};
 return{j,J,TIP,TORSO,P,HP,Y,k,H,hyW:Y(hy)*k};}
// o: robeHem (y of robe hem, null = no robe), coat (y of coat hem, null), belly, sleeveFlare, bootH, noseLen, skipArmR
export function sageBody(A,F,o={}){const{E,C}=A;const{P,k,H}=F;const hy=o.hy??1.04;const hs=H*k;const Q=(x,y,z)=>F.HP(x/H,hy+(y-hy)/H,z/H);
 // ---- head ----
 E('T:skull',Q(0,hy+.012*H,0),[.126*hs,.136*hs,.13*hs],null,.05*k);
 E('T:jaw',Q(0,hy-.058*H,.03*H),[.1*hs,.078*hs,.098*hs],null,.05*k);
 for(const s of[-1,1]){const L=s<0?'L':'R';
  E('T:cheek'+L,Q(s*.066*H,hy-.044*H,.086*H),[.05*hs,.043*hs,.044*hs],null,.04*k);
  E('T:brow'+L,Q(s*.048*H,hy+.032*H,.106*H),[.036*hs,.012*hs,.02*hs],[0,s*.3,0],.045*k);E('T:cheekbone'+L,Q(s*.074*H,hy-.018*H,.09*H),[.034*hs,.022*hs,.03*hs],null,.04*k);E('T:alar'+L,Q(s*.018*H,hy-.036*H,.132*H),[.012*hs,.011*hs,.012*hs],null,.012*k);
  E('T:socket'+L,Q(s*.046*H,hy+.002*H,.116*H),[.029*hs,.024*hs,.019*hs],null,.022*k,'s');
  if(o.ears!==false){E('T:ear'+L,Q(s*.126*H,hy-.012*H,-.005*H),[.02*hs,.042*hs,.03*hs],[0,s*-.3,s*-.1],.02*k);E('T:earcut'+L,Q(s*.134*H,hy-.01*H,.004*H),[.008*hs,.024*hs,.012*hs],[0,s*-.3,0],.004*k,'s');}}
 const nl=o.noseLen??1;E('T:nose',Q(0,hy-.018*H,.13*H+.012*H*(nl-1)),[.022*hs,.028*hs,.026*hs*nl],[-.25,0,0],.016*k);
 E('T:lipLo',Q(0,hy-.086*H,.104*H),[.022*hs,.008*hs,.012*hs],null,.03*k);E('T:chin',Q(0,hy-.102*H,.086*H),[.034*hs,.022*hs,.03*hs],null,.04*k);
 C('T:neck',P(0,.87,-.005),Q(0,hy-.07*H,-.01),.047*k,.044*k,.03*k);
 // ---- torso ----
 const bl=o.belly??1;
 E('T:chest',P(0,.79,0),[.158*k,.12*k,.105*k],null,.06*k);E('T:shoulders',P(0,.845,-.005),[.18*k,.05*k,.09*k],null,.05*k);
 E('T:waist',P(0,.645,.004),[.132*k,.1*k,.1*k*bl],null,.06*k);E('T:belly',P(0,.66,.035*bl),[.115*k,.08*k,.075*k*bl],null,.05*k);
 E('T:pelvis',P(0,.55,0),[.138*k,.07*k,.1*k],null,.05*k);
 if(o.robeHem!=null){const hm=o.robeHem;E('T:robe',P(0,.3,0),[.165*k*(o.flare??1),.27*k,.145*k*(o.flare??1)],null,.08*k);E('T:robeLow',P(0,.16,0),[.21*k*(o.flare??1),.16*k,.18*k*(o.flare??1)],null,.07*k);
  for(let i=0;i<8;i++){const a=(i+.5)/8*TAU;C('T:fold'+i,P(Math.sin(a)*.15*(o.flare??1),.38,Math.cos(a)*.125*(o.flare??1)),P(Math.sin(a)*.215*(o.flare??1),Math.max(.04,hm+.02),Math.cos(a)*.185*(o.flare??1)),.012*k,.02*k,.05*k);}
  E('T:hemcut',P(0,-.7,0),[1.4*k,(.7+hm)*k,1.4*k],null,.012*k,'s');}
 if(o.coat!=null){const ch=o.coat;E('T:coat',P(0,.46,-.005),[.158*k,.13*k,.12*k],null,.06*k);E('T:coatSkirt',P(0,.3,-.01),[.168*k,.2*k,.132*k],null,.07*k);
  for(let i=0;i<6;i++){const a=(i+.5)/6*TAU+Math.PI/6;C('T:cfold'+i,P(Math.sin(a)*.14,.46,Math.cos(a)*.108),P(Math.sin(a)*.168,ch+.03,Math.cos(a)*.13),.01*k,.014*k,.05*k);}
  E('T:coatcut',P(0,ch-.7,0),[1.4*k,.7*k,1.4*k],null,.012*k,'s');E('T:coatslit',P(0,ch,.16),[.014*k,.18*k,.06*k],null,.01*k,'s');}
 if(o.belt!==false)E('T:belt',P(0,.6,.004),[.137*k,.022*k,.106*k],null,.012*k);
 // ---- arms (sleeve, cuff, hand with fingers) ----
 for(const s of[-1,1]){const L=s<0?'L':'R';if(s>0&&o.skipArmR){E('sh'+L+':cap',F.j.sh(s),[.058*k,.05*k,.055*k],null,.03*k);continue;}
  const sh=F.j.sh(s),el=F.j.el(s),wr=F.j.wr(s);const fl=o.sleeveFlare??1;
  E('sh'+L+':delt',sh,[.058*k,.055*k,.056*k],null,.035*k);C('sh'+L+':arm1',sh,el,.05*k,.044*k,.03*k);E('el'+L+':elb',el,[.045*k,.045*k,.045*k],null,.02*k);
  C('el'+L+':arm2',el,[wr[0],wr[1]+.03*k,wr[2]],.043*k,.047*k*fl,.025*k);E('el'+L+':cuff',[wr[0],wr[1]+.026*k,wr[2]],[.05*k*fl,.02*k,.05*k*fl],null,.012*k);
  // hand: palm faces inward, fingers relaxed and slightly curled
  const hx=wr[0],hy2=wr[1],hz=wr[2],ix=-s;C('ha'+L+':wrist',[hx,hy2+.02*k,hz],[hx,hy2-.012*k,hz],.022*k,.024*k,.01*k);
  E('ha'+L+':palm',[hx+ix*.002*k,hy2-.04*k,hz+.004*k],[.017*k,.036*k,.03*k],[0,0,s*.08],.014*k);
  for(let f=0;f<4;f++){const fz=hz+(-.018+f*.012)*k,len=[.9,1,.96,.8][f];const a=[hx+ix*.001*k,hy2-.072*k,fz],b=[hx+ix*.007*k,hy2-(.072+.028*len)*k,fz+.003*k],c=[hx+ix*.015*k,hy2-(.072+.048*len)*k,fz+.006*k];
   C('ha'+L+':fg'+f,a,b,.0088*k,.0078*k,.004*k);C('ha'+L+':ft'+f,b,c,.0078*k,.0066*k,.003*k);}
  C('ha'+L+':tb0',[hx+ix*.01*k,hy2-.03*k,hz+.024*k],[hx+ix*.02*k,hy2-.056*k,hz+.034*k],.011*k,.0092*k,.005*k);C('ha'+L+':tb1',[hx+ix*.02*k,hy2-.056*k,hz+.034*k],[hx+ix*.024*k,hy2-.074*k,hz+.036*k],.0092*k,.0075*k,.003*k);}
 // ---- legs and boots ----
 for(const s of[-1,1]){const L=s<0?'L':'R';const hp=F.j.hip(s),kn=F.j.kn(s),an=F.j.an(s);
  C('th'+L+':leg1',hp,kn,.058*k,.047*k,.03*k);C('kn'+L+':leg2',kn,[an[0],an[1]+.02*k,an[2]],.046*k,.038*k,.025*k);
  const bh=o.bootH??.07;E('kn'+L+':bootcuff',[an[0],(bh+.02)*k,an[2]],[.047*k,.022*k,.05*k],null,.012*k);
  E('ft'+L+':boot',[an[0],.045*k,an[2]+.03*k],[.048*k,.045*k,.085*k],null,.025*k);E('ft'+L+':toe',[an[0],.04*k,an[2]+.09*k],[.042*k,.034*k,.04*k],null,.025*k);
  E('ft'+L+':sole',[an[0],.008*k,an[2]+.03*k],[.052*k,.012*k,.1*k],null,.006*k);}}
// ---- region picker: returns one of skin, hair, lip, top, robe, coat, belt, legs, boot, sole, hand, cuff, other ----
export function nearest(A,x,y,z){let m=1,n='';for(const p of A.prims){if(p.op==='s')continue;const dx=x-p.c[0],dy=y-p.c[1],dz=z-p.c[2];if(Math.sqrt(dx*dx+dy*dy+dz*dz)-p.R>m)continue;const d=Math.abs(p.f(x,y,z));if(d<m){m=d;n=p.name;}}return n;}
export function region(n){if(/^T:(hair|beard|stache)/.test(n))return'hair';if(/^ft[LR]:sole/.test(n))return'sole';if(/^ft[LR]:|^kn[LR]:bootcuff/.test(n))return'boot';
 if(/^ha[LR]:/.test(n))return'hand';if(/^el[LR]:cuff/.test(n))return'cuff';if(/^T:belt/.test(n))return'belt';if(/^T:cravat/.test(n))return'cravat';if(/^T:(skull|jaw|cheek|brow|nose|ear|lip|alar|chin|socket)/.test(n))return'skin';if(/^T:neck/.test(n))return'neck';
 if(/^(th|kn)[LR]:leg/.test(n))return'legs';if(/^T:(robe|fold)/.test(n))return'robe';if(/^T:(coat|cfold)/.test(n))return'coat';if(/^(sh|el)[LR]:/.test(n))return'sleeve';return'top';}
// shared mouth line + blush + skin shading
export function paintFace(x,y,z,c,K,F,o={}){const{k,H}=F;const hs=H*k;const hy=F.hyW;const my=hy-.07*hs;const ao=o.ao??1;
 // skin as a living surface: warm blood colour in the creases and at the cheeks, nose, ears and lips; cooler and lighter on forehead and bridge
 const sk=K.skin,red=new THREE.Color(0xC8584A),redD=new THREE.Color(0x7A3028),lite=sk.clone().lerp(new THREE.Color(0xFFF0DC),.35);
 c.copy(sk).lerp(lite,sstep(hy-.01*hs,hy+.09*hs,y)*.18*sstep(.02,.1,z/hs));
 c.lerp(redD,(1-ao)*.55);
 const ch=sstep(.05*hs,0,Math.hypot(Math.abs(x)-.068*hs,(y-(hy-.036*hs))*1.2,(z-.09*hs)*1.2));c.lerp(red,ch*(o.blush??.35)*1.1);
 const nt=sstep(.03*hs,0,Math.hypot(x,y-(hy-.024*hs),z-.15*hs));c.lerp(red,nt*.28);
 c.lerp(red,sstep(.1*hs,.125*hs,Math.abs(x))*sstep(.02*hs,-.02*hs,z)*.3);
 c.lerp(new THREE.Color(0x8A7A6A),sstep(.02*hs,-.03*hs,y-(my-.035*hs))*sstep(.03,.1,z/hs)*(o.stubble??0));
 // lips: a soft upper-lip shadow line, a rosier lower lip, dimples at the corners
 if(z>.08*hs&&Math.abs(x)<.036*hs){const u=x/(.032*hs),cy=my-(o.smile??.006)*hs*(1-Math.min(1,u*u));const dd=y-cy;const w=.0036*hs*Math.max(0,1-u*u*.6);
  if(Math.abs(u)<1){if(Math.abs(dd)<w)c.copy(K.mouth);else if(Math.abs(dd)<w+.006*hs)c.lerp(K.mouth,.5*(1-(Math.abs(dd)-w)/(.006*hs)));
   if(dd<0&&dd>-.016*hs)c.lerp(red.clone().lerp(sk,.3),.4*(1-Math.min(1,u*u))*sstep(-.016*hs,-.007*hs,dd)*sstep(-.002*hs,-.006*hs,dd));}
  const cd=Math.hypot(Math.abs(x)-.033*hs,y-(my-(o.smile??.006)*hs*.2));c.lerp(K.mouth,sstep(.004*hs,0,cd)*.18);}
 c.offsetHSL(0,0,(vnoise(x*400,y*400,z*400)-.5)*.018);}
export function clothShade(c,K,base,light,dark,ny,nz,ao,x,y,z,weave=0){c.copy(base).lerp(light,sstep(.3,.95,ny)*.25+sstep(.4,.95,nz)*.1).lerp(dark,(1-ao)*.6+sstep(-.2,-.8,ny)*.2);if(weave)c.lerp(dark,sstep(.35,.75,vnoise(x*38,y*38,z*38))*weave*.45);return c;}

// brows that sit on the skin: a tapered curved tube hugging the brow ridge; o: col, w (thickness), lift, arch, y (brow height), len
export function sageBrows(Pt,F,o={}){const{add,hit,PB}=Pt;const T=THREE;const G=new T.Group();const ctr=F.HP(0,1.035,.02);const mat=PB(o.col??0x3A2418,{roughness:.9});
 for(const s of[-1,1]){const pts=[];for(let i=0;i<=6;i++){const u=i/6;const dx=s*(.16+u*.44*(o.len??1)),dy=(o.y??.3)+Math.sin(u*Math.PI)*(o.arch??.06)-u*(o.drop??.03)+(o.tilt??0)*s*0+ (1-u)*(o.inner??0);
   const h=hit([dx,dy,1],ctr,.008);pts.push(h.p.clone());}
  const cu=new T.CatmullRomCurve3(pts);const tg=new T.TubeGeometry(cu,24,(o.w??.0075)*F.k,8,false);const P=tg.attributes.position;const R=9;
  for(let i=0;i<P.count;i++){const ti=Math.floor(i/R),u=ti/24;const c=cu.getPoint(u);const f=.35+.9*Math.sin(Math.min(1,u*1.15+.08)*Math.PI)*(1-u*.35);const v=new T.Vector3(P.getX(i),P.getY(i),P.getZ(i)).sub(c).multiplyScalar(f);P.setXYZ(i,c.x+v.x,c.y+v.y*.7,c.z+v.z);}
  tg.computeVertexNormals();const m=add(tg,mat,null,null,null,G);m.userData.bone='head';m.name='brow'+(s<0?'L':'R');}
 return G;}
