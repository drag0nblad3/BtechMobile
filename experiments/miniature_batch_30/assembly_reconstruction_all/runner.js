// Experimental independent component shell generation. 
function reconstructAssemblies(lib,round,inputs){
 const R=eval(round)(lib),K=p=>p.join(","),V=k=>k.split(",").map(Number),D=[[1,0,0],[-1,0,0],[0,1,0],[0,-1,0],[0,0,1],[0,0,-1]],add=(a,b,n=1)=>a.map((x,i)=>x+b[i]*n),mean=a=>a.length?a.reduce((n,x)=>n+x,0)/a.length:0,rad=a=>a*Math.PI/180;
 function rot(p,o,[a,b,c]){let [x,y,z]=p.map((v,i)=>v-o[i]);a=rad(a);b=rad(b);c=rad(c);[y,z]=[y*Math.cos(a)-z*Math.sin(a),y*Math.sin(a)+z*Math.cos(a)];[x,z]=[x*Math.cos(b)+z*Math.sin(b),-x*Math.sin(b)+z*Math.cos(b)];[x,y]=[x*Math.cos(c)-y*Math.sin(c),x*Math.sin(c)+y*Math.cos(c)];return [x+o[0],y+o[1],z+o[2]]}
 function project(p,c){let [x,y,z]=p.map((v,i)=>v-c.target[i]),a=rad(c.yaw),b=rad(c.elev),r=rad(c.roll),u=(c.flipX?-1:1)*(x*Math.cos(a)+z*Math.sin(a)),dep=-x*Math.sin(a)+z*Math.cos(a),v=y*Math.cos(b)+dep*Math.sin(b),d=c.distance+dep*Math.cos(b)-y*Math.sin(b);return [(Math.cos(r)*u-Math.sin(r)*v)*c.scale/d+c.tx,-(Math.sin(r)*u+Math.cos(r)*v)*c.scale/d+c.ty]}
 function inside(poly,x,y){let f=false;for(let i=0,j=poly.length-1;i<poly.length;j=i++){let [a,b]=poly[j],[c,d]=poly[i];if((d>y)!=(b>y)&&x<(a-c)*(y-d)/(b-d)+c)f=!f}return f}
 function samples(s,m){let o=new Set(Object.values(m).flatMap(x=>[...x.keys()])),out=[];for(let [loc,v] of Object.entries(s.muzzles||{}))for(let [i,p] of (Array.isArray(v[0])?v:[v]).entries()){if(!Array.isArray(p)||p.length!==3||p.some(x=>!Number.isFinite(x)))continue;let keys=[0,1,2].map(z=>K([Math.floor(p[0]),Math.floor(p[1]),Math.floor(p[2])+z]));out.push({id:loc+":"+i,keys,clear:keys.every(k=>!o.has(k))})}return out}
 function change(a,b){let n=0;for(let [k,v] of a)if(b.get(k)!==v)n++;for(let k of b.keys())if(!a.has(k))n++;return n}
 function writeDelta(spec,name,old,now){const p=spec.parts.find(q=>q.name===name);let rows=new Map();function put(k,op,mat){let [x,y,z]=V(k),key=JSON.stringify([y,z,op,mat]);if(!rows.has(key))rows.set(key,[]);rows.get(key).push(x)}for(let [k,v] of old)if(!now.has(k))put(k,"subtract","frame");for(let [k,v] of now)if(old.get(k)!==v)put(k,"add",v);for(let [key,xs] of rows){let [y,z,op,mat]=JSON.parse(key);xs.sort((a,b)=>a-b);let st=xs[0],en=st;for(let x of [...xs.slice(1),null]){if(x===en+1){en=x;continue}p.shapes.push(lib.B([st,y,z],[en+1,y+1,z+1],mat,op));st=en=x}}}
 function candidate(spec,maps,name,family,reg,blocked){
  let by=Object.fromEntries(spec.parts.map(p=>[p.name,p])),part=by[name],old=maps[name],others=new Map();for(let [n,m] of Object.entries(maps))if(n!==name)for(let k of m.keys())others.set(k,n);
  let armor=[...old].filter(([k,v])=>v==="armor"||v==="plate");if(armor.length<35)return null;
  let axis=({x:0,y:1,z:2})[part.shapes.find(s=>s.op==="add"&&["armor","plate"].includes(s.mat))?.axis]??1;let [u,v]=[0,1,2].filter(i=>i!==axis),xyz=armor.map(([k])=>V(k)),min=Math.min(...xyz.map(p=>p[axis])),max=Math.max(...xyz.map(p=>p[axis]));
  let collar=new Set(),allOld=new Set(old.keys());for(let [k,mat] of old){let p=V(k);if(!["armor","plate"].includes(mat))collar.add(k);for(let d of D){let n=others.get(K(add(p,d)));if(n&&(n===part.parent||by[n]?.parent===name)){collar.add(k);let inward=K(add(p,d,-1));if(old.has(inward))collar.add(inward)}}}
  let s=new Map();for(let k of collar)s.set(k,old.get(k));
  let stations=new Map();for(let p of xyz){let a=p[axis];if(!stations.has(a))stations.set(a,[]);stations.get(a).push(p)}
  const dominant=armor.filter(x=>x[1]==="plate").length>armor.length/2?"plate":"armor";
  let ranges={};for(let a=min;a<=max;a++){let q=stations.get(a)||[];if(!q.length)continue;ranges[a]=[u,v].map(i=>{let mn=Math.min(...q.map(p=>p[i])),mx=Math.max(...q.map(p=>p[i]));return [(mn+mx+1)/2,(mx-mn+1)/2]})}
  let chain=/^[lr][al]/.test(name)?name.slice(0,2):null;
  let refs=reg.flatMap(({photo,camera,pose})=>{let rr=photo.regions.filter(r=>r.parts.includes(name));return rr.length&&camera.rmse<=18&&(!chain||pose.residuals[chain]==null||pose.residuals[chain]<=35)?[{rr,camera,pose:pose.pose,weight:1/(1+(camera.rmse/10)**2+(chain?(pose.residuals[chain]||0)**2/400:0))}]:[]});
  if(family.startsWith("photo_")&&!refs.length)return null;
  function inPhoto(p){let good=0,total=0;for(let r of refs){let q=p.map(x=>x+.5),t=part;while(t){if(r.pose[t.name])q=rot(q,t.pivot,r.pose[t.name]);t=by[t.parent]}let [x,y]=project(q,r.camera);total+=r.weight;if(r.rr.some(z=>inside(z.polygon,x,y)))good+=r.weight}return total?good/total:1}
  function allowed(k,p){if(others.has(k)||blocked.has(k))return false;if(!old.has(k)){let neighbors=D.filter(d=>allOld.has(K(add(p,d)))).length;if(neighbors>=5)return false}return true}
  for(let a=min;a<=max;a++){if(!ranges[a])continue;let t=(a-min+.5)/(max-min+1),w=Math.sin(Math.PI*t),smooth=[0,1].map(i=>{let arr=[a-1,a,a+1].filter(k=>ranges[k]);return [mean(arr.map(k=>ranges[k][i][0])),mean(arr.map(k=>ranges[k][i][1]))]});
    let [[cu,ru],[cv,rv]]=smooth;let taper=family==="wedge"?(.67+.65*t):family==="bell"?(.72+.46*w):1;ru=Math.max(.65,ru*taper*(family==="rounded"?1.12:family==="faceted"?1.15:family.startsWith("photo_")?1.22:1));rv=Math.max(.65,rv*(family==="wedge"?(1.25-.4*t):family==="rounded"?1.10:family.startsWith("photo_")?1.22:1));if(family==="wedge")cv+=(t-.5)*rv*.34;
    for(let i=Math.floor(cu-ru);i<Math.ceil(cu+ru);i++)for(let j=Math.floor(cv-rv);j<Math.ceil(cv+rv);j++){
      let x=Math.abs((i+.5-cu)/ru),y=Math.abs((j+.5-cv)/rv),ok=family==="rounded"?x*x+y*y<=1:family==="faceted"?Math.max(x,y)<=1&&x+y<=1.48:family==="wedge"?Math.max(x,y)<=1&&x+y<=1.58:family==="bell"?Math.max(x,y)<=1&&x+y<=1.7:Math.max(x,y)<=1&&x+y<=1.85;if(!ok)continue;
      let p=[];p[axis]=a;p[u]=i;p[v]=j;let k=K(p);if(s.has(k)||!allowed(k,p))continue;
      if(family.startsWith("photo_")&&inPhoto(p)<(family==="photo_intersection"?(old.has(k)?.85:.999):(old.has(k)?.48:.72)))continue;
      s.set(k,old.get(k)||dominant);
    }
  }
  let comps=lib.components(s);if(comps.length>1){for(let c of comps.slice(1)){if(c.some(k=>collar.has(k))||c.length>Math.max(10,Math.round(s.size*.03)))return null;for(let k of c)s.delete(k)}}
  if(!s.size||s.size<old.size*.55||s.size>old.size*1.55)return null;let delta=change(old,s);if(delta<Math.max(18,old.size*.06))return null;
  return {map:s,delta,before:old.size,after:s.size};
 }

 const out=[];
 function symPair(maps,a,b,ca,cb){ // mirror only edit deltas, never replace asymmetric pre-existing geometry.
  const mirror=k=>{let p=V(k);p[0]=-p[0]-1;return K(p)};
  let A=maps[a],B=maps[b],common=[...A.keys()].filter(k=>B.has(mirror(k))).length,similar=2*common/(A.size+B.size);
  if(similar<.65)return null;
  let aa=new Map(A),bb=new Map(B),keys=new Set([...A.keys(),...ca.keys(),...[...B.keys(),...cb.keys()].map(mirror)]);
  for(let k of keys){let h=mirror(k),x=A.has(k),y=B.has(h),nx=ca.has(k),ny=cb.has(h);
   if(x!==nx&&y!==ny&&nx===ny){if(nx){aa.set(k,ca.get(k));bb.set(h,cb.get(h))}else{aa.delete(k);bb.delete(h)}}}
  return {a:aa,b:bb,similar,delta:change(A,aa)+change(B,bb)};
 }
 for(const input of inputs){
  const {id,source,review}=input;let spec=lib.clone(input.spec),baseMaps=lib.raster(spec),maps={...baseMaps},baseQa=lib.audit(spec,maps),baselineSamples=samples(spec,maps),blocked=new Set(baselineSamples.filter(x=>x.clear).flatMap(x=>x.keys)),trials=[],selected=[],proposals=[],reg=[],initial=null,current=null;
  try{
   if(baseQa.faults.length)throw Error("baseline fails neutral audit");
   if(review?.photos?.length){let by=new Set(spec.parts.map(p=>p.name)),r=lib.clone(review);for(let p of r.photos){p.regions=p.regions.filter(z=>z.parts.some(n=>by.has(n))).map(z=>({...z,parts:z.parts.filter(n=>by.has(n))}));p.chains=(p.chains||[]).filter(z=>by.has(z.root)&&by.has(z.child))}r.photos=r.photos.filter(p=>p.regions.length&&Object.keys(p.rigid||{}).filter(k=>r.anchors[k]).length>=3);if(r.photos.length)reg=R.register(spec,r)}
   if(reg.length){initial=R.measure(spec,maps,reg);current=initial}
   const has=n=>maps[n]?.size>=60;
   const groups=[{name:"paired arm assembly",parts:["la","ra","la_forearm","ra_forearm"],paired:true},{name:"paired leg assembly",parts:["ll","rl","ll_shin","rl_shin","ll_tarsus","rl_tarsus","ll_foot","rl_foot"],paired:true},{name:"core assembly",parts:["ct","lt","rt","hd"],paired:false}].map(g=>({...g,parts:g.parts.filter(has)})).filter(g=>g.parts.length>=2);
   let rank=groups.map(g=>({...g,score:initial?mean(initial.flatMap((v,i)=>reg[i].photo.regions.filter(z=>z.parts.some(n=>g.parts.includes(n))).map(z=>v.regions[z.name].iou))):null})).sort((a,b)=>(a.score??0)-(b.score??0));
   for(let group of rank){let best=null,priorScore=current;
    for(let family of ["faceted","wedge",...(reg.length?["photo_consensus","photo_intersection"]:["rounded"])])for(let mode of (group.paired?["symmetric","joint"]:["joint"])){
     let test={...maps},built={},deltas=[],pairChecks=[];
     // Build all replacements against the same pre-trial assembly, then audit together.
     for(let n of group.parts){let c=candidate(spec,maps,n,family,reg,blocked);if(c)built[n]=c.map}
     if(mode==="symmetric"){for(let a of group.parts.filter(n=>n.startsWith("l"))){let b="r"+a.slice(1);if(!built[a]||!built[b])continue;let p=symPair(maps,a,b,built[a],built[b]);if(p&&p.delta>=36&&change(maps[a],p.a)>=18&&change(maps[b],p.b)>=18){test[a]=p.a;test[b]=p.b;pairChecks.push({left:a,right:b,baselineSymmetry:p.similar,changed:p.delta})}}}
     else for(let [n,m] of Object.entries(built))test[n]=m;
     for(let n of group.parts){let d=change(maps[n],test[n]);if(d)deltas.push({part:n,delta:d})}
     let t={group:group.name,family,mode,parts:deltas,pairChecks,delta:deltas.reduce((n,x)=>n+x.delta,0)};
     if(deltas.length<2){trials.push({...t,status:"insufficient simultaneous changes"});continue}
     let qa=lib.audit(spec,test),newBlocks=samples(spec,test).filter((x,i)=>baselineSamples[i].clear&&!x.clear).length;
     if(qa.faults.length||newBlocks){trials.push({...t,status:"structural rejection",faults:qa.faults.slice(0,3),newBlocks});continue}
     let scores=reg.length?R.measure(spec,test,reg):null,score=scores?R.mean(scores):null,old=priorScore?R.mean(priorScore):null,perView=scores?scores.map((v,i)=>R.mean([v])-R.mean([priorScore[i]])):[],worst=scores?Math.min(...scores.flatMap((v,i)=>Object.entries(v.regions).map(([k,x])=>x.iou-priorScore[i].regions[k].iou))):0,local=scores?mean(scores.flatMap((v,i)=>reg[i].photo.regions.filter(z=>z.parts.some(n=>deltas.some(d=>d.part===n))).map(z=>v.regions[z.name].iou-priorScore[i].regions[z.name].iou))):null;
     // Strict joint acceptance across all reference views; avoid hidden regressions.
     let ok=scores?score>old+.0005&&local>0&&perView.every(x=>x>=-.003)&&worst>=-.035:true;
     // For joint edits to a nearly symmetric pair, reject newly introduced asymmetry > 0.04.
     let asym=[];for(let a of group.parts.filter(n=>n.startsWith("l"))){let b="r"+a.slice(1);if(!maps[b]||!test[b])continue;let mirror=k=>{let p=V(k);p[0]=-p[0]-1;return K(p)},similar=(A,B)=>2*[...A.keys()].filter(k=>B.has(mirror(k))).length/(A.size+B.size);let pre=similar(maps[a],maps[b]),post=similar(test[a],test[b]);if(pre>=.75&&post<pre-.04)asym.push({a,b,pre,post})}
     if(asym.length)ok=false;
     t={...t,score,local,perView,worst,asym,status:ok?(scores?"eligible":"unranked structural pass"):"photo or symmetry rejection"};trials.push(t);
     if(ok&&(!best||(scores?score>best.score+1e-8||(Math.abs(score-best.score)<1e-8&&mode==="symmetric"):t.delta>best.t.delta)))best={test,t,scores,score};
    }
    if(best){let next=lib.clone(spec);for(let d of best.t.parts)writeDelta(next,d.part,maps[d.part],best.test[d.part]);let replay=lib.raster(next),qa=lib.audit(next,replay),same=Object.keys(replay).every(n=>change(replay[n],best.test[n])===0);if(!same||qa.faults.length){trials.push({group:group.name,status:"roundtrip rejection",same,faults:qa.faults.slice(0,3)});continue}
     if(reg.length){spec=next;maps=best.test;current=best.scores;selected.push(best.t)}
     else proposals.push({group:group.name,delta:best.t.delta,mode:best.t.mode,family:best.t.family,spec:next,parts:best.t.parts});
    }
   }
   let remap=lib.raster(spec),qa=lib.audit(spec,remap),same=Object.keys(maps).every(n=>change(maps[n],remap[n])===0),afterSamples=samples(spec,remap),perView=initial?current.map((v,i)=>({name:v.view,before:R.mean([initial[i]]),after:R.mean([v]),cameraRms:reg[i].camera.rmse,poseRms:reg[i].pose.residuals})):[],before=initial?R.mean(initial):null,after=current?R.mean(current):null;
   let reject=!same||qa.faults.length||baselineSamples.some((p,i)=>p.clear&&!afterSamples[i].clear)||perView.some(v=>v.after<v.before-.003)||initial&&current.some((v,i)=>Object.entries(v.regions).some(([k,x])=>x.iou<initial[i].regions[k].iou-.035));
   if(reject){spec=lib.clone(input.spec);selected=[];after=before}
   const status=reg.length?(reject?"rejected":selected.length?"photo-scored assembly":"retained control"):(proposals.length?"unranked structural assemblies":"no structural alternative");
   // Save only source deltas against exact named baseline, to avoid repeating whole recipes.
   function deltas(s){return s.parts.flatMap(p=>{let q=input.spec.parts.find(x=>x.name===p.name);return p.shapes.length>q.shapes.length?[{part:p.name,appendShapes:p.shapes.slice(q.shapes.length)}]:[]})}
   out.push({id,spec,deltas:deltas(spec),proposals:proposals.map(p=>({group:p.group,mode:p.mode,family:p.family,delta:p.delta,parts:p.parts,deltas:deltas(p.spec)})),summary:{id,source,status,views:reg.length,usableCameraViews:reg.filter(r=>r.camera.rmse<=18).length,before,after,perView,selected,trials,changed:selected.reduce((n,t)=>n+t.delta,0),faults:reject?baseQa.faults.length:qa.faults.length,clearBefore:baselineSamples.filter(x=>x.clear).length,clearAfter:reject?baselineSamples.filter(x=>x.clear).length:afterSamples.filter(x=>x.clear).length,muzzleTotal:baselineSamples.length,roundTrip:same,unranked:proposals.map(({group,family,mode,delta,parts})=>({group,family,mode,delta,parts}))}});
  }catch(e){out.push({id,spec:input.spec,deltas:[],proposals:[],summary:{id,source,status:"blocked",reason:String(e),trials,selected:[],changed:0}})}
 }return out;
}
;reconstructAssemblies
