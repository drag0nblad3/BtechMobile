// Experimental, individually specified component profiles, no production edits.
// Forward is -z; y up. Build in neutral articulated pose, not photo stance.
function build(lib,id){
const {assembly,L,B,cyl,loft,ellipse,sidePart}=lib;
const cfg={
banshee:{unit:"banshee_bnc3e",pitch:.065,w:24,k:12,h:7,s:13,sy:38,el:28,wr:19,torso:[[27,5,4,4],[31,8,6,6],[37,9,6,6],[42,7,4,5]],head:[0,41,3.6,4,7],shoulder:"vertical",arm:[3.5,4.2,3.4],thigh:[3.8,4.5,3],shin:[4,4.7,3.5],foot:[5,7,4],detail:"banshee"},
charger:{unit:"charger_cgr1a1",pitch:.060,w:25,k:13,h:6,s:12,sy:40,el:29,wr:20,torso:[[28,4,3.6,4],[32,8,5.5,5],[38,9,6,6],[44,7,4.5,4]],head:[0,43,3.8,4.2,6],shoulder:"round",arm:[3.2,3.8,3.1],thigh:[3.4,4.5,3],shin:[3.7,4.2,3.1],foot:[4.5,6.4,3.6],detail:"charger"},
enforcer:{unit:"enforcer_enf4r",pitch:.052,w:22,k:11,h:6,s:11,sy:36,el:27,wr:18,torso:[[25,4.5,4,4],[29,7.5,6,5],[35,8,6,5],[39,6,4,4]],head:[0,38,3.4,4.3,6],shoulder:"shield",arm:[3,3.4,3.1],thigh:[3.1,3.9,2.7],shin:[3.5,4.3,3],foot:[4.6,6.4,3.7],detail:"enforcer"},
hatchetman:{unit:"hatchetman_hct3f",pitch:.053,w:23,k:12,h:5.7,s:11,sy:37,el:27,wr:19,torso:[[26,4.2,3.8,4],[29,7,6,5],[35,7.5,6,5],[40,5.8,4,4]],head:[0,39,3,4.6,7],shoulder:"round",arm:[3,3.3,2.8],thigh:[3,3.7,2.6],shin:[3.2,4.2,2.7],foot:[4.3,6.5,3.5],detail:"hatchetman"},
highlander:{unit:"highlander_hgn732",pitch:.065,w:23,k:11,h:7,s:13,sy:39,el:28,wr:19,torso:[[26,6,4.8,5],[30,9,7,6],[37,10,7,6],[43,8,5.6,5]],head:[0,42,4.1,5.0,6],shoulder:"squared",arm:[3.9,4.6,3.8],thigh:[4,4.5,3.3],shin:[4.7,5,4],foot:[5.8,8,4.5],detail:"highlander"},
jagermech:{unit:"jagermech_jm6s",pitch:.060,w:22,k:11,h:6.5,s:12,sy:37,el:33,wr:27,torso:[[25,4.7,3.5,5],[29,8.2,5.5,6],[35,9,6,6],[40,8,4.6,5]],head:[0,39,3.1,4,4.6],shoulder:"gunpod",arm:[4.1,4.5,4],thigh:[3.5,4,3],shin:[4,4.4,3.2],foot:[4.8,6.8,4],detail:"jagermech"},
phoenix_hawk:{unit:"phoenix_hawk_pxh1",pitch:.055,w:25,k:13,h:5.5,s:10.5,sy:39,el:29,wr:20,torso:[[28,3.8,3.2,3.5],[32,6.2,5.7,4],[37,7.5,6,4.8],[42,5.8,4,4]],head:[0,41,3,3.6,5.5],shoulder:"small",arm:[2.6,3.3,2.7],thigh:[2.8,3.5,2.5],shin:[3.2,4,2.6],foot:[4,6,3.5],detail:"phoenix_hawk"},
trebuchet:{unit:"trebuchet_tbt5n",pitch:.053,w:24,k:12,h:5.8,s:10.8,sy:37,el:27,wr:19,torso:[[27,3.7,3.3,3.5],[30,7.1,5.8,4.8],[36,7.8,5.5,5],[40,5.5,4,4]],head:[0,39,3.5,3.8,5.4],shoulder:"vertical",arm:[2.8,3.6,2.8],thigh:[2.8,3.6,2.4],shin:[3.1,3.7,2.6],foot:[4,5.8,3.4],detail:"trebuchet"},
warhammer:{unit:"warhammer_whm6r",pitch:.05,w:23,k:12,h:7,s:14,sy:37,el:27,wr:20,torso:[[26,5.7,3.8,4],[29,9.2,6.2,5.8],[35,11,6,6],[40,9,4.5,5]],head:[0,38,3.2,4.3,6],shoulder:"horizontal",arm:[3.4,4,3.4],thigh:[3.8,4.2,3.2],shin:[4.5,4.8,3.6],foot:[5.4,7.1,4.1],detail:"warhammer"},
rifleman:{unit:"rifleman_rfl3n",pitch:.055,w:23,k:12,h:6.5,s:13.5,sy:36,el:32,wr:26,torso:[[26,4.8,4,4],[30,9,5.2,5.2],[36,10,6,5.5],[40,8.7,5,4.4]],head:[0,37,3.1,4,5],shoulder:"gunpod",arm:[4.2,4.1,3.8],thigh:[3.5,4,2.8],shin:[3.5,4.3,3.1],foot:[4.7,6.5,3.6],detail:"rifleman"},
timber_wolf:{unit:"timber_wolf_prime",pitch:.05,w:22,k:13,h:7,s:13,sy:33,el:25,wr:18,torso:[[25,6.5,5,5],[29,9,7,7],[34,10,7,8],[38,8,4.8,7]],head:[0,30,5.5,6,6],shoulder:"round",arm:[3.5,4.1,3.4],thigh:[3.7,4.2,3.2],shin:[4.4,4.5,3.3],foot:[5.1,7.5,4],detail:"timber_wolf",reverse:true},
mad_dog:{unit:"mad_dog_prime",pitch:.054,w:23,k:13,h:6.5,s:12,sy:33,el:25,wr:19,torso:[[26,4.5,3.8,4],[29,7,5.5,5.5],[34,8.5,6,6],[39,7,5,5.4]],head:[0,32,4.7,5.4,6],shoulder:"small",arm:[3,3.8,3],thigh:[3.4,4,2.7],shin:[3.7,4.3,2.9],foot:[4.6,6.6,3.8],detail:"mad_dog",reverse:true},
nova:{unit:"nova_prime",pitch:.051,w:22,k:13,h:6,s:12,sy:32,el:26,wr:20,torso:[[25,5,4,4],[29,8,6,6],[34,9,6.5,6.5],[37,8,5,5.5]],head:[0,30,4.7,5,5],shoulder:"gunpod",arm:[3.8,4.1,3.8],thigh:[3.3,4.1,2.8],shin:[3.8,4.2,2.8],foot:[4.7,6.4,3.7],detail:"nova",reverse:true},
summoner:{unit:"summoner_prime",pitch:.056,w:23,k:13,h:6.5,s:12,sy:36,el:28,wr:20,torso:[[26,4.6,3.6,4],[30,7.5,6,5.5],[36,8.5,6,6],[41,6.7,4.8,5]],head:[0,39,3.6,4,6],shoulder:"shield",arm:[3.4,4,3.2],thigh:[3.5,4.1,3],shin:[4,4.5,3.2],foot:[4.8,7,4],detail:"summoner",reverse:true},
jenner:{unit:"jenner_jr7d",pitch:.043,w:22,k:13,h:6.5,s:12.5,sy:33,el:29,wr:25,torso:[[25,5.5,4,4.5],[29,8.6,6,7],[35,9.5,7.5,7],[39,7,4,5]],head:[0,32,5.8,5,5],shoulder:"gunpod",arm:[3.4,3.7,3.1],thigh:[3.1,3.8,2.7],shin:[3.6,4,2.6],foot:[4.8,7,4],detail:"jenner",reverse:true}
}[id];
if(!cfg)throw Error(id);let c=cfg;
const {spec,part}=assembly(id,id.replace(/_/g," ").replace(/\b\w/g,s=>s.toUpperCase()),c.pitch,c.reverse?"digitigrade":"plantigrade");spec.unit=c.unit;spec.punch=!["jagermech","rifleman","warhammer","nova","jenner","mad_dog"].includes(id);
const Y=(r,m)=>L("y",r,m),X=(r,m)=>L("x",r,m),Z=(r,m)=>L("z",r,m);
const sym=(n,l,parent,p,sh,j)=>{for(let q of ["l","r"])sidePart(part,q,n,q.toUpperCase()+l,typeof parent==="function"?parent(q):parent,p,sh,j)};
const row=(y,x,a,z,b,k=.14)=>[y,x-a,x+a,z-b,z+b,k];
let {w,k,h,s,sy,el,wr}=c,f=4,m=c.torso.at(-1)[0],max=Math.max(...c.torso.map(t=>t[1])),[hx,hy,hw,hd,hh]=c.head,[aw,ad,af]=c.arm,[tw,td,tk]=c.thigh,[sw,sd,sk]=c.shin,[fw,ff,fb]=c.foot;
part("pelvis","CT",null,[0,w,0],[Y([[w-4,-h-1,h+1,-3,3,.18],[w-1,-h-2,h+2,-4,4,.12],[w+3,-4,4,-3,3,.12]],"armor")]);
part("ct","CT","pelvis",[0,w+3,0],[Y(c.torso.map(([y,x,z,b])=>[y,-x,x,-z,b,.19]))]);
if(!["jenner","timber_wolf","mad_dog","nova"].includes(id)){
let z=-c.torso[1][2];part("ct_breast","CT","ct",[0,sy-3,z],[Z([[z-2,-max*.64,max*.64,w+7,sy,.25],[z,-max*.91,max*.91,w+6,sy+1,.19],[z+3,-max*.8,max*.8,w+7,sy,.15]],"plate")]);
}
if(["jenner","timber_wolf","mad_dog","nova"].includes(id)){
let end=id==="jenner"?-22:id==="timber_wolf"?-20:id==="mad_dog"?-15:-14;let frontY=id==="jenner"?hy-1:hy-4;
let shape=id==="jenner"?loft("z",[[end,ellipse(0,hy,hw*.66,2.3,16)],[end+3,ellipse(0,hy,hw,3,16)],[-12,ellipse(0,hy,hw*1.1,3.5,16)],[-7,ellipse(0,hy,hw*.75,3.3,16)]],"plate"):Z([[end,-hw*.5,hw*.5,frontY,frontY+3,.25],[end+4,-hw,hw,frontY,hy+3,.23],[-7,-hw*1.08,hw*1.08,hy-3,hy+5,.2],[-5,-hw*.8,hw*.8,hy-2,hy+4,.1]],"plate");
part("hd","HD","ct",[0,hy,-7],[shape,B([-hw*.5,hy,end+1],[hw*.5,hy+2,end+4],"glass","paint")]);
}else{
let hs=id==="trebuchet"?loft("y",[[hy,ellipse(0,-1,hw*.85,hd*.82,16)],[hy+2,ellipse(0,-1,hw,hd,16)],[hy+hh-1,ellipse(0,-1,hw*.67,hd*.67,16)],[hy+hh,ellipse(0,-1,hw*.4,hd*.42,16)]],"plate"):Y([[hy,-hw*.76,hw*.76,-hd,2,.15],[hy+2,-hw,hw,-hd-1,2.8,.18],[hy+hh-1,-hw*.82,hw*.82,-hd+.2,2.5,.23],[hy+hh,-hw*.58,hw*.58,-hd+1.4,1.8,.15]],"plate");
part("hd","HD","ct",[0,hy,0],[hs,B([-hw*.6,hy+1,-hd-1],[hw*.6,hy+2.5,-hd+.2],"glass","paint")]);
}
let t0=max-2.2;
sym("t","T","ct",[t0,sy,0],[X([[t0,sy-6,sy+3,-4,5,.12],[s-1,sy-5.5,sy+3,-4,5.6,.19],[s,sy-5,sy+2,-3.4,4.5,.14]],"armor")]);
if(id==="phoenix_hawk"||id==="summoner"||id==="highlander"){
sym("t_jump","T",q=>q+"t",[s-3,sy,4],[Y([[sy-8,s-5.4,s-.5,3.5,7,.13],[sy-4,s-6,s,4,9,.17],[sy+3,s-6,s,4,9,.2],[sy+7,s-5.5,s-1,5,8,.25]],"plate")]);
}else if(!["jenner","nova"].includes(id)){
sym("t_back","T",q=>q+"t",[s-3,sy-1,5],[Z([[4,s-5,s-1,sy-6,sy+1,.12],[7,s-4.8,s-.8,sy-5,sy+1,.2],[9,s-4.2,s-1.3,sy-4,sy,.2]],"plate")]);
}
let armx=s+3.2, gunpod=c.shoulder==="gunpod";
let caps={
vertical:[[s,sy-4,sy+4,-ad,ad,.15],[s+2,sy-6,sy+6,-ad-1,ad+1,.23],[s+4,sy-5,sy+5,-ad-.5,ad+.8,.18],[s+6,sy-3,sy+2,-ad*.7,ad*.7,.22]],
shield:[[s,sy-3,sy+3,-ad,ad,.1],[s+2,sy-4,sy+6,-ad-1,ad+1,.16],[s+5,sy-5,sy+3,-ad-1,ad,.24],[s+6.5,sy-4,sy,-ad*.6,ad*.8,.19]],
squared:[[s,sy-4,sy+4,-ad,ad,.08],[s+2,sy-5,sy+5,-ad-1,ad+1,.1],[s+6,sy-5,sy+4,-ad-1,ad+1,.15],[s+7,sy-4,sy+3,-ad,ad,.16]],
horizontal:[[s,sy-3,sy+3,-ad,ad,.08],[s+2,sy-2.8,sy+3.8,-ad-1,ad+1,.16],[s+6,sy-2.5,sy+3,-ad-.5,ad+.6,.19],[s+7,sy-1.5,sy+1.5,-ad*.75,ad*.8,.18]],
small:[[s,sy-3,sy+3,-ad,ad,.12],[s+2,sy-4,sy+4,-ad+.1,ad+.4,.25],[s+4.5,sy-3.5,sy+2,-ad*.9,ad*.9,.18]],
gunpod:[[s,sy-3,sy+3,-ad,ad,.08],[s+2,sy-4,sy+4,-ad-1.5,ad+1,.14],[s+6,sy-4,sy+4,-ad-1.5,ad+1,.14],[s+7,sy-2.5,sy+2.5,-ad,ad,.2]]
};
let cap=c.shoulder==="round"?loft("x",[[s,ellipse(sy,0,3.4,ad,16)],[s+2,ellipse(sy,0,5.1,ad+1,16)],[s+4.8,ellipse(sy,0,4.8,ad+.6,16)],[s+6.2,ellipse(sy,0,3,ad*.75,16)]],"plate"):X(caps[c.shoulder],"plate");
let bridgeY=gunpod?sy-4:sy-6;
sym("a","A",q=>q+"t",[s,sy,0],[cap,Y([row(bridgeY,armx,aw*.67,0,ad*.67,.08),row(sy-2,armx,aw*.67,0,ad*.68,.09)],"frame")],"shoulder");
if(!gunpod){
sym("a_upper","A",q=>q+"a",[armx,bridgeY,0],[Y([row(el,armx,aw*.66,0,ad*.66,.08),row(el+2,armx,aw*.87,0,ad*.82,.18),row(bridgeY,armx,aw*.67,0,ad*.67,.09)],"armor")]);
sym("a_forearm","A",q=>q+"a_upper",[armx,el,0],[Y([row(wr,armx,af*.85,-.8,ad*.83,.16),row(wr+2.5,armx,af+0.4,-.8,ad+.7,.22),row(el,armx,aw*.66,0,ad*.66,.08)],"plate")],"elbow");
}else{
sym("a_forearm","A",q=>q+"a",[armx,bridgeY,0],[Y([row(wr,armx,af,-1,ad,.14),row(bridgeY,armx,aw*.67,0,ad*.67,.08)],"plate")],"elbow");
}
let hands=!["warhammer","rifleman","jagermech","nova","jenner","mad_dog"].includes(id);
if(hands){sym("a_hand","A",q=>q+"a_forearm",[armx,wr,-.8],[Y([row(wr-3.6,armx,af*.66,-.8,ad*.64,.21),row(wr-1.6,armx,af*.83,-.8,ad*.81,.13),row(wr,armx,af*.85,-.8,ad*.83,.09)],"frame")]);}
function gun(name,loc,parent,x,y,start,end,r,style="barrel"){
let sh=style==="pod"?[Z([[end,x-r*.8,x+r*.8,y-r*.8,y+r*.8,.18],[end+3,x-r,x+r,y-r,y+r,.18],[start,x-r*1.03,x+r*1.03,y-r,y+r,.13]],"plate")]:[Z([[end,x-r*.75,x+r*.75,y-r*.75,y+r*.75,.2],[end+3,x-r*.8,x+r*.8,y-r*.8,y+r*.8,.2],[start-3,x-r,x+r,y-r,y+r,.15],[start,x-r,x+r,y-r,y+r,.1]],"gun")];
sh.push(cyl("z",end,end+3,x,y,Math.max(.72,r*.40),Math.max(.72,r*.40),"gun","subtract"));part(name,loc,parent,[x,y,start],sh);(spec.muzzles[loc]??=[]).push([x,y,end]);
}
function rack(name,loc,parent,x,y,start,end,cols,rows,sep=1.8,round=false){
let rx=(cols-1)*sep/2+1.6,ry=(rows-1)*sep/2+1.6,pts=Array.from({length:cols*rows},(_,i)=>[x+(i%cols-(cols-1)/2)*sep,y+(Math.floor(i/cols)-(rows-1)/2)*sep]);
let sh=round?[cyl("z",end,start,x,y,rx,ry,"plate")]:[Z([[end,x-rx,x+rx,y-ry,y+ry,.13],[end+2,x-rx-.2,x+rx+.2,y-ry-.2,y+ry+.2,.13],[start,x-rx*.95,x+rx*.95,y-ry*.95,y+ry*.95,.16]],"plate")];
sh.push(...pts.map(([px,py])=>cyl("z",end,end+2.5,px,py,.63,.63,"gun","subtract")));part(name,loc,parent,[x,y,start],sh);spec.muzzles[loc]=(spec.muzzles[loc]||[]).concat(pts.map(([x,y])=>[x,y,end]));
}
const ag=(q,n,r=2.4,len=10,style="barrel",yo=2)=>gun(q+"a_"+n,q.toUpperCase()+"A",q+"a_forearm",(q==="r"?1:-1)*armx,wr+yo,-ad-.15,-ad-len,r,style);
const ctGun=(q,n,r,len)=>gun(q+"t_"+n,q.toUpperCase()+"T",q+"t",(q==="r"?1:-1)*(s-1.6),sy-1,-3.6,-3.6-len,r);
const roof=(q,name,cols,rows,dy=4,dx=0,sep=1.8)=>{let x=(q==="r"?1:-1)*(s-2+dx),y=sy+dy;let p=part(q+"t_"+name+"_mount",q.toUpperCase()+"T",q+"t",[x,sy+2,0],[B([x-2,sy+2,-2.4],[x+2,y-1,3.2],"frame")]);rack(q+"t_"+name,q.toUpperCase()+"T",p.name,x,y,3.1,-8,cols,rows,sep)};
if(id==="banshee"){ctGun("l","ac5",1.9,8);ctGun("r","ppc",1.8,4);}
if(id==="charger"){ag("l","small_laser",1.2,2.8,"pod");ag("r","small_laser",1.2,2.8,"pod");}
if(id==="enforcer"){ag("r","ac10",2.8,13);ag("l","large_laser",2.2,7,"pod");}
if(id==="hatchetman"){ctGun("r","ac10",2.5,12);let x=armx,y=wr-1;part("ra_hatchet","RA","ra_hand",[x,y,-1],[cyl("z",-15,1,x,y,1,1,"frame"),loft("x",[[x-.7,[[y-1,-16],[y+6,-17],[y+9,-15],[y+9,-13],[y+2,-9],[y-1,-9]].map(([a,b])=>[a,b])],[x+.7,[[y-1,-16],[y+6,-17],[y+9,-15],[y+9,-13],[y+2,-9],[y-1,-9]]]],"plate")]);}
if(id==="highlander"){ag("r","gauss",2.8,16);roof("l","lrm20",4,5,6,0,1.8);rack("la_srm6","LA","la_forearm",-armx,wr+3,-ad,-ad-5,3,2,1.65);}
if(id==="jagermech"||id==="rifleman"){for(let q of ["l","r"]){let sg=q==="l"?-1:1,xx=sg*armx;gun(q+"a_outer_ac",q.toUpperCase()+"A",q+"a",xx+sg*1.8,sy+1,-ad,-ad-(id==="rifleman"?15:13),1.8);gun(q+"a_inner_"+(id==="rifleman"?"laser":"ac"),q.toUpperCase()+"A",q+"a",xx-sg*2.1,sy-2,-ad,-ad-(id==="rifleman"?11:16),1.6);}}
if(id==="phoenix_hawk"){ag("r","large_laser",2.3,9);ag("l","mg",1.2,2.5,"pod");}
if(id==="trebuchet"){roof("r","lrm15",3,5,5,0,1.7);rack("la_lrm15","LA","la_forearm",-armx,wr+4,-ad,-ad-6,3,5,1.7);}
if(id==="warhammer"){ag("l","ppc",3,12,"pod");ag("r","ppc",3,12,"pod");roof("r","srm6",3,2,5,0,1.8);let x=-s+2;part("lt_searchlight","LT","lt",[x,sy+3,0],[B([x-2,sy+2,-1.8],[x+2,sy+5,2.5],"frame"),cyl("z",-4,2,x,sy+5,2.9,2.1,"plate")]);}
if(id==="timber_wolf"||id==="mad_dog"){roof("l","lrm20",4,5,id==="mad_dog"?8:9,id==="mad_dog"?0:1,1.8);roof("r","lrm20",4,5,id==="mad_dog"?8:9,id==="mad_dog"?0:1,1.8);ag("l","laser",2.7,id==="timber_wolf"?9:8,"pod");ag("r","laser",2.7,id==="timber_wolf"?9:8,"pod");}
if(id==="nova"){for(let q of ["l","r"])rack(q+"a_six_lasers",q.toUpperCase()+"A",q+"a",q==="l"?-armx:armx,sy-2,-ad,-ad-8,3,2,2.0);}
if(id==="summoner"){roof("l","lrm15",3,5,6,0,1.7);ag("l","lbx",2.6,11);ag("r","ppc",2.5,13);}
if(id==="jenner"){for(let q of ["l","r"])rack(q+"a_lasers",q.toUpperCase()+"A",q+"a",q==="l"?-armx:armx,sy-1,-ad,-ad-8,1,2,2.6);rack("ct_srm4","CT","ct",0,sy+2,-5,-9,4,1,1.7);}
if(!c.reverse){
sym("l","L","pelvis",[h,w-4,0],[Y([row(k,h+1,tk,0,tk,.09),row(k+3,h+.8,tw,0,td,.22),row(w-4,h,Math.min(tw,3.5),0,3,.1)],"armor")],"hip");
sym("l_shin","L",q=>q+"l",[h+1,k,0],[Y([row(f,h+1.5,sk,0,sk,.1),row(f+2.5,h+1.6,sw,0,sd,.22),row(k-2,h+1.2,sw*.94,-.4,sd*.95,.16),row(k,h+1,tk,0,tk,.08)],"armor")],"knee");
sym("l_kneecap","L",q=>q+"l_shin",[h+1,k-2,-tk],[Z([[-sd-1,h+1-sw*.65,h+1+sw*.65,k-4,k-.4,.18],[-sd+.3,h+1-sw*.75,h+1+sw*.75,k-4,k,.13],[-1,h+1-sw*.66,h+1+sw*.66,k-4,k-.5,.1]],"plate")]);
sym("l_foot","L",q=>q+"l_shin",[h+1.5,f,0],[Y([[0,h+1.5-fw,h+1.5+fw,-ff,fb,.18],[2,h+1.5-fw,h+1.5+fw,-ff+1,fb,.18],[f,h+1.5-sk,h+1.5+sk,-sk,sk,.09]],"plate")],"ankle");
}else{
let kz=-3,hz=4.8,xk=h+1.2,xf=h+1.8;
sym("l","L","pelvis",[h,w-4,0],[Y([row(k,xk,tk,kz,tk,.09),row(k+3,h+.8,tw,kz+1,td,.21),row(w-4,h,Math.min(tw,3.5),0,3,.1)],"armor")],"hip");
sym("l_shin","L",q=>q+"l",[xk,k,kz],[Y([row(6,xf,sk,hz,sk,.09),row(9,xf,sw,hz-2,sd,.22),row(k-2,xk,sw*.85,kz+1.5,sd*.8,.18),row(k,xk,tk,kz,tk,.09)],"plate")],"knee");
sym("l_tarsus","L",q=>q+"l_shin",[xf,6,hz],[Y([row(3,xf,sk*.83,.8,sk*.8,.09),row(6,xf,sk,hz,sk,.09)],"frame")],"hock");
sym("l_foot","L",q=>q+"l_tarsus",[xf,3,.8],[Y([[0,xf-fw,xf+fw,-ff,fb,.22],[1.5,xf-fw,xf+fw,-ff+1,fb,.18],[3,xf-sk*.83,xf+sk*.83,.8-sk*.8,.8+sk*.8,.08]],"plate")],"ankle");
}
return {spec,anchors:{waist:[0,w+1,0],head:[0,hy+2,-hd],ls:[-s,sy,0],rs:[s,sy,0],chest:[0,sy-4,-c.torso[1][2]],top:[0,hy+hh,0]}}
}
build