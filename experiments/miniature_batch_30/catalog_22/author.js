// Experimental catalog-photo component sculpts. Not production recipes.
function author(lib,base,row){
 const [id,unit,name,photo,pitch,legs,w,h,tw,fd,bd,top,th,sh,aw,fw,head,shoulder,lgun,rgun,ln,rn,note]=row;
 const reference="https://jadedfalconer.com/Pictures/CGLminis/"+photo+".jpg";
 const s=base(lib,{profile:[id,name,pitch,legs,w,h,tw,fd,bd,top,th,sh,aw,fw,head,shoulder,lgun,rgun,"","",0,0,note],reference});
 s.unit=unit;s.reference=reference;s.anatomy=note;const {L,B,cyl,loft,ellipse}=lib,P=n=>s.parts.find(p=>p.name===n),Y=(a,m="plate")=>L("y",a,m),Z=(a,m="plate")=>L("z",a,m),X=(a,m="plate")=>L("x",a,m);
 const part=(name,loc,parent,pivot,shapes)=>s.parts.push({name,loc,parent,pivot,shapes});
 const sym=f=>[-1,1].forEach((k,i)=>f(k,i?"r":"l"));
 const body=(a)=>P("ct").shapes=[Y(a,"armor")];
 const armless=["cicada","flea","hoplite"].includes(id);
 if(armless){s.parts=s.parts.filter(p=>!/^([lr]a)/.test(p.name));s.muzzles={};s.punch=false;}
 if(["annihilator","grizzly","gunslinger","hoplite"].includes(id)){
  const radii=id==="hoplite"?[.68,1,.94,.68]:id==="annihilator"?[.66,.94,1,.77]:[.73,1,.94,.71];
  P("ct").shapes=[loft("y",[[w+3,ellipse(0,0,5,4,20)],[w+6,ellipse(0,0,tw*radii[0],fd*.8,20)],[top-8,ellipse(0,0,tw*radii[1],fd,20)],[top-3,ellipse(0,0,tw*radii[2],fd*.88,20)],[top,ellipse(0,0,tw*radii[3],bd*.72,20)]],"armor")];
 }else if(["assassin","cicada","flea","chameleon","exterminator"].includes(id)){
  body([[w+3,-5,5,-3,4,.1],[w+6,-tw*.67,tw*.67,-fd*.7,bd*.8,.23],[top-10,-tw*.89,tw*.89,-fd,bd,.22],[top-4,-tw,tw,-fd*.87,bd*.8,.19],[top,-tw*.65,tw*.65,-fd*.55,bd*.75,.21]]);
 }else if(["battle_cobra","black_lanner","emperor","helios","devastator","dervish"].includes(id)){
  body([[w+3,-5,5,-3,4,.09],[w+6,-tw*.66,tw*.66,-fd*.72,bd*.8,.16],[top-10,-tw*.87,tw*.87,-fd,bd,.21],[top-4,-tw,tw,-fd*.83,bd,.18],[top,-tw*.83,tw*.83,-fd*.62,bd*.8,.22]]);
 }
 // Distinctive nose and helm structures.
 if(["black_lanner","cicada","flea","hoplite","caesar","chameleon","exterminator","griffin_iic"].includes(id)){
  let y=top-6,rx=id==="hoplite"?tw*.78:id==="flea"?2.4:id==="black_lanner"?4.5:id==="caesar"?3.4:3.5,reach=id==="black_lanner"?8:id==="hoplite"?4:id==="cicada"?5:4,front=-fd-reach;
  P("hd").shapes=[Z([[front,-rx*.6,rx*.6,y-3,y+1,.22],[front+2,-rx,rx,y-4,y+3,.24],[-fd+2,-rx*.9,rx*.9,y-3,y+5,.18]],"plate"),B([-rx*.55,y-1,front],[rx*.55,y+2,front+2],"glass","paint")];
 }
 if(["crockett","emperor","gunslinger","helios","devastator"].includes(id)){
  let y=top-5,rx=id==="gunslinger"?4.2:3.4;P("hd").shapes=[Z([[-fd-3,-rx*.72,rx*.72,y-2,y+2,.18],[-fd,-rx,rx,y-3,y+4,.19],[-fd+2,-rx*.8,rx*.8,y-2,y+3,.18]],"plate"),B([-rx*.65,y,-fd-3],[rx*.65,y+2,-fd-1],"glass","paint")];
 }
 // Explicit front weapons: matched apertures, independent parented housings.
 function battery(q,n,y,kind="rack",extra=0){
  if(!n)return;let k=q==="l"?-1:1,x=k*(tw*.72),loc=q.toUpperCase()+"T",cols=n===15?5:n===10?2:n===6?2:n===5?2:n===2?2:1,nr=Math.ceil(n/cols),rw=Math.max(2.25,cols+1),rh=Math.max(2.2,nr+1),front=-fd-3-extra,back=-fd+3;
  if(armless){x=k*(tw+1);back=2;front=-fd-5-extra;rw=2.5;rh=2.5;}
  if(id==="crockett"||id==="howler"||id==="helios"){back=bd*.4;front=-fd-2-extra;}
  let pts=Array.from({length:n},(_,j)=>[x+2*(j%cols-(cols-1)/2),y+2*(Math.floor(j/cols)-(nr-1)/2),front]);
  let housing=kind==="round"?cyl("z",front,back,x,y,rw,rh,"plate"):Z([[front,x-rw,x+rw,y-rh,y+rh,.12],[front+3,x-rw,x+rw,y-rh,y+rh,.14],[back,x-rw*.82,x+rw*.82,y-rh*.84,y+rh*.84,.18]]);
  const parent=armless?q+"t":"ct";let shapes=[housing,...pts.map(([a,b])=>cyl("z",front,front+3,a,b,n===1?1:.8,n===1?1:.8,"gun","subtract"))];
  if(y>top-3)shapes.push(B([x-1.5,top-5,-2],[x+1.5,y+1,2],"frame"));
  part(q+"t_battery",loc,parent,[x,y,back],shapes);s.muzzles[loc]=pts;
 }
 for(let [q,n] of [["l",ln],["r",rn]]){let y=id==="crockett"?top+2:id==="howler"?top+3:id==="helios"?top+2:id==="black_lanner"?top-4:id==="dervish"?top-7:id==="devastator"?top-12:top-7;battery(q,n,y,["helios","hoplite","cicada","flea","devastator","emperor"].includes(id)?"round":"rack",id==="hoplite"&&q==="r"?4:0);}
 if(id==="annihilator")sym((k,q)=>battery(q,1,top-8,"round",1));
 if(id==="hermes_ii"){let y=top-11,z=-fd-4;part("ct_cannon","CT","ct",[0,y,-fd],[cyl("z",z,-fd+2,0,y,2.2,2.2,"plate"),cyl("z",z,z+3,0,y,1,1,"gun","subtract")]);s.muzzles.CT=[[0,y,z]];}
 // Shoulder panels and different dorsal details are separate supported parts.
 if(["battle_cobra","devastator","hatamoto_chi"].includes(id))sym((k,q)=>{
  let x=k*(tw+3),y=top-5,xx=k*(tw+4),hi=id==="hatamoto_chi"?top+6:id==="devastator"?top+2:top+1;
  part(q+"a_guard",q.toUpperCase()+"A",q+"a",[x,y,0],[Y([[y-2,xx-2.4,xx+2.4,-aw,aw,.16],[y+2,xx-3,xx+3,-aw-1,aw+1,.2],[hi,xx-2,xx+2,-aw*.72,aw*.85,.23]],"plate")]);
 });
 if(["hatamoto_chi","griffin_iic","hermes_ii","chameleon"].includes(id))sym((k,q)=>{
  let x=k*2.2,y=id==="hatamoto_chi"?top+3:id==="hermes_ii"?top+3:top-2,parent=["hatamoto_chi","hermes_ii"].includes(id)?"hd":"ct";
  part(q+"h_crest",parent==="hd"?"HD":"CT",parent,[x,y,0],[Y([[y,x-1.5,x+1.5,-1.3,1.4,.08],[y+3,x+k*.8-1.1,x+k*.8+1.1,-.5,1.4,.15],[y+6,x+k*1.8-.7,x+k*1.8+.7,0,1.5,.12]],"plate")]);
 });
 if(["caesar","grizzly","flea"].includes(id)){
  let y=id==="flea"?top:top-1;part("ct_antenna","CT","ct",[0,y,2],[cyl("y",y,y+5,0,2,1.1,1.1,"frame"),...(id==="flea"?[cyl("y",y+4,y+6,0,2,2.5,2.5,"plate")]:[])]);
 }
 if(["assassin","chameleon","exterminator","dervish","clint"].includes(id))sym((k,q)=>{
  let x=k*tw*.55,y=top-5,z=bd-1;
  part(q+"t_backpack",q.toUpperCase()+"T","ct",[x,y,z],[Y([[y-7,x-2,x+2,z,z+3,.16],[y-2,x-2.5,x+2.5,z,z+4,.19],[y+4,x-2,x+2,z,z+3,.21]])]);
 });
 if(id==="hatamoto_chi")sym((k,q)=>{let x=k*(h-1);part(q+"t_skirt","CT","pelvis",[x,w-1,-3],[Z([[-7,x-2.8,x+2.8,w-7,w-1,.15],[-5,x-3,x+3,w-7,w+1,.15],[-2,x-2.5,x+2.5,w-5,w+1,.1]])]);});
 return s;
}
;author
