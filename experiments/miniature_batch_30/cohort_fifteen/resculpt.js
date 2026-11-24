function resculpt(lib,raw,id,mode=1){
const {L,B,cyl,ellipse,loft,sidePart}=lib;
const {spec,anchors}=raw;
const Y=(r,m)=>L("y",r,m),X=(r,m)=>L("x",r,m),Z=(r,m)=>L("z",r,m);
const p=n=>spec.parts.find(q=>q.name===n);
const ax={x:[0,1,2],y:[1,0,2],z:[2,0,1]};
function add(n,loc,parent,pivot,shapes,joint){const q={name:n,loc,parent,pivot,shapes};if(joint)q.joint=joint;spec.parts.push(q);return q}
function del(...names){spec.parts=spec.parts.filter(q=>!names.includes(q.name))}
function scale(q,axis,f,origin=q.pivot[axis],shift=0){for(let sh of q.shapes){let [a,u,v]=ax[sh.axis];for(let sec of sh.sections){if(a===axis)sec.at=origin+(sec.at-origin)*f+shift;else for(let pt of sec.polygon){let i=u===axis?0:1;pt[i]=origin+(pt[i]-origin)*f+shift}}}q.pivot[axis]=origin+(q.pivot[axis]-origin)*f+shift}
function shift(q,d){for(let i=0;i<3;i++)scale(q,i,1,q.pivot[i],d[i]);}
function replaceSym(n,shapes){let old=p("r"+n);if(!old)return;let left=p("l"+n);old.shapes=shapes;left.shapes=lib.clone(shapes).map(s=>{if(s.axis==="x")s.sections=s.sections.map(sec=>({...sec,at:-sec.at})).reverse();else for(let sec of s.sections)for(let a of sec.polygon)a[0]*=-1;return s});}
function clearMuzzle(loc){spec.muzzles[loc]=[]}
function rack(n,loc,parent,x,y,z,back,cols,rows,sep,round=false){
let rx=(cols-1)*sep/2+1.4,ry=(rows-1)*sep/2+1.4,pts=Array.from({length:cols*rows},(_,i)=>[x+(i%cols-(cols-1)/2)*sep,y+(Math.floor(i/cols)-(rows-1)/2)*sep]);
let sh=round?[cyl("z",z,back,x,y,Math.max(rx,ry),Math.max(rx,ry),"plate")]:[Z([[z,x-rx,x+rx,y-ry,y+ry,.11],[z+2,x-rx-.15,x+rx+.15,y-ry-.15,y+ry+.15,.12],[back,x-rx*.9,x+rx*.9,y-ry*.92,y+ry*.92,.2]],"plate")];sh.push(...pts.map(([a,b])=>cyl("z",z,z+2.5,a,b,.63,.63,"gun","subtract")));add(n,loc,parent,[x,y,back],sh);spec.muzzles[loc]=(spec.muzzles[loc]||[]).concat(pts.map(([a,b])=>[a,b,z]));
}
const fixes=[];
if(id==="jagermech"){p("ct_breast").shapes[0]=Z([[-7.5,-5.7,5.7,29,36,.2],[-5.3,-7.8,7.8,28,37,.15],[-2.5,-7.1,7.1,29,36,.12]],"plate");for(let q of ["l","r"])shift(p(q+"l_kneecap"),[0,0,-.7]);}
if(id==="summoner"){let g=p("ra_ppc"),x=g.pivot[0],y=g.pivot[1];p("ra_forearm").shapes.push(B([x-2.2,y-2.1,-5.5],[x+2.2,y+2.1,-2.5],"frame"))}
if(id==="warhammer"){let mount=p("rt_srm6_mount"),rackp=p("rt_srm6"),x=mount.pivot[0],y=mount.pivot[1];mount.shapes=[B([x-2.3,y-1,-3.2],[x+2.3,y+3.1,3.4],"frame")];shift(rackp,[0,1.6,-1.1]);spec.muzzles.RT=spec.muzzles.RT.map(v=>[v[0],v[1]+1.6,v[2]-1.1])}
if(!mode)return raw;
switch(id){
case "banshee":
p("hd").shapes=[Y([[41,-3,3,-3.6,2,.17],[43,-4,4,-5.5,2.5,.25],[46,-3.7,3.7,-4.8,2.5,.22],[48,-2.5,2.5,-3.8,1.5,.25]],"plate"),B([-2.5,43,-5.3],[2.5,44.5,-4.1],"glass","paint")];p("hd").pivot=[0,41,0];scale(p("ct"),2,.88,0);for(let q of ["l","r"])scale(p(q+"l"),2,.9);
break;
case "charger":
for(let q of ["l","r"]){scale(p(q+"a"),2,.82);scale(p(q+"l_shin"),2,.9)}
p("ct_breast").shapes=[Z([[-8,-3.6,3.6,32,38,.2],[-5.5,-6,6,31,39,.2],[-3,-6,6,31,38,.14]],"plate")];p("hd").shapes=[Y([[43,-3.4,3.4,-3.8,2,.2],[45,-4,4,-5.6,2.8,.22],[47,-3.4,3.4,-4.8,2,.23],[49,-2.3,2.3,-3.5,1.5,.2]],"plate"),B([-2.8,45,-5.4],[2.8,46.5,-4.5],"glass","paint")];
break;
case "enforcer":
for(let q of ["l","r"]){scale(p(q+"a"),1,.87);scale(p(q+"l_shin"),0,.87);scale(p(q+"l"),0,.9)}
p("hd").shapes=[Y([[38,-3,3,-3.7,2,.15],[39.7,-3.8,3.8,-5.5,2.5,.2],[43,-3.5,3.5,-4.8,2.4,.16],[44,-2.5,2.5,-3.4,1.6,.2]],"plate"),B([-2.4,40,-5.4],[2.4,41.6,-4.5],"glass","paint")];break;
case "hatchetman":
// Long faceted armored skull with a narrow low jaw, not a ball on a stalk.
p("hd").shapes=[Z([[-9,-2.5,2.5,36,41,.2],[-6,-3.6,3.6,36.5,45,.12],[-3,-4.2,4.2,38,46,.16],[2,-3.1,3.1,39,44,.2]],"plate"),B([-2.6,39,-8],[2.6,40.6,-6.2],"glass","paint")];p("hd").pivot=[0,39,0];anchors.head=[0,39,-8];anchors.top=[0,46,0];scale(p("ct"),0,.90,0);for(let q of ["l","r"])scale(p(q+"l_shin"),2,.85);
break;
case "highlander":
p("hd").shapes=[Y([[42,-3.6,3.6,-4.8,2,.13],[44,-4.7,4.7,-6,2.5,.13],[47,-4.4,4.4,-5.2,2.5,.17],[48,-3.7,3.7,-4.5,2,.15]],"plate"),B([-3.6,44.1,-5.8],[3.6,46,-5],"glass","paint")];for(let q of ["l","r"])scale(p(q+"l_shin"),2,1.12);break;
case "jagermech":
case "rifleman":{
let y=p("hd").shapes[0].sections.at(-1).at;add("hd_radar","HD","hd",[0,y,0],[B([-1.5,y-.7,-1.2],[1.5,y+2,1.2],"frame"),X([[-7,y+1.5,y+3.2,-1,1,.15],[-5,y+1.6,y+3.5,-1.3,1.3,.15],[5,y+1.6,y+3.5,-1.3,1.3,.15],[7,y+1.5,y+3.2,-1,1,.15]],"plate")]);anchors.top=[0,y+3,0];
if(id==="rifleman"){scale(p("ct"),1,.86,p("ct").pivot[1]);scale(p("ct"),2,.88,0)}
break;
}
case "phoenix_hawk":
for(let q of ["l","r"]){let jump=p(q+"t_jump");scale(jump,1,1.18,jump.pivot[1]);scale(jump,2,.85);scale(p(q+"l_shin"),0,.92)}
p("hd").shapes=[Z([[-7,-2.1,2.1,41,43.5,.2],[-4,-3,3,41,46,.15],[0,-3.3,3.3,42,46.8,.2],[3,-2.6,2.6,42,45,.2]],"plate"),B([-2.4,42,-6], [2.4,43.5,-4],"glass","paint")];anchors.head=[0,42,-6];break;
case "trebuchet":{
del("rt_lrm15","rt_lrm15_mount");clearMuzzle("RT");let x=7.5,y=35; // torso-embedded launcher face, not a separate roof tower
p("rt").shapes.push(B([x-2.1,y-3,-5.5],[x+2.1,y+3,-2],"frame"));
rack("rt_lrm15","RT","rt",x,y,-8.5,-5,3,5,1.6);
for(let q of ["l","r"]){scale(p(q+"a"),2,.82);scale(p(q+"l_shin"),0,.9)}
break;
}
case "warhammer":
// Sink helmet into the shoulder plane and preserve a distinct forehead.
p("hd").shapes=[Z([[-7,-2.4,2.4,36,41,.16],[-4,-3.3,3.3,37,43,.18],[1,-3,3,38,42.7,.16],[3,-2.3,2.3,38,41,.15]],"plate"),B([-2.1,38,-6.8],[2.1,39.5,-5],"glass","paint")];anchors.head=[0,39,-6];anchors.top=[0,43,0];for(let q of ["l","r"]){scale(p(q+"l_shin"),0,1.08);scale(p(q+"a"),1,.9)}break;
case "timber_wolf":
// Curved egg-shaped cockpit, with nose genuinely rounded in both sections.
p("hd").shapes=[loft("z",[[-21,ellipse(0,30.4,1.6,2.0,20)],[-18,ellipse(0,31,4.4,3.9,20)],[-14,ellipse(0,32,6.0,5.1,20)],[-10,ellipse(0,33,6.6,5.4,20)],[-6,ellipse(0,33,5.2,4.5,20)]],"plate"),B([-4,31,-19],[4,33.3,-15.5],"glass","paint")];anchors.head=[0,31,-20];for(let q of ["l","r"]){scale(p(q+"l_shin"),0,1.12);scale(p(q+"l_shin"),2,1.08)}break;
case "mad_dog":{
// The twin arrays are raked slabs adjacent to the central wedge.
for(let q of ["l","r"]){let loc=q.toUpperCase()+"T",sign=q==="l"?-1:1;del(q+"t_lrm20",q+"t_lrm20_mount");clearMuzzle(loc);let x=sign*9.7,y=35;
let rows=Array.from({length:5},(_,i)=>{let yy=29.5+i*2.0,z=-9.2+i*1.12;return [yy,x-4.1,x+4.1,z,z+6.5,.12]});
let sh=[Y(rows,"plate")];let pts=[];for(let iy=0;iy<5;iy++)for(let ix=0;ix<4;ix++){let xx=x+(ix-1.5)*1.85,yy=29.9+iy*1.88,z=-9.1+iy*1.12;sh.push(cyl("z",z-.7,z+2.6,xx,yy,.66,.66,"gun","subtract"));pts.push([xx,yy,z]);}
p(q+"t").shapes.push(B([x-2.2,31,-4],[x+2.2,36,2],"frame"));add(q+"t_lrm20",loc,q+"t",[x,y,0],sh);spec.muzzles[loc]=pts;}
p("hd").shapes=[Z([[-17,-3.4,3.4,27,32,.16],[-13,-4.2,4.2,28,35,.18],[-8,-5.0,5.0,31,39,.17],[-4,-4.6,4.6,31,38,.13]],"plate"),B([-3.2,30,-14],[3.2,33,-10],"glass","paint")];anchors.head=[0,30,-15];anchors.top=[0,39,-4];break;
}
case "nova":{
// Broad flat shoulder beam and six separate barrels per hand, with short elbow.
for(let q of ["l","r"]){let s=q==="l"?-1:1,loc=q.toUpperCase()+"A",x=p(q+"a").pivot[0]+s*3.2,y=24;del(q+"a_six_lasers");clearMuzzle(loc);let fore=p(q+"a_forearm");fore.shapes.push(B([x-3,y-2,-4.4],[x+3,y+2,-1],"frame"));let sh=[];for(let row=0;row<2;row++)for(let col=0;col<3;col++){let xx=x+(col-1)*2.2,yy=y+(row-.5)*2.2;sh.push(cyl("z",-13,-3,xx,yy,1.15,1.15,"gun"),cyl("z",-13,-10,xx,yy,.65,.65,"gun","subtract"));spec.muzzles[loc].push([xx,yy,-13])}sh.unshift(B([x-3.3,y-2.1,-5],[x+3.3,y+2.1,-3.5],"frame"));add(q+"a_six_lasers",loc,fore.name,[x,y,-4],sh)}
scale(p("ct"),0,1.1,0);p("hd").shapes=[Z([[-17,-1.8,1.8,24,28,.19],[-13,-3.1,3.1,24,31,.18],[-8,-4,4,26,34,.15],[-5,-4,4,27,33,.13]],"plate"),B([-2,28,-13],[2,30,-10],"glass","paint")];anchors.head=[0,28,-13];anchors.top=[0,37,0];break;
}
case "summoner":{
// Cylindrical single roof launcher; retain the same fifteen ports.
let q="l",old=p("lt_lrm15"),x=old.pivot[0],y=old.pivot[1],z=-8;
del("lt_lrm15");clearMuzzle("LT");rack("lt_lrm15","LT","lt_lrm15_mount",x,y,z,3.1,3,5,1.7,true);
p("hd").shapes=[Z([[-7,-2.8,2.8,37,40,.14],[-4,-3.7,3.7,38,43,.18],[2,-3.3,3.3,39,42,.15]],"plate"),B([-2.5,38.4,-6.8],[2.5,39.7,-5],"glass","paint")];anchors.head=[0,39,-6];anchors.top=[0,43,0];break;
}
case "jenner":{
// Horizontal saucer: elliptic sections around Y, extended forwards.
p("hd").shapes=[loft("y",[[27.5,ellipse(0,-12.8,4,6,20)],[29,ellipse(0,-13.8,6.4,8.6,20)],[31.7,ellipse(0,-13.8,7.2,9.3,20)],[34,ellipse(0,-12.8,5.6,7.4,20)],[35,ellipse(0,-11,3.4,4.2,20)]],"plate"),B([-4,31,-22],[4,32.8,-19],"glass","paint")];p("hd").pivot=[0,32,-7];anchors.head=[0,31,-22];anchors.top=[0,39,0];for(let q of ["l","r"]){let f=p(q+"a_forearm");scale(f,1,.45,f.pivot[1]);scale(p(q+"a"),2,.9)}
break;
}
}
return {spec,anchors};
}
resculpt