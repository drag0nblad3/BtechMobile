function rebuild(lib,source,v){
const s=lib.clone(source),{L,B,cyl,loft,ellipse}=lib,P=n=>s.parts.find(p=>p.name===n),Y=(r,m="plate")=>L("y",r,m),Z=(r,m="plate")=>L("z",r,m),X=(r,m="plate")=>L("x",r,m),set=(n,sh)=>P(n).shapes=sh;
const pair=fn=>[-1,1].forEach(k=>fn(k,k<0?"l":"r")),box=(y,x,r,z,d,ch=.15)=>[y,x-r,x+r,z-d,z+d,ch];
if(s.id==="nova"){
const w=v===1?9:11;
set("ct",[Y([[25,-5,5,-3,4,.10],[28,-w*.8,w*.8,-6,6,.16],[32,-w,w,-6,7,.12],[37,-w,w,-6,7,.18],[39,-w*.85,w*.85,-5,6,.18]],"armor")]);
set("hd",[Z([[-17,-2.7,2.7,25,29,.25],[-14,-4.4,4.4,26,33,.20],[-10,-5,5,29,35,.25],[-5,-4.5,4.5,31,36,.20]],"plate"),B([-2.8,30,-14],[2.8,33,-11],"glass","paint")]);
pair((k,q)=>{let x=k*15,t=k*10;
set(q+"t",[X([[Math.min(k*9,k*13),30,36,-4,4,.12],[Math.max(k*9,k*13),30,36,-4,4,.12]],"frame")]);
set(q+"a",[loft("x",[[x-2.6,ellipse(33,0,4.5,4.5,20)],[x+2.6,ellipse(33,0,4.5,4.5,20)]],"plate"),Y([box(25,x,2.2,0,2.2),box(29,x,2.7,0,2.7),box(33,x,2.7,0,2.7)],"frame")]);
set(q+"a_forearm",[Y([box(20,x,3,0,3.3),box(23,x,3.6,0,3.4),box(25,x,2.2,0,2.2)],"plate")]);
let pts=Array.from({length:6},(_,i)=>[x+(i%3-1)*2.2,21+(Math.floor(i/3)-.5)*2.6,-13]);
set(q+"a_weapon",[Z([[-8,x-4,x+4,17,25,.19],[-2,x-3,x+3,18,24,.16]],"plate"),...pts.flatMap(([a,b,c])=>[cyl("z",c,-5,a,b,1.1,1.1),cyl("z",c,c+3,a,b,.6,.6,"gun","subtract")])]);s.muzzles[q.toUpperCase()+"A"]=pts;
let lx=k*9;set(q+"l_shin",[Y([box(8,lx,2.1,0,2.5),box(10,lx,2.9,2,3),box(12,k*8,3,6,3)],"plate")]);
set(q+"l_foot",[Y([[0,lx-4,lx+4,-7,4,.28],[2,lx-4,lx+4,-6,4,.24],box(4,lx,2.7,-1,2.7)],"plate"),B([lx-1.3,0,-9],[lx+1.3,2,-5],"plate")]);
});
}else if(s.id==="fire_moth"){
let w=v===1?5:6;
set("ct",[Y([[29,-4,4,-3,4,.1],[32,-w,w,-5,5,.18],[35,-w,w,-5,5,.20],[38,-w*.84,w*.84,-3,5,.16]],"armor")]);
set("hd",[Z([[-13,-2.5,2.5,28,31,.23],[-10,-3.4,3.4,28,35,.20],[-7,-3.5,3.5,31,38,.20],[-2,-3,3,33,38,.15]],"plate"),B([-2.2,33,-10],[2.2,36,-7],"glass","paint")]);
pair((k,q)=>{let x=k*11;
set(q+"t",[X([[Math.min(k*5,k*9),31,36,-3,4,.12],[Math.max(k*5,k*9),31,39,-3,4,.12]],"plate")]);
set(q+"a",[Y([box(35,k*9,2.1,0,2.3),box(38,k*10,2.5,0,2.7),box(41,x,2.4,0,2.6)],"frame")]);
set(q+"a_forearm",[Z([[-8,x-2.4,x+2.4,37,42,.14],[-3,x-2.7,x+2.7,37,42,.17],[1,x-2.3,x+2.3,37,42,.14]],"plate")]);
let pts=q==="l"?Array.from({length:6},(_,i)=>[x+(i%2-.5)*1.9,41+(Math.floor(i/2)-1)*1.9,-13]):[[x-1.4,41,-16],[x+1.4,41,-16]];
let sh=q==="l"?[Z([[-13,x-3.2,x+3.2,37,45,.22],[-8,x-3.2,x+3.2,37,45,.16]],"plate")]:[Z([[-10,x-3,x+3,38,44,.16],[-6,x-2.5,x+2.5,38,43,.14]],"plate"),...pts.map(([a,b,z])=>cyl("z",z,-7,a,b,1.5,1.5))];set(q+"a_weapon",[...sh,...pts.map(([a,b,z])=>cyl("z",z,z+3,a,b,.7,.7,"gun","subtract"))]);s.muzzles[q.toUpperCase()+"A"]=pts;
let lx=k*6;set(q+"l_shin",[Y([box(4,lx,1.9,0,2.1),box(8,lx,2.4,-.5,2.6),box(11,k*5,2,0,2.3),box(15,k*5,2.3,0,2.3)],"plate")]);
set(q+"l_foot",[Y([[0,lx-2.8,lx+2.8,-5,3,.26],[2,lx-2.6,lx+2.6,-4,3,.22],box(4,lx,1.9,0,2.1)],"plate"),B([lx-1,0,-8],[lx+1,2,-4],"plate")]);
});
}else{
let w=v===1?8:9;
set("ct",[Y([[26,-5,5,-3,4,.1],[29,-w,w,-6,6,.23],[34,-w,w,-7,8,.2],[38,-w*.85,w*.85,-6,7,.18],[40,-w*.65,w*.65,-4,6,.19]],"armor")]);
set("hd",[loft("z",[[-20,ellipse(0,31,2.9,2.7,20)],[-17,ellipse(0,31,5,5.1,20)],[-12,ellipse(0,32,6.2,6,20)],[-6,ellipse(0,32,5.8,6,20)]],"plate"),B([-2.7,32,-19],[2.7,35,-16],"glass","paint")]);
pair((k,q)=>{let x=k*14,rx=k*10.5;
set(q+"t",[X([[Math.min(k*7,k*12),31,37,-4,4,.12],[Math.max(k*7,k*12),31,37,-4,4,.12]],"frame")]);
let pts=Array.from({length:20},(_,i)=>[rx+(i%4-1.5)*1.8,43+(Math.floor(i/4)-2)*1.8,-8]);
set(q+"t_rack",[B([rx-2,34,-2],[rx+2,40,3],"frame"),Z([[-8,rx-4.5,rx+4.5,37.5,48.5,.13],[4,rx-4.5,rx+4.5,37.5,48.5,.13],[7,rx-4,rx+4,38,48,.16]],"plate"),...pts.map(([a,b,z])=>cyl("z",z,z+3,a,b,.7,.7,"gun","subtract"))]);s.muzzles[q.toUpperCase()+"T"]=pts;
set(q+"a",[Y([box(26,x,2.2,0,2.1),box(29,k*13,2.5,0,2.6),box(34,k*12,2.9,0,3.2),box(36,k*12,2.5,0,2.8)],"frame")]);
set(q+"a_forearm",[Y([box(20,x,3.3,0,3.3),box(23,x,3.8,0,3.6),box(26,x,2.2,0,2.1)],"plate")]);
let ap=[[x,24,-15],[x,20.5,-13]];
set(q+"a_weapon",[Z([[-10,x-3.4,x+3.4,18,26,.18],[-2,x-3.4,x+3.4,18,26,.18]],"plate"),...ap.flatMap(([a,b,z])=>[cyl("z",z,-7,a,b,1.6,1.6),cyl("z",z,z+3,a,b,.85,.85,"gun","subtract")])]);s.muzzles[q.toUpperCase()+"A"]=ap;
let lx=k*10;set(q+"l_shin",[loft("y",[[8,ellipse(lx,0,2.4,3,16)],[10,ellipse(lx,1,3.7,4,16)],[12,ellipse(k*9,4,3.5,3.6,16)],[13,ellipse(k*9,6,3,3,16)]],"plate")]);
set(q+"l_foot",[Y([[0,lx-4.4,lx+4.4,-6,4,.24],[2,lx-4,lx+4,-5,4,.22],box(4,lx,2.6,-1,2.8)],"plate"),B([lx-3.7,0,-8],[lx-1.4,2,-4],"plate"),B([lx+1.4,0,-8],[lx+3.7,2,-4],"plate")]);
});
}
return s;
}
;rebuild