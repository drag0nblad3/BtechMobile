function revise(lib,build,repair,id){
const {B,L,cyl}=lib;let s=build(lib,id),p=n=>s.parts.find(q=>q.name===n);let log=[];
function shift(name,axis,d){let q=p(name);if(!q)return;for(let sh of q.shapes){let ax={x:[0,1,2],y:[1,0,2],z:[2,0,1]}[sh.axis];for(let se of sh.sections)if(ax[0]===axis)se.at+=d;else for(let v of se.polygon)v[ax.indexOf(axis)-1]+=d}q.pivot[axis]+=d}
function merge(name){let q=p(name),pa=p(q.parent);pa.shapes.push(...q.shapes);s.parts=s.parts.filter(x=>x!==q);log.push("Integrated "+name+" into "+pa.name+" as distinct armor loft, avoiding floating overlay")}
if(["blackjack","jagermech"].includes(id)){for(let q of ["l","r"]){let a=p(q+"a"),f=p(q+"a_forearm"),g=p(q+"a_gun"),x=f.pivot[0],y=f.pivot[1],w=2.4;f.shapes=[L("z",[[-7,x-w,x+w,y-w,y+w,.1],[-5,x-w-0.4,x+w+0.4,y-w-0.5,y+w+0.5,.12],[-3,x-w,x+w,y-w,y+w,.08]],"frame")];g.shapes=g.shapes.map(sh=>{if(sh.axis!=="z")return sh;return {...sh,sections:sh.sections.map(se=>({...se,at:se.at-3}))}});g.pivot[2]-=3;let m=s.muzzles[q.toUpperCase()+"A"];s.muzzles[q.toUpperCase()+"A"]=Array.isArray(m[0])?m.map(t=>[t[0],t[1],t[2]-3]):[m[0],m[1],m[2]-3];log.push("Rebuilt forward high gun collar "+q)}}
if(["archer","charger","hatchetman","hunchback","blackjack","warhammer"].includes(id))for(let q of ["l","r"])merge(q+"l_kneecap");
if(["banshee","battlemaster","warhammer"].includes(id)){for(let n of id==="warhammer"?["rt_rack","lt_searchlight"]:["lt_rack"]){let a=p(n),x=a.pivot[0],y=a.pivot[1],q=p(a.parent);a.shapes.push(B([x-2,y-2,-2],[x+2,y+3,2],"frame"));a.parent="ct";log.push("Rebuilt "+n+" attachment directly into supported torso roof")}}
if(id==="hatchetman"){let a=p("ra_axe"),x=a.pivot[0],y=a.pivot[1];a.shapes=[cyl("y",y-7,y+11,x,0,1.5,1.5,"frame"),L("x",[[x-1.4,y+5,y+12,-7,1,.12],[x+1.4,y+5,y+12,-7,1,.12]],"plate")];log.push("Rebuilt continuous haft-to-edge axe blade");}
if(id==="trebuchet"){let g=p("ra_gun"),x=g.pivot[0],y=g.pivot[1],z=g.pivot[2];g.shapes=[L("z",[[z-5,x-1.7,x+1.7,y-1.7,y+1.7,.18],[z-2,x-2.5,x+2.5,y-2.5,y+2.5,.12],[z+1,x-2.4,x+2.4,y-2.4,y+2.4,.1]],"gun"),cyl("z",z-5,z-3,x,y,1,1,"gun","subtract")];s.muzzles.RA=[x,y,z-5];log.push("Rebuilt short weapon housing and barrel throat");}
let r=repair(lib,s);return {...r,log};
}
;revise
