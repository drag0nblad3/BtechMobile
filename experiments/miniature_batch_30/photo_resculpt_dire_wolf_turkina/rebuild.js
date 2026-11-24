function rebuild(lib,src,v){
const s=lib.clone(src),{L,B,cyl,loft,ellipse}=lib,P=n=>s.parts.find(p=>p.name===n),Y=(r,m="plate")=>L("y",r,m),Z=(r,m="plate")=>L("z",r,m),X=(r,m="plate")=>L("x",r,m),set=(n,shapes)=>P(n).shapes=shapes,part=(name,loc,parent,pivot,shapes)=>s.parts.push({name,loc,parent,pivot,shapes});
if(s.id==="dire_wolf"){
 const w=v===1?13:14;
 set("ct",[Z([[-8,-w+1,w-1,31,40,.16],[-3,-w,w,27,41,.16],[4,-w,w,26,42,.2],[9,-w+1,w-1,27,39,.24],[12,-w+3,w-3,29,36,.25]],"armor"),Y([[26,-5,5,-3,4,.12],[29,-8,8,-3,5,.15]],"frame")]);
 set("hd",[loft("z",[[-16,ellipse(0,32,2.8,3.4,20)],[-13,ellipse(0,32,5.5,5.3,20)],[-8,ellipse(0,33,6,6,20)],[-4,ellipse(0,33,4,4,20)]],"plate"),B([-2.6,33,-15],[2.6,36,-12],"glass","paint")]);
 for(let k of [-1,1]){let q=k<0?"l":"r",x=k*18;
 set(q+"a",[loft("x",[[Math.min(k*14,k*19),ellipse(35,0,4.3,4.5,20)],[Math.max(k*14,k*19),ellipse(35,0,4.3,4.5,20)]],"plate"),Y([[27,x-2,x+2,-2,2,.13],[31,x-2.4,x+2.4,-3,3,.14],[35,x-2.5,x+2.5,-3,3,.15]],"frame")]);
 set(q+"a_forearm",[Y([[21,x-3.7,x+3.7,-3.6,3.6,.15],[25,x-3.8,x+3.8,-3.5,3.5,.18],[27,x-2,x+2,-2,2,.12]],"plate")]);
 let pts=[[x,22,-18],[x-1.8,25,-15],[x+1.8,25,-15]];
 set(q+"a_weapon",[Z([[-12,x-3.8,x+3.8,19,28,.18],[-3,x-3.8,x+3.8,19,28,.18]],"plate"),...pts.flatMap(([a,b,c],i)=>[cyl("z",c,-10,a,b,i?1.25:1.9,i?1.25:1.9),cyl("z",c,c+3,a,b,i?.65:1.0,i?.65:1.0,"gun","subtract")])]);s.muzzles[q.toUpperCase()+"A"]=pts;
 let vx=k*8.3;part(q+"t_vent",q.toUpperCase()+"T","ct",[vx,32,-6],[Z([[-11,vx-2,vx+2,26,37,.12],[-6,vx-2,vx+2,26,37,.12]],"frame"),...Array.from({length:5},(_,i)=>B([vx-1.2,27+i*1.7,-11],[vx+1.2,27.9+i*1.7,-9],"frame","subtract"))]);
 let lx=k*10;set(q+"l_foot",[Y([[0,lx-5,lx+5,-6,4,.28],[2,lx-4.8,lx+4.8,-5,4,.2],[4,lx-3.2,lx+3.2,-2.7,2.7,.15]],"plate"),B([lx-1.3,0,-8],[lx+1.3,2,-4],"plate")]);
 }
 let pts=[[-11,42,-7],[-9,42,-7],[-7,42,-7],[-10,44,-7],[-8,44,-7]];
 set("lt_rack",[Z([[-7,-13,-5,39,46,.22],[-4,-13,-5,39,46,.20],[4,-12,-6,39,45,.18]],"plate"),...pts.map(([a,b,c])=>cyl("z",c,c+3,a,b,.76,.76,"gun","subtract"))]);s.muzzles.LT=pts;
}else{
 let w=v===1?14:15.5;
 set("ct",[loft("y",[[24,ellipse(0,0,5,4,20)],[27,ellipse(0,-1,w*.75,8,20)],[32,ellipse(0,-1,w,12,20)],[36,ellipse(0,0,w*.86,10,20)],[39,ellipse(0,0,w*.58,6,20)]],"armor")]);
 set("hd",[loft("z",[[-19,ellipse(0,29,3,2.1,20)],[-16,ellipse(0,30,7.5,3.7,20)],[-10,ellipse(0,32,9.2,5.2,20)],[-3,ellipse(0,33,8,4.5,20)]],"plate"),B([-3,31,-15],[3,34,-12],"glass","paint")]);
 for(let k of [-1,1]){let q=k<0?"l":"r",x=k*18,rx=k*13;
 set(q+"t",[X([[Math.min(k*11,k*16),30,36,-3,4,.13],[Math.max(k*11,k*16),30,36,-3,4,.13]],"frame")]);
 set(q+"a",[Y([[26,x-2.4,x+2.4,-2.3,2.3,.13],[30,x-3,x+3,-3,3,.18],[34,k*16-3.2,k*16+3.2,-3.5,3.5,.18],[37,k*16-3,k*16+3,-3,3,.15]],"plate")]);
 let pts=[[x-1.6,23,-17],[x+1.6,23,-17]];
 set(q+"a_weapon",[Z([[-10,x-3.8,x+3.8,19,27,.23],[-2,x-3.8,x+3.8,19,27,.20]],"plate"),...pts.flatMap(([a,b,c])=>[cyl("z",c,-8,a,b,1.6,1.6),cyl("z",c,c+3,a,b,.85,.85,"gun","subtract")])]);s.muzzles[q.toUpperCase()+"A"]=pts;
 let p=Array.from({length:15},(_,i)=>[rx+(i%5-2)*1.65,37+(Math.floor(i/5)-1)*1.9,-10]);
 set(q+"t_rack",[Y([[34,rx-3,rx+3,-3,4,.1],[37,rx-5.3,rx+5.3,-6,6,.2]],"frame"),Z([[-10,rx-5.3,rx+5.3,33.5,41,.27],[-5,rx-5.8,rx+5.8,33.2,41.8,.24],[7,rx-5.2,rx+5.2,34,41,.26]],"plate"),...p.map(([a,b,c])=>cyl("z",c,c+3,a,b,.7,.7,"gun","subtract"))]);s.muzzles[q.toUpperCase()+"T"]=p;
 let lx=k*11;set(q+"l_foot",[Y([[0,lx-5,lx+5,-6,4,.28],[2,lx-5,lx+5,-6,4,.25],[4,lx-3,lx+3,-3,2.5,.15]],"plate"),...[-3.2,3.2].map(dx=>B([lx+dx-1.1,0,-8],[lx+dx+1.1,2,-4],"plate"))]);
 }
}
return s;
}
;rebuild