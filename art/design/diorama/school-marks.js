(function(){
const SC={Motion:['#FFE6A0','#F2B43C','#A8640E'],Matter:['#D8CCFF','#8C6CF0','#4A2FA0'],Time:['#C8F6FC','#3CC6D8','#167486'],Energy:['#FFD0B0','#F07A3C','#A0401A'],Life:['#CFF5C8','#5CC46A','#25763A'],Spirit:['#FFC8EC','#E05CB4','#922A74']};
const C=(x,y,r)=>'M'+(x-r)+' '+y+'a'+r+' '+r+' 0 1 0 '+(2*r)+' 0a'+r+' '+r+' 0 1 0 '+(-2*r)+' 0z';
const E=(x,y,rx,ry)=>'M'+(x-rx)+' '+y+'a'+rx+' '+ry+' 0 1 0 '+(2*rx)+' 0a'+rx+' '+ry+' 0 1 0 '+(-2*rx)+' 0z';
const HX=(x,y,r)=>{const h=r*.866;return 'M'+x+' '+(y-r)+'L'+(x+h)+' '+(y-r/2)+'L'+(x+h)+' '+(y+r/2)+'L'+x+' '+(y+r)+'L'+(x-h)+' '+(y+r/2)+'L'+(x-h)+' '+(y-r/2)+'z';};
const petals=()=>{let d='';for(let i=0;i<5;i++){const a=-Math.PI/2+i*Math.PI*2/5;d+=C(+(24+Math.cos(a)*9).toFixed(1),+(22+Math.sin(a)*9).toFixed(1),6.5);}return d;};
// kinds: m cream, a school, d ink, o outline stroke, w thick school stroke, h highlight
const G={
 bounce:['Motion',[['d',E(24,42,10,2.6)],['o','M8 40q4-18 12-24'],['a',C(27,17,9)],['h','M22 13.5q2-3 5-3.4']]],
 halfgravity:['Motion',[['d',E(24,43,11,2.4)],['m','M10 32l6-10 13-2 9 8-4 10-17 2z'],['a','M17 13l7-7 7 7-3.2 3.2L24 12.4l-3.8 3.8z'],['h','M15 30l3.6-6']]],
 frictionless:['Motion',[['m','M3 38h42v6H3z'],['a','M21 24h19a3.5 3.5 0 0 1 3.5 3.5v5a3.5 3.5 0 0 1-3.5 3.5H21a3.5 3.5 0 0 1-3.5-3.5v-5A3.5 3.5 0 0 1 21 24z'],['o','M3 25h10M6 31h9M3 19h8'],['h','M23 28h14']]],
 inwardpull:['Motion',[['m','M24 16l-6.5-10h13z'],['m','M24 32l-6.5 10h13z'],['m','M16 24l-10-6.5v13z'],['m','M32 24l10-6.5v13z'],['a',C(24,24,6)]]],
 current:['Motion',[['w','M4 17h26a5 5 0 1 0-5-5'],['w','M4 27h34a5 5 0 1 1-5 5'],['w','M4 37h16']]],
 brittlestone:['Matter',[['m','M8 12h32v26H8z'],['o','M8 25h12M28 25h12M18 12v13M30 25v13'],['o','M23 12l4 8-5 6 4 12'],['a','M38 41l5 1.6-2 4.4-4.6-1.8z'],['a','M5 41l3.6-1.4 1.4 3.6-3.6 1.4z']]],
 glass:['Matter',[['a','M10 5h28v38H10z'],['o','M24 5v38'],['h','M14 15l7-6M14 24l8-7M28 34l6-5']]],
 honeycomb:['Matter',[['a',HX(16.5,17,8.5)],['m',HX(31.5,17,8.5)],['a',HX(24,30,8.5)]]],
 density:['Matter',[['o','M18 18v-4a6 6 0 0 1 12 0v4'],['a','M14 18h20l7 24H7z'],['m','M17 28h14v6H17z'],['h','M13 36l3-12']]],
 haste:['Time',[['a','M22.5 6h7v5h-7z'],['m',C(26,27,14)],['o','M26 27l5-7M26 18v2'],['o','M3 22h7M2 28h6M4 34h6']]],
 slowrivers:['Time',[['w','M5 15q6.5-6 13 0t13 0t13 0'],['w','M5 25q6.5-6 13 0t13 0t13 0'],['w','M5 35q6.5-6 13 0t13 0t13 0']]],
 delay:['Time',[['m','M14 8h20v3q0 8-7 13 7 5 7 13v3H14v-3q0-8 7-13-7-5-7-13z'],['a','M18.5 37q5.5-6 11 0v3h-11z'],['a','M19 12h10q-2 5-5 7-3-2-5-7z'],['d','M11 4h26v4.5H11zM11 39.5h26V44H11z']]],
 stillness:['Time',[['a',C(24,24,17)],['m','M17 15h5v18h-5zM26 15h5v18h-5z'],['h','M12 18q2-5 7-7.5']]],
 dayandnight:['Time',[['a','M24 7a17 17 0 0 0 0 34z'],['d','M24 7a17 17 0 0 1 0 34z'],['m','M30 17a5 5 0 1 0 4 8 6 6 0 0 1-4-8z']]],
 tidemark:['Time',[['w','M4 34q6.5-6 13 0t13 0t13 0'],['o','M30 6v24'],['m','M30 6h12l-4 5 4 5H30z']]],
 glowingdark:['Energy',[['m','M31 7a17 17 0 1 0 0 34 13 13 0 0 1 0-34z'],['a',C(37,13,3.2)],['a',C(41,25,2.4)],['a',C(35,36,2.8)]]],
 static:['Energy',[['a','M28 3L11 27h11l-4 18 19-26H26z'],['o','M7 11l4 3M39 34l4 3M41 9l-4 3']]],
 aurora:['Energy',[['w','M4 30q10-20 20-8t20-10'],['w','M4 40q10-14 20-6t20-8'],['m','M11 7l1.6 3.4 3.4 1.6-3.4 1.6L11 17l-1.6-3.4L6 12l3.4-1.6z']]],
 chainlightning:['Energy',[['w','M10 11l13 6-4 4 18 3'],['w','M36 28l-11 5 4 3-15 5'],['m',C(9,10,4.5)],['m',C(38,25,4.5)],['m',C(12,41,4.5)]]],
 kinship:['Life',[['o','M24 40v5'],['a','M24 40Q5 35 7 11q17 2 17 29z'],['m','M24 40q19-5 17-29-17 2-17 29z']]],
 thorns:['Life',[['w','M6 42q12-4 16-17t21-18'],['m','M14 37l-4-7 7 2z'],['m','M23 25l1-8 4 6z'],['m','M33 13l-1-7 5 4z'],['m','M27 31l7-1-4 6z']]],
 regrowth:['Life',[['m','M13 33h22l-3 11H16z'],['o','M24 33V19'],['a','M24 22Q13 22 11 11q11 0 13 11z'],['a','M24 26q11 0 13-11-11 0-13 11z']]],
 bloom:['Life',[['o','M24 31v13'],['a',petals()],['m',C(24,22,5.5)]]],
 whispers:['Spirit',[['m','M8 9h25a4 4 0 0 1 4 4v14a4 4 0 0 1-4 4H20l-8 8v-8H8a4 4 0 0 1-4-4V13a4 4 0 0 1 4-4z'],['a',C(13,20,2.4)+C(20.5,20,2.4)+C(28,20,2.4)],['o','M41 13q4 7 0 14']]],
 echoes:['Spirit',[['a',C(11,24,6)],['w','M21 15q7 9 0 18'],['w','M28 9q11 15 0 30'],['w','M35 4q15 20 0 40']]],
 sleepwalk:['Spirit',[['m','M3 24q21-15 42 0-21 15-42 0z'],['o','M6 24q18 10 36 0'],['o','M14 30l-2 4.5M24 33v5M34 30l2 4.5'],['w','M31 4h9l-9 8h9']]],
 soulswap:['Spirit',[['w','M11 21a13 13 0 0 1 24-6'],['a','M39 9v11l-10-3.4z'],['w','M37 27a13 13 0 0 1-24 6'],['a','M9 39V28l10 3.4z'],['m',C(24,24,4)]]]
};

const RS={
 mangrove:['Time','Life',[['b',E(24,14,16,9)],['h','M14 10q4-4 10-4'],['m','M21 20h6v7l8 11h-5l-5-7-1 8h-4l-1-8-5 7h-5l8-11z'],['x','M3 43q5-4 10 0t10 0t10 0t10 0']]],
 drifting:['Motion','Spirit',[['m','M27 24h11v20H27z'],['o','M27 34h11M32 24v10'],['a',C(10,38,5)],['x','M14 30Q16 10 40 9'],['x','M18 36Q22 20 42 18']]],
 vigil:['Time','Spirit',[['a',C(24,14,10)],['m','M19.5 9h3.5v10h-3.5zM25 9h3.5v10H25z'],['b','M3 35q21-13 42 0-21 13-42 0z'],['o','M8 35q16 7 32 0M15 39l-2 4M24 41v4M33 39l2 4']]],
 glasstide:['Matter','Time',[['a','M11 4h26v40H11z'],['o','M24 4v16'],['h','M15 13l6-5M15 20l7-6'],['x','M3 31q5.25-5 10.5 0t10.5 0t10.5 0t10.5 0'],['x','M3 40q5.25-5 10.5 0t10.5 0t10.5 0t10.5 0']]],
 staticbloom:['Energy','Life',[['o','M24 31v13'],['b',petals()],['a','M27 13l-7 9h5l-3 8 8-10h-5z']]],
 frozenfall:['Motion','Time',[['d',E(24,44,10,2.2)],['o','M24 33v5M17 31l-3 4M31 31l3 4'],['a',C(24,18,12)],['m','M19 12h4v12h-4zM25 12h4v12h-4z'],['h','M15 13q2-4 6-5']]],
 whisperchain:['Spirit','Spirit',[['b','M20 4h20a4 4 0 0 1 4 4v10a4 4 0 0 1-4 4h-3v5l-5-5H20a4 4 0 0 1-4-4V8a4 4 0 0 1 4-4z'],['m','M8 18h22a4 4 0 0 1 4 4v12a4 4 0 0 1-4 4H18l-7 7v-7H8a4 4 0 0 1-4-4V22a4 4 0 0 1 4-4z'],['a',C(12,28,2.3)+C(19,28,2.3)+C(26,28,2.3)]]],
 slipstream:['Motion','Time',[['o','M2 18h5M1 24h5M2 30h5'],['a','M9 12l13 12-13 12h8l13-12-13-12z'],['b','M23 12l13 12-13 12h8l13-12-13-12z']]],
 emberdark:['Energy','Energy',[['d',C(22,24,19)],['m','M30 9a15 15 0 1 0 0 30 11 11 0 0 1 0-30z'],['a','M32 14l-6 10h5l-3 10 9-12h-5z'],['h','M10 18q2-5 6-7']]],
 rootedkin:['Life','Life',[['a','M14 22Q4 20 3 8q12 1 11 14z'],['b','M34 22q10-2 11-14-12 1-11 14z'],['o','M14 22v6q0 6 10 6t10-6v-6M24 34v10M24 39l-6 5M24 39l6 5']]],
 hollowstone:['Matter','Motion',[['a',HX(24,24,19)],['o','M10 13l6 5M38 35l-6-5M33 7l-3 6'],['d',C(24,24,9)],['x','M24 24a3 3 0 1 1 3 3 6 6 0 1 1-6-6']]],
 soultide:['Spirit','Time',[['w','M10 20a14 14 0 0 1 25-7'],['a','M39 6v12l-10-4z'],['m',C(24,24,4)],['x','M3 36q5.25-5 10.5 0t10.5 0t10.5 0t10.5 0'],['x','M3 44q5.25-5 10.5 0t10.5 0t10.5 0t10.5 0']]]
};
const norm=n=>String(n||'').toLowerCase().replace(/[^a-z]/g,'');
const cache={};
const ink='#120C2A';
function svg(id,sil){const g=G[id];if(!g)return null;return draw(SC[g[0]],SC[g[0]],g[1],sil);}
function draw(c,c2,parts,sil){let b='';
 const sf='#0E0824',so='rgba(178,160,236,.6)';
 parts.forEach(([k,d])=>{
  if(sil){if(k==='h')return;if(k==='o')b+='<path d="'+d+'" fill="none" stroke="'+so+'" stroke-width="2" stroke-linecap="round" stroke-linejoin="round"/>';else if(k==='w')b+='<path d="'+d+'" fill="none" stroke="'+sf+'" stroke-width="6" stroke-linecap="round" stroke-linejoin="round"/><path d="'+d+'" fill="none" stroke="'+so+'" stroke-width="1.4" stroke-linecap="round" stroke-linejoin="round" opacity=".7"/>';else if(k==='x')b+='<path d="'+d+'" fill="none" stroke="'+sf+'" stroke-width="6" stroke-linecap="round" stroke-linejoin="round"/><path d="'+d+'" fill="none" stroke="'+so+'" stroke-width="1.4" stroke-linecap="round" stroke-linejoin="round" opacity=".7"/>';else b+='<path d="'+d+'" fill="'+sf+'" stroke="'+so+'" stroke-width="1.8" stroke-linejoin="round"/>';return;}
  if(k==='o')b+='<path d="'+d+'" fill="none" stroke="'+ink+'" stroke-width="2.4" stroke-linecap="round" stroke-linejoin="round"/>';
  else if(k==='h')b+='<path d="'+d+'" fill="none" stroke="#fff" stroke-opacity=".75" stroke-width="1.8" stroke-linecap="round"/>';
  else if(k==='w'||k==='x')b+='<path d="'+d+'" fill="none" stroke="'+ink+'" stroke-width="6.4" stroke-linecap="round" stroke-linejoin="round"/><path d="'+d+'" fill="none" stroke="url(#'+(k==='x'?'b':'a')+')" stroke-width="3.4" stroke-linecap="round" stroke-linejoin="round"/><path d="'+d+'" fill="none" stroke="#fff" stroke-opacity=".45" stroke-width="1" stroke-linecap="round" stroke-linejoin="round" transform="translate(-.6 -.8)"/>';
  else b+='<path d="'+d+'" fill="'+(k==='m'?'url(#m)':k==='a'?'url(#a)':k==='b'?'url(#b)':'#2A1A48')+'" stroke="'+ink+'" stroke-width="2.2" stroke-linejoin="round" stroke-linecap="round"/>';});
 return '<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 48 48"><defs><linearGradient id="m" x1="0" y1="0" x2="0" y2="1"><stop offset="0" stop-color="#FFFDF4"/><stop offset="1" stop-color="#E4CC9A"/></linearGradient><linearGradient id="a" x1="0" y1="0" x2=".6" y2="1"><stop offset="0" stop-color="'+c[0]+'"/><stop offset=".5" stop-color="'+c[1]+'"/><stop offset="1" stop-color="'+c[2]+'"/></linearGradient><linearGradient id="b" x1="0" y1="0" x2=".6" y2="1"><stop offset="0" stop-color="'+c2[0]+'"/><stop offset=".5" stop-color="'+c2[1]+'"/><stop offset="1" stop-color="'+c2[2]+'"/></linearGradient></defs>'+b+'</svg>';}
function url(n,sil){const id=norm(n);const k=id+(sil?'_s':'');if(k in cache)return cache[k];const s=svg(id,sil);return cache[k]=s?'data:image/svg+xml,'+encodeURIComponent(s):null;}
const FR={Common:{mat:'Oak',ink:'#8A5428',bg:'repeating-linear-gradient(96deg,rgba(50,24,8,.2) 0 2px,transparent 2px 7px),linear-gradient(160deg,#C89058 0%,#8A5630 45%,#AE7442 70%,#6A3E1E 100%)'},Uncommon:{mat:'Silver',ink:'#4E5A6E',bg:'linear-gradient(135deg,#FAFCFF 0%,#B4BECE 28%,#EEF2F7 48%,#86919F 72%,#DCE2EA 100%)'},Rare:{mat:'Gold',ink:'#94600E',bg:'linear-gradient(135deg,#FFF6CF 0%,#E9B65C 28%,#FFE8A0 48%,#AE6E16 72%,#F2C45C 100%)'},Deep:{mat:'Prismatic',ink:'#A8327E',bg:'conic-gradient(from 200deg,#FF8AD0,#FFD27A,#8AF0C8,#7AC4FF,#C29AFF,#FF8AD0)'}};
const rcache={};function rurl(id,sil){const k=id+(sil?'_s':'');if(k in rcache)return rcache[k];const g=RS[id];if(!g)return null;return rcache[k]='data:image/svg+xml,'+encodeURIComponent(draw(SC[g[0]],SC[g[1]],g[2],sil));}
window.RBLaw={url,res:rurl,school:n=>(G[norm(n)]||[])[0],frame:r=>FR[r]||FR.Common,ids:Object.keys(G)};
const wrap=()=>{if(!window.RBI||window.RBI.__law)return!!window.RBI;const o=window.RBI;const w=(g,n)=>norm(g)==='laws'&&G[norm(n)]?url(n):o(g,n);Object.assign(w,o);w.__law=1;window.RBI=w;return true;};
if(!wrap()){const t=setInterval(()=>{if(wrap())clearInterval(t);},50);setTimeout(()=>clearInterval(t),8000);}
})();
