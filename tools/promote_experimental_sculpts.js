// Replay and materialize a selected source-cell sculpt while retaining authored
// lofts, part hierarchy, weapon coordinates and fine-grid detail.
// Origin: remaining_149/runner.js, exact source-neutral raster convention.
function promotion(){
const lib={clone:v=>JSON.parse(JSON.stringify(v))};

const K=v=>v.join(","),V=k=>k.split(",").map(Number),D=[[1,0,0],[-1,0,0],[0,1,0],[0,-1,0],[0,0,1],[0,0,-1]],plus=(a,b,n=1)=>a.map((v,i)=>v+b[i]*n),clone=lib.clone,armor=m=>["armor","plate","edge"].includes(m),swap=n=>n?.split("_").map(x=>({la:"ra",ra:"la",lt:"rt",rt:"lt",ll:"rl",rl:"ll"}[x]||x)).join("_"),locswap=l=>({LA:"RA",RA:"LA",LT:"RT",RT:"LT",LL:"RL",RL:"LL"}[l]||l);
function inside(poly,x,y){let f=false;for(let i=0,j=poly.length-1;i<poly.length;j=i++){let [a,b]=poly[j],[c,d]=poly[i],dx=c-a,dy=d-b;let cross=(x-a)*dy-(y-b)*dx;if(Math.abs(cross)<1e-8&&(x-a)*(x-c)+(y-b)*(y-d)<=1e-8)return true;if((d>y)!=(b>y)&&x<(a-c)*(y-d)/(b-d)+c)f=!f}return f}
function paint(m,shapes,voids){for(let sh of shapes||[]){if(sh.loft){let {axis="y",sections}=sh.loft;if(!["y","z"].includes(axis))throw Error("unsupported loft axis "+axis);let a=axis==="y"?1:2,u=0,v=axis==="y"?2:1,painted=new Map();for(let i=0;i<sections.length-1;i++){let l=sections[i],h=sections[i+1],lo=Math.trunc(l.at),hi=Math.trunc(h.at);if(l.polygon.length!==h.polygon.length||hi<lo)throw Error("invalid loft");for(let z=lo;z<=hi;z++){let t=hi===lo?0:(z-lo)/(hi-lo),p=l.polygon.map((q,j)=>q.map((x,k)=>x+(h.polygon[j][k]-x)*t)),xs=p.map(q=>q[0]),ys=p.map(q=>q[1]);for(let x=Math.floor(Math.min(...xs));x<Math.ceil(Math.max(...xs));x++)for(let y=Math.floor(Math.min(...ys));y<Math.ceil(Math.max(...ys));y++)if(inside(p,x+.5,y+.5)){let pos=[];pos[a]=z;pos[u]=x;pos[v]=y;painted.set(K(pos),sh.mat)}}}for(let [k,mat] of painted)if(!sh.hollow||D.some(d=>!painted.has(K(plus(V(k),d)))))m.set(k,mat);continue}
let kind=["box","shell","erase"].find(k=>sh[k]);if(!kind)throw Error("unknown native shape");let [lo,hi]=sh[kind].map(p=>p.map(Math.trunc));for(let x=lo[0];x<=hi[0];x++)for(let y=lo[1];y<=hi[1];y++)for(let z=lo[2];z<=hi[2];z++){let p=[x,y,z],k=K(p);if(kind==="erase"){m.delete(k);voids.add(k)}else m.set(k,kind==="shell"&&!p.some((n,i)=>n===lo[i]||n===hi[i])?sh.core||sh.mat:sh.mat)}}}
function native(j){let parts=[],maps={},voids=new Set(),vmap={};for(let p of j.parts){let m=new Map(),vv=new Set(),meta;if(p.mirror){let src=parts.find(x=>x.name===p.mirror);if(!src)throw Error("missing mirror");for(let [k,v] of maps[p.mirror]){let [x,y,z]=V(k);m.set(K([-x-1,y,z]),v)}for(let k of vmap[p.mirror]){let [x,y,z]=V(k);vv.add(K([-x-1,y,z]))}meta={...src,name:p.name,loc:locswap(src.loc),pivot:[-src.pivot[0],...src.pivot.slice(1)],parent:p.parent??swap(src.parent)}}else{meta={name:p.name,loc:p.loc,parent:p.parent||"",joint:p.joint||"",pivot:p.pivot||[0,0,0]};paint(m,p.shapes,vv)}paint(m,p.add,vv);parts.push(meta);maps[p.name]=m;vmap[p.name]=vv;for(let k of vv)voids.add(k)}
return {parts,maps,voids}}
function own(maps){let out=Object.fromEntries(Object.entries(maps).map(([n,m])=>[n,new Map(m)])),o=new Map(),overlap=0;for(let [n,m] of Object.entries(out).sort((a,b)=>a[1].size-b[1].size||a[0].localeCompare(b[0])))for(let k of m.keys())if(o.has(k)){m.delete(k);overlap++}else o.set(k,n);return {maps:out,o,overlap}}
function delta(a,b){let rows=new Map();function put(k,mat){let [x,y,z]=V(k),key=JSON.stringify([y,z,mat]);(rows.get(key)||rows.set(key,[]).get(key)).push(x)}for(let [k,v] of a)if(!b.has(k))put(k,null);for(let [k,v] of b)if(a.get(k)!==v)put(k,v);let out=[],count=0;for(let [key,xs] of rows){let [y,z,mat]=JSON.parse(key);xs.sort((a,b)=>a-b);let st=xs[0],en=st;for(let x of [...xs.slice(1),null]){if(x===en+1){en=x;continue}out.push(mat===null?{erase:[[st,y,z],[en,y,z]]}:{box:[[st,y,z],[en,y,z]],mat});count+=en-st+1;st=en=x}}return {out,count}}

function promote(source,record){
 const expected=own(native(source).maps).maps;
 for(const patch of record.patches||[]){if(!expected[patch.part])throw Error("unknown patch part");paint(expected[patch.part],patch.shapes,new Set());}
 const occupied=new Set();
 for(const m of Object.values(expected))for(const k of m.keys()){if(occupied.has(k))throw Error("overlapping selected geometry");occupied.add(k);}
 if(occupied.size!==record.final.cells)throw Error("exact selection replay count "+occupied.size+" != "+record.final.cells);
 const candidate=clone(source);
 for(const e of record.selected?.loftEdits||[]){const p=candidate.parts.find(p=>p.name===e.part);if(p?.shapes?.[e.shape]?.loft)p.shapes[e.shape].loft=clone(e.loft);}
 // Apply explicit residuals in parent/source order so a changed mirror
 // source cannot accidentally change the opposite side twice.
 const maps={};let edits=0;
 for(const p of candidate.parts){let m=new Map(),v=new Set();if(p.mirror){if(!maps[p.mirror])throw Error("unknown mirror");for(const [k,mat] of maps[p.mirror]){const [x,y,z]=V(k);m.set(K([-x-1,y,z]),mat);}}
 else paint(m,p.shapes,v);
 paint(m,p.add,v);
 const d=delta(m,expected[p.name]);
 if(d.out.length){p.add=[...(p.add||[]),...d.out];paint(m,d.out,v);edits+=d.out.length;}
 maps[p.name]=m;
 }
 const verification=native(candidate).maps;
 for(const [name,m] of Object.entries(verification)){const d=delta(m,expected[name]);if(d.count)throw Error("material/geometry replay mismatch "+name);}
 candidate.exclusive_parts=true;
 candidate.source_sculpt_promotion={revision:"20261124-exact-neutral-source-selection",source_blob:record.sha,expected_coarse_cells:record.final.cells,selected_from:record.selectedFrom||"",original_art_quality_revision:source.art_quality_revision||"",source_diagnostic_only:true};
 // Authored polygon edit plus exact residuals must not receive another
 // unrelated heuristic primary-shape transform during model loading.
 candidate.art_quality_revision="silhouette-and-weapon-clarity-20261121";
 return {candidate,edits};
}
function compatible(a,b){
 const signature=p=>JSON.stringify([p.name,p.loc||"",p.parent||"",p.joint||"",p.pivot||[0,0,0],p.mirror||"",p.shapes||[],p.add||[]]);
 return a.voxel_size===b.voxel_size&&a.parts?.length===b.parts?.length&&a.parts.every((p,i)=>signature(p)===signature(b.parts[i]))&&JSON.stringify(a.materials)===JSON.stringify(b.materials);
}
function transfer(high,source){
 const d=clone(high);
 for(let i=0;i<d.parts.length;i++){const p=d.parts[i],q=source.parts[i];for(const k of ["shapes","add"]){if(q[k])p[k]=clone(q[k]);else delete p[k];}}
 d.exclusive_parts=true;d.source_sculpt_promotion=clone(source.source_sculpt_promotion);d.art_quality_revision=source.art_quality_revision;
 return d;
}
return {promote,compatible,transfer};
}
