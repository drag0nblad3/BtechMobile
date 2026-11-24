function build12(lib,id){
const {assembly,L,B,cyl,loft,ellipse}=lib;
const Y=(r,m)=>L("y",r,m),Z=(r,m)=>L("z",r,m),X=(r,m)=>L("x",r,m);
const cfg={
banshee:{unit:"banshee_bnc3e",pitch:.054,waist:26,body:[[26,5,4,4],[30,8,6,5],[37,10,7,6],[43,8,4,5]],head:[0,43,4,5,6],hip:6.5,thigh:4,shin:4.5,knee:14,ankle:4,feet:[5.5,7,4],shoulder:11,sy:39,arm:4,el:30,wr:21,shield:"angled",armMode:"hands"},
charger:{unit:"charger_cgr1a1",pitch:.052,waist:25,body:[[25,5,4,4],[29,8,5,5],[35,10,7,5],[42,7,4,4]],head:[0,42,4,4,5],hip:7,thigh:3.5,shin:4,knee:13,ankle:4,feet:[5,7,4],shoulder:11,sy:38,arm:3.8,el:29,wr:21,shield:"angled",armMode:"hands"},
enforcer:{unit:"enforcer_enf4r",pitch:.047,waist:24,body:[[24,4,3.5,3],[28,6,5,4],[35,8,5,4],[40,6,3.5,4]],head:[0,40,4,3.5,5],hip:6,thigh:3,shin:3,knee:13,ankle:4,feet:[4.5,6,3],shoulder:9,sy:37,arm:2.7,el:28,wr:20,shield:"vertical",armMode:"guns"},
hatchetman:{unit:"hatchetman_hct3f",pitch:.045,waist:23,body:[[23,4,3,3],[27,6,5,4],[33,7,5,4],[38,6,3.5,3]],head:[0,36,3.5,5,8],hip:6.5,thigh:3,shin:2.7,knee:12,ankle:3,feet:[4,6,3],shoulder:8,sy:35,arm:2.5,el:26,wr:18,shield:"joint",armMode:"hands"},
highlander:{unit:"highlander_hgn732",pitch:.055,waist:24,body:[[24,5,4,4],[29,9,6,6],[35,10,7,6],[41,9,4,5]],head:[0,41,5,4.5,6],hip:7,thigh:4.5,shin:5,knee:12,ankle:4,feet:[6,8,5],shoulder:11,sy:38,arm:4.5,el:29,wr:20,shield:"vertical",armMode:"hands"},
phoenix_hawk:{unit:"phoenix_hawk_pxh1",pitch:.046,waist:24,body:[[24,4,3,3],[28,7,5,4],[34,9,6,4],[40,7,3.5,4]],head:[0,40,4,4,5],hip:6,thigh:3.3,shin:3.6,knee:12,ankle:4,feet:[4.5,7,3],shoulder:10,sy:36,arm:3.5,el:28,wr:20,shield:"angled",armMode:"hands"},
trebuchet:{unit:"trebuchet_tbt5n",pitch:.047,waist:23,body:[[23,4,3.5,3],[27,7,5,4],[33,8,5,4],[39,7,4,4]],head:[0,39,3.5,3,5],hip:6.5,thigh:3.5,shin:3,knee:12,ankle:3,feet:[4.5,6,4],shoulder:9,sy:35,arm:3.3,el:27,wr:20,shield:"round",armMode:"guns"},
warhammer:{unit:"warhammer_whm6r",pitch:.05,waist:24,body:[[24,5,3.5,3],[28,8,5,5],[35,10,6,5],[41,8,4,4]],head:[0,40,3.6,4,5],hip:7,thigh:4,shin:4.5,knee:13,ankle:4,feet:[5.5,7,4],shoulder:11,sy:37,arm:4,el:28,wr:19,shield:"horizontal",armMode:"guns"},
jagermech:{unit:"jagermech_jm6s",pitch:.05,waist:23,body:[[23,5,3,4],[27,8,5,5],[32,9,6,5],[38,8,5,4]],head:[0,38,3,3,3],hip:7,thigh:3.5,shin:4,knee:12,ankle:4,feet:[5,6,4],shoulder:10,sy:36,arm:3.5,el:34,wr:28,shield:"gunpod",armMode:"battery"},
rifleman:{unit:"rifleman_rfl3n",pitch:.05,waist:25,body:[[25,5,3,4],[28,8,6,5],[34,10,7,6],[40,8,4,5]],head:[0,38,3.5,5,3],hip:7,thigh:3.8,shin:4.5,knee:13,ankle:4,feet:[5.5,7,4],shoulder:11,sy:35,arm:4,el:33,wr:27,shield:"gunpod",armMode:"battery"}
}[id];
let spec,part;
function init(unit,pitch,legs="plantigrade"){let x=assembly(id,id.replaceAll("_"," "),pitch,legs);spec=x.spec;part=x.part;spec.unit=unit}
function mir(shape){let a=lib.clone(shape);if(a.axis==="x")a.sections=a.sections.map(s=>({...s,at:-s.at})).reverse();else for(let q of a.sections)for(let p of q.polygon)p[0]*=-1;return a}
function sym(n,loc,parent,pivot,sh,j){for(let s of ["l","r"])part(s+n,s.toUpperCase()+loc,typeof parent==="function"?parent(s):parent,pivot.map((v,i)=>s==="l"&&i===0?-v:v),s==="l"?sh.map(mir):lib.clone(sh),j)}
function gun(n,loc,parent,x,y,z0,z1,r,mat="gun"){let sh=[cyl("z",z0,z1,x,y,r,r,mat),cyl("z",z0,z0+3,x,y,r*.5,r*.5,"gun","subtract")];part(n,loc,parent,[x,y,z1],sh);(spec.muzzles[loc]??=[]).push([x,y,z0])}
function rack(n,loc,parent,x,y,z,cols,rows,step=2){let pts=Array.from({length:cols*rows},(_,i)=>[x+(i%cols-(cols-1)/2)*step,y+(Math.floor(i/cols)-(rows-1)/2)*step]);let w=cols*step/2+.7,h=rows*step/2+.7;part(n,loc,parent,[x,y,z+5],[Z([[z,x-w,x+w,y-h,y+h,.14],[z+5,x-w,x+w,y-h,y+h,.13],[z+6,x-w+.4,x+w-.4,y-h+.4,y+h-.4,.12]],"plate"),...pts.map(([u,v])=>cyl("z",z,z+2.5,u,v,.7,.7,"gun","subtract"))]);(spec.muzzles[loc]??=[]).push(...pts.map(([u,v])=>[u,v,z]))}
function leg(h,w,k,f,t,sh,feet){let [fw,ff,fb]=feet;
 sym("l","L","pelvis",[h,w-4,0],[Y([[k,h+.6-t*.65,h+.6+t*.65,-2.5,2.5,.1],[k+3,h+.5-t,h+.5+t,-t,t,.18],[w-4,h-t*.65,h+t*.65,-3,3,.1]],"armor")],"hip");
 sym("l_shin","L",s=>s+"l",[h+.6,k,0],[Y([[f,h+1.1-sh*.65,h+1.1+sh*.65,-2.5,2.5,.1],[f+3,h+1.1-sh,h+1.1+sh,-sh,sh,.17],[k-2,h+.6-sh*.88,h+.6+sh*.88,-sh,sh*.8,.14],[k,h+.6-t*.65,h+.6+t*.65,-2.5,2.5,.08]],"plate")],"knee");
 sym("l_foot","L",s=>s+"l_shin",[h+1.1,f,0],[Y([[0,h+1.1-fw,h+1.1+fw,-ff,fb,.2],[2,h+1.1-fw,h+1.1+fw,-ff+1,fb,.14],[f,h+1.1-sh*.65,h+1.1+sh*.65,-2.5,2.5,.1]],"plate")],"ankle");
}
if(id==="raven"){
 init("raven_rvn3l",.049,"digitigrade");spec.punch=false;
 part("pelvis","CT",null,[0,23,1],[Y([[20,-6,6,-3,5,.16],[23,-7,7,-4,5,.13],[26,-5,5,-4,4,.1]])]);
 part("ct","CT","pelvis",[0,26,1],[Z([[-8,-5,5,28,35,.2],[-3,-8,8,26,40,.18],[4,-9,9,26,40,.17],[10,-7,7,29,38,.2]])]);
 part("hd","HD","ct",[0,31,-8],[Z([[-24,-2,2,26,28,.18],[-21,-4,4,27,31,.24],[-16,-5,5,27,34,.2],[-11,-6,6,28,36,.17],[-8,-5,5,28,35,.13]],"plate"),B([-2,30,-20],[2,32,-16],"glass","paint")]);
 sym("t","T","ct",[8,34,2],[X([[8,29,37,-4,7,.1],[12,29,38,-3,7,.15],[13,30,36,-2,6,.12]],"plate")]);
 sym("a","A",s=>s+"t",[13,33,2],[X([[13,30,36,-3,4,.1],[16,29,37,-4,5,.15],[17,30,35,-3,4,.1]],"armor")],"shoulder");
 gun("la_narc","LA","la",-15,33,-10,-3,2.2);gun("ra_laser1","RA","ra",15,34,-10,-3,1.6);gun("ra_laser2","RA","ra",15,30,-9,-3,1.5);
 rack("rt_srm6","RT","rt",10,30,-11,3,2,2);
 part("lt_ecm_spine","LT","lt",[-10,37,4],[Y([[37,-12,-8,2,6,.1],[39,-12,-8,2,6,.12],[43,-11,-9,3,5,.08]],"plate")]);
 sym("l","L","pelvis",[5,20,1],[Y([[14,5,9,4,9,.12],[17,4,9,1,8,.15],[20,3,7,-1,6,.09]],"armor")],"hip");
 sym("l_shin","L",s=>s+"l",[7,14,6],[Y([[6,7,10,-1,3,.1],[10,6,11,0,6,.16],[14,5,9,4,9,.08]],"plate")],"knee");
 sym("l_tarsus","L",s=>s+"l_shin",[8,6,1],[Y([[3,7,10,-1,3,.06],[6,7,10,-1,3,.08]],"frame")],"hock");
 sym("l_foot","L",s=>s+"l_tarsus",[8,3,1],[Y([[0,4,13,-6,5,.2],[1.5,5,12,-5,4,.18],[3,7,10,-1,3,.07]],"plate")],"ankle");
 return {spec,anchors:{waist:[0,23,1],head:[0,28,-23],ls:[-13,33,2],rs:[13,33,2],chest:[0,35,-3],top:[0,39,3]}}
}
if(id==="urbanmech"){
 init("urbanmech_umr60",.046);spec.punch=false;
 part("pelvis","CT",null,[0,20,0],[Y([[16,-6,6,-3,4,.18],[20,-7,7,-4,4,.13],[23,-5,5,-4,4,.1]])]);
 part("ct","CT","pelvis",[0,23,0],[loft("y",[[23,ellipse(0,0,5,4,24)],[27,ellipse(0,0,9,7.5,24)],[33,ellipse(0,0,10,8.5,24)],[37,ellipse(0,0,8.5,7.5,24)]],"armor")]);
 part("hd","HD","ct",[0,37,0],[loft("y",[[37,ellipse(0,0,8.5,7.5,24)],[39,ellipse(0,0,8,7,24)],[42,ellipse(0,0,6,5,24)],[44,ellipse(0,0,3,2.5,24)]],"plate"),Z([[-7.3,-4,4,37,39,.05],[-5,-4,4,37,39,.06]],"glass")]);
 for(let s of [-1,1])part((s<0?"l":"r")+"t","CT","ct",[s*8,33,0],[X(s<0?[[-12,29,36,-4,4,.15],[-9,29,36,-4,4,.1],[-8,30,36,-4,4,.1]]:[[8,30,36,-4,4,.1],[9,29,36,-4,4,.1],[12,29,36,-4,4,.15]],"plate")]);
 sym("a","A",s=>s+"t",[12,33,0],[X([[12,29,36,-4,4,.1],[15,28,38,-5,5,.16],[18,29,37,-4,4,.17]],"armor")],"shoulder");
 gun("ra_ac10","RA","ra",15,33,-17,-4,3.5);gun("la_laser","LA","la",-15,34,-8,-4,2);
 for(let s of [-1,1])part((s<0?"l":"r")+"t_exhaust","CT","hd",[s*2,43,2],[Y([[43,s*2-1,s*2+1,1,3,.06],[47,s*2-1,s*2+1,1,3,.08]],"frame")]);
 leg(5.5,20,10,3,3.4,4.4,[4.7,5,4]);return {spec,anchors:{waist:[0,20,0],head:[0,39,-7],ls:[-12,33,0],rs:[12,33,0],chest:[0,31,-7],top:[0,44,0]}}
}
init(cfg.unit,cfg.pitch);spec.punch=cfg.armMode==="hands";let c=cfg,w=c.waist,m=c.body.at(-1)[0],max=Math.max(...c.body.map(q=>q[1])),s=c.shoulder,sy=c.sy,ax=s+3,el=c.el,wr=c.wr,a=c.arm,[hx,hy,hw,hd,hh]=c.head;
part("pelvis","CT",null,[0,w-2,0],[Y([[w-4,-c.hip-2,c.hip+2,-3,4,.2],[w-1,-c.hip-2,c.hip+2,-4,4,.16],[w,-4.5,4.5,-3,3,.1]],"armor")]);
part("ct","CT","pelvis",[0,w,0],[Y(c.body.map(([y,x,z,b])=>[y,-x,x,-z,b,.15]))]);
let chestDepth=c.body[1][2];part("ct_breast","CT","ct",[0,sy-4,-chestDepth],[Z([[-chestDepth-3,-max+3,max-3,w+4,sy-1,.22],[-chestDepth-1,-max+1,max-1,w+3,sy+2,.17],[-3,-max+2,max-2,w+4,sy+1,.13]],"plate")]);
let headShapes=id==="hatchetman"?[Z([[-10,-2.5,2.5,35,39,.2],[-7,-3.5,3.5,35,43,.17],[-3,-3.5,3.5,37,45,.14],[1,-3,3,38,44,.15]],"plate"),B([-2,38,-10],[2,40,-8],"glass","paint")]:id==="highlander"?[Y([[hy,-4,4,-4,3,.12],[hy+2,-5,5,-5,4,.13],[hy+hh,-4.8,4.8,-4,3,.13]],"plate"),B([-4,hy+1,-5],[4,hy+3,-3],"glass","paint")]:[Y([[hy,hx-hw*.8,hx+hw*.8,-hd,2,.12],[hy+2,hx-hw,hx+hw,-hd-1,3,.15],[hy+hh-1,hx-hw*.85,hx+hw*.85,-hd+.2,3,.18],[hy+hh,hx-hw*.65,hx+hw*.65,-hd+1,2,.18]],"plate"),B([hx-hw*.6,hy+1,-hd-1],[hx+hw*.6,hy+3,-hd+.1],"glass","paint")];
if(id==="hatchetman"||id==="rifleman"||id==="warhammer"){ // embedded cockpit, breast/front casing is supporting body
 part("hd","HD","ct",[hx,hy,-1],headShapes)
}else part("hd","HD","ct",[hx,hy,-1],headShapes);
sym("t","T","ct",[max-1,sy,0],[X([[max-2,sy-5,sy+3,-4,5,.08],[s-1,sy-5,sy+3,-4,4,.14],[s,sy-4,sy+2,-3,4,.1]],"armor")]);
let cap=c.shield==="round"?loft("x",[[s,ellipse(sy,0,3.8,3,16)],[s+2,ellipse(sy,0,4.8,4,16)],[s+5,ellipse(sy,0,4,3.5,16)],[s+6,ellipse(sy,0,2.7,2.5,16)]],"plate"):c.shield==="vertical"?X([[s,sy-4,sy+4,-3,3,.1],[s+2,sy-5,sy+5,-4,4,.14],[s+5,sy-5,sy+4,-3.5,3.5,.14],[s+6,sy-3,sy+3,-3,3,.12]],"plate"):c.shield==="horizontal"?X([[s,sy-3,sy+3,-4,4,.08],[s+3,sy-3,sy+4,-5,5,.12],[s+7,sy-3,sy+3,-4,4,.15]],"plate"):c.shield==="joint"?X([[s,sy-2.6,sy+2.6,-2.4,2.4,.1],[s+3,sy-3,sy+3,-3,3,.15],[s+5,sy-2.5,sy+2.5,-2.5,2.5,.1]],"frame"):c.shield==="gunpod"?X([[s,sy-4,sy+4,-5,4,.12],[s+3,sy-5,sy+5,-5,5,.14],[s+7,sy-4,sy+4,-4,4,.17]],"armor"):X([[s,sy-3,sy+3,-3,3,.1],[s+2,sy-4,sy+6,-4,4,.14],[s+5,sy-4,sy+4,-4,4,.18],[s+7,sy-2,sy+2,-3,3,.17]],"plate");
if(c.armMode==="battery"){
sym("a","A",q=>q+"t",[s,sy,0],[cap],"shoulder");
for(let side of ["l","r"]){let sign=side==="l"?-1:1,x=sign*(s+4),yy=sy;let loc=side.toUpperCase()+"A";
 gun(side+"a_ac5",loc,side+"a",x,yy+1,-23,-4,2.1);gun(side+"a_secondary",loc,side+"a",x-sign*3,yy-2,-16,-4,1.6)}
 part("hd_radar","HD","hd",[0,hy+hh,0],[Y([[hy+hh,-1,1,-1,1,.05],[hy+hh+3,-1,1,-1,1,.05]],"frame"),B([-7,hy+hh+3,-1],[7,hy+hh+5,1],"plate")]);
}else{
sym("a","A",q=>q+"t",[s,sy,0],[cap,Y([[sy-7,ax-a*.52,ax+a*.52,-2,2,.07],[sy-3,ax-a*.6,ax+a*.6,-2.4,2.4,.08]],"frame")],"shoulder");
sym("a_upper","A",q=>q+"a",[ax,sy-7,0],[Y([[el,ax-a*.56,ax+a*.56,-2,2,.08],[Math.max(el+.6,sy-8),ax-a*.75,ax+a*.75,-2.7,2.7,.13],[sy-7,ax-a*.52,ax+a*.52,-2,2,.08]],"armor")]);
sym("a_forearm","A",q=>q+"a_upper",[ax,el,0],[Y([[wr,ax-a*.9,ax+a*.9,-3,2.5,.15],[wr+3,ax-a,ax+a,-4,3,.18],[el,ax-a*.56,ax+a*.56,-2,2,.08]],"plate")],"elbow");
if(c.armMode==="hands")sym("a_hand","A",q=>q+"a_forearm",[ax,wr,0],[Y([[wr-4,ax-a*.73,ax+a*.73,-2.6,2.3,.17],[wr-2,ax-a*.8,ax+a*.8,-3,2.4,.14],[wr,ax-a*.9,ax+a*.9,-3,2.5,.09]],"frame")]);
}
if(id==="banshee"){gun("lt_ac5","LT","ct_breast",-5,sy-7,-14,-chestDepth-1,1.7);gun("rt_ppc","RT","ct_breast",5,sy-7,-15,-chestDepth-1,2.1)}
if(id==="charger"){for(let sg of [-1,1]){let side=sg<0?"l":"r";gun(side+"a_small_laser",side.toUpperCase()+"A",side+"a_forearm",sg*ax,wr+2,-8,-3,1.1)}gun("hd_laser","HD","hd",0,hy+2,-8,-hd,1.0)}
if(id==="enforcer"){gun("ra_ac10","RA","ra_forearm",ax,wr+3,-18,-3,2);gun("la_laser","LA","la_forearm",-ax,wr+3,-12,-3,2.2)}
if(id==="hatchetman"){gun("rt_ac10","RT","ct_breast",4,sy-5,-14,-chestDepth-1,2);gun("la_laser","LA","la_forearm",-ax,wr+2,-10,-3,1.5);
part("ra_hatchet","RA","ra_hand",[ax,wr-2,-1],[Y([[wr-6,ax-1,ax+1,-1,1,.05],[wr-1,ax-1,ax+1,-1,1,.05],[wr+6,ax-1,ax+1,-1,1,.07]],"frame"),X([[ax-1,wr+3,wr+9,-7,1,.12],[ax+1,wr+3,wr+9,-7,1,.14]],"plate")]);}
if(id==="highlander"){gun("ra_gauss","RA","ra_forearm",ax,wr+3,-20,-3,2.5);rack("lt_lrm20","LT","ct_breast",-5,sy-2,-13,4,5,1.7);rack("la_srm6","LA","la_forearm",-ax,wr+4,-9,3,2,1.8)}
if(id==="phoenix_hawk"){gun("ra_large_laser","RA","ra_forearm",ax,wr+3,-17,-3,1.7);gun("la_mg","LA","la_forearm",-ax,wr+2,-7,-3,1.1);sym("t_jump_pack","T",q=>q+"t",[s-3,sy+3,4],[Y([[sy-1,s-5,s-1,4,9,.12],[sy+4,s-5,s-1,4,9,.14],[sy+10,s-5,s-1,5,8,.15],[sy+12,s-4.5,s-1.5,6,7.5,.1]],"plate")]);}
if(id==="trebuchet"){rack("rt_lrm15","RT","ct_breast",5,sy-2,-13,3,5,1.8);rack("la_lrm15","LA","la_forearm",-ax,wr+3,-10,3,5,1.7);gun("ra_laser","RA","ra_forearm",ax,wr+3,-11,-3,2.1)}
if(id==="warhammer"){gun("ra_ppc","RA","ra_forearm",ax,wr+3,-22,-3,2.1);gun("la_ppc","LA","la_forearm",-ax,wr+3,-22,-3,2.1);part("rt_rack_mount","RT","rt",[s-2,sy+3,1],[Y([[sy+2,s-4,s,0,3,.08],[sy+6,s-4,s,0,3,.1]],"frame")]);rack("rt_srm6","RT","rt_rack_mount",s-2,sy+7,-6,3,2,1.8);part("lt_searchlight","LT","lt",[-s+2,sy+4,1],[Y([[sy+2,-s,-s+4,0,3,.09],[sy+6,-s,-s+4,0,3,.1]],"frame"),Z([[-4,-s,-s+4,sy+5,sy+9,.1],[3,-s,-s+4,sy+5,sy+9,.1]],"plate"),B([-s+.5,sy+6,-4],[-s+3.5,sy+8,-2],"glass","paint")]);}
leg(c.hip,w,c.knee,c.ankle,c.thigh,c.shin,c.feet);
return {spec,anchors:{waist:[0,w-1,0],head:[hx,hy+2,-hd],ls:[-s,sy,0],rs:[s,sy,0],chest:[0,sy-5,-chestDepth],top:[hx,hy+hh,0]}}
}
;build12
