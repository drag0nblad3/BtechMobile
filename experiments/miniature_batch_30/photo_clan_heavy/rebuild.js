function rebuild(lib,source,v){
const s=lib.clone(source),{L,B,cyl,loft,ellipse}=lib,P=n=>s.parts.find(p=>p.name===n),Y=(r,m="plate")=>L("y",r,m),Z=(r,m="plate")=>L("z",r,m),X=(r,m="plate")=>L("x",r,m),set=(n,sh)=>P(n).shapes=sh, pair=f=>[-1,1].forEach(k=>f(k,k<0?"l":"r")),box=(y,x,r,z,d,ch=.15)=>[y,x-r,x+r,z-d,z+d,ch];
const d=s.id==="dire_wolf",w=s.id==="warhawk",t=s.id==="summoner",top=d?40:w?41:41,wa=t?25:23,tw=d?13:w?12:10,ax=d?18:w?17:15,sy=d?35:36,el=sy-8,gy=el-4,hip=t?9:10,kn=t?14:13,wr=wa+3,wide=v===1?tw:tw-1;
if(t){
set("ct",[Y([[wr,-5,5,-3,4,.1],[wr+3,-6,6,-5,5,.18],[35,-wide,wide,-7,7,.22],[40,-wide,wide,-6,7,.22],[42,-wide*.72,wide*.72,-5,5,.22]],"armor")]);
set("hd",[Z([[-10,-2,2,35,39,.22],[-7,-3,3,34,40,.16],[-5,-3,3,34,40,.14]],"plate"),B([-1.5,36,-10],[1.5,38,-8],"glass","paint")]);
}else{
set("ct",[Y([[wr,-5,5,-3,4,.1],[wr+2,-wide*.68,wide*.68,-6,6,.15],[top-9,-wide*.78,wide*.78,-7,7,.13],[top-5,-wide,wide,-9,8,.2],[top-2,-wide,wide,-10,8,.20],[top,-wide*.82,wide*.82,-8,7,.22]],"armor")]);
set("hd",d?[loft("z",[[-13,ellipse(0,32,3.7,4,20)],[-10,ellipse(0,33,4.8,5,20)],[-6,ellipse(0,33,4.9,5.4,20)]],"plate"),B([-2.4,34,-13],[2.4,36,-10],"glass","paint")]:[Z([[-11,-2.9,2.9,29,36,.22],[-8,-3.8,3.8,29,38,.18],[-5,-4,4,29,38,.18]],"plate"),B([-2.2,35,-11],[2.2,37,-8],"glass","paint")]);
}
pair((k,q)=>{let x=k*ax,loc=q.toUpperCase()+"A",sx=k*(ax-2);
set(q+"t",[X([[Math.min(k*(tw-2),sx),sy-4,sy+3,-4,4,.12],[Math.max(k*(tw-2),sx),sy-4,sy+3,-4,4,.12]],"frame")]);
set(q+"a",[loft("x",[[sx-2.2,ellipse(sy,0,3.6,4,20)],[sx+2.2,ellipse(sy,0,3.6,4,20)]],"plate"),Y([box(el,x,2.4,0,2.4),box(el+4,x,2.7,0,2.8),box(sy,sx,2.8,0,2.8)],"frame")]);
set(q+"a_forearm",[Y([box(el-6,x,d?3.4:2.8,0,3),box(el-3,x,d?3.8:3.2,0,3.3),box(el,x,2.4,0,2.4)],"plate")]);
let pts=d?[[x,gy-1.5,-14],[x-1.8,gy+1.6,-10],[x+1.8,gy+1.6,-10]]:w?[[x-1.65,gy,-20],[x+1.65,gy,-19]]:[[x,gy,-16]];
let sh=[Z([[-8,x-3.8,x+3.8,gy-3.2,gy+3.2,.19],[-2,x-3.2,x+3.2,gy-3.2,gy+3.2,.18]],"plate")];for(const [a,b,z] of pts){const r=d&&b<gy?2:1.45;sh.push(cyl("z",z,-6,a,b,r,r),cyl("z",z,z+3,a,b,r*.55,r*.55,"gun","subtract"))}set(q+"a_weapon",sh);s.muzzles[loc]=pts;
const lx=k*hip;
set(q+"l_shin",[Y([box(4,lx,2.8,0,2.8),box(7,lx,d||w?4.2:3.8,-.4,3.8,.23),box(kn-2,k*(hip-1),d||w?4:3.5,0,3.8,.22),box(kn,k*(hip-1),3,0,3,.14)],"plate")]);
set(q+"l_foot",[Y([[0,lx-4.7,lx+4.7,-6,4,.28],[2,lx-4.5,lx+4.5,-5,4,.24],box(4,lx,2.8,0,2.8)],"plate"),B([lx-1.3,0,-8],[lx+1.3,2,-4],"plate")]);
});
let p=P("lt_rack"),x=t?-7:7,y=t?44:d?43:42,z=t?-10:-8;
if(!t){p.name="rt_rack";p.loc="RT";delete s.muzzles.LT;}p.pivot=[x,top,0];
let count=d?10:w?10:15,cols=t?5:5,pts=Array.from({length:count},(_,i)=>[x+(i%cols-2)*(t?1.65:1.6),y+(Math.floor(i/cols)-(Math.ceil(count/cols)-1)/2)*1.6,z]);
p.shapes=[B([x-2,top-3,-2],[x+2,y-1,4],"frame"),...(t?[cyl("z",z,7,x,y,5,5,"plate")]:[Z([[z,x-4.8,x+4.8,y-2.6,y+2.6,.2],[3,x-4.8,x+4.8,y-2.6,y+2.6,.2]],"plate")]),...pts.map(([a,b,c])=>cyl("z",c,c+3,a,b,.65,.65,"gun","subtract"))];s.muzzles[p.loc]=pts;
return s;
}
;rebuild