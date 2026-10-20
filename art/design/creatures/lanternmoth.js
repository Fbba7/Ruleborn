import * as THREE from 'three';
import {makeMoth} from './moth-base.js';
// Lantern moths (The Heart): cream and gold, a glowing lantern tail
const M=makeMoth({name:'lanternmoth',col:{leg:0xC8A060,ant:0x8A5A2A},glowTail:true,wing:['#FFF4D0','#F8CC66','#D08A3A'],edge:'rgba(110,60,20,.7)',vein:'rgba(110,60,20,.35)',wingSheen:0xFFE8B0,irid:.2,rim:0xFFE6B0,
 spots(x,fore){x.fillStyle='rgba(255,236,170,.95)';x.beginPath();x.arc(fore?120:140,fore?100:150,fore?26:22,0,6.3);x.fill();x.fillStyle='rgba(150,90,30,.9)';x.beginPath();x.arc(fore?120:140,fore?100:150,fore?12:10,0,6.3);x.fill();x.fillStyle='#FFF';x.beginPath();x.arc(fore?116:136,fore?96:146,4,0,6.3);x.fill();},
 abilityLabel:'Lantern flare',workLabel:'Circle the Spire lamp'});
export const S=M.S,makeRig=M.makeRig,skinGeo=M.skinGeo,CLIPS=M.CLIPS,EXPR=M.EXPR,build=M.build,loadBaked=M.loadBaked;
export const BIN='lanternmoth.bin?v=1',RES=.0036,GAME_SCALE=1.6;
export const EMBERS=[['earL',[-.1,.43,.04]],['earR',[.1,.43,.04]],['tail',[0,.27,-.14]]];
export const ROUTE=[{to:[1.1,-.4],clip:'walk',sp:.3},{at:true,clip:'work',dur:4,face:[2,-1]},{to:[-.7,1],clip:'walk',sp:.3},{at:true,clip:'ability',dur:2.4,face:[1,3]},{at:true,clip:'idle',dur:3,face:[1,3]},{to:[.2,.2],clip:'run',sp:.4},{at:true,clip:'nap',dur:5,face:[2,2]}];
export const HERO={cam:[.52,.8,.78],target:[0,.3,-.03],clip:'idle'};
