import * as THREE from 'three';
import {makeMoth} from './moth-base.js';
// Ash moths (Emberreach): charcoal fuzz, ember-rimmed wings, sparks where they fly
const M=makeMoth({name:'ashmoth',col:{fuzz:0x3A3436,fuzzL:0x5A5256,fuzzD:0x141012,belly:0x6A5E5A,leg:0x1E1A1C,ant:0x2A2224},wing:['#4A4044','#2A2426','#18141A'],edge:'rgba(255,120,40,.85)',vein:'rgba(255,140,60,.25)',wingSheen:0xFF9A5A,irid:.1,rim:0xFF7A3A,sheen:0x5A4A48,
 spots(x,fore){for(let k=0;k<5;k++){x.fillStyle='rgba(255,'+(110+k*20)+',40,.9)';x.beginPath();x.arc(60+k*34,fore?70+k*8:130+k*10,5+k%2*3,0,6.3);x.fill();}},
 paint(x,y,z,nx,ny,nz,ao,c,A,K){},
 acc(A,G,P,COL){const{glowTex}=P;const f=new THREE.Group();f.userData.bone='hips';f.userData.spin=1.2;f.userData.spinAx='y';f.position.set(0,.27,-.1);G.add(f);const m=new THREE.SpriteMaterial({map:glowTex('rgba(255,140,50,.95)'),transparent:true,depthWrite:false,blending:THREE.AdditiveBlending});for(let k=0;k<6;k++){const s=new THREE.Sprite(m);s.position.set(Math.sin(k*2.3)*.05,-.02-k*.012,-.02-k*.018);s.scale.setScalar(.022-k*.002);f.add(s);}},
 moteCss:'rgba(255,150,60,.95)',abilityLabel:'Ember shower',workLabel:'Ride the vent heat'});
export const S=M.S,makeRig=M.makeRig,skinGeo=M.skinGeo,CLIPS=M.CLIPS,EXPR=M.EXPR,build=M.build,loadBaked=M.loadBaked;
export const BIN='ashmoth.bin?v=1',RES=.0036,GAME_SCALE=1.6;
export const EMBERS=[['earL',[-.1,.43,.04]],['earR',[.1,.43,.04]],['tail',[0,.27,-.14]]];
export const ROUTE=[{to:[1.1,-.4],clip:'walk',sp:.3},{at:true,clip:'work',dur:4,face:[2,-1]},{to:[-.7,1],clip:'walk',sp:.3},{at:true,clip:'ability',dur:2.4,face:[1,3]},{at:true,clip:'idle',dur:3,face:[1,3]},{to:[.2,.2],clip:'run',sp:.4},{at:true,clip:'nap',dur:5,face:[2,2]}];
export const HERO={cam:[.52,.8,.78],target:[0,.3,-.03],clip:'idle'};
