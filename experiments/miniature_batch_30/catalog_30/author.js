// Independent provisional chassis profiles; no production integration.
function author(lib,base,row,meta){
 const [id,name,baseNo,photoVariant,w,h,tw,fd,bd,top,th,sh,aw,fw,head,shoulder,lgun,rgun,ln,rn,note,style]=row;
 const pitch=meta.pitch,legs=meta.legs==="digitigrade"?"reverse":"upright",reference={catalog:"https://jadedfalconer.com/Pages/6How/miniatures",base:baseNo,variant:photoVariant};
 const {L,B,cyl,loft,ellipse,assembly}=lib,Y=(a,m="plate")=>L("y",a,m),Z=(a,m="plate")=>L("z",a,m);
 if(style==="quad"){
  let {spec:s,part}=assembly(id,name,pitch,"quad");s.unit=meta.unit;s.reference=reference;s.anatomy=note;
  part("ct","CT",null,[0,19,0],[Y([[14,-tw*.65,tw*.65,-fd*.8,bd*.8,.18],[19,-tw,tw,-fd,bd,.18],[24,-tw,tw,-fd,bd,.24],[top-4,-tw*.85,tw*.85,-fd*.8,bd*.8,.28],[top,-tw*.5,tw*.5,-fd*.45,bd*.6,.3]],"armor")]);
  part("hd","HD","ct",[0,24,-fd],[Z([[-fd-5,-3.3,3.3,20,24,.25],[-fd-2,-4.3,4.3,19,26,.23],[-fd+2,-4.3,4.3,20,27,.18]],"plate"),B([-2.5,22,-fd-5],[2.5,24,-fd-3],"glass","paint")]);
  for(let [k,q] of [[-1,"l"],[1,"r"]]){
   let x=k*(tw+2),loc=q.toUpperCase()+"T";part(q+"t",loc,"ct",[k*tw,24,0],[L("x",[[Math.min(k*(tw-1),k*(tw+3)),20,26,-5,6,.15],[Math.max(k*(tw-1),k*(tw+3)),20,26,-5,6,.15]],"plate")]);
   for(let [side,z] of [["a",-fd*.68],["l",bd*.68]]){
    let n=q+side,l=q.toUpperCase()+side.toUpperCase(),hip=k*(tw-1),knee=k*(tw+4),ank=k*(tw+5),zz=z+(side==="a"?-2:2);
    part(n,l,"ct",[hip,18,z],[Y([[11,knee-th*.6,knee+th*.6,zz-2.6,zz+2.6,.13],[15,x-th*.7,x+th*.7,z-3,z+3,.2],[19,hip-th*.72,hip+th*.72,z-3,z+3,.12]],"armor")],"hip");
    part(n+"_shin",l,n,[knee,11,zz],[Y([[4,ank-sh*.65,ank+sh*.65,zz-2,zz+2,.12],[7,ank-sh*.84,ank+sh*.84,zz-3,zz+3,.23],[11,knee-th*.6,knee+th*.6,zz-2.6,zz+2.6,.13]])],"knee");
    part(n+"_foot",l,n+"_shin",[ank,4,zz],[Y([[0,ank-fw,ank+fw,zz-fw-2,zz+fw,.24],[2,ank-fw,ank+fw,zz-fw-1,zz+fw,.2],[4,ank-sh*.65,ank+sh*.65,zz-2,zz+2,.1]])],"ankle");
   }
  }
  let z=-fd-9,x=id==="goliath"?0:3,y=top+2;
  part("dorsal_ppc","RT","ct",[x,top-2,1],[B([x-2,top-3,-2],[x+2,top+3,5],"frame"),cyl("z",z,6,x,y,2.1,2.1,"gun"),cyl("z",z,z+3,x,y,1,1,"gun","subtract")]);s.muzzles.RT=[[x,y,z]];
  let xx=-tw*.56,yy=top-7,front=-fd-3,n=id==="scorpion"?6:1,pts=Array.from({length:n},(_,i)=>[xx+(i%2-.5)*2,yy+(Math.floor(i/2)-1)*2,front]);
  part("lt_rack","LT","ct",[xx,yy,-fd],[Z([[front,xx-3,xx+3,yy-4,yy+4,.1],[-fd+4,xx-3,xx+3,yy-4,yy+4,.12]]),...pts.map(([a,c])=>cyl("z",front,front+3,a,c,.8,.8,"gun","subtract"))]);s.muzzles.LT=pts;return s;
 }
 const s=base(lib,{profile:[id,name,pitch,legs,w,h,tw,fd,bd,top,th,sh,aw,fw,head,shoulder,lgun,rgun,"","",0,0,note],reference:reference.catalog});s.reference=reference;s.unit=meta.unit;s.anatomy=note;const P=n=>s.parts.find(x=>x.name===n),part=(name,loc,parent,pivot,shapes,joint)=>s.parts.push({name,loc,parent,pivot,shapes,...(joint?{joint}:{})});
 const sy=top-5,armx=tw+5,e=sy-8,gy=e-4;
 if(style==="round"||style==="sensor"||id==="akuma"){
  P("ct").shapes=[loft("y",[[w+3,ellipse(0,0,5,4,20)],[w+6,ellipse(0,0,tw*.72,fd*.78,20)],[top-9,ellipse(0,0,tw,fd,20)],[top-3,ellipse(0,0,tw*.94,fd*.85,20)],[top,ellipse(0,0,tw*.67,bd*.75,20)]],"armor")];
 }else{
  let skinny=style==="fins"||style==="disc"||style==="pod";P("ct").shapes=[Y([[w+3,-5,5,-3,4,.1],[w+6,-tw*(skinny?.65:.78),tw*(skinny?.65:.78),-fd*.72,bd*.75,.21],[top-9,-tw,tw,-fd,bd,.16],[top-3,-tw,tw,-fd*.82,bd*.88,.2],[top,-tw*.75,tw*.75,-fd*.55,bd*.65,.22]],"armor")];
 }
 if(["prow","disc","pod"].includes(style)){
  let y=top-8,rx=style==="disc"?5.6:style==="pod"?3.1:Math.max(3.2,tw*.43),reach=style==="disc"?9:6;
  P("hd").shapes=style==="disc"?[loft("y",[[y-3,ellipse(0,-fd-3,rx*.7,6,20)],[y-1,ellipse(0,-fd-3,rx,8,20)],[y+2,ellipse(0,-fd-3,rx,8,20)],[y+4,ellipse(0,-fd-2,rx*.78,6,20)]],"plate"),B([-3,y,-fd-11],[3,y+2,-fd-9],"glass","paint")]:[Z([[-fd-reach,-rx*.55,rx*.55,y-3,y+1,.2],[-fd-reach+3,-rx,rx,y-4,y+3,.23],[-fd+3,-rx,rx,y-3,y+5,.16]]),B([-rx*.48,y-1,-fd-reach],[rx*.48,y+1,-fd-reach+3],"glass","paint")];
 }
 if(style==="pod"){for(let [k,q] of [[-1,"l"],[1,"r"]]){let x=k*(tw+3);s.parts=s.parts.filter(p=>p.name!==q+"a_forearm");P(q+"a").shapes=[Y([[top-11,x-2.5,x+2.5,-3,3,.15],[top-7,x-3,x+3,-4,4,.18],[top-3,x-2.5,x+2.5,-3,3,.13]])];let p=P(q+"a_weapon");p.parent=q+"a";let z=-fd-5,y=top-8,pts=Array.from({length:4},(_,i)=>[x+(i%2-.5)*2,y+(Math.floor(i/2)-.5)*2,z]);p.shapes=[Z([[z,x-3.1,x+3.1,y-2.8,y+2.8,.13],[-2,x-2.8,x+2.8,y-2.8,y+2.8,.15]]),...pts.map(([a,c])=>cyl("z",z,z+3,a,c,.8,.8,"gun","subtract"))];s.muzzles[q.toUpperCase()+"A"]=pts;}}
 if(id==="highlander_iic"){let p=P("la_weapon"),x=-armx,z=-15,pts=Array.from({length:12},(_,i)=>[x+(i%3-1)*2,gy+(Math.floor(i/3)-1.5)*2,z]);p.shapes=[Z([[z,x-4.3,x+4.3,gy-5,gy+5,.13],[z+3,x-4.3,x+4.3,gy-5,gy+5,.13],[-2,x-aw*.8,x+aw*.8,gy-aw*.8,gy+aw*.8,.12]]),...pts.map(([a,c])=>cyl("z",z,z+3,a,c,.8,.8,"gun","subtract"))];s.muzzles.LA=pts;}
 function battery(q,n,y,raised=false,long=false){
  if(!n)return;let k=q==="l"?-1:1,x=k*(tw*.72),loc=q.toUpperCase()+"T",cols=n===20?4:n===15?3:n===10?2:n===6?2:n===5?2:n===4?2:n===3?3:n===2?2:1,rows=Math.ceil(n/cols),rw=Math.max(2.5,cols+1),rh=Math.max(2.5,rows+1),z=-fd-(long?10:4),back=raised?bd*.65:-fd+3,pts=Array.from({length:n},(_,i)=>[Math.floor(x+2*(i%cols-(cols-1)/2))+.5,Math.floor(y+2*(Math.floor(i/cols)-(rows-1)/2))+.5,z]);
  let shape=Z([[z,x-rw,x+rw,y-rh,y+rh,.1],[z+3,x-rw,x+rw,y-rh,y+rh,.12],[back,x-rw*.86,x+rw*.86,y-rh*.85,y+rh*.85,.16]]);
  let shapes=[shape,...pts.map(([a,c])=>cyl("z",z,z+3,a,c,n===1?1:.8,n===1?1:.8,"gun","subtract"))];if(raised)shapes.push(B([x-2,top-6,-2],[x+2,Math.max(top,y+1),3],"frame"));
  part(q+"t_battery",loc,"ct",[x,y,back],shapes);s.muzzles[loc]=pts;
 }
 for(let [q,n] of [["l",ln],["r",rn]]){let raised=style==="twin_tower"||style==="sword"||id==="highlander_iic";let y=raised?top+3:top-6;battery(q,n,y,raised,id==="hunchback_iic");}
 if(id==="mackie"||id==="ostsol"||id==="ostroc")for(let [k,q] of [[-1,"l"],[1,"r"]])battery(q,id==="mackie"?1:2,top-12,false,id==="mackie");
 if(id==="avatar"||id==="jenner_iic"||id==="locust_iic"){let n=id==="avatar"?2:id==="jenner_iic"?6:1,z=-fd-3,y=top-13,cols=n===6?3:n,rows=Math.ceil(n/cols),pts=Array.from({length:n},(_,i)=>[(i%cols-(cols-1)/2)*2,y+(Math.floor(i/cols)-(rows-1)/2)*2,z]);part("ct_rack","CT","ct",[0,y,-fd],[B([-cols-1,y-rows-1,z],[cols+1,y+rows+1,-fd+3],"plate"),...pts.map(([a,c])=>cyl("z",z,z+3,a,c,.8,.8,"gun","subtract"))]);s.muzzles.CT=pts;}
 if(style==="fins"||style==="sword")for(let [k,q] of [[-1,"l"],[1,"r"]]){let x=k*tw*.6;part(q+"t_fin",q.toUpperCase()+"T","ct",[x,top-3,bd-1],[Y([[top-7,x-2,x+2,bd-2,bd+3,.13],[top-1,x-2.5,x+2.5,bd-1,bd+4,.15],[top+6,x-1.4,x+1.4,bd+1,bd+4,.13]])]);}
 if(style==="horns"){for(let [k,q] of [[-1,"l"],[1,"r"]]){let x=k*2.5;part(q+"h_horn","HD","hd",[x,top+2,0],[Y([[top+2,x-1.5,x+1.5,-1.5,1.5,.1],[top+5,x+k*.5-1,x+k*.5+1,-.5,1.6,.13],[top+8,x+k*1.2-.7,x+k*1.2+.7,.2,1.8,.13]])]);}}
 if(style==="sword"){let p=P("ra_hand"),[x,y,z]=p.pivot;part("ra_sword","RA","ra_hand",[x,y-2,z],[cyl("y",y-8,y+2,x,z,1.2,1.2,"frame"),B([x-3,y-8,z-1.3],[x+3,y-6,z+1.3],"frame"),loft("y",[[y-23,[[x-.3,z-.2],[x+.3,z-.2],[x+.3,z+.2],[x-.3,z+.2]]],[y-21,[[x-1.7,z-.6],[x+1.7,z-.6],[x+1.7,z+.6],[x-1.7,z+.6]]],[y-7,[[x-1.7,z-.6],[x+1.7,z-.6],[x+1.7,z+.6],[x-1.7,z+.6]]]],"plate")]);}
 if(style==="sensor"){let y=top;part("ct_sensor","CT","ct",[0,y-1,2],[cyl("y",y-1,y+5,0,2,1.5,1.5,"frame"),cyl("y",y+3,y+6,0,2,4,3,"plate")]);}
 return s;
}
;author
