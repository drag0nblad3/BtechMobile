function refit(lib,repair,source,photos){
 const {clone,raster,audit,fitCamera,fitPose,visibleMasks,L,B,cyl}=lib;
 const id=source.id,parts=Object.fromEntries(source.parts.map(p=>[p.name,p])),a=parts.hd.pivot,anchors={waist:parts.pelvis.pivot,head:[a[0],a[1],a[2]-3],rs:parts.ra.pivot,ls:parts.la.pivot};
 const mean=m=>Object.values(m).reduce((a,b)=>a+b.iou,0)/Object.keys(m).length;
 const initialMaps=raster(source),regs=photos.map(photo=>{let camera=fitCamera(anchors,photo),pose=fitPose(source,photo,camera),masks=visibleMasks(source,initialMaps,photo,camera,pose.pose);return {photo,camera,pose,masks,mean:mean(masks)}});
 function transform(s,names,axis,scale,shift=0){for(const p of s.parts.filter(p=>names.includes(p.name))){const pivot=p.pivot[axis];for(const sh of p.shapes){const ax={x:[0,1,2],y:[1,0,2],z:[2,0,1]}[sh.axis];for(const se of sh.sections){if(ax[0]===axis)se.at=pivot+(se.at-pivot)*scale+shift;else for(const v of se.polygon){const i=ax.indexOf(axis)-1;v[i]=pivot+(v[i]-pivot)*scale+shift;}}}if(p.name.endsWith("_weapon")||p.name.endsWith("_rack")||p.name==="dorsal_cannon"){for(const v of s.muzzles[p.loc]??[])v[axis]=pivot+(v[axis]-pivot)*scale+shift;}}}
 const variants=[];
 const add=(label,fn)=>variants.push({label,fn});
 const head=(s,shape)=>{s.parts.find(p=>p.name==="hd").shapes=shape};
 const paired=["la_weapon","ra_weapon"],legs=["ll_shin","rl_shin"];
 if(id==="king_crab"){
 add("Rebuild low, broad integrated cockpit prow",s=>{head(s,[L("z",[[-19,-5.5,5.5,25,29,.25],[-16,-9,9,24,33,.2],[-12,-10,10,27,35,.26],[-9,-8,8,28,35,.28]],"plate"),B([-5,25,-19],[5,28,-17],"glass","paint")]);});
 add("Reduce chest height and widen sloped shell",s=>{transform(s,["ct"],1,.82);transform(s,["ct"],0,1.1)});
 add("Broader claw housings",s=>{transform(s,paired,0,1.3);transform(s,paired,1,1.2)});
 add("Shorter armored claws",s=>transform(s,paired,2,.82));
 add("Wider lower legs",s=>transform(s,legs,0,1.25));
 }else if(id==="marauder_ii"){
 add("Long tapered cockpit wedge",s=>{head(s,[L("z",[[-21,-2,2,29,33,.22],[-16,-3.3,3.3,29,36,.19],[-11,-5,5,31,39,.2],[-7,-5.4,5.4,33,40,.2]],"plate"),B([-2,30,-21],[2,33,-19],"glass","paint")])});
 add("Paired stacked rectangular gun apertures",s=>{for(const q of ["l","r"]){let p=s.parts.find(p=>p.name===q+"a_weapon"),[x,y]=p.pivot,z=-17;p.shapes=[L("z",[[z,x-2.6,x+2.6,y-4,y+3,.2],[z+4,x-3.2,x+3.2,y-4.3,y+3.5,.16],[-2,x-3,x+3,y-3,y+3,.13]],"plate"),cyl("z",z,z+3,x,y+1,1,1,"gun","subtract"),cyl("z",z,z+3,x,y-2,1,1,"gun","subtract")];s.muzzles[p.loc]=[[x,y+1,z],[x,y-2,z]]}});
 add("Broader armored shin plates",s=>transform(s,legs,0,1.3));
 add("Shorter forward arm batteries",s=>transform(s,paired,2,.8));
 add("Taper rear body depth",s=>transform(s,["ct"],2,.85));
 }else{
 add("Tall sloped central nose extending between racks",s=>head(s,[L("z",[[-19,-2.4,2.4,25,30,.17],[-16,-3.7,3.7,26,34,.13],[-12,-4.2,4.2,29,39,.13],[-7,-4.2,4.2,33,44,.16],[-3,-3.8,3.8,36,44,.2]],"plate"),B([-2.5,28,-19],[2.5,30,-17],"glass","paint")]));
 add("Taller narrow shoulder missile banks",s=>{transform(s,["lt_rack","rt_rack"],0,.85);transform(s,["lt_rack","rt_rack"],1,1.18)});
 add("Lengthen paired arm guns",s=>transform(s,paired,2,1.22));
 add("Enlarge rounded lower-leg armor",s=>transform(s,legs,0,1.25));
 add("Reduce central torso depth",s=>transform(s,["ct"],2,.82));
 }
 let selected=clone(source),selectedScores=regs.map(r=>r.mean),trials=[];
 function channels(s,m){const all=new Set(Object.values(m).flatMap(p=>[...p.keys()]));const pts=Object.values(s.muzzles).flatMap(x=>Array.isArray(x[0])?x:[x]);return {total:pts.length,clear:pts.filter(([x,y,z])=>[0,1,2].every(d=>!all.has([Math.floor(x),Math.floor(y),Math.floor(z)+d].join(",")))).length}}
 for(const {label,fn} of variants){
  let candidate=clone(selected);fn(candidate);
  let fixed=repair(lib,candidate),m=raster(fixed.spec),qa=audit(fixed.spec,m);
  // clear nominal muzzle axes without creating isolated parts or thin joints
  let ch=channels(fixed.spec,m);if(ch.clear<ch.total){let c=clone(fixed.spec);for(const [x,y,z] of Object.values(c.muzzles).flatMap(v=>Array.isArray(v[0])?v:[v]))for(let d=0;d<3;d++){let p=[Math.floor(x),Math.floor(y),Math.floor(z)+d],k=p.join(",");for(const q of c.parts)if(m[q.name].has(k))q.shapes.push(B(p,p.map(v=>v+1),"gun","subtract"))}let nm=raster(c),nqa=audit(c,nm);if(!nqa.faults.length){fixed.spec=c;m=nm;qa=nqa;ch=channels(c,nm)}}
  const scores=regs.map(({photo,camera,pose})=>{let masks=visibleMasks(fixed.spec,m,photo,camera,pose.pose);return {masks,mean:mean(masks)}});
  const before=raster(selected),delta=Object.keys(before).reduce((n,k)=>n+[...before[k].keys()].filter(v=>!m[k].has(v)).length+[...m[k].keys()].filter(v=>!before[k].has(v)).length,0);
  const confidence=regs.every(r=>r.camera.rmse<=18&&Object.values(r.pose.residuals).every(v=>v<=35));
  const ok=delta>0&&qa.faults.length===0&&ch.clear===ch.total&&scores.every((v,i)=>v.mean>=selectedScores[i]-.015)&&scores.reduce((n,v)=>n+v.mean,0)>selectedScores.reduce((n,v)=>n+v,0)+.002;
  trials.push({label,delta,structuralFaults:qa.faults.slice(0,8),channels:ch,scores,accepted:ok,confidence,reason:ok?"Diagnostic improvement without substantial per-view regression; provisional only":"Rejected by fit or structural/aperture gate",candidate:fixed.spec});
  if(ok){selected=fixed.spec;selectedScores=scores.map(s=>s.mean)}
 }
 return {id,anchors,registrations:regs,trials,selected,selectedScores,qa:audit(selected,raster(selected)),channels:channels(selected,raster(selected))};
}
;refit