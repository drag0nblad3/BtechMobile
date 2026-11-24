
function clone(x){return JSON.parse(JSON.stringify(x))}
const rad=Math.PI/180,xyz=k=>k.split(",").map(Number),mean=(vs,w)=>vs.reduce((s,v,i)=>s+v*w[i],0)/w.reduce((s,v)=>s+v,0);
function change(part,axis,factor,delta,center){
let scale=v=>center+(v-center)*factor+delta;
for(let s of [...(part.shapes||[]),...(part.add||[])]){
 let kind=["box","shell","erase"].find(k=>s[k]);
 if(kind){let a=s[kind][0],b=s[kind][1];a[axis]=Math.round(scale(a[axis]));b[axis]=Math.round(scale(b[axis]+1))-1;if(b[axis]<a[axis])b[axis]=a[axis]}
 else if(s.loft){let ax={x:0,y:1,z:2}[s.loft.axis],dim=[0,1,2].filter(i=>i!==ax);if(axis===ax)for(let q of s.loft.sections)q.at=+scale(q.at).toFixed(4);else for(let q of s.loft.sections)for(let v of q.polygon){let i=dim.indexOf(axis);v[i]=+scale(v[i]).toFixed(4)}}
}
delete part.detail;
}
function refine(j,refs,core,fit){
let maps=core.raster(j),cloud=fit.cloud(maps),w=refs.map(q=>q.weight||1),fits=refs.map(q=>fit.fit(j,q,cloud)),baseline=fits.map(q=>({rmse:q.rmse,hull_iou:q.iou})),changes=[];
const summary=(model,mp,fs)=>({objective:mean(fs.map(q=>q.objective),w),rmse:mean(fs.map(q=>q.rmse),w),hull_iou:mean(fs.map(q=>q.iou),w),visible_iou:mean(fs.map((q,i)=>fit.render(model,mp,q.p,q.flip,q,refs[i],96).visibleIoU),w)});
let base=summary(j,maps,fits),best=base;
for(let round=0;round<2;round++){
 let ranking={};for(let i=0;i<fits.length;i++)for(let q of fits[i].regions){let p=j.parts.find(p=>p.name===q.model);if(!p)continue;let source=p.mirror||p.name;if(!ranking[source])ranking[source]=[0,0];ranking[source][0]+=(1-q.iou)*w[i];ranking[source][1]+=w[i]}
 let candidates=Object.keys(ranking).filter(n=>j.parts.find(p=>p.name===n)?.shapes?.some(s=>s.loft)).sort((a,b)=>ranking[b][0]/ranking[b][1]-ranking[a][0]/ranking[a][1]).slice(0,5);
 let trials=[];
 for(let name of candidates){let pts=cloud[name];if(!pts?.length)continue;for(let axis of [0,1,2]){let center=(Math.min(...pts.map(q=>q[axis]))+Math.max(...pts.map(q=>q[axis])))/2;
  for(let [factor,delta] of [[.86,0],[1.14,0],[1,-1.5],[1,1.5]]){if(delta&&!(name==="hd"||name.includes("rack")||name.includes("srm")||name.includes("hunch")))continue;
  let cc={...cloud},scale=q=>q.map((v,i)=>i===axis?center+(v-center)*factor+delta:v);cc[name]=pts.map(scale);
  for(let p of j.parts.filter(p=>p.mirror===name)){let ctr=axis===0?-center:center,dd=axis===0?-delta:delta;cc[p.name]=cloud[p.name].map(q=>q.map((v,i)=>i===axis?ctr+(v-ctr)*factor+dd:v))}
  let fs=refs.map((a,i)=>fit.evaluate(j,a,cc,fits[i].p,fits[i].flip,fits[i].swap,true)),score=mean(fs.map(q=>q.objective),w);
  if(score<best.objective-.15)trials.push({name,axis,factor,delta,center,score});
 }}}
 trials.sort((a,b)=>a.score-b.score);let accepted=false;
 for(let t of trials.slice(0,5)){let candidate=clone(j);change(candidate.parts.find(p=>p.name===t.name),t.axis,t.factor,t.delta,t.center);let r;
  try{r=core.repair(candidate)}catch{continue}
  let check=core.audit(candidate);if(!check.pass||check.cells>bestCells(maps)*1.17||check.cells<bestCells(maps)*.84)continue;
  let c=fit.cloud(r.maps),fs=refs.map((a,i)=>fit.fit(candidate,a,c,fits[i])),s=summary(candidate,r.maps,fs);
  if(s.objective<best.objective-.1&&s.visible_iou>=best.visible_iou-.012){changes.push({...t,before:best,after:s,repair:r.changes});j=candidate;maps=r.maps;cloud=c;fits=fs;best=s;accepted=true;break}
 }
 if(!accepted)break
}
return {j,maps,fits,changes,baseline,base,best,validation:core.audit(j)};
function bestCells(mp){let all=new Set;for(let m of Object.values(mp))for(let k of m.keys())all.add(k);return all.size}
}
return {refine};