import * as THREE from 'three';
import {makeSculpt,makeRigKit,stdClips,sstep,vnoise,clamp,ease,bump,blink,cyc,TAU,merge,gait} from './creature-kit.js';
import {parts,hourglass} from './creature-parts.js';
// ============ HOURKEEPER · Mender · Time · owl with an hourglass belly, 0.9 m, cyan and brass (GDD 11.4) ============
const COL={beakD:0x5A3A18,f:0x2A7690,fL:0x5EAEC4,fD:0x0E2C3C,cream:0xEEE4CC,creamD:0xB8AE94,disc:0xF6F0E0,discR:0x22404E,beak:0x8A6436,talon:0x2A2224,leg:0xE2D6BA};
const K=Object.fromEntries(Object.entries(COL).map(([k,v])=>[k,new THREE.Color(v)]));
const mir=(p,s)=>[p[0]*s,p[1],p[2]];let A0=null;
// overlapping feather scallops in (around, up) space
const hsh=(a,b)=>{const s=Math.sin(a*12.989+b*78.233)*43758.5453;return s-Math.floor(s);};
// feathers: teardrops pointing down, each row overlapping the one below; per-feather tone, shaft and a dark chevron tip
const sc=(x,y,z,n=9,m=30)=>{const a=Math.atan2(x,z)/Math.PI*n;const v=y*m;const row=Math.floor(v);const u=a+(row%2)*.5;const col=Math.floor(u);const fu=u-col-.5,fv=v-row;const e=Math.abs(fu)/(.6*Math.sqrt(Math.max(.0004,2*fv-fv*fv))+.002);const ins=e<1?1:0;
 return{e,in:ins,edge:sstep(.78,.98,e)*(1-sstep(1.02,1.2,e)),tip:ins*sstep(.14,.24,fv)*(1-sstep(.3,.42,fv))*sstep(.55,.2,Math.abs(fu)),shaft:ins*sstep(.07,0,Math.abs(fu))*sstep(.12,.55,fv),rnd:hsh(row,col),under:1-ins};};
const def={name:'hourkeeper',box:[[-.32,0,-.34],[.32,.94,.28]],res:.0066,warm:0x10283A,aoWarm:.2,sheen:0xE0F4FF,rim:0xBFEFFF,
 bodyMat:{roughness:.72,sheen:.28,sheenRoughness:.55},fur:{len:.003,dens:[900,700,900],shells:2},
 sculpt(A){const{E,C}=A;A0=A;
  // round egg of a body, big head merged into it, dished facial discs
  E('T:body',[0,.34,-.01],[.2,.25,.18],null,.08);E('T:belly',[0,.3,.05],[.17,.2,.14],null,.07);
  E('T:head',[0,.635,.02],[.2,.15,.165],null,.08);E('T:brow',[0,.705,.12],[.15,.035,.06],null,.03);
  C('T:beak',[0,.628,.19],[0,.588,.222],.02,.007,.006);C('T:beakH',[0,.588,.222],[0,.568,.213],.008,.003,.004);E('T:cere',[0,.63,.186],[.017,.011,.014],null,.006);
  for(const s of[-1,1]){const L=s<0?'L':'R';
   E('T:disc'+L,mir([.068,.632,.152],s),[.088,.094,.03],[0,s*.35,0],.022,'s');E('T:ruff'+L,mir([.1,.63,.1],s),[.06,.1,.06],[0,s*.4,0],.04);
   C('ear'+L+':tuft',mir([.115,.755,.05],s),mir([.18,.84,.015],s),.032,.006,.03);
   E('sh'+L+':wing1',mir([.195,.44,-.01],s),[.05,.11,.095],[0,0,s*.14],.05);E('el'+L+':wing2',mir([.215,.31,-.03],s),[.042,.09,.08],[0,0,s*.05],.035);
   for(let k=0;k<3;k++)C('ha'+L+':prim'+k,mir([.215,.25,-.07+k*.035],s),mir([.198,.17,-.09+k*.03],s),.02,.006,.012);
   E('th'+L+':leg',mir([.075,.15,.03],s),[.06,.07,.065],null,.05);C('kn'+L+':shin',mir([.08,.1,.04],s),mir([.085,.05,.06],s),.03,.025,.025);
   E('th'+L+':ruffle',mir([.08,.19,.05],s),[.07,.05,.07],null,.04);E('ft'+L+':foot',mir([.088,.028,.08],s),[.03,.018,.035],null,.012);for(let k=0;k<3;k++){const a=(k-1)*.45;C('ft'+L+':toe'+k,mir([.088,.024,.085],s),mir([.088+Math.sin(a)*.05,.014,.085+Math.cos(a)*.05],s),.011,.007,.006);}}
  E('tail:fan',[0,.13,-.19],[.1,.024,.09],[-.55,0,0],.04);},
 disp(x,y,z,d){if(Math.abs(d)>.03)return d;const face=sstep(.02,.004,A0.minD(/^T:(disc|beak|cere)/,x,y,z));const hd=sstep(.6,.66,y);
  const S=sc(x,y,z,hd?14:10,hd?52:36);const inDisc=sstep(1.02,.9,Math.hypot((Math.abs(x)-.068)/.088,(y-.632)/.094))*sstep(.1,.18,z);const ang=Math.atan2(y-.632,Math.abs(x)-.068);
  return d+(1-face)*(1-inDisc)*(-S.in*(1-sstep(0,.9,S.e))*.0006+S.tip*.001-S.under*.0005)+inDisc*Math.pow(Math.abs(Math.sin(ang*11)),2)*.0006+(vnoise(x*90,y*90,z*90)-.5)*.0005;},
 paint(x,y,z,nx,ny,nz,ao,c,A){const hd=sstep(.58,.64,y);const S=sc(x,y,z,hd?14:10,hd?52:36);
  const front=sstep(.0,.7,nz)*sstep(.16,.04,Math.abs(x))*sstep(.55,.4,y)*sstep(.08,.16,y);
  c.copy(K.f).lerp(K.fL,S.in*(.1+S.rnd*.34)*(1-sstep(.5,1,S.e))+sstep(.2,.9,ny)*.12).lerp(K.fD,S.edge*.24+S.under*.1+S.tip*.22+S.shaft*.12+(1-ao)*.45+sstep(.2,-.8,nz)*.12).offsetHSL((vnoise(x*9,y*9,z*9)-.5)*.02,0,(S.rnd-.5)*.03);
  // barred cream chest
  const bar=Math.abs(Math.sin(y*110+Math.sin(x*40)*.8));c.lerp(K.cream,front*.9);c.lerp(K.f,front*sstep(.85,.97,bar)*.6);
  // facial discs: pale bowls with a dark rim and a soft eyebrow V
  const dL=Math.hypot((Math.abs(x)-.068)/.088,(y-.632)/.094);const dz=sstep(.08,.16,z);const disc=Math.max(sstep(1.04,.86,dL),sstep(.04,.02,Math.abs(x))*sstep(.72,.66,y)*sstep(.56,.6,y))*dz;const ang=Math.atan2(y-.632,Math.abs(x)-.068);
  c.lerp(K.disc,disc*.95);c.lerp(K.creamD,disc*sstep(.25,.85,dL)*(.25+.35*Math.pow(Math.abs(Math.sin(ang*11)),3)));c.lerp(K.discR,sstep(.88,1,dL)*sstep(1.2,1.04,dL)*dz*.9*sstep(.03,.075,Math.abs(x)));
  const bw=Math.abs(y-(.705-Math.abs(x)*.3));c.lerp(K.disc,sstep(.012,.004,bw)*sstep(.13,.06,Math.abs(x))*dz*.85);
  c.lerp(K.cream,sstep(.02,.004,A.dist('T:brow',x,y,z))*sstep(.1,.15,z)*.3);
  const bk=A.minD(/^T:(beak|cere)/,x,y,z);if(bk<.0016){c.copy(K.beak).lerp(K.beakD,sstep(.64,.6,y)*.55+sstep(.2,-.6,ny)*.3).lerp(K.fD,sstep(.004,-.002,A.dist('T:cere',x,y,z))*.2);}
  const lg=A.minD(/^(th|kn)[LR]:/,x,y,z);if(lg<.004)c.lerp(K.leg,.75);const ft=A.minD(/^ft[LR]:/,x,y,z);if(ft<.004)c.copy(K.talon).lerp(K.beak,sstep(.05,.03,y)*.3);
  const pr=A.minD(/^ha[LR]:prim|^tail:/,x,y,z);if(pr<.004){const u=(y*50+Math.abs(x)*20)%1;c.lerp(K.fD,sstep(.7,.85,u)*.5);c.lerp(K.fL,sstep(.2,.1,u)*.2);}
  const tf=A.minD(/^ear[LR]:/,x,y,z);if(tf<.004)c.lerp(K.fD,.4);
  return 0;},
 accessories(A){const G=new THREE.Group();const P=parts(A,G);const{PB,add,hit,onSurf,irisTex,eye}=P;
  const tex=irisTex('#050302','#E09A1C','#F8D060','#5A3208',{pup:.36});
  for(const s of[-1,1])eye(s,{r:.046,ctr:[0,.642,.02],dir:[.62,.02,1],off:-.013,tex,lid:COL.fD,lidCut:.28,yaw:.48,irisK:1.2});
  // the hourglass belly: a brass-framed glass set into the chest, cyan sand glowing
  const hb=new THREE.Group();hb.userData.bone='chest';{const h=hit([0,-.05,1],[0,.33,0],-.018);hb.position.copy(h.p);}G.add(hb);
  const brass=PB(COL.beak,{metalness:1,roughness:.28});const frame=new THREE.TorusGeometry(.085,.012,10,32);add(frame,brass,[0,0,-.005],null,[.82,1.2,1],hb);
  const hg=hourglass(P,.15,0x9BEAF3,COL.beak);hg.position.z=.012;hb.add(hg);const pl=new THREE.PointLight(0x9BEAF3,.5,.45,2);pl.position.set(0,0,.06);hb.add(pl);
  for(let k=0;k<8;k++){const a=k/8*TAU;add(new THREE.SphereGeometry(.006,10,8),brass,[Math.cos(a)*.07,Math.sin(a)*.102,.0],null,null,hb);}
  // Time mark: small brass hourglass pin on the brow
  
  // mend glow (ability)
  const fx=new THREE.Group();fx.userData.bone='root';fx.userData.fx='heal';fx.userData.fxMode='show';fx.position.set(0,.02,0);G.add(fx);
  for(let k=0;k<3;k++){const rg=P.ring(0x9BEAF3,.2+k*.07,.215+k*.07);rg.rotation.x=-Math.PI/2;rg.position.y=k*.12;fx.add(rg);}
  for(let k=0;k<12;k++){const sp=new THREE.Mesh(new THREE.SphereGeometry(.008,8,6),new THREE.MeshBasicMaterial({color:0xDFFBFF}));const a=k/12*TAU;sp.position.set(Math.cos(a)*.24,.1+(k%4)*.12,Math.sin(a)*.24);fx.add(sp);}
  return G;}};
export const S=makeSculpt(def);
const J={root:[null,[0,0,0]],hips:['root',[0,.26,0]],chest:['hips',[0,.44,.01]],head:['chest',[0,.56,.02]],earL:['head',[-.115,.755,.05]],earR:['head',[.115,.755,.05]],
 shL:['chest',[-.18,.5,0]],elL:['shL',[-.21,.36,-.02]],haL:['elL',[-.215,.25,-.04]],shR:['chest',[.18,.5,0]],elR:['shR',[.21,.36,-.02]],haR:['elR',[.215,.25,-.04]],
 thL:['hips',[-.075,.16,.03]],knL:['thL',[-.08,.1,.04]],ftL:['knL',[-.085,.05,.06]],thR:['hips',[.075,.16,.03]],knR:['thR',[.08,.1,.04]],ftR:['knR',[.085,.05,.06]],tail:['hips',[0,.18,-.15]]};
const cfg={name:'hourkeeper',J,TIP:{haL:[-.2,.16,-.08],haR:[.2,.16,-.08],ftL:[-.088,.01,.13],ftR:[.088,.01,.13]},
 TORSO:{hips:[[0,.08,0],[0,.34,0],.22],chest:[[0,.34,0],[0,.52,0],.22],head:[[0,.52,.02],[0,.84,.02],.21]},
 AIM:[],floor:.006,pivot:.26,shMin:-1.9,springs:[['earL','vx',-.4,150,9,0,.3],['earR','vx',-.4,150,9,0,.3],['tail','vx',-.3,130,10,0,.25]]};
const RK=makeRigKit(S,cfg);export const makeRig=RK.makeRig,skinGeo=RK.skinGeo;
// owls turn their heads in snaps: ease between held angles
const snap=(t,per,angs)=>{const i=Math.floor(t/per)%angs.length,f=(t/per)%1;const a=angs[i],b=angs[(i+1)%angs.length];return a+(b-a)*sstep(.82,.95,f);};
export const CLIPS=stdClips({w:.45,arm:.18,x:{
 idle:{label:'Idle',len:8,f:t=>{const b=Math.sin(t*TAU/4)*.5+.5;const hy=snap(t,2,[0,.4,.4,-.35]);const hz=snap(t,2,[0,.1,-.15,0]);return{sq:b*.012,hy,hz,hx:.02,eye:blink(t,4,1.2)<1?.2:1,b:{chest:[-b*.03,0,0],shL:[0,0,-.02-b*.03],shR:[0,0,.02+b*.03]}};}},
 idle2:{label:'Idle 2',len:4,f:t=>{const u=cyc(t,4);const bob=Math.sin(u*TAU*3)*bump(u,.1,.6);const fluff=bump(u,.65,.9);return{y:-bob*.01,hx:bob*.15,hz:Math.sin(u*TAU)*.2,sq:fluff*.04,eye:1-fluff*.6,b:{shL:[0,0,-.35*fluff],shR:[0,0,.35*fluff]}};}},
 ability:{label:'Flip the hourglass',len:2.6,f:t=>{const u=cyc(t,2.6);const cr=bump(u,0,.22),air=bump(u,.18,.58),glow=bump(u,.4,1);const turn=ease(clamp((u-.2)/.36,0,1));return{y:air*.14-cr*.03,sq:-cr*.08+air*.05,ry:turn*TAU,hx:-.1*glow,eye:1+glow*.15,heal:glow,
  b:{shL:[-.2*air,0,-1.2*air-.6*glow],shR:[-.2*air,0,1.2*air+.6*glow],elL:[-.3,0,0],elR:[-.3,0,0],thL:[-.7*cr,0,0],knL:[1.1*cr,0,0],thR:[-.7*cr,0,0],knR:[1.1*cr,0,0]}};}},
 work:{label:'Watches it drain',len:6,f:t=>{const tick=Math.floor(t)%2;const tilt=snap(t,1.5,[.15,-.12,.08,-.1]);return{hx:.55,hz:tilt,eye:.75+.1*tick,b:{chest:[.12,0,0],shL:[-.35,0,.1],shR:[-.35,0,-.1]}};}},
 nap:{label:'Nap',len:5,f:t=>{const b=Math.sin(t*TAU/5)*.5+.5;return{y:-.05,sq:-.05+b*.03,hx:.5,hz:.2,hy:.6,eye:.04,b:{chest:[.2+b*.03,0,0],thL:[-.6,0,0],knL:[.9,0,0],thR:[-.6,0,0],knR:[.9,0,0],shL:[0,0,.05],shR:[0,0,-.05]}};}},
 celebrate:{label:'Celebrate',len:2,f:t=>{const u=cyc(t,2);const flap=Math.sin(u*TAU*4)*bump(u,0,.7);const hop=bump(u,.05,.55);return{y:hop*.16,sq:hop*.05,hx:-.2*hop,eye:hop>.5?.3:1,heal:bump(u,.3,.8)*.5,b:{shL:[-.2,0,-1.3*hop-.4*flap],shR:[-.2,0,1.3*hop+.4*flap],thL:[-.4*hop,0,0],knL:[.6*hop,0,0],thR:[-.4*hop,0,0],knR:[.6*hop,0,0]}};}}}});
export const EXPR={
 fussy:{label:'Fussy',hx:.1,hz:.18,eye:.6,b:{shL:[0,0,.15],shR:[0,0,-.15],chest:[.05,0,0]}},
 focus:{label:'Precise',hx:.15,eye:.78,eyeW:1.02,b:{chest:[.08,0,0]}},
 startled:{label:'Startled',hx:-.15,eye:1.25,eyeW:1.12,b:{shL:[0,0,-.9],shR:[0,0,.9]}},
 caught:{label:'Caught',hx:.35,hz:.15,eye:.45,b:{chest:[.25,0,0],shL:[.1,0,.1],shR:[.1,0,-.1]}}};
export const build=o=>S.build(o),loadBaked=(u,r)=>S.loadBaked(u,r);
export const BIN='hourkeeper.bin?v=1',RES=.0066,GAME_SCALE=1.1;
export const EMBERS=[['earL',[-.15,.87,.02]],['earR',[.15,.87,.02]],['chest',[0,.33,.2]]];
export const ROUTE=[{to:[1.2,-.4],clip:'walk',sp:.2},{at:true,clip:'work',dur:6,face:[2,-1]},{to:[-.8,1],clip:'walk',sp:.2},{at:true,clip:'ability',dur:2.6,face:[1,3]},{at:true,clip:'idle',dur:8,face:[1,3]},{to:[.2,.2],clip:'carry',sp:.18},{at:true,clip:'nap',dur:5,face:[2,2]}];
export const HERO={cam:[1.05,.95,2.15],target:[0,.44,0],clip:'idle'};
