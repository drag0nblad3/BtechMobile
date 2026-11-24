// Experimental, data-driven batch search. Evaluate as a function with existing lab + round2 source.
function run30(lib0,roundSource,inputs){
 const all=[]; const patched=roundSource.replace("let accepted=overall>=mean(prior)-.00001","let accepted=scores.every((view,i)=>mean([view])>=mean([prior[i]])-.005)&&overall>=mean(prior)-.00001");
 if(patched===roundSource)throw Error("could not install per-view gate");
 const make=eval(patched);
 for(const {id,spec,review,source} of inputs){let cache=new Map(),hits=0,misses=0;const lib={...lib0,raster(s){let o={};for(let p of s.parts){let k=JSON.stringify(p),m=cache.get(k);if(m){hits++}else{misses++;m=lib0.raster({...s,parts:[p]})[p.name];cache.set(k,m)}o[p.name]=new Map(m)}return o}};
 const base=lib.clone(spec),valid=new Set(base.parts.map(p=>p.name)),r2=make(lib);let annotations=lib.clone(review);
 try{
  if(!annotations?.anchors||!annotations?.photos?.length)throw Error("missing photo registration");
  for(let p of annotations.photos){p.regions=p.regions.filter(r=>r.parts.some(n=>valid.has(n))).map(r=>({...r,parts:r.parts.filter(n=>valid.has(n))}));p.chains=(p.chains||[]).filter(c=>valid.has(c.root)&&valid.has(c.child));if(!p.regions.length||Object.keys(p.rigid).filter(k=>annotations.anchors[k]).length<3)throw Error("insufficient matched landmarks or regions")}
  const groups=[];const groupDefs=[["core",n=>/^(ct|hd|lt|rt)$/.test(n)],["arms",n=>/^[lr]a(_forearm)?$/.test(n)],["legs",n=>/^[lr]l(_shin|_tarsus)?$/.test(n)],["feet",n=>/^[lr]l_foot$/.test(n)]];
  for(let [name,match] of groupDefs){let names=base.parts.filter(p=>match(p.name)&&p.shapes[0]?.op==="add"&&p.shapes[0].sections.length>=2&&p.shapes[0].sections.every((s,i,a)=>!i||s.at>a[i-1].at&&s.polygon.length===a[0].polygon.length)).map(p=>p.name);if(!names.length)continue;
    let rs=[...new Set(annotations.photos.flatMap(p=>p.regions.filter(r=>r.parts.some(n=>names.includes(n))).map(r=>r.name)))];if(!rs.length)continue;
    let target="^(?:"+rs.map(s=>s.replace(/[.*+?^${}()|[\]\\]/g,"\\$&")).join("|")+")$";
    let variants=[];for(let [id,axis,scale,shift] of [["narrow",0,.82,0],["broaden",0,1.18,0],["flatten",2,.78,0],["deepen",2,1.22,0],["forward",2,1,-1],["back",2,1,1]]){let ns=names.filter(n=>base.parts.find(p=>p.name===n).shapes[0].axis!==["x","y","z"][axis]);if(ns.length)variants.push({id,edits:[{names:ns,scale:{[axis]:scale},shift:{[axis]:shift}}]})}if(variants.length)groups.push({name,target,variants});
  }
  const beforeMaps=lib.raster(base),qa=lib.audit(base,beforeMaps);if(qa.faults.length)throw Error("control faults: "+JSON.stringify(qa.faults.slice(0,2)));
  const r=r2.evaluate(base,annotations,groups);
  const sample=(s,m)=>{let o=new Set(Object.values(m).flatMap(x=>[...x.keys()])),a=[];for(let [loc,v] of Object.entries(s.muzzles||{}))for(let [i,p] of (Array.isArray(v[0])?v:[v]).entries()){if(!Array.isArray(p)||p.length!==3||p.some(x=>!Number.isFinite(x)))continue;a.push({key:loc+":"+i,clear:[0,1,2].every(z=>!o.has([Math.floor(p[0]),Math.floor(p[1]),Math.floor(p[2])+z].join(",")))})}return a};
  let b=sample(base,beforeMaps),a=sample(r.spec,lib.raster(r.spec)),regression=b.some((p,i)=>p.clear&&!a[i]?.clear);let mean=v=>Object.values(v).reduce((s,x)=>s+x.iou,0)/Object.keys(v).length;
  let views=r.views.map(v=>({name:v.view,before:mean(v.before),after:mean(v.after),cameraRms:v.camera.rmse,poseRms:v.pose.residuals}));
  const reject=regression||r.qa.faults.length||views.some(v=>v.after<v.before-.005);const selected=reject?base:r.spec;
  let summary={id,source,views,baseline:r.baseline,candidate:reject?r.baseline:r.candidate,changed:reject?0:r.changedCells,trials:r.history.reduce((n,g)=>n+g.attempts.length,0),faults:lib.audit(selected,lib.raster(selected)).faults.length,cache:{hits,misses},muzzles:{before:b.filter(p=>p.clear).length,after:(reject?b:a).filter(p=>p.clear).length,total:b.length},status:reject?"rejected":r.changedCells?"provisional improvement":"retained control",groups:r.history};
  all.push({id,spec:selected,summary});
 }catch(e){all.push({id,spec:base,summary:{id,source,status:"blocked",reason:String(e),cache:{hits,misses}}})}
 }return all
}
;run30
