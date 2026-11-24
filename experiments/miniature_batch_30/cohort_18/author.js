function build(lib,id){
const {assembly,L,B,cyl,loft,ellipse,sidePart}=lib,Y=(a,m)=>L("y",a,m),Z=(a,m)=>L("z",a,m),X=(a,m)=>L("x",a,m);
const conf={
blackjack:["Blackjack BJ-2",.045,23,13,4,6,8,5,5,36,42,3.2,3.5,3.3,3.3,4.5,6,4, "box","gun","gun",10,8],
archer:["Archer ARC-2R",.05,22,11,4,7,10,7,6,35,42,3.5,4.2,4.5,4,5.6,7,4.5,"round","fist","fist",0,0],
awesome:["Awesome AWS-8Q",.055,23,12,4,8,12,7,6,37,40,4.1,5,4.8,4.4,5.8,7,4.5,"round","fist","gun",0,8],
banshee:["Banshee BNC-3S",.053,24,13,4,7,9,6,5,38,43,3.9,4.5,3.9,3.7,5,7,4,"shield","gun","fist",7,0],
battlemaster:["BattleMaster BLR-1G",.053,23,12,4,7,10,7,6,36,43,3.8,4.5,4.4,3.6,5.3,7,4,"shield","fist","gun",0,9],
centurion:["Centurion CN9-A",.046,24,13,4,6,7.5,5,4.5,37,42,3,3.3,3.4,2.8,4.5,6,4,"box","fist","gun",0,10],
charger:["Charger CGR-3K",.05,24,13,4,7,9,6,5,37,42,3.7,4.3,4,3.7,5,6.5,4,"shield","gun","fist",6,0],
enforcer:["Enforcer ENF-5D",.045,23,12,4,6,8,6,5,36,42,3,3.6,3.2,3,4.5,6,3.6,"box","gun","gun",6,11],
hatchetman:["Hatchetman HCT-3F",.043,24,13,4,6,7,5,4.5,37,41,2.7,3.2,2.8,2.5,4.4,6,3.5,"round","fist","axe",0,0],
highlander:["Highlander HGN-694",.054,23,12,4,8,10,7,6,38,43,4.3,4.5,4.6,4,5.6,7,4.5,"round","fist","gun",0,9],
hunchback:["Hunchback HBK-4G",.048,22,11,4,7,9,6,5,35,39,3.8,4.2,4,3.2,5,6.5,4,"box","fist","fist",0,0],
jagermech:["JagerMech JM6-S",.05,22,11,4,7,10,5.5,6,37,40,3.9,3.8,4,3,5.4,6,4,"high","dual","dual",10,10],
phoenix_hawk:["Phoenix Hawk PXH-1",.045,24,13,4,6,8,5.5,5,37,42,3.1,3.4,3.3,3.1,4.4,6.4,3.5,"shield","fist","gun",0,8],
trebuchet:["Trebuchet TBT-5N",.046,24,13,4,6,8,5.5,4.5,37,42,3,3.4,3.3,3,4.4,6,3.5,"round","rack","gun",0,4],
warhammer:["Warhammer WHM-6R",.05,23,12,4,7,10,6,5.5,37,41,3.7,4.4,4.1,3.6,5.2,7,4,"box","gun","gun",14,14],
atlas:["Atlas AS7-D",.056,23,12,4,8,12,7,6,38,40,4.8,5,5,4.5,6,7,4.5,"round","fist","fist",0,0]
};
if(["catapult","adder","locust"].includes(id)){
const a=id==="catapult",b=id==="adder",name=a?"Catapult CPLT-C1":b?"Adder Prime":"Locust LCT-1V";
let {spec,part}=assembly(id,name,a?.048:b?.042:.036,"digitigrade");spec.unit=a?"catapult_cplt_c1":b?"adder_prime":"locust_lct1v";
let s=a?8:b?7:5,hipY=a?23:b?21:22,bodyY=a?29:b?31:31,roof=a?39:b?42:37,front=a?-18:b?-13:-17;
part("pelvis","CT",null,[0,hipY,2],[Y([[hipY-3,-s,s,-2,7,.18],[hipY,-s-1,s+1,-3,7,.15],[hipY+3,-s+1,s-1,-2,6,.12]],"frame")]);
part("ct","CT","pelvis",[0,hipY+3,2],[Z(a?[[-6,-5,5,26,37,.25],[0,-9,9,25,39,.25],[7,-10,10,26,39,.25],[12,-6,6,28,35,.26]]:b?[[-6,-8,8,26,38,.12],[0,-10,10,25,42,.13],[7,-10,10,26,42,.16],[11,-7,7,30,39,.19]]:[[-5,-4,4,26,35,.15],[1,-6,6,25,38,.17],[7,-5,5,27,35,.2]],"armor")]);
part("hd","HD","ct",[0,bodyY,-6],[Z([[front,-2.5,2.5,bodyY-4,bodyY+1,.25],[front+3,-4.5,4.5,bodyY-5,bodyY+4,.22],[-9,-5.5,5.5,bodyY-4,bodyY+6,.23],[-6,-5,5,bodyY-3,bodyY+7,.18]],"plate"),B([-3,bodyY,front+2],[3,bodyY+2,front+4],"glass","paint")]);
let sym=(n,loc,parent,p,sh,j)=>{for(let q of ["l","r"])sidePart(part,q,n,q.toUpperCase()+loc,typeof parent==="function"?parent(q):parent,p,sh,j)};
let sx=a?10:b?10:6;
sym("t","T","ct",[sx,bodyY+2,1],[X([[sx-1,bodyY-3,bodyY+5,-3,5,.12],[sx+2,bodyY-3,bodyY+5,-3,5,.14],[sx+3,bodyY-2,bodyY+4,-2,4,.2]],"plate")]);
if(a){for(let q of ["l","r"]){let x=(q==="l"?-1:1)*15,y=43;
part(q+"a",q.toUpperCase()+"A",q+"t",[x,bodyY+3,0],[B([x-2,bodyY,x===0?0:-2],[x+2,y-4,3],"frame"),Z([[-5,x-5,x+5,y-5,y+4,.1],[4,x-5,x+5,y-5,y+4,.13]],"plate"),...Array.from({length:15},(_,i)=>cyl("z",-5,-2,x+(i%5-2)*1.65,y-3+Math.floor(i/5)*2,.62,.62,"gun","subtract"))],"shoulder");part(q+"a_lid",q.toUpperCase()+"A",q+"a",[x,y+4,2],[Y([[y+4,x-5,x+5,1,4,.05],[y+11,x-4.8,x+4.8,2,5,.08]],"plate")]);spec.muzzles[q.toUpperCase()+"A"]=Array.from({length:15},(_,i)=>[x+(i%5-2)*1.65,y-3+Math.floor(i/5)*2,-5])}}
else if(b){sym("a","A",q=>q+"t",[sx+3,bodyY,0],[X([[sx+3,bodyY-3,bodyY+3,-4,4,.1],[sx+6,bodyY-3,bodyY+3,-4,4,.16]],"frame")],"shoulder");for(let q of ["l","r"]){let x=(q==="l"?-1:1)*(sx+5),y=bodyY-3;part(q+"a_ppc",q.toUpperCase()+"A",q+"a",[x,y,-3],[Z([[-17,x-2.6,x+2.6,y-2.6,y+2.6,.22],[-10,x-3,x+3,y-3,y+3,.16],[-3,x-3,x+3,y-3,y+4,.1]],"plate"),cyl("z",-17,-14,x,y,1.4,1.4,"gun","subtract")]);spec.muzzles[q.toUpperCase()+"A"]=[x,y,-17]}}
else {sym("a","A",q=>q+"t",[sx+3,bodyY+2,0],[X([[sx+3,bodyY,bodyY+5,-4,4,.12],[sx+6,bodyY,bodyY+4,-4,4,.15]],"plate")],"shoulder");for(let q of ["l","r"]){let x=(q==="l"?-1:1)*(sx+4);part(q+"a_mg",q.toUpperCase()+"A",q+"a",[x,bodyY+1,-4],[cyl("z",-12,-4,x,bodyY+1,1.45,1.45),cyl("z",-12,-9,x,bodyY+1,.6,.6,"gun","subtract")]);spec.muzzles[q.toUpperCase()+"A"]=[x,bodyY+1,-12]}part("hd_antenna","HD","ct",[1,roof-1,2],[Y([[roof-1,0,2,1,3,.04],[roof+9,0,1.5,4,5.5,.04]],"frame")]);}
let k=a?13:b?12:12,hock=a?5:5;
sym("l","L","pelvis",[s-2,hipY-3,2],[Y([[k,s-1,s+4,a?3:5,a?9:10,.15],[k+4,s-2,s+4,2,9,.18],[hipY-3,s-4,s+1,0,6,.12]],"armor")],"hip");
sym("l_shin","L",q=>q+"l",[s+1,k,6],[Y([[hock,s-1,s+4,-2,3,.12],[hock+3,s-1,s+4,0,6,.15],[k,s-1,s+4,a?3:5,a?9:10,.12]],"plate")],"knee");
sym("l_tarsus","L",q=>q+"l_shin",[s+1,hock,1],[Y([[3,s-1,s+3,-2,3,.08],[hock,s-1,s+4,-2,3,.08]],"frame")],"hock");
sym("l_foot","L",q=>q+"l_tarsus",[s+1,3,1],[Y([[0,s-3,s+6,-7,6,.22],[2,s-3,s+6,-6,5,.17],[3,s-1,s+3,-2,3,.1]],"plate")],"ankle");
return spec;
}
let c=conf[id], [name,pitch,w,k,f,h,tw,td,tb,sy,top,th,sh,arm,fore,fw,ff,fb,style,la,ra,lg,rg]=c;
let {spec,part}=assembly(id,name,pitch,"plantigrade");spec.unit=id;spec.punch=la==="fist"||ra==="fist";
let sym=(n,loc,parent,p,sh,j)=>{for(let q of ["l","r"])sidePart(part,q,n,q.toUpperCase()+loc,typeof parent==="function"?parent(q):parent,p,sh,j)};
let yr=(y,x,r,z,d,ch=.16)=>[y,x-r,x+r,z-d,z+d,ch];
part("pelvis","CT",null,[0,w,0],[Y([[w-4,-h-2,h+2,-3,4,.18],[w,-h-3,h+3,-4,4,.16],[w+3,-4.5,4.5,-3,3,.1]],"frame")]);
let wa=id==="centurion"||id==="hatchetman"||id==="phoenix_hawk"? .57:.7;
part("ct","CT","pelvis",[0,w+3,0],[Y([[w+3,-4.5,4.5,-3,3,.1],[w+6,-tw*wa,tw*wa,-td*.78,tb*.85,.2],[sy-3,-tw,tw,-td,tb,.19],[sy+2,-tw*.95,tw*.95,-td*.85,tb,.15],[top,-tw*.65,tw*.65,-td*.55,tb*.65,.18]],"armor")]);
let hx=id==="archer"?4:id==="atlas"?5:id==="highlander"?4.7:id==="hatchetman"?3.6:3.4,hy=id==="archer"?sy-5:id==="atlas"?sy-1:id==="awesome"?sy+1:top,hh=id==="archer"?10:id==="atlas"?6:id==="jagermech"?4:6;
if(id==="archer"){part("hd","HD","ct",[0,sy-4,-td+1],[Z([[-td-5,-3,3,sy-8,sy-2,.2],[-td-2,-hx,hx,sy-8,sy+1,.18],[-td+1,-hx,hx,sy-5,sy+7,.15]],"plate"),B([-2,sy-6,-td-5],[2,sy-3,-td-3],"glass","paint")])}
else if(id==="atlas"){part("hd","HD","ct",[0,hy,-td+2],[Z([[-td-3,-3.6,3.6,hy-2,hy+3,.16],[-td,-hx,hx,hy-3,hy+5,.16],[-td+3,-hx,hx,hy-3,hy+5,.22]],"plate"),B([-3,hy+1,-td-3],[-1,hy+3,-td-1],"glass","paint"),B([1,hy+1,-td-3],[3,hy+3,-td-1],"glass","paint")])}
else {let head=id==="battlemaster"?loft("y",[[hy,ellipse(0,-2,3.2,3.7,16)],[hy+2,ellipse(0,-2,4,4.4,16)],[hy+4,ellipse(0,-2,3.6,4.3,16)],[hy+6,ellipse(0,-1,2.6,2.9,16)]],"glass"):Y([[hy,-hx*.76,hx*.76,-3.5,2.7,.12],[hy+2,-hx,hx,-4.8,3.5,.2],[hy+hh-2,-hx*.9,hx*.9,-4.4,3,.17],[hy+hh,-hx*.65,hx*.65,-2.8,2.4,.12]],"plate");part("hd","HD","ct",[0,hy,-1],[head,B([-hx*.75,hy+1,-4.8],[hx*.75,hy+3,-3.2],"glass","paint")])}
let attach=tw*.82,s=tw+3,ax=s+2;
sym("t","T","ct",[attach,sy,0],[X([[attach,sy-5,sy+3,-td*.65,tb*.85,.1],[tw,sy-5,sy+3,-td*.6,tb,.14],[s,sy-4,sy+2,-td*.55,tb*.85,.15]],"plate")]);
if(id==="phoenix_hawk"){sym("t_jet","T",q=>q+"t",[tw-1,sy+2,tb-1],[Y([[sy-2,tw-4,tw+1,tb-1,tb+4,.14],[sy+5,tw-4,tw+1,tb,tb+5,.13],[top+6,tw-3,tw+1,tb+1,tb+4,.2]],"plate")])}
if(id==="awesome"){sym("t_shield","T",q=>q+"t",[s-1,sy+1,0],[Y([[sy-2,s-2,s+.5,-4,4,.06],[sy+3,s-2,s+.5,-4,4,.08],[sy+9,s-1,s+.5,-3,3,.1]],"plate")])}
let el=sy-9,wr=el-8;
for(let [q,kind,len] of [["l",la,lg],["r",ra,rg]]){let d=q==="l"?-1:1,x=d*ax,loc=q.toUpperCase()+"A",pn=q+"a";
const high=style==="high"||id==="blackjack";let cap=style==="round"?loft("x",[[s,ellipse(sy,0,3.3,arm,16)],[s+2,ellipse(sy,0,4.6,arm+1,16)],[s+5,ellipse(sy,0,3.4,arm,16)]],"plate"):X([[s,sy-3,sy+3,-arm,arm,.12],[s+2,sy-4,sy+4,-arm-1,arm+1,style==="shield"?.22:.1],[s+5,sy-3,sy+2,-arm,arm,.18]],"plate");
sidePart(part,q,"a",loc,q+"t",[s,sy,0],high?[cap]:[cap,Y([yr(el,ax,arm*.66,0,arm*.64,.1),yr(el+3,ax,arm*.85,0,arm*.8,.15),yr(sy-3,ax,arm*.7,0,arm*.7,.08)],"armor")],"shoulder");
let gY=high?sy:wr+3,gs=high?-arm:-fore,ge=gs-len;
if(high){part(pn+"_forearm",loc,pn,[x,sy,0],[Z([[gs,x-fore,x+fore,gY-fore,gY+fore,.16],[1,x-fore,x+fore,gY-fore,gY+fore,.16],[4,x-fore*.8,x+fore*.8,gY-fore*.8,gY+fore*.8,.18]],"frame")],"elbow")}
else sidePart(part,q,"a_forearm",loc,pn,[ax,el,0],[Y([yr(wr,ax,fore,-.5,fore,.15),yr(wr+3,ax,fore+.3,-.5,fore+.6,.18),yr(el,ax,arm*.66,0,arm*.64,.08)],"plate")],"elbow");
if(kind==="fist"||kind==="axe")sidePart(part,q,"a_hand",loc,pn+"_forearm",[ax,wr,-.5],[Y([yr(wr-4,ax,fore*.75,-.5,fore*.75,.2),yr(wr-2,ax,fore*.85,-.5,fore*.8,.13),yr(wr,ax,fore,-.5,fore,.08)],"frame")]);
if(kind==="gun"||kind==="dual"){let rr=kind==="dual"?1.7:Math.max(1.4,fore*.58);
let shapes=[Z([[ge,x-rr,x+rr,gY-rr,gY+rr,.22],[ge+Math.min(3,len/2),x-rr,x+rr,gY-rr,gY+rr,.2],[gs-1,x-fore*.9,x+fore*.9,gY-fore*.85,gY+fore*.85,.13],[gs+1,x-fore*.8,x+fore*.8,gY-fore*.8,gY+fore*.8,.13]],"gun"),cyl("z",ge,ge+3,x,gY,rr*.6,rr*.6,"gun","subtract")];
if(kind==="dual"){shapes.push(cyl("z",ge+2,gs+1,x,gY+3,1.45,1.45,"gun"),cyl("z",ge+2,ge+4,x,gY+3,.75,.75,"gun","subtract"))}
part(pn+"_gun",loc,pn+"_forearm",[x,gY,gs],shapes);spec.muzzles[loc]=kind==="dual"?[[x,gY,ge],[x,gY+3,ge+2]]:[x,gY,ge]}
if(kind==="axe"){part(pn+"_axe",loc,pn+"_hand",[x,wr-2,0],[cyl("y",wr-8,wr+9,x,0,1.5,1.5,"frame"),X([[x-1,wr+4,wr+9,-2,2,.08],[x+1,wr+4,wr+9,-5,2,.1]],"plate"),Z([[-8,x-1,x+1,wr+3,wr+10,.05],[-2,x-1.5,x+1.5,wr+4,wr+9,.1]],"plate")])}
if(kind==="rack"){let y=wr+2;part(pn+"_rack",loc,pn+"_forearm",[x,y,-fore],[Z([[-fore-5,x-4,x+4,y-4,y+4,.14],[-fore,x-4,x+4,y-4,y+4,.15]],"plate"),...Array.from({length:15},(_,i)=>cyl("z",-fore-5,-fore-2,x+(i%3-1)*2,y+(Math.floor(i/3)-2)*1.4,.6,.6,"gun","subtract"))]);spec.muzzles[loc]=Array.from({length:15},(_,i)=>[x+(i%3-1)*2,y+(Math.floor(i/3)-2)*1.4,-fore-5])}
}
function torsoWeapon(q,kind,x,y,depth,count=0,mount="ct"){
let name=q+"t_"+kind,loc=q.toUpperCase()+"T",front=-td-depth,back=-td+1,rad=kind==="ac20"?4.2:kind==="rack"?4.6:2.2;let pts=count?Array.from({length:count},(_,i)=>{let cols=count===20?4:count===15?3:2;return [x+(i%cols-(cols-1)/2)*1.55,y+(Math.floor(i/cols)-(Math.ceil(count/cols)-1)/2)*1.5]}):[[x,y]];
let sh=kind==="rack"||kind==="ac20"?[Z([[front,x-rad,x+rad,y-rad,y+rad,.12],[back,x-rad,x+rad,y-rad,y+rad,.14]],"plate")]:[cyl("z",front,back,x,y,rad,rad,"plate")];
for(let [xx,yy] of pts)sh.push(cyl("z",front,Math.min(front+3,back),xx,yy,kind==="ac20"?2:count?.6:1.2,kind==="ac20"?2:count?.6:1.2,"gun","subtract"));
part(name,loc,mount,[x,y,back],sh);spec.muzzles[loc]=count?pts.map(([x,y])=>[x,y,front]):[x,y,front];return name}
function topRack(q,x,y,n){let nm=q+"t_rack",lo=-5,hi=5,cols=n===20?4:n===15?3:2,r=n===20?5:n===15?4.5:3.3;let loc=q.toUpperCase()+"T";let pts=Array.from({length:n},(_,i)=>[x+(i%cols-(cols-1)/2)*1.5,y+(Math.floor(i/cols)-(Math.ceil(n/cols)-1)/2)*1.5]);part(nm,loc,q+"t",[x,sy+2,0],[B([x-2,sy+1,-2],[x+2,y-r+1,3],"frame"),Z([[lo,x-r,x+r,y-r,y+r,.11],[hi,x-r,x+r,y-r,y+r,.12]],"plate"),...pts.map(([a,b])=>cyl("z",lo,lo+3,a,b,.6,.6,"gun","subtract"))]);spec.muzzles[loc]=pts.map(([a,b])=>[a,b,lo]);return nm}
if(id==="archer"){for(let q of ["l","r"]){let x=(q==="l"?-1:1)*tw*.78,y=sy+5,n=topRack(q,x,y,20);part(q+"t_lid",q.toUpperCase()+"T",n,[x,y+5,1],[Y([[y+5,x-4,x+4,1,4,.04],[y+12,x-4,x+4,2,5,.06]],"plate")])}}
if(id==="awesome"){torsoWeapon("l","ppc",-tw*.55,sy-7,4);torsoWeapon("r","ppc",tw*.55,sy-7,4)}
if(id==="banshee"){topRack("l",-tw*.76,sy+7,6);torsoWeapon("l","ppc",-tw*.55,sy-7,3);torsoWeapon("r","ppc",tw*.55,sy-7,3)}
if(id==="battlemaster")topRack("l",-tw*.7,sy+8,6);
if(id==="centurion")torsoWeapon("l","rack",-tw*.5,sy-3,3,10);
if(id==="charger")torsoWeapon("r","rack",tw*.55,sy-3,3,10);
if(id==="hatchetman")torsoWeapon("r","cannon",tw*.52,sy-6,3);
if(id==="highlander"){torsoWeapon("l","cannon",-tw*.57,sy-5,3);torsoWeapon("r","rack",tw*.5,sy-5,3,6)}
if(id==="hunchback"){let x=tw*.82,y=sy+5;part("rt_ac20","RT","rt",[x,sy,0],[B([x-3,sy-1,-3],[x+3,y-2,4],"frame"),Z([[-td-6,x-4.5,x+4.5,y-4.5,y+4.5,.16],[5,x-4.5,x+4.5,y-4.5,y+4.5,.14]],"plate"),cyl("z",-td-6,-td-2,x,y,2.5,2.5,"gun","subtract")]);spec.muzzles.RT=[x,y,-td-6]}
if(id==="jagermech"){part("hd_radar","HD","hd",[0,top+4,1],[Y([[top+4,-1.5,1.5,0,2,.05],[top+7,-1.5,1.5,0,2,.05]],"frame"),X([[-7,top+7,top+8,0,2,.02],[7,top+7,top+8,0,2,.02]],"plate")])}
if(id==="trebuchet")torsoWeapon("r","rack",tw*.45,sy-3,3,15);
if(id==="warhammer"){topRack("r",tw*.7,sy+7,6);let x=-tw*.7,y=sy+7;part("lt_searchlight","LT","lt",[x,sy+2,0],[B([x-1.5,sy+2,-1],[x+1.5,y-1,2],"frame"),Z([[-5,x-3,x+3,y-2,y+2,.15],[3,x-3,x+3,y-2,y+2,.16]],"plate"),B([x-2,y-1,-5],[x+2,y+1,-3],"glass","paint")])}
if(id==="atlas"){torsoWeapon("r","ac20",tw*.5,sy-9,4);torsoWeapon("l","rack",-tw*.55,sy-4,3,20)}
sym("l","L","pelvis",[h,w-4,0],[Y([yr(k,h+1,th*.75,0,th*.75,.1),yr(k+4,h+.5,th,0,th+.3,.2),yr(w-4,h,th*.8,0,3,.1)],"armor")],"hip");
sym("l_shin","L",q=>q+"l",[h+1,k,0],[Y([yr(f,h+2,sh*.72,0,sh*.72,.1),yr(f+3,h+2,sh,0,sh+.4,.2),yr(k-2,h+1,sh*.88,-.4,sh,.16),yr(k,h+1,th*.75,0,th*.75,.1)],"plate")],"knee");
sym("l_kneecap","L",q=>q+"l_shin",[h+1,k-2,-th*.75],[Z([[-sh-1,h+1-sh*.58,h+1+sh*.58,k-4,k-.5,.16],[-sh+.4,h+1-sh*.68,h+1+sh*.68,k-4,k,.13],[-1,h+1-sh*.62,h+1+sh*.62,k-4,k-.5,.1]],"plate")]);
sym("l_foot","L",q=>q+"l_shin",[h+2,f,0],[Y([[0,h+2-fw,h+2+fw,-ff,fb,.18],[2,h+2-fw,h+2+fw,-ff+1,fb,.15],[f,h+2-sh*.72,h+2+sh*.72,-sh*.72,sh*.72,.1]],"plate")],"ankle");
return spec;
}
;build
