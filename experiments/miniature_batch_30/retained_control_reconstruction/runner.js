// Experimental directional panel reconstruction; freeze photo and joint registration.
function directionalReconstruction(lib,round,spec,review){
 const R=eval(round)(lib),K=p=>p.join(","),V=k=>k.split(",").map(Number),D=[[1,0,0],[-1,0,0],[0,1,0],[0,-1,0],[0,0,1],[0,0,-1]],add=(p,d)=>p.map((v,i)=>v+d[i]),armor=v=>v==="armor"||v==="plate";
 const original=lib.clone(spec),base=lib.raster(spec),by=Object.fromEntries(spec.parts.map(p=>[p.name,p]));let maps=base;
 const names=new Set(Object.keys(maps));review=lib.clone(review);for(const p of review.photos){p.regions=p.regions.map(q=>({...q,parts:q.parts.filter(n=>names.has(n))})).filter(q=>q.parts.length);p.chains=(p.chains||[]).filter(q=>names.has(q.root)&&names.has(q.child));}review.photos=review.photos.filter(p=>p.regions.length&&Object.keys(p.rigid||{}).filter(k=>review.anchors[k]).length>=3);
 let reg=R.register(spec,review),initial=R.measure(spec,maps,reg),current=initial;
 const startAudit=lib.audit(spec,base);if(startAudit.faults.length)throw Error("baseline fault");
 const occ=m=>new Set(Object.values(m).flatMap(x=>[...x.keys()])),o=occ(base),blocked=new Set(),samples=[];
 for(const v of Object.values(spec.muzzles||{}))for(const q of (Array.isArray(v[0])?v:[v]))if(q.length===3&&q.every(Number.isFinite)){let p=q.map(Math.floor),ks=[0,1,2].map(z=>K([p[0],p[1],p[2]+z]));let clear=ks.every(k=>!o.has(k));samples.push({ks,clear});if(clear)ks.forEach(k=>blocked.add(k))}
 function diff(a,b){let n=0;for(let [k,v] of a)if(b.get(k)!==v)n++;for(let k of b.keys())if(!a.has(k))n++;return n}
 function strip(m,n,axis,sign,mode){
  let old=m[n],out=new Map(old),others=new Map();for(const [p,mm] of Object.entries(m))if(p!==n)for(const k of mm.keys())others.set(k,p);
  let dir=D[2*axis+(sign===1?0:1)],orth=D.filter((_,i)=>Math.floor(i/2)!==axis),protectedCells=new Set();
  for(const [k,v] of old){let p=V(k);if(!armor(v)){protectedCells.add(k);for(const d of D)protectedCells.add(K(add(p,d)))}for(const d of D)if(others.has(K(add(p,d)))){protectedCells.add(k);for(const t of D)protectedCells.add(K(add(p,t)))}}
  for(const [k,v] of old){if(!armor(v)||protectedCells.has(k))continue;let p=V(k),next=add(p,dir),nk=K(next);if(old.has(nk)||others.has(nk))continue;
   if(mode==="trim"){if(orth.filter(d=>old.has(K(add(p,d)))).length>=2)out.delete(k);}
   else if(!blocked.has(nk)&&orth.filter(d=>old.has(K(add(p,d)))).length>=3&&!D.some(d=>others.has(K(add(next,d)))))out.set(nk,v);
  }
  return out;
 }
 const groups=[["ct","lt","rt"],["hd"],["la","ra"],["la_forearm","ra_forearm"],["ll","rl"],["ll_shin","rl_shin"],["ll_tarsus","rl_tarsus"],["ll_foot","rl_foot"]].map(g=>g.filter(n=>maps[n]?.size>=40)).filter(g=>g.length);
 const local=(scores,g)=>{let a=scores.flatMap((v,i)=>reg[i].photo.regions.filter(z=>z.parts.some(n=>g.includes(n))).map(z=>v.regions[z.name].iou));return a.length?a.reduce((s,x)=>s+x,0)/a.length:0};
 groups.sort((a,b)=>local(initial,a)-local(initial,b));let history=[],selected=[];
 function saveDelta(s,n,a,b){let p=s.parts.find(q=>q.name===n),rows=new Map();function put(k,op,mat){let [x,y,z]=V(k),key=JSON.stringify([y,z,op,mat]);if(!rows.has(key))rows.set(key,[]);rows.get(key).push(x)}for(let [k,v] of a)if(!b.has(k))put(k,"subtract","frame");for(let [k,v] of b)if(a.get(k)!==v)put(k,"add",v);for(let [key,xs] of rows){let [y,z,op,mat]=JSON.parse(key);xs.sort((a,b)=>a-b);let st=xs[0],en=st;for(let x of [...xs.slice(1),null]){if(x===en+1){en=x;continue}p.shapes.push(lib.B([st,y,z],[en+1,y+1,z+1],mat,op));st=en=x}}}
 for(const group of groups){let best=null,oldScore=R.mean(current),oldLocal=local(current,group),trials=[];
  for(const axis of [0,1,2])for(const sign of [-1,1])for(const mode of ["trim","extend"]){
   let candidate={...maps},paired=group.length===2&&group[0][0]==="l"&&group[1][0]==="r";
   for(const n of group){let s=axis===0&&paired&&n[0]==="l"?-sign:sign;candidate[n]=strip(maps,n,axis,s,mode)}
   let changed=group.reduce((s,n)=>s+diff(maps[n],candidate[n]),0);if(changed<12)continue;
   let qa=lib.audit(spec,candidate),occupied=occ(candidate);if(qa.faults.length||[...blocked].some(k=>occupied.has(k))){trials.push({axis,sign,mode,changed,status:"structure"});continue}
   let scores=R.measure(spec,candidate,reg),score=R.mean(scores),localScore=local(scores,group),worst=Math.min(...scores.flatMap((v,i)=>Object.entries(v.regions).map(([k,x])=>x.iou-current[i].regions[k].iou))),viewLoss=Math.min(...scores.map((v,i)=>R.mean([v])-R.mean([current[i]])));
   let ok=score>oldScore+.00015&&localScore>oldLocal&&worst>=-.025&&viewLoss>=-.002;let row={axis,sign,mode,changed,score,localScore,worst,viewLoss,status:ok?"eligible":"photo"};trials.push(row);if(ok&&(!best||score>best.score))best={candidate,scores,score,row};
  }
  if(best){let next=lib.clone(spec);for(const n of group)saveDelta(next,n,maps[n],best.candidate[n]);let replay=lib.raster(next);if(Object.keys(replay).every(n=>diff(replay[n],best.candidate[n])===0)&&!lib.audit(next,replay).faults.length){spec=next;maps=replay;current=best.scores;selected.push({group,...best.row})}}
  history.push({group,trials});
 }
 let final=lib.audit(spec,maps),finalOcc=occ(maps),views=reg.map((v,i)=>({name:v.photo.name,cameraRms:v.camera.rmse,poseRms:v.pose.residuals,before:R.mean([initial[i]]),after:R.mean([current[i]])})),regression=views.some(v=>v.after<v.before-.003)||current.some((v,i)=>Object.entries(v.regions).some(([k,x])=>x.iou<initial[i].regions[k].iou-.035));
 if(regression||final.faults.length||[...blocked].some(k=>finalOcc.has(k))){spec=original;maps=base;current=initial;selected=[];views.forEach(v=>v.after=v.before)}
 const summary={id:spec.id,before:R.mean(initial),after:R.mean(current),views,selected,history,changed:Object.keys(base).reduce((s,n)=>s+diff(base[n],maps[n]),0),faults:lib.audit(spec,maps).faults,clearBefore:samples.filter(x=>x.clear).length,clearAfter:samples.filter(x=>x.ks.every(k=>!occ(maps).has(k))).length,totalSamples:samples.length};
 return {summary,deltas:spec.parts.flatMap(p=>{let orig=original.parts.find(x=>x.name===p.name);return p.shapes.length>orig.shapes.length?[{part:p.name,appendShapes:p.shapes.slice(orig.shapes.length)}]:[]})};
}
;directionalReconstruction
