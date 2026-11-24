function author(lib,source,variant=1){
const s=lib.clone(source),{L,B,cyl,loft,ellipse}=lib,P=n=>s.parts.find(p=>p.name===n),Y=(r,m="plate")=>L("y",r,m),Z=(r,m="plate")=>L("z",r,m),X=(r,m="plate")=>L("x",r,m);
function part(name,loc,parent,pivot,shapes){s.parts.push({name,loc,parent,pivot,shapes})}
function set(n,shapes){P(n).shapes=shapes}
if(s.id==="king_crab"){
 // Reference: broad curved nose, down-sloping shell, recessed lower visor.
 const width=variant===1?16:18;
 set("ct",[Z([[-17,-5,5,28,32,.30],[-13,-10,10,26,34,.22],[-7,-width,width,25,36,.24],[1,-width,width,25,37,.20],[8,-14,14,26,36,.22],[12,-10,10,28,33,.30]],"armor"),Y([[23,-5,5,-3,4,.10],[26,-8,8,-4,6,.15]],"frame")]);
 set("hd",[Z([[-18,-3.5,3.5,26,29,.22],[-15,-8,8,25,29,.20],[-11,-11,11,25,28,.18],[-8,-10,10,25,27,.14]],"glass"),Z([[-17,-3,3,24.5,26.5,.20],[-12,-8,8,24,26.5,.16],[-8,-10,10,24,26.5,.16]],"frame")]);
 for(const sign of [-1,1]){const q=sign<0?"l":"r",x=sign*19,t=sign*14;
  set(q+"t",[X([[Math.min(t,sign*17),27,34,-5,5,.20],[Math.max(t,sign*17),27,34,-5,5,.20]],"plate")]);
  set(q+"a",[Y([[24,x-2,x+2,-2.3,2.3,.15],[27,x-2.6,x+2.6,-3,3,.15],[30,x-2.4,x+2.4,-3,3,.15],[34,x-3.8,x+3.8,-4,4,.20],[35,x-3,x+3,-3.5,3.5,.22]],"plate")]);
  set(q+"a_forearm",[Y([[19,x-2.8,x+2.8,-2.6,2.6,.12],[22,x-3,x+3,-3,3,.15],[24,x-2,x+2,-2.3,2.3,.12]],"frame")]);
  const z=-19,back=-2;
  set(q+"a_weapon",[Z([[z,x-3.5,x+3.5,16,24,.26],[z+4,x-5,x+5,15,27,.24],[-7,x-5,x+5,16,27,.22],[back,x-3.3,x+3.3,18,24,.2]],"plate"),cyl("z",z-1,z+5,x,20,2.6,2.6,"gun"),cyl("z",z-1,z+4,x,20,1.5,1.5,"gun","subtract"),B([x-1.4,19,z],[x+1.4,21,z+4],"gun","subtract")]);
  s.muzzles[q.toUpperCase()+"A"]=[[x,20,z-1]];
  const fx=sign*5;
  part(q+"t_fin",q.toUpperCase()+"T","ct",[fx,35,7],[Y([[35,fx-1.5,fx+1.5,5,9,.1],[40,fx-1.3,fx+1.3,7,10,.12],[44,fx-.8,fx+.8,8,10,.1]],"plate")]);
  const shx=sign*12;set(q+"l_foot",[Y([[0,shx-5.5,shx+5.5,-7,5,.28],[2,shx-5,shx+5,-7,5,.25],[4,shx-3.5,shx+3.5,-4,2,.2]],"plate")]);
 }
 // Raised asymmetric top-shell weapon mounts; identity still needs record-sheet confirmation.
 part("lt_dorsal_gun","LT","ct",[-8,35,-3],[Y([[33,-11,-5,-7,1,.20],[37,-10.5,-5.5,-6,1,.20]],"plate"),cyl("z",-10,-4,-8,35,1.8,1.8),cyl("z",-10,-7,-8,35,.9,.9,"gun","subtract")]);
 s.muzzles.LT=[[-8,35,-10]];
 const pts=Array.from({length:15},(_,i)=>[8+(i%5-2)*1.2,35+(Math.floor(i/5)-1)*1.3,-7]);
 part("rt_dorsal_rack","RT","ct",[8,35,-3],[Z([[-7,4,12,32,38,.24],[-3,4,12,32,38,.20],[1,5,11,33,37,.20]],"plate"),...pts.map(([x,y,z])=>cyl("z",z,z+2,x,y,.55,.55,"gun","subtract"))]);s.muzzles.RT=pts;
}else if(s.id==="bushwacker"){
 const wid=variant===1?5:4;
 // Narrow wedge hull. Distinct sloping roof rather than a wide chest with a small nose stuck on it.
 set("ct",[Z([[-10,-wid,wid,25,32,.20],[-5,-wid,wid,26,35,.18],[0,-wid-2,wid+2,27,39,.17],[6,-wid-1,wid+1,30,41,.22],[9,-wid,wid,32,39,.20]],"armor"),Y([[27,-5,5,-3,4,.1],[30,-5,5,-3,5,.1]],"frame")]);
 set("hd",[Z([[-19,-2.5,2.5,24,27,.25],[-15,-3.7,3.7,24,30,.18],[-10,-4.5,4.5,26,34,.20],[-5,-4.5,4.5,28,36,.18]],"plate"),B([-2.5,28,-15],[2.5,30,-12],"glass","paint"),B([-3,31,-10],[3,33,-8],"glass","paint")]);
 // Cylindrical shoulder drums and articulated elbow collars.
 for(const k of [-1,1]){const q=k<0?"l":"r",x=k*12;
  set(q+"t",[X([[Math.min(k*5,k*10),31,37,-4,4,.15],[Math.max(k*5,k*10),31,37,-4,4,.15]],"frame")]);
  set(q+"a",[loft("x",[[k<0?-14:9,ellipse(34,0,3.5,3.4,16)],[k<0?-9:14,ellipse(34,0,3.5,3.4,16)]],"plate"),Y([[26,x-1.7,x+1.7,-2,2,.15],[30,x-2,x+2,-2,2,.15],[33,x-2.3,x+2.3,-2,2,.15]],"frame")]);
  set(q+"a_forearm",[Y([[20,x-2.8,x+2.8,-3,3,.18],[23,x-3,x+3,-3,3,.18],[26,x-1.7,x+1.7,-2,2,.12]],"plate")]);
 }
 const pts=Array.from({length:6},(_,i)=>[12+(i%2-.5)*2,22+(Math.floor(i/2)-1)*2,-10]);
 set("ra_weapon",[Z([[-10,8.5,15.5,18,26,.18],[-6,8.5,15.5,18,26,.18],[-2,9,15,19,25,.15]],"plate"),...pts.map(([x,y,z])=>cyl("z",z,z+3,x,y,.7,.7,"gun","subtract"))]);s.muzzles.RA=pts;
 set("rt_rack",[Y([[37,2.5,6.5,1,5,.16],[42,4,8,1,5,.15],[45,5,9,0,4,.18]],"frame"),Z([[-4,4,10,43,49,.30],[1,4,10,43,49,.28],[5,5,9,44,48,.22]],"plate"),...[[6,45],[8,45],[7,47]].map(([x,y])=>cyl("z",-4,-1,x,y,.7,.7,"gun","subtract"))]);s.muzzles.RT=[[6,45,-4],[8,45,-4],[7,47,-4]];
 P("rt_rack").pivot=[5,40,3];
 // Front nose weapon stubs, integral to the lower hull, not a second head.
 part("ct_nose_guns","CT","hd",[0,26,-17],[B([-3,24,-18],[3,27,-15],"frame"),...[-1.6,1.6].map(x=>cyl("z",-22,-17,x,25,1.15,1.15)),...[-1.6,1.6].map(x=>cyl("z",-22,-19,x,25,.6,.6,"gun","subtract"))]);s.muzzles.CT=[[-1.6,25,-22],[1.6,25,-22]];
}
return s;
}
;author