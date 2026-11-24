// Coordinated assembly search, with paired symmetry guard and frozen multi-view scoring.
function assemblyPass(lib,round,oldRunner,inputs){
 const R=eval(round)(lib);
 const helpers=eval(oldRunner.replace("const out=[];","return {candidate,writeDelta,samples,change}; const out=[];"))(lib,round,[]);
 const {candidate,writeDelta,samples,change}=helpers;
 const mean=a=>a.length?a.reduce((n,v)=>n+v,0)/a.length:0;
 const key=p=>p.join(","),vec=k=>k.split(",").map(Number),mirror=k=>{let [x,y,z]=vec(k);return key([-x-1,y,z])};
 const iou=(a,b)=>{let n=0;for(let k of a)if(b.has(k))n++;return n/(a.size+b.size-n||1)};
 const sym=(a,b)=>iou(new Set([...a.keys()].map(mirror)),new Set(b.keys()));
 const ret=[];
 for(let input of inputs){
 let {id,source,review}=input,spec=lib.clone(input.spec),maps=lib.raster(spec),base=maps,baselineQa=lib.audit(spec,maps),trials=[],accepted=[],unranked=[],reg=[],initial=null,current=null;
 const by=Object.fromEntries(spec.parts.map(p=>[p.name,p]));const present=n=>!!maps[n]&&maps[n].size>=60;
 const pairs=[["la","ra"],["la_forearm","ra_forearm"],["ll","rl"],["ll_shin","rl_shin"],["ll_tarsus","rl_tarsus"],["ll_foot","rl_foot"],["lt","rt"]].filter(p=>p.every(present));
 const eligible=new Set(["ct","hd",...pairs.flat()].filter(present));
 const bSamples=samples(spec,maps),blocked=new Set(bSamples.filter(x=>x.clear).flatMap(x=>x.keys));
 try{
  if(baselineQa.faults.length)throw Error("baseline neutral faults "+JSON.stringify(baselineQa.faults.slice(0,2)));
  if(review?.photos?.length&&review.anchors){let r=lib.clone(review);for(let p of r.photos){p.regions=(p.regions||[]).filter(z=>z.parts.some(n=>by[n])).map(z=>({...z,parts:z.parts.filter(n=>by[n])}));p.chains=(p.chains||[]).filter(z=>by[z.root]&&by[z.child])}r.photos=r.photos.filter(p=>p.regions.length&&Object.keys(p.rigid||{}).filter(k=>r.anchors[k]).length>=3);if(r.photos.length)reg=R.register(spec,r)}
  if(reg.length){initial=R.measure(spec,maps,reg);current=initial}
  const scorePart=n=>reg.length?mean(reg.flatMap((r,i)=>r.photo.regions.filter(z=>z.parts.includes(n)).map(z=>initial[i].regions[z.name].iou))):0;
  const refCount=n=>reg.filter(r=>r.camera.rmse<=18&&r.photo.regions.some(z=>z.parts.includes(n))&&!Object.entries(r.pose.residuals||{}).some(([root,v])=>v>30&&(n===root||n.startsWith(root+"_")))).length;
  const groups=[{id:"paired legs assembly",names:["ll","rl","ll_shin","rl_shin","ll_tarsus","rl_tarsus","ll_foot","rl_foot"]},{id:"paired arm assembly",names:["la","ra","la_forearm","ra_forearm"]},{id:"torso assembly",names:["ct","hd","lt","rt"]}].map(g=>({...g,names:g.names.filter(n=>eligible.has(n))})).filter(g=>g.names.length>=2);
  if(reg.length){for(let p of pairs.slice().sort((a,b)=>mean(a.map(scorePart))-mean(b.map(scorePart))).slice(0,2))groups.push({id:"pair "+p.join("/"),names:p,strictPair:true})}
  function pairedDelta(before,after,n1,n2,strict){
   let s0=sym(before[n1],before[n2]),s1=sym(after[n1],after[n2]);
   if(s0<.72||s1>=s0-.015)return {ok:true,before:s0,after:s1};
   if(!strict)return {ok:false,before:s0,after:s1};
   // Keep only mirrored compatible additions/removals. Never copy weapons, frame, or glass.
   let a=new Map(before[n1]),b=new Map(before[n2]);for(let [k,v] of before[n1]){let m=mirror(k);if(!after[n1].has(k)&&before[n2].has(m)&&!after[n2].has(m)&&["armor","plate"].includes(v)&&["armor","plate"].includes(before[n2].get(m))){a.delete(k);b.delete(m)}}
   for(let [k,v] of after[n1]){let m=mirror(k);if(!before[n1].has(k)&&!before[n2].has(m)&&after[n2].has(m)&&["armor","plate"].includes(v)&&["armor","plate"].includes(after[n2].get(m))){a.set(k,v);b.set(m,after[n2].get(m))}}
   after[n1]=a;after[n2]=b;s1=sym(a,b);return {ok:s1>=s0-.015,before:s0,after:s1};
  }
  for(let g of groups){let best=null,prior=maps,priorScore=current;
   const modes=reg.length?["photo_all","photo_strict_pair","photo_best_view","wedge","faceted"]:["wedge","rounded","faceted"];
   for(let mode of modes){
    let test={...prior},changedNames=[],symmetry=[],viewsUsed={},valid=true;
    for(let n of g.names){
     let rs=reg.filter(r=>r.camera.rmse<=18&&r.photo.regions.some(z=>z.parts.includes(n))&&!Object.entries(r.pose.residuals||{}).some(([root,v])=>v>30&&(n===root||n.startsWith(root+"_"))));
     if(mode==="photo_best_view")rs=rs.slice().sort((a,b)=>a.camera.rmse-b.camera.rmse).slice(0,1);
     if(mode.startsWith("photo")&&!rs.length)continue;
     viewsUsed[n]=mode.startsWith("photo")?rs.length:0;
     let c=candidate(spec,test,n,mode.startsWith("photo")?"photo_hull":mode,rs,blocked);if(c){test[n]=c.map;changedNames.push(n)}
    }
    for(let [a,b] of pairs.filter(p=>p.every(n=>g.names.includes(n)))){if(!changedNames.includes(a)&&!changedNames.includes(b))continue;
     let p=pairedDelta(prior,test,a,b,mode==="photo_strict_pair");symmetry.push({pair:[a,b],...p});if(!p.ok){valid=false;break}}
    changedNames=g.names.filter(n=>change(prior[n],test[n])>=Math.max(35,prior[n].size*.12));
    // Undo tiny deltas; never apply a one-sided change as a paired assembly.
    for(let n of g.names)if(!changedNames.includes(n))test[n]=prior[n];
    if(changedNames.length<2||g.strictPair&&changedNames.length!==g.names.length){trials.push({group:g.id,mode,status:"insufficient coordinated replacement",changedNames});continue}
    for(let [a,b] of pairs.filter(p=>p.every(n=>g.names.includes(n)))){let sa=sym(prior[a],prior[b]),sb=sym(test[a],test[b]);if(sa>=.72&&(sb<sa-.015||changedNames.includes(a)!==changedNames.includes(b))){valid=false;break}}
    if(!valid){trials.push({group:g.id,mode,status:"symmetry rejection",symmetry});continue}
    let qa=lib.audit(spec,test),afterS=samples(spec,test),newBlock=bSamples.some((p,i)=>p.clear&&!afterS[i]?.clear);if(qa.faults.length||newBlock){trials.push({group:g.id,mode,status:"structural rejection",faults:qa.faults.slice(0,4),newBlock});continue}
    let delta=changedNames.reduce((s,n)=>s+change(prior[n],test[n]),0);
    let sc=reg.length?R.measure(spec,test,reg):null,old=priorScore?R.mean(priorScore):null,next=sc?R.mean(sc):null,perView=sc?sc.map((v,i)=>R.mean([v])-R.mean([priorScore[i]])):[],worst=sc?Math.min(...sc.flatMap((v,i)=>Object.entries(v.regions).map(([k,x])=>x.iou-priorScore[i].regions[k].iou))):0;
    let local=sc?mean(sc.flatMap((v,i)=>reg[i].photo.regions.filter(z=>z.parts.some(n=>changedNames.includes(n))).map(z=>v.regions[z.name].iou-priorScore[i].regions[z.name].iou))):null;
    let ok=sc?next>old+.0005&&local>0&&perView.every(x=>x>=-.003)&&worst>=-.035:true;
    let tr={group:g.id,mode,changedNames,delta,score:next,local,perView,worst,symmetry,viewsUsed,status:ok?(sc?"eligible":"unranked pass"):"photo rejection"};trials.push(tr);
    if(ok&&(!best||(sc?next>best.tr.score:delta>best.tr.delta)))best={test,sc,tr};
   }
   if(best){let target=lib.clone(spec);for(let n of best.tr.changedNames)writeDelta(target,n,prior[n],best.test[n]);let replay=lib.raster(target),qa=lib.audit(target,replay),same=Object.keys(replay).every(n=>change(replay[n],best.test[n])===0);if(!same||qa.faults.length){trials.push({group:g.id,status:"roundtrip rejection"});continue}
    if(reg.length){spec=target;maps=replay;current=best.sc;accepted.push(best.tr)}
    else{unranked.push({spec:target,trial:best.tr})}
   }
  }
  let scoreBefore=initial?R.mean(initial):null,scoreAfter=current?R.mean(current):null,views=reg.map((r,i)=>({name:r.photo.name,cameraRms:r.camera.rmse,before:R.mean([initial[i]]),after:R.mean([current[i]])}));let finalQ=lib.audit(spec,maps),finalSamples=samples(spec,maps),reject=finalQ.faults.length||bSamples.some((p,i)=>p.clear&&!finalSamples[i]?.clear)||views.some(v=>v.after<v.before-.003);if(reject){spec=lib.clone(input.spec);maps=base;accepted=[];scoreAfter=scoreBefore;views=views.map(v=>({...v,after:v.before}))}
  ret.push({id,spec,unranked,summary:{id,source,status:reg.length?(accepted.length?"selected assembly improvement":"retained control"):(unranked.length?"unranked assembly alternatives":"no safe alternative"),before:scoreBefore,after:scoreAfter,views,usableViews:reg.filter(r=>r.camera.rmse<=18).length,trialCount:trials.length,accepted,unranked:unranked.map(x=>x.trial),trials,changed:Object.keys(base).reduce((s,n)=>s+change(base[n],maps[n]),0),faults:lib.audit(spec,maps).faults.length,muzzles:{before:bSamples.filter(x=>x.clear).length,after:samples(spec,maps).filter(x=>x.clear).length,total:bSamples.length}}})
 }catch(e){ret.push({id,spec:input.spec,unranked:[],summary:{id,source,status:"blocked",reason:String(e),trials,trialCount:trials.length,accepted:[],changed:0}})}
 }
 return ret;
}
;assemblyPass
