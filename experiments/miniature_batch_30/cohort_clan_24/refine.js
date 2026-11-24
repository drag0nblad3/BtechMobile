// Second pass: distinct forward gun tubes, intact rear pod collars.
// Retain a trial only if every neutral source-cell structural gate passes.
function refine(lib,spec){
 const {raster,audit,cyl,loft,L,clone}=lib, original=clone(spec), maps=raster(spec);
 let trials=[], selected=clone(spec);
 for(const p of spec.parts.filter(p=>p.name.endsWith("_weapon"))){
  const pts=spec.muzzles[p.loc]; if(!Array.isArray(pts?.[0])||![2,3].includes(pts.length))continue;
  const trial=clone(selected), q=trial.parts.find(q=>q.name===p.name);
  const z=pts[0][2], collar=z+5, s=q.shapes.find(s=>s.axis==="z"&&s.op==="add"&&s.mat==="gun");if(!s)continue;
  const end=s.sections.at(-1).at;if(collar>=end-2)continue;
  // Preserve the rear collar cross-section exactly, replacing only the nose.
  const ss=s.sections;let j=ss.findIndex((v,i)=>i>0&&v.at>=collar),a=ss[j-1],b=ss[j],t=(collar-a.at)/(b.at-a.at);
  const poly=a.polygon.map((v,i)=>v.map((x,k)=>x+(b.polygon[i][k]-x)*t));
  s.sections=[{at:collar,polygon:poly},...ss.filter(v=>v.at>collar)];
  const additions=pts.map(([x,y])=>cyl("z",z,collar+2,x,y,1.25,1.25,"gun"));
  const idx=q.shapes.indexOf(s);q.shapes.splice(idx+1,0,...additions);
  const tm=raster(trial), qa=audit(trial,tm), change=[...maps[p.name].keys()].filter(k=>!tm[p.name].has(k)).length+[...tm[p.name].keys()].filter(k=>!maps[p.name].has(k)).length;
  trials.push({part:p.name,change,faults:qa.faults.length,accepted:qa.faults.length===0&&change>0});
  if(qa.faults.length===0&&change>0)selected=trial;
 }
 const qa=audit(selected,raster(selected));return {spec:selected,trials,qa};
}
function muzzleAudit(lib,spec){
 const maps=lib.raster(spec),all=new Set(Object.values(maps).flatMap(m=>[...m.keys()]));
 let points=0,open=0,blocked=[];
 for(const [loc,value] of Object.entries(spec.muzzles)){
  const pts=Array.isArray(value[0])?value:[value];
  for(const [x,y,z] of pts){points++;let key=[Math.floor(x),Math.floor(y),Math.floor(z)].join(",");if(!all.has(key))open++;else blocked.push({loc,point:[x,y,z]})}
 }
 return {points,open,blocked};
}
// Orthographic projections, rendered directly from selected occupied cells.
// Three views: front, quarter, side. Visible cells depth-sorted.
function thumbnail(lib,spec,yaw){
 const maps=lib.raster(spec),color=Object.fromEntries(spec.materials.map(m=>[m.name,m.color])),a=yaw*Math.PI/180,b=-8*Math.PI/180,px=new Map();
 let cells=Object.values(maps).flatMap(m=>[...m]),height=Math.max(...cells.map(([k])=>+k.split(",")[1]))+1,scale=47/height;
 for(const [k,m] of cells){const [x,y,z]=k.split(",").map(Number),u=x*Math.cos(a)+z*Math.sin(a),d=-x*Math.sin(a)+z*Math.cos(a),v=y*Math.cos(b)+d*Math.sin(b),depth=d*Math.cos(b)-y*Math.sin(b),ix=Math.round(32+scale*u),iy=Math.round(53-scale*v);
 const shade=1+Math.min(.15,Math.max(-.2,-depth/110)),c=color[m].match(/../g).map(h=>Math.round(Math.min(255,parseInt(h,16)*shade)).toString(16).padStart(2,"0")).join("");
 for(let dx=0;dx<=Math.floor(scale*.8);dx++)for(let dy=0;dy<=Math.floor(scale*.8);dy++){const k=(ix+dx)+","+(iy+dy),old=px.get(k);if(!old||old.depth>depth)px.set(k,{depth,c})}}
 const paths={};for(const [k,{c}] of px){const [x,y]=k.split(",");paths[c]=(paths[c]||"")+"M"+x+" "+y+"h1v1h-1z";}
 return Object.entries(paths).map(([c,d])=>'<path fill="#'+c+'" d="'+d+'"/>').join("");
}
;({refine,muzzleAudit,thumbnail})