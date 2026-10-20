import * as THREE from 'three';
import {makePuffball} from './puffball-base.js';

const M=makePuffball({name:'puffbee',col:{wool:0xF4E6C8,woolL:0xFFF8E6,woolD:0xB89A74,face:0x4A3A30,faceL:0x6E5646},ribbon:0xF2B43C,ring:0xFFE08A,rim:0xFFE8B0,
 paint(x,y,z,nx,ny,nz,ao,c,A,K){},
 acc(A,G,P,COL){const{PB,add,glowTex}=P;
  // daisies caught in the fleece
  const pet=PB(0xFFFFFF,{roughness:.6,sheen:.5}),mid=PB(0xF2C23A,{roughness:.5});
  for(const [d,up] of[[[.35,.9,.3],0],[[-.6,.7,-.2],1],[[.1,.95,-.5],2],[[-.2,.8,.6],3],[[.8,.4,-.3],1]]){const g=new THREE.Group();P.onSurf?0:0;const dir=new THREE.Vector3(...d).normalize();
   let t=.5;const c=new THREE.Vector3(0,.2,0);for(let i=0;i<200;i++){const p=c.clone().addScaledVector(dir,t);const s=A.sdf(p.x,p.y,p.z);if(s<.001)break;t-=Math.max(s*.8,.001);}
   const p=c.clone().addScaledVector(dir,t+.008);g.position.copy(p);g.lookAt(p.clone().add(dir));g.userData.bone='chest';G.add(g);
   for(let k=0;k<8;k++){const a=k/8*Math.PI*2;add(new THREE.SphereGeometry(.012,10,6),pet,[Math.cos(a)*.018,Math.sin(a)*.018,.004],[0,0,a],[1.6,.7,.35],g);}add(new THREE.SphereGeometry(.009,12,8),mid,[0,0,.008],null,[1,1,.6],g);}
  // two bees on lazy orbits round it
  const bee=(r,y,sp,ph)=>{const o=new THREE.Group();o.userData.bone='root';o.userData.spin=sp;o.userData.spinAx='y';o.rotation.y=ph;G.add(o);const b=new THREE.Group();b.position.set(r,y,0);b.rotation.y=Math.PI;o.add(b);
   const cv=document.createElement('canvas');cv.width=8;cv.height=64;const x=cv.getContext('2d');for(let i=0;i<8;i++){x.fillStyle=i%2?'#2A1A10':'#F2B43C';x.fillRect(0,i*8,8,8);}const tx=new THREE.CanvasTexture(cv);tx.colorSpace=THREE.SRGBColorSpace;
   const bg=new THREE.SphereGeometry(.018,18,12);bg.rotateX(Math.PI/2);add(bg,PB(0xffffff,{map:tx,roughness:.6,sheen:.8}),[0,0,0],null,[1,1,1.35],b);
   add(new THREE.SphereGeometry(.013,14,10),PB(0x2A1A10,{roughness:.5}),[0,.002,.024],null,null,b);
   for(const s of[-1,1]){add(new THREE.SphereGeometry(.004,8,6),PB(0xFFFFFF,{roughness:.2}),[s*.006,.007,.034],null,null,b);
    const w=add(new THREE.SphereGeometry(.016,14,8),new THREE.MeshPhysicalMaterial({color:0xE8F6FF,transparent:true,opacity:.55,roughness:.15,iridescence:1,depthWrite:false}),[s*.016,.02,0],[0,0,s*.6],[1,.2,.6],b);w.castShadow=false;w.userData.spin=[40,.5];w.userData.spinAx='z';}
   add(new THREE.ConeGeometry(.003,.01,6),PB(0x2A1A10),[0,0,-.03],[-Math.PI/2,0,0],null,b);return o;};
  bee(.26,.34,.9,0);bee(.2,.42,-1.2,2.4);}});
export const S=M.S,makeRig=M.makeRig,skinGeo=M.skinGeo,CLIPS=M.CLIPS,EXPR=M.EXPR,build=M.build,loadBaked=M.loadBaked;
export const BIN='puffbee.bin?v=1',RES=0.0048,GAME_SCALE=1.25;
export const EMBERS=[['earL',[-.08,.25,.16]],['earR',[.08,.25,.16]],['tail',[0,.27,-.17]]];
export const ROUTE=[{to:[1.1,-.4],clip:'walk',sp:.2},{at:true,clip:'work',dur:4,face:[2,-1]},{to:[-.7,1],clip:'walk',sp:.22},{at:true,clip:'ability',dur:2,face:[1,3]},{at:true,clip:'idle2',dur:3.4,face:[1,3]},{to:[.2,.2],clip:'run',sp:.34},{at:true,clip:'nap',dur:4.6,face:[2,2]}];
export const HERO={cam:[.95,.42,1.2],target:[0,.19,0],clip:'idle'};
