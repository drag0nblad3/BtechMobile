function rebuild(lib,source,variant){
 const s=lib.clone(source),{L,B,cyl,loft,ellipse}=lib,P=n=>s.parts.find(p=>p.name===n),Y=(v,m="plate")=>L("y",v,m),Z=(v,m="plate")=>L("z",v,m),X=(v,m="plate")=>L("x",v,m);
 const set=(n,shapes)=>P(n).shapes=shapes,part=(name,loc,parent,pivot,shapes)=>s.parts.push({name,loc,parent,pivot,shapes});
 if(s.id==="king_crab"){
  let w=variant===1?14:16,back=variant===1?10:12;
  // Low, curved forward carapace with a thick rear deck and inset cockpit.
  set("ct",[Z([[-18,-3,3,27,30,.28],[-15,-8,8,26,32,.25],[-10,-w+2,w-2,26,35,.24],[-4,-w,w,25,38,.24],[3,-w,w,25,39,.22],[back,-w+3,w-3,27,36,.28]],"armor"),Y([[23,-5,5,-3,4,.10],[26,-7,7,-4,5,.10]],"frame")]);
  set("hd",[Z([[-18,-3.5,3.5,25,27,.15],[-14,-7.5,7.5,24,26.5,.12],[-9,-10,10,24,26.5,.15],[-5,-8,8,24,27,.15]],"frame"),B([-6,24,-15],[6,26,-12],"glass","paint")]);
  for(let k of [-1,1]){let q=k<0?"l":"r",x=k*19,t=k*14;
   set(q+"t",[X([[Math.min(t,k*17),27,34,-5,5,.1],[Math.max(t,k*17),27,34,-5,5,.1]],"frame")]);
   set(q+"a",[Y([[24,x-2,x+2,-2,2,.13],[28,x-2.5,x+2.5,-3,3,.18],[31,x-3.7,x+3.7,-4,4,.18],[35,x-4,x+4,-4,4,.22]],"plate")]);
   set(q+"a_forearm",[Y([[19,x-2.5,x+2.5,-2.5,2.5,.1],[22,x-3,x+3,-3,3,.15],[24,x-2,x+2,-2,2,.1]],"frame")]);
   const z=-20,wide=variant===1?4.4:5.2;
   set(q+"a_weapon",[Z([[z,x-3,x+3,16,24,.22],[z+4,x-wide,x+wide,15,27,.18],[-8,x-wide,x+wide,15,27,.18],[-2,x-3.1,x+3.1,18,24,.15]],"plate"),cyl("z",z-1,z+5,x,20,2.1,2.1),cyl("z",z-1,z+4,x,20,1.3,1.3,"gun","subtract"),B([x-3,18.5,z],[x+3,21.5,z+4],"gun","subtract")]);
   s.muzzles[q.toUpperCase()+"A"]=[[x,20,z-1]];
   const fx=k*5;part(q+"t_fin",q.toUpperCase()+"T","ct",[fx,36,7],[Y([[35,fx-1.5,fx+1.5,5,9,.07],[39,fx-1.5,fx+1.5,6,9,.1],[45,fx-1,fx+1,8,10,.1]],"plate")]);
   const lx=k*12;set(q+"l_foot",[Y([[0,lx-5.5,lx+5.5,-7,5,.25],[2,lx-5.5,lx+5.5,-6.5,5,.2],[4,lx-3.6,lx+3.6,-3,2.4,.12]],"plate")]);
  }
  part("lt_dorsal_gun","LT","ct",[-8,35,0],[B([-10,32,-5],[-6,37,1],"plate"),cyl("z",-9,-2,-8,36,1.9,1.9),cyl("z",-9,-6,-8,36,.9,.9,"gun","subtract")]);s.muzzles.LT=[[-8,36,-9]];
  let pts=Array.from({length:15},(_,i)=>[8+(i%5-2)*1.3,35+(Math.floor(i/5)-1)*1.3,-5]);
  part("rt_dorsal_rack","RT","ct",[8,35,0],[B([4,32,-5],[12,38,2],"plate"),...pts.map(([x,y,z])=>cyl("z",z,z+3,x,y,.56,.56,"gun","subtract"))]);s.muzzles.RT=pts;
 }else{
  // Mad Dog: narrow continuous descending beak; two angled tall banks separated by open side gaps.
  let w=variant===1?4.5:5.5;
  set("ct",[Y([[26,-5,5,-3,4,.1],[29,-w,w,-5,6,.16],[34,-w,w,-4,7,.18],[40,-w,w,-1,7,.18],[43,-w*.75,w*.75,1,6,.2]],"armor")]);
  set("hd",[Y([[28,-3,3,-18,-9,.15],[32,-4,4,-19,-7,.16],[36,-3.8,3.8,-15,-4,.18],[40,-3.5,3.5,-10,0,.16],[43,-3,3,-5,4,.15]],"plate"),B([-2.5,33,-18],[2.5,35,-15],"glass","paint")]);
  for(let k of [-1,1]){let q=k<0?"l":"r",x=k*9,ax=k*13;
   set(q+"t",[X([[Math.min(k*4,k*11),33,39,-1,5,.1],[Math.max(k*4,k*11),33,39,-1,5,.1]],"frame")]);
   let pts=[];for(let row=0;row<5;row++)for(let col=0;col<4;col++)pts.push([x+(col-1.5)*1.8,33+row*2.1,-15+row*1.25]);
   set(q+"t_rack",[Y([[30,x-4,x+4,-17,-5,.15],[33,x-4.2,x+4.2,-16,-3,.12],[38,x-4.2,x+4.2,-13,0,.12],[44,x-4,x+4,-8,3,.12],[46,x-3.3,x+3.3,-6,3,.18]],"plate"),...pts.map(([a,b,z])=>cyl("z",z-2,z+4,a,b,.74,.74,"gun","subtract"))]);s.muzzles[q.toUpperCase()+"T"]=pts.map(([a,b,z])=>[a,b,z-2]);
   set(q+"a",[Y([[28,ax-1.9,ax+1.9,-2,2,.1],[31,ax-2.1,ax+2.1,-2.4,2.4,.13],[34,ax-2.3,ax+2.3,-3,3,.17],[38,ax-2.8,ax+2.8,-3,3,.18]],"frame")]);
   set(q+"a_forearm",[Y([[23,ax-3,ax+3,-3,3,.16],[26,ax-3,ax+3,-3,3,.16],[28,ax-1.9,ax+1.9,-2,2,.1]],"plate")]);
   let y=25,z=-20,points=[[ax-1.6,y,z],[ax+1.6,y,z+2]];
   set(q+"a_weapon",[Z([[-9,ax-3.5,ax+3.5,y-2.3,y+2.3,.14],[-2,ax-3,ax+3,y-2.4,y+2.4,.12]],"plate"),...points.flatMap(([a,b,c])=>[cyl("z",c,-6,a,b,1.5,1.5,"gun"),cyl("z",c,c+4,a,b,.76,.76,"gun","subtract")])]);s.muzzles[q.toUpperCase()+"A"]=points;
   let lx=k*10;
   set(q+"l_foot",[Y([[0,lx-4.7,lx+4.7,-7,3,.26],[2,lx-4,lx+4,-6,3,.20],[4,lx-2.8,lx+2.8,-3,2,.1]],"plate"),B([lx-1.4,0,-9],[lx+1.4,2,-5],"plate")]);
  }
 }
 return s;
}
;rebuild