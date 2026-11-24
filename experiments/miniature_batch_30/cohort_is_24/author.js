// Inner Sphere component reconstruction, based on individually specified silhouettes.
// Independent experimental geometry, not a production-format or variant guarantee.
function author(lib,base,row){
 const s=base(lib,row),{L,B,cyl,loft,ellipse,clone}=lib;
 const [id,name,pitch,legs,w,h,tw,fd,bd,top,th,sh,aw,fw,head,shoulder,lgun,rgun,lr,rr,ln,rn]=row.profile;
 const Y=(v,m="plate")=>L("y",v,m),X=(v,m="plate")=>L("x",v,m),Z=(v,m="plate")=>L("z",v,m);
 const P=n=>s.parts.find(p=>p.name===n),sym=(f)=>[-1,1].forEach(k=>f(k,k<0?"l":"r"));
 function part(name,loc,parent,pivot,shapes){s.parts.push({name,loc,parent,pivot,shapes});}
 function replace(name,shapes){P(name).shapes=shapes;}
 const center=(k,q)=>k*(tw+5);
 const armY=top-5-8-6+2;
 function rack(q,count,cols,rh,depth){
  let k=q==="l"?-1:1,x=center(k,q),loc=q.toUpperCase()+"A",y=armY,z=-depth,back=-Math.floor(aw*.8)+1,rows=Math.ceil(count/cols),gap=2,rx=(cols-1)+1.8;
  let pts=Array.from({length:count},(_,i)=>[x+(i%cols-(cols-1)/2)*gap,y+(Math.floor(i/cols)-(rows-1)/2)*gap,z]);
  replace(q+"a_weapon",[Z([[z,x-rx,x+rx,y-rh,y+rh,.13],[z+4,x-rx,x+rx,y-rh,y+rh,.13],[back,x-aw*.78,x+aw*.78,y-aw*.78,y+aw*.78,.1]]),...pts.map(([a,b])=>cyl("z",z,z+3,a,b,.8,.8,"gun","subtract"))]);s.muzzles[loc]=pts;
 }
 function barrel(q,length,radius,offset=0){
  let k=q==="l"?-1:1,x=center(k,q),loc=q.toUpperCase()+"A",y=armY+offset,z=-length,back=-Math.floor(aw*.8)+1;
  replace(q+"a_weapon",[cyl("z",z,back,x,y,radius,radius,"gun"),Z([[z+3,x-radius-1,x+radius+1,y-radius-1,y+radius+1,.2],[back,x-aw*.76,x+aw*.76,y-aw*.76,y+aw*.76,.15]],"plate"),cyl("z",z,z+4,x,y,.9,.9,"gun","subtract")]);s.muzzles[loc]=[[x,y,z]];
 }
 function chest(q,name,n,x,y,z,r,cols=1){
  let loc=q==="c"?"CT":q.toUpperCase()+"T",rows=Math.ceil(n/cols),pts=Array.from({length:n},(_,i)=>[x+(i%cols-(cols-1)/2)*2,y+(Math.floor(i/cols)-(rows-1)/2)*2,z]);
  let back=-fd+2,rx=Math.max(r,cols),ry=Math.max(r,rows);
  part(name,loc,"ct",[x,y,back],[Z([[z,x-rx,x+rx,y-ry,y+ry,.15],[back,x-rx,x+rx,y-ry,y+ry,.1]]),...pts.map(([a,b])=>cyl("z",z,z+3,a,b,.8,.8,"gun","subtract"))]);s.muzzles[loc]=pts;
 }
 function jets(style){
  sym((k,q)=>{let x=k*(tw*.62),y=top-8,lo=y-4,hi=style==="fin"?top+5:top-1,z=bd-1;
   part(q+"t_jump_pack",q.toUpperCase()+"T","ct",[x,y,z],[Y([[lo,x-2,x+2,z,z+4,.15],[y,x-2.5,x+2.5,z,z+4,.15],[hi,x-1.6,x+1.6,z+1,z+3,.18]],"plate")]);});
 }
 function crest(){
  let p=P("hd"),y=p.pivot[1];p.shapes.push(Y([[y+3,-1,1,-3,1,.1],[y+7,-.8,.8,-1,1,.15]],"plate"));
 }
 if(id==="marauder_ii"){
  replace("ct",[Y([[w+3,-5,5,-3,4,.1],[w+6,-tw*.66,tw*.66,-fd*.66,bd*.8,.2],[top-9,-tw,tw,-fd,bd,.22],[top-4,-tw*.94,tw*.94,-fd*.72,bd,.3],[top,-tw*.48,tw*.48,-fd*.35,bd*.78,.2]],"armor")]);
  sym((k,q)=>barrel(q,20,2.2));
  part("dorsal_cannon","RT","ct",[2,top-2,3],[B([0,top-4,1],[4,top+3,6],"frame"),cyl("z",-16,9,2,top+3,2.1,2.1),cyl("z",-16,-12,2,top+3,.9,.9,"gun","subtract")]);s.muzzles.RT=[[2,top+3,-16]];
 }else if(id==="orion"){
  barrel("r",19,2.6);chest("r","rt_autocannon",1,tw*.55,top-13,-fd-4,2.6);
 }else if(id==="crusader"){
  sym((k,q)=>rack(q,15,5,4.3,13));
  sym((k,q)=>{let x=k*(h+2),y=8,z=-Math.round(sh*.8);part(q+"l_srm_face",q.toUpperCase()+"L",q+"l_shin",[x,y,z],[B([x-2,y-2,z-3],[x+2,y+2,z+1]),...[-1,1].map(a=>cyl("z",z-3,z-1,x+a,y,.7,.7,"gun","subtract"))]);});
 }else if(id==="grasshopper"){
  jets("pack");chest("c","ct_laser",1,0,top-14,-fd-3,2.1);
 }else if(id==="wolfhound"){
  barrel("r",18,1.7);chest("c","ct_laser",1,0,top-14,-fd-3,1.8);
 }else if(id==="longbow"){
  sym((k,q)=>rack(q,20,4,6.3,15));
  replace("hd",[Z([[-fd-5,-2.4,2.4,top-10,top-5,.2],[-fd-2,-3.4,3.4,top-11,top-3,.18],[-fd+2,-3,3,top-10,top-3,.18]]),B([-2,top-9,-fd-5],[2,top-6,-fd-3],"glass","paint")]);
 }else if(id==="zeus"){
  barrel("l",20,2.4);rack("r",15,3,5.7,14);crest();
 }else if(id==="nightstar"){
  sym((k,q)=>barrel(q,22,2.6));
  replace("hd",[Z([[-fd-3,-4.5,4.5,top-9,top-3,.25],[-fd+2,-5.5,5.5,top-10,top-2,.18]]),B([-3.5,top-7,-fd-3],[3.5,top-5,-fd-1],"glass","paint")]);
 }else if(id==="cataphract"){
  barrel("l",19,2.3);chest("r","rt_cannon",1,tw*.45,top-12,-fd-4,2.1);
 }else if(id==="axman"){
  barrel("l",19,2.8);let p=P("ra_hand"),[x,y,z]=p.pivot;
  part("ra_axe","RA","ra_hand",[x,y-1,z],[cyl("y",y-12,y+7,x,z,1.1,1.1,"frame"),Z([[z-2,x-1,x+1,y-11,y+3,.06],[z+1,x-1,x+1,y-11,y+3,.06]],"frame"),X([[x-1,y+3,y+9,z-8,z+2,.08],[x+1,y+3,y+9,z-8,z+2,.08]],"plate")]);s.punch=true;
 }else if(id==="bushwacker"){
  barrel("l",21,2);replace("hd",[Z([[-fd-8,-2.4,2.4,top-10,top-6,.18],[-fd-4,-3.4,3.4,top-11,top-4,.17],[-fd+2,-4.2,4.2,top-12,top-2,.2]]),B([-2.6,top-8,-fd-8],[2.6,top-6,-fd-5],"glass","paint")]);
 }else if(id==="victor"){
  barrel("r",20,3);jets("pack");
 }else if(id==="thug"){
  sym((k,q)=>barrel(q,19,2.5));
 }else if(id==="spider"){
  jets("fin");crest();
 }else if(id==="valkyrie"){
  barrel("r",10,1.6);jets("pack");
 }else if(id==="stinger"){
  barrel("r",10,1.4);jets("pack");
 }else if(id==="wasp"){
  barrel("r",11,1.6);jets("fin");
 }else if(id==="black_knight"){
  barrel("r",19,2.1);crest();chest("c","ct_laser",1,0,top-13,-fd-4,2.1);
 }else if(id==="king_crab"){
  replace("ct",[Y([[w+3,-5,5,-3,4,.1],[w+6,-tw*.83,tw*.83,-fd*.77,bd*.9,.2],[top-10,-tw,tw,-fd,bd,.24],[top-4,-tw*.98,tw*.98,-fd,bd,.28],[top,-tw*.65,tw*.65,-fd*.5,bd*.7,.3]],"armor")]);
  sym((k,q)=>{let x=center(k,q),y=armY,z=-18,back=-Math.floor(aw*.8)+1;
   replace(q+"a_weapon",[Z([[z,x-3.7,x+3.7,y-3.1,y+3.1,.25],[z+5,x-5.1,x+5.1,y-4.1,y+4.1,.25],[back,x-aw*.85,x+aw*.85,y-aw*.85,y+aw*.85,.15]],"plate"),cyl("z",z,z+5,x,y,2,2,"gun","subtract")]);s.muzzles[q.toUpperCase()+"A"]=[[x,y,z]];});
 }else if(id==="guillotine"){
  barrel("r",15,1.9);jets("pack");
 }else if(id==="flashman"){
  replace("ct",[loft("y",[[w+3,ellipse(0,0,5,4,20)],[w+6,ellipse(0,0,tw*.8,fd*.8,20)],[top-9,ellipse(0,0,tw,fd,20)],[top-3,ellipse(0,0,tw,fd,20)],[top,ellipse(0,0,tw*.68,fd*.7,20)]],"armor")]);
  chest("c","ct_laser",1,0,top-14,-fd-4,2.2);
 }else if(id==="sentinel"){
  barrel("r",17,2.1);barrel("l",10,1.4);
 }else if(id==="vindicator"){
  barrel("r",17,1.9);jets("pack");
 }else if(id==="kintaro"){
  rack("l",6,3,3.3,11);barrel("r",11,1.5);
 }
 return s;
}
;author