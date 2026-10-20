import * as THREE from 'three';
import {makePuffball} from './puffball-base.js';

const M=makePuffball({name:'puffballflock',ribbon:0x5CC46A,rim:0xE8FFE0});
export const S=M.S,makeRig=M.makeRig,skinGeo=M.skinGeo,CLIPS=M.CLIPS,EXPR=M.EXPR,build=M.build,loadBaked=M.loadBaked;
export const BIN='puffballflock.bin?v=1',RES=0.0048,GAME_SCALE=1.25;
export const EMBERS=[['earL',[-.08,.25,.16]],['earR',[.08,.25,.16]],['tail',[0,.27,-.17]]];
export const ROUTE=[{to:[1.1,-.4],clip:'walk',sp:.2},{at:true,clip:'work',dur:4,face:[2,-1]},{to:[-.7,1],clip:'walk',sp:.22},{at:true,clip:'ability',dur:2,face:[1,3]},{at:true,clip:'idle2',dur:3.4,face:[1,3]},{to:[.2,.2],clip:'run',sp:.34},{at:true,clip:'nap',dur:4.6,face:[2,2]}];
export const HERO={cam:[.95,.42,1.2],target:[0,.19,0],clip:'idle'};
