function rebuild(lib,src,v){const s=lib.clone(src),{L,B,cyl,loft,ellipse}=lib,P=n=>s.parts.find(p=>p.name===n),Y=(r,m="plate")=>L("y",r,m),Z=(r,m="plate")=>L("z",r,m),X=(r,m="plate")=>L("x",r,m),set=(n,shapes)=>P(n).shapes=shapes;
const part=(name,loc,parent,pivot,shapes)=>s.parts.push({name,loc,parent,pivot,shapes});
if(s.id==="grasshopper"){
 let w=v===1?8:9;
 set("ct",[Y([[30,-4,4,-3,3,.15],[33,-5.5,5.5,-5,4,.16],[37,-w,w,-7,4,.25],[41,-w,w,-4,4,.18],[42,-5,5,-3,3,.15]],"armor")]);
 set("hd",[Z([[-7,-3.5,3.5,40,45,.28],[-4,-4,4,39,47,.20],[1,-4.1,4.1,40,47,.18],[4,-3,3,41,46,.20]],"plate"),B([-2.3,41,-7],[2.3,43,-5],"glass","paint")]);
 part("lt_head_rack","LT","ct",[-4,42,0],[Y([[40,-7,-3,-3,3,.1],[46,-7,-3,-4,3,.14],[48,-6,-3,-3,2,.12]],"plate"),...Array.from({length:5},(_,i)=>cyl("z",-4,-1,-5.4+(i%2)*1.5,43+Math.floor(i/2)*1.5,.7,.7,"gun","subtract"))]);s.muzzles.LT=Array.from({length:5},(_,i)=>[-5.4+(i%2)*1.5,43+Math.floor(i/2)*1.5,-4]);
 for(let k of [-1,1]){let q=k<0?"l":"r",x=k*14;
 set(q+"a",[Y([[29,x-1.9,x+1.9,-2,2,.12],[33,x-2.2,x+2.2,-2.5,2.5,.15],[36,x-3.6,x+3.6,-3.8,3.6,.25],[41,x-3.9,x+3.9,-3.5,3.5,.30],[43,x-2.8,x+2.8,-2.7,2.7,.25]],"plate")]);
 set(q+"a_forearm",[Y([[23,x-2.4,x+2.4,-2.5,2.5,.15],[26,x-2.8,x+2.8,-3.2,3,.18],[29,x-1.9,x+1.9,-2,2,.15]],"plate")]);
 let lx=k*7;set(q+"l_shin",[Y([[4,k*8-2,k*8+2,-2,2,.1],[7,lx-3.1,lx+3.1,-3,3,.18],[11,lx-3.4,lx+3.4,-4.4,3,.20],[14,lx-3.2,lx+3.2,-3.2,3,.18],[15,lx-2.6,lx+2.6,-2.6,2.6,.1]],"plate")]);
 }
 // Low waist-mounted laser pods visible in frontal photo; preserve existing central sample.
 for(let k of [-1,1]){let q=k<0?"l":"r",x=k*4.0;part(q+"t_waist_gun",q.toUpperCase()+"T","ct",[x,31,-3],[B([x-1.5,29,-6],[x+1.5,33,-2],"frame"),cyl("z",-10,-5,x,30.5,1.4,1.4),cyl("z",-10,-7,x,30.5,.7,.7,"gun","subtract")]);if(k>0)s.muzzles.RT=[[x,30.5,-10]];else s.muzzles.LT.push([x,30.5,-10]);}
}else if(s.id==="timber_wolf"){
 let w=v===1?8.5:9.5;
 set("ct",[Y([[26,-5,5,-3,4,.15],[29,-w,w,-6,7,.2],[34,-w,w,-5,8,.20],[39,-w*.8,w*.8,-4,6,.25]],"armor")]);
 set("hd",[loft("z",[[-19,ellipse(0,31,2.6,3.4,20)],[-16,ellipse(0,32,6,6,20)],[-11,ellipse(0,32,7.3,7,20)],[-5,ellipse(0,33,7,6,20)],[-2,ellipse(0,33,5,4,20)]],"plate"),B([-2.7,31,-18],[2.7,35,-15],"glass","paint")]);
 for(let k of [-1,1]){let q=k<0?"l":"r",x=k*14,r=k*10.5;
 set(q+"t",[X([[Math.min(k*7,k*12),31,37,-3.5,3.5,.1],[Math.max(k*7,k*12),31,37,-3.5,3.5,.1]],"frame")]);
 set(q+"a",[Y([[26,x-2,x+2,-2,2,.12],[30,x-2.1,x+2.1,-2.5,2.5,.18],[34,k*12-2.7,k*12+2.7,-3,3,.2],[37,k*12-2.3,k*12+2.3,-2.5,2.5,.15]],"plate")]);
 set(q+"a_forearm",[Y([[20,x-3.4,x+3.4,-3.3,3.3,.20],[24,x-3.4,x+3.4,-3.3,3.3,.20],[26,x-2,x+2,-2,2,.12]],"plate")]);
 let pts=[[x,22,-17],[x,25,-15]];
 set(q+"a_weapon",[Z([[-13,x-3.2,x+3.2,19,27,.20],[-2,x-3.2,x+3.2,19,27,.17]],"plate"),...pts.flatMap(([a,b,c])=>[cyl("z",c,-11,a,b,1.45,1.45),cyl("z",c,c+3,a,b,.8,.8,"gun","subtract")])]);s.muzzles[q.toUpperCase()+"A"]=pts;
 let p=Array.from({length:20},(_,i)=>[r+(i%4-1.5)*2,38+Math.floor(i/4)*2,-8]);
 set(q+"t_rack",[Y([[35,r-2.5,r+2.5,-2,3,.12],[38,r-4.8,r+4.8,-5,5,.12]],"frame"),Z([[-8,r-4.8,r+4.8,36.4,47.6,.12],[-5,r-4.8,r+4.8,36.4,47.6,.12],[6,r-4.6,r+4.6,36.4,47.6,.18]],"plate"),...p.map(([a,b,z])=>cyl("z",z,z+3,a,b,.76,.76,"gun","subtract"))]);s.muzzles[q.toUpperCase()+"T"]=p;
 let lx=k*10;set(q+"l_tarsus",[Y([[4,lx-2.6,lx+2.6,-2.5,2.5,.15],[6,lx-3.8,lx+3.8,-3.8,3.8,.28],[8,lx-2.8,lx+2.8,-2.7,2.7,.15]],"plate")]);
 set(q+"l_foot",[Y([[0,lx-4,lx+4,-5.7,3,.3],[2,lx-3.8,lx+3.8,-5,3,.25],[4,lx-2.6,lx+2.6,-2.5,2.5,.15]],"plate"),...[-2.4,2.4].map(dx=>B([lx+dx-1,0,-7],[lx+dx+1,2,-4],"plate"))]);
 }
}else if(s.id==="zeus"){
 let w=v===1?8:9;
 set("ct",[Y([[29,-5,5,-3.5,4,.15],[32,-6.5,6.5,-5,5,.22],[37,-w,w,-5,6,.22],[42,-w*.85,w*.85,-4,5,.16],[43,-5,5,-3,4,.15]],"armor")]);
 set("hd",[Z([[-8,-2.7,2.7,36,43,.22],[-5,-3.7,3.7,35,45,.20],[0,-3.8,3.8,36,47,.22],[3,-3,3,37,46,.2]],"plate"),B([-2,39,-8],[2,41,-6],"glass","paint")]);
 for(let k of [-1,1]){let q=k<0?"l":"r",x=k*15;
 // Wide shoulder cylinders span the entire upper arm axis; taper at outer end.
 let ends=[k*9,k*12,k*16,k*18].sort((a,b)=>a-b);
 set(q+"t",[X([[Math.min(k*7,k*11),34,42,-3.3,3.3,.1],[Math.max(k*7,k*11),34,42,-3.3,3.3,.1]],"frame")]);
 set(q+"a",[loft("x",ends.map(t=>[t,ellipse(39,0,Math.abs(t)>=16?5:4.1,Math.abs(t)>=16?5:4.2,16)]),"plate"),Y([[30,x-2.3,x+2.3,-2.5,2.5,.15],[34,x-2.5,x+2.5,-3,3,.15],[37,x-2.6,x+2.6,-3,3,.15]],"frame")]);
 let lx=k*8;set(q+"l_shin",[Y([[4,k*9-2.8,k*9+2.8,-2.7,2.7,.15],[8,lx-4,lx+4,-4,3.5,.20],[12,lx-3.6,lx+3.6,-3.7,3.5,.15],[15,lx-3,lx+3,-3,3,.15]],"plate")]);
 }
 let x=15,y=26,z=-14,pts=Array.from({length:6},(_,i)=>[x+2.3*Math.cos(i*Math.PI/3),y+2.3*Math.sin(i*Math.PI/3),z]);
 set("ra_weapon",[loft("z",[[z,ellipse(x,y,4,4,20)],[z+4,ellipse(x,y,4.3,4.3,20)],[-2,ellipse(x,y,3.2,3.2,20)]],"plate"),...pts.map(([a,b,c])=>cyl("z",c,c+3,a,b,.76,.76,"gun","subtract"))]);s.muzzles.RA=pts;
}
return s;
}
;rebuild