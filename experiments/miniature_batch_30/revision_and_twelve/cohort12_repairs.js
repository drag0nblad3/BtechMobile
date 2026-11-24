function fix(lib,build,repair,id){
let {spec,anchors}=build(lib,id),p=n=>spec.parts.find(p=>p.name===n),Y=(r,m)=>lib.L("y",r,m),Z=(r,m)=>lib.L("z",r,m),X=(r,m)=>lib.L("x",r,m),B=lib.B;
if(id==="charger"){p("ct_breast").shapes=[Z([[-8,-6,6,29,35,.2],[-6,-7,7,28,39,.18],[-4,-6,6,29,39,.1]],"plate")]}
if(id==="hatchetman"){let q=p("ra_hatchet"),x=11,y=18;
q.shapes=[B([x-1,y-5,-5],[x+1,y+8,-3],"frame"),B([x-1,y-2,-4],[x+1,y+1,-1],"frame"),X([[x-1,y+4,y+10,-11,-3,.1],[x+1,y+4,y+10,-11,-3,.12]],"plate")];q.pivot=[x,y-2,-4]}
if(id==="phoenix_hawk"||id==="trebuchet"){
let c=id==="phoenix_hawk"?{s:10,sy:36,el:28,wr:20,a:3.5}:{s:9,sy:35,el:27,wr:20,a:3.3};
for(let sg of [-1,1]){let side=sg<0?"l":"r",ax=sg*(c.s+3),w=c.a*.7,upper=p(side+"a_upper"),parent=p(side+"a"),fore=p(side+"a_forearm"),y=c.el+4;
parent.shapes=parent.shapes.filter(sh=>sh.axis!=="y");parent.shapes.push(B([ax-w,y,-2.5],[ax+w,c.sy-1,2.5],"frame"));
upper.shapes=[Y([[c.el,ax-w,ax+w,-2.5,2.5,.05],[c.el+2,ax-w-.4,ax+w+.4,-2.8,2.8,.12],[y,ax-w,ax+w,-2.5,2.5,.05]],"armor")];upper.pivot=[ax,y,0];
fore.shapes[0].sections.at(-1).polygon=lib.oct(ax-w,ax+w,-2.5,2.5,.05);
}}
if(id==="warhammer"){let q=p("rt_rack_mount");q.parent="ra";q.shapes=[B([11,39,0],[15,44,3],"frame")];p("rt_srm6").parent="rt_rack_mount";let r=p("lt_searchlight");r.parent="la";r.shapes[0]=B([-15,39,0],[-11,43,3],"frame");}
if(id==="urbanmech"){let q=p("la_laser");q.shapes=[lib.cyl("z",-9,-3,-15,34,2.4,2.4,"gun"),lib.cyl("z",-9,-7,-15,34,.9,.9,"gun","subtract")];spec.muzzles.LA=[[-15,34,-9]]}
if(id==="rifleman"){p("hd").shapes=[Y([[40,-3,3,-4,2,.1],[42,-4,4,-5,3,.14],[43,-3,3,-4,2,.12]],"plate"),B([-2,41,-5],[2,42,-3],"glass","paint")];p("hd").pivot=[0,40,0];p("hd_radar").shapes=[B([-1,43,-1],[1,46,1],"frame"),B([-7,46,-1],[7,48,1],"plate")];p("hd_radar").pivot=[0,43,0];anchors.head=[0,42,-4];anchors.top=[0,47,0];}
return {...repair(lib,spec),anchors};
}
;fix
