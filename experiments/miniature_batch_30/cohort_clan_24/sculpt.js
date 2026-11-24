// Chassis-specific loft profiles. One cell is one experimental source unit.
// Forward is -Z. Coordinates are not production rig coordinates.
function sculpt(lib, row) {
 const {assembly,L,B,cyl,loft,ellipse,sidePart}=lib;
 const [id,name,pitch,legs,w,h,tw,fd,bd,top,th,sh,aw,fw,head,shoulder,lgun,rgun,lr,rr,ln,rn,note]=row.profile;
 const {spec,part}=assembly(id,name,pitch,legs==="reverse"?"digitigrade":"plantigrade");
 spec.unit=id;spec.reference=row.reference;spec.anatomy=note;
 const Y=(rows,mat="armor")=>L("y",rows,mat),Z=(rows,mat="armor")=>L("z",rows,mat),X=(rows,mat="armor")=>L("x",rows,mat);
 const yr=(y,x,r,z,d,ch=.12)=>[y,x-r,x+r,z-d,z+d,ch];
 const sym=(n,loc,parent,p,shapes,joint)=>{for(const q of ["l","r"])sidePart(part,q,n,q.toUpperCase()+loc,typeof parent==="function"?parent(q):parent,p,shapes,joint)};
 const sy=shoulder==="raised"?top+2:top-5, lower=w+3, hip=h+2;
 part("pelvis","CT",null,[0,w,0],[Y([[w-4,-h-3,h+3,-4,4,.1],[w,-h-4,h+4,-4,5,.1],[lower,-5,5,-3,4,.1]],"frame")]);
 // Core side wall is deliberately full width for several layers to accept shoulder modules.
 part("ct","CT","pelvis",[0,lower,0],[Y([[lower,-5,5,-3,4,.1],[lower+3,-tw*.72,tw*.72,-fd*.7,bd*.8,.16],[top-9,-tw,tw,-fd,bd,.12],[top-3,-tw,tw,-fd,bd,.12],[top,-tw*.74,tw*.74,-fd*.72,bd*.75,.15]],"armor")]);
 if(head==="nose"){
  const y=top-8,front=-fd-(id==="timber_wolf"?8:id==="ice_ferret"?7:5),r=id==="turkina"?6:id==="nova"?4.5:Math.max(3,tw*.45);
  part("hd","HD","ct",[0,y,-fd],[Z([[front,-r*.55,r*.55,y-3,y+1,.24],[front+3,-r,r,y-4,y+3,.24],[-fd+2,-r,r,y-3,y+6,.18]],"plate"),B([-r*.48,y-1,front],[r*.48,y+2,front+3],"glass","paint")]);
 } else if(head==="crown"){
  const r=id==="kingfisher"?4.7:3.5;
  part("hd","HD","ct",[0,top,-1],[loft("y",[[top-1,ellipse(0,-1,r,r,16)],[top+2,ellipse(0,-1,r,r+1,16)],[top+5,ellipse(0,-1,r*.8,r*.82,16)]],"plate"),B([-r*.6,top+1,-r-2],[r*.6,top+3,-r],"glass","paint")]);
 } else {
  const y=top-5,r=id==="dire_wolf"?4.5:3;
  part("hd","HD","ct",[0,y,-fd],[Z([[-fd-3,-r*.85,r*.85,y-3,y+3,.22],[-fd,-r,r,y-3.5,y+3.5,.16],[-fd+2,-r,r,y-3,y+3,.12]],"plate"),B([-r*.6,y,-fd-3],[r*.6,y+2,-fd-1],"glass","paint")]);
 }
 // Side torso slabs / arm hardpoints. Raised Fire Moth mounts are independent risers.
 const s=tw+3, armx=s+2, e=shoulder==="raised"?top:sy-8, wrist=shoulder==="raised"?top+2:e-6;
 sym("t","T","ct",[tw,top-6,0],[X([[tw-1,top-9,top-3,-fd*.55,bd*.7,.06],[s,top-9,top-3,-fd*.55,bd*.7,.08]],"plate"),...(shoulder==="raised"?[B([tw-1,top-7,-3],[s,top+3,3],"frame")]:[])]);
 let gunMounts=[];
 for(const [q,kind] of [["l",lgun],["r",rgun]]){
  const sign=q==="r"?1:-1,x=sign*armx,loc=q.toUpperCase()+"A",n=q+"a";
  const cap=shoulder==="round"?loft("x",[[s-1,ellipse(sy,0,3,aw+1,16)],[s+2,ellipse(sy,0,4,aw+1,16)],[s+5,ellipse(sy,0,3,aw,16)]],"plate"):X([[s-1,sy-3,sy+3,-aw,aw,.08],[s+2,sy-4,sy+4,-aw-1,aw+1,shoulder==="shield"?.22:.1],[s+5,sy-3,sy+3,-aw,aw,.12]],"plate");
  const high=shoulder==="raised";
  sidePart(part,q,"a",loc,q+"t",[s,sy,0],high?[cap]:[cap,Y([yr(e,armx,aw*.7,0,aw*.7),yr(e+3,armx,aw,0,aw),yr(sy-2,armx,aw*.8,0,aw*.8)],"armor")],"shoulder");
  const gy=high?sy:wrist+2,rz=Math.max(2,aw*.76),back=-Math.floor(aw*.8);
  if(high){
    part(n+"_forearm",loc,n,[x,gy,0],[B([x-rz,gy-rz,back],[x+rz,gy+rz,2],"frame")],"elbow");
  } else {
    sidePart(part,q,"a_forearm",loc,n,[armx,e,0],[Y([yr(wrist,armx,rz,0,rz),yr(wrist+3,armx,aw,0,aw),yr(e,armx,aw*.7,0,aw*.7)],"plate")],"elbow");
  }
  if(kind==="hand"){sidePart(part,q,"a_hand",loc,n+"_forearm",[armx,wrist,0],[Y([yr(wrist-4,armx,rz*.8,0,rz*.8),yr(wrist-2,armx,rz,0,rz),yr(wrist,armx,rz,0,rz)],"frame")]);spec.punch=true;continue}
  const count=kind==="six"?6:kind==="triple"?3:kind==="dual"?2:kind==="rack"?6:1;
  const end=back-(kind==="long"?13:kind==="short"?6:kind==="dual"?10:kind==="six"?8:7);
  const cols=count===6?3:count===3?3:count,rows=Math.ceil(count/cols),spacing=kind==="six"?2.15:count>1?2.65:0;
  const pts=Array.from({length:count},(_,i)=>[x+(i%cols-(cols-1)/2)*spacing,gy+(Math.floor(i/cols)-(rows-1)/2)*spacing]);
  const r=Math.max(rz, (cols-1)*spacing/2+1.6),ry=Math.max(rz,(rows-1)*spacing/2+1.6);
  const shapes=[Z([[end,x-r,x+r,gy-ry,gy+ry,.12],[end+3,x-r,x+r,gy-ry,gy+ry,.12],[back+1,x-rz,x+rz,gy-rz,gy+rz,.12]],kind==="rack"?"plate":"gun")];
  for(const [a,b] of pts)shapes.push(cyl("z",end,end+3,a,b,count===1?1.1:.66,count===1?1.1:.66,"gun","subtract"));
  part(n+"_weapon",loc,n+"_forearm",[x,gy,back],shapes);spec.muzzles[loc]=pts.map(([a,b])=>[a,b,end]);gunMounts.push(n+"_weapon");
 }
 for(const [q,kind,count] of [["l",lr,ln],["r",rr,rn]]){
  if(!kind)continue;const sign=q==="r"?1:-1,x=sign*(tw*.72),loc=q.toUpperCase()+"T",cols=count===20?4:count===15?5:count===10?5:count===6?3:count===5?3:2,rows=Math.ceil(count/cols),gap=2;
  const rw=Math.max(3.5,(cols-1)*gap/2+1.5),rh=Math.max(kind==="tallrack"?6:3.5,(rows-1)*gap/2+1.5),y=kind==="tallrack"?top-3:top+2,front=kind==="tallrack"?-fd-3:-fd*.65-4,back=bd*.65;
  const pts=Array.from({length:count},(_,i)=>[x+(i%cols-(cols-1)/2)*gap,y+(Math.floor(i/cols)-(rows-1)/2)*gap]);
  const housing=kind==="roundrack"?cyl("z",front,back,x,y,Math.max(rw,rh),Math.max(rw,rh),"plate"):Z([[front,x-rw,x+rw,y-rh,y+rh,.08],[front+3,x-rw,x+rw,y-rh,y+rh,.1],[back,x-rw*.9,x+rw*.9,y-rh*.9,y+rh*.9,.1]],"plate");
  part(q+"t_rack",loc,"ct",[x,y,0],[housing,B([x-2,top-5,-2],[x+2,Math.max(top,y),3],"frame"),...pts.map(([a,b])=>cyl("z",front,front+3,a,b,.66,.66,"gun","subtract"))]);spec.muzzles[loc]=pts.map(([a,b])=>[a,b,front]);
 }
 const knee=Math.round(w*.56),ankle=4;
 if(legs==="reverse"){
  const hx=h+1,kx=h+2,zz=id==="turkina"?8:6,hock=8;
  sym("l","L","pelvis",[hx,w-4,0],[Y([yr(knee,kx,th*.66,zz,th*.7),yr(knee+4,kx,th*.82,zz*.75,th*.8),yr(w-4,hx,th*.75,0,3)],"armor")],"hip");
  sym("l_shin","L",q=>q+"l",[kx,knee,zz],[Y([yr(hock,kx+1,sh*.68,0,sh*.7),yr(hock+3,kx+1,sh*.85,2,sh*.84),yr(knee,kx,th*.66,zz,th*.7)],"plate")],"knee");
  sym("l_tarsus","L",q=>q+"l_shin",[kx+1,hock,0],[Y([yr(ankle,kx+1,sh*.66,-1,sh*.66),yr(hock,kx+1,sh*.68,0,sh*.7)],"frame")],"hock");
  sym("l_foot","L",q=>q+"l_tarsus",[kx+1,ankle,-1],[Y([[0,kx+1-fw,kx+1+fw,-fw-5,fw,.22],[2,kx+1-fw,kx+1+fw,-fw-4,fw,.16],yr(ankle,kx+1,sh*.66,-1,sh*.66)],"plate")],"ankle");
 }else{
  sym("l","L","pelvis",[h,w-4,0],[Y([yr(knee,h+1,th*.7,0,th*.7),yr(knee+4,h+.5,th*.9,0,th*.9),yr(w-4,h,th*.72,0,3)],"armor")],"hip");
  sym("l_shin","L",q=>q+"l",[h+1,knee,0],[Y([yr(ankle,h+2,sh*.7,0,sh*.7),yr(ankle+4,h+2,sh*.9,0,sh),yr(knee-2,h+1,sh*.85,-.5,sh*.85),yr(knee,h+1,th*.7,0,th*.7)],"plate")],"knee");
  sym("l_foot","L",q=>q+"l_shin",[h+2,ankle,0],[Y([[0,h+2-fw,h+2+fw,-fw-3,fw,.18],[2,h+2-fw,h+2+fw,-fw-2,fw,.14],yr(ankle,h+2,sh*.7,0,sh*.7)],"plate")],"ankle");
 }
 return spec;
}
;sculpt