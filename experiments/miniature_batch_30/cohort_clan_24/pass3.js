// Refine external armor without translating joints. Subtractions run last so they cannot expose duplicate ownership.
function pass3(lib,source){
 const {clone,raster,audit,B}=lib;let spec=clone(source),history=[];
 const points=(s)=>Object.values(s.muzzles).flatMap(v=>Array.isArray(v[0])?v:[v]);
 const ray=(s,m)=>{let all=new Set(Object.values(m).flatMap(p=>[...p.keys()]));return points(s).filter(([x,y,z])=>[0,1,2].every(d=>!all.has([Math.floor(x),Math.floor(y),Math.floor(z)+d].join(",")))).length};
 function check(label,trial){const a=raster(spec),b=raster(trial),qa=audit(trial,b),delta=Object.keys(a).reduce((n,k)=>n+[...a[k].keys()].filter(v=>!b[k].has(v)).length+[...b[k].keys()].filter(v=>!a[k].has(v)).length,0),before=ray(spec,a),after=ray(trial,b),ok=delta>0&&!qa.faults.length&&after>=before;history.push({label,delta,faults:qa.faults.length,before,after,accepted:ok});if(ok)spec=trial;return ok}
 // Improve weapon cavity depth, including obstructions in neighbouring armor.
 let t=clone(spec),maps=raster(t);for(const [x,y,z] of points(t)){for(let d=0;d<3;d++){const p=[Math.floor(x),Math.floor(y),Math.floor(z)+d],key=p.join(",");for(const q of t.parts)if(maps[q.name].has(key))q.shapes.push(B(p,p.map(v=>v+1),"gun","subtract"))}}
 check("Clear first three axial muzzle cells across all owners",t);
 // Sculpt local corner relief on paired limb armor, preserving central attachment columns.
 const styles={
 timber_wolf:["l_shin","r_shin",2,.18],executioner:["la","ra",2,.22],nova:["la_forearm","ra_forearm",2,.2],grendel:["l_shin","r_shin",0,.2],
 dire_wolf:["ct",2,.14],stormcrow:["l_shin","r_shin",2,.18],shadow_cat:["hd",0,.18],mist_lynx:["ct",2,.19],
 summoner:["l_shin","r_shin",0,.15],gargoyle:["la_forearm","ra_forearm",2,.2],hellbringer:["ct",2,.18],mad_dog:["hd",0,.22],
 ice_ferret:["hd",0,.14],viper:["l_shin","r_shin",0,.23],warhawk:["ct",2,.14],nova_cat:["la","ra",2,.18],
 cougar:["hd",0,.15],kit_fox:["l_shin","r_shin",2,.18],fire_moth:["ct",0,.24],crossbow:["hd",0,.19],
 ebon_jaguar:["hd",0,.19],huntsman:["l_shin","r_shin",2,.18],kingfisher:["la","ra",2,.14],turkina:["hd",0,.17]};
 const config=styles[spec.id];if(config){const names=config.slice(0,-2),axis=config.at(-2),ratio=config.at(-1);
 for(const f of [ratio,ratio*.65,ratio*.4]){
  let trial=clone(spec);let m=raster(trial);
  for(const q of trial.parts.filter(p=>names.includes(p.name))){
   const cells=[...m[q.name].keys()].map(k=>k.split(",").map(Number));const lo=[0,1,2].map(i=>Math.min(...cells.map(c=>c[i]))),hi=[0,1,2].map(i=>Math.max(...cells.map(c=>c[i]))),mid=(lo[axis]+hi[axis])/2,half=(hi[axis]-lo[axis]+1)/2;
   // Relief tapers toward the free end; maintain the joint band and the central cross section.
   for(const p of cells){let y=(p[1]-lo[1])/Math.max(1,hi[1]-lo[1]);let end=q.name==="hd"?(hi[2]-p[2])/Math.max(1,hi[2]-lo[2]):q.name==="ct"?Math.sin(Math.PI*y):Math.sin(Math.PI*y);
    if(Math.abs(p[axis]-mid)>half*(1-f*end)&&end>.25&&Math.abs(p[1]-q.pivot[1])>2)q.shapes.push(B(p,p.map(v=>v+1),"armor","subtract"));
   }
  }
  if(check("Chassis-specific tapered armor relief "+names.join("/")+" "+f,trial))break;
 }}
 return {spec,history,qa:audit(spec,raster(spec)),axialClear:ray(spec,raster(spec)),points:points(spec).length};
}
;pass3