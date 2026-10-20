import * as THREE from 'three';
import {makeMoth} from './moth-base.js';
// Fireflies and moths (Lantern Vale): an indigo moth with glowing blue eye-spots, escorted by fireflies
const M=makeMoth({name:'valemoth',eye:['#04040A','#1A2A5A','#4A7AC8','#06060C'],col:{fuzz:0x6A6AB8,fuzzL:0xA8B0E8,fuzzD:0x2A2A5A,belly:0xC8D4FF,leg:0x2A2A48,ant:0x4A4A80},wing:['#8A90E0','#4A4AA0','#262660'],edge:'rgba(160,200,255,.55)',vein:'rgba(200,220,255,.25)',wingSheen:0xB8D8FF,irid:.6,rim:0x9FD4FF,sheen:0xD0E0FF,
 spots(x,fore){const g=x.createRadialGradient(fore?120:140,fore?100:150,0,fore?120:140,fore?100:150,fore?30:24);g.addColorStop(0,'rgba(200,255,255,1)');g.addColorStop(.5,'rgba(120,220,255,.9)');g.addColorStop(1,'rgba(120,220,255,0)');x.fillStyle=g;x.beginPath();x.arc(fore?120:140,fore?100:150,fore?30:24,0,6.3);x.fill();},
 acc(A,G,P,COL){const{PB,add,glowTex}=P;const m=new THREE.SpriteMaterial({map:glowTex('rgba(230,255,140,.95)'),transparent:true,depthWrite:false,blending:THREE.AdditiveBlending});
  for(let k=0;k<4;k++){const o=new THREE.Group();o.userData.bone='root';o.userData.spin=(k%2?-1:1)*(.7+k*.25);o.userData.spinAx='y';o.rotation.y=k*1.6;G.add(o);const b=new THREE.Group();b.position.set(.16+k*.035,.3+(k%3-1)*.05,0);o.add(b);
   add(new THREE.SphereGeometry(.007,10,8),PB(0x3A3020,{roughness:.6}),[0,0,.006],null,[1,1,1.3],b);const tl=add(new THREE.SphereGeometry(.007,10,8),PB(0xE8FF8A,{emissive:0xC8FF5A,emissiveIntensity:1.4}),[0,0,-.006],null,[1,1,1.2],b);
   const s=new THREE.Sprite(m.clone());s.position.set(0,0,-.006);s.scale.setScalar(.06);b.add(s);b.userData.spin=[3+k,.3];b.userData.spinAx='x';}},
 moteCss:'rgba(160,230,255,.95)',abilityLabel:'Eye-spot flash',workLabel:'Dance with the fireflies'});
export const S=M.S,makeRig=M.makeRig,skinGeo=M.skinGeo,CLIPS=M.CLIPS,EXPR=M.EXPR,build=M.build,loadBaked=M.loadBaked;
export const BIN='valemoth.bin?v=1',RES=.0036,GAME_SCALE=1.6;
export const EMBERS=[['earL',[-.1,.43,.04]],['earR',[.1,.43,.04]],['tail',[0,.27,-.14]]];
export const ROUTE=[{to:[1.1,-.4],clip:'walk',sp:.3},{at:true,clip:'work',dur:4,face:[2,-1]},{to:[-.7,1],clip:'walk',sp:.3},{at:true,clip:'ability',dur:2.4,face:[1,3]},{at:true,clip:'idle',dur:3,face:[1,3]},{to:[.2,.2],clip:'run',sp:.4},{at:true,clip:'nap',dur:5,face:[2,2]}];
export const HERO={cam:[.52,.8,.78],target:[0,.3,-.03],clip:'idle'};
