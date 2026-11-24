// Experimental independent component shell generation. 
function reconstructBatch(lib,round,inputs){
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
  let refs=reg.flatMap(({photo,camera,pose})=>{let rr=photo.regions.filter(r=>r.parts.includes(name));return rr.length&&camera.rmse<=18?[{rr,camera,pose:pose.pose}]:[]});
  if(family==="photo_hull"&&!refs.length)return null;
  function inPhoto(p){let good=0;for(let r of refs){let q=p.map(x=>x+.5),t=part;while(t){if(r.pose[t.name])q=rot(q,t.pivot,r.pose[t.name]);t=by[t.parent]}let [x,y]=project(q,r.camera);if(r.rr.some(z=>inside(z.polygon,x,y)))good++}return refs.length?good/refs.length:1}
  function allowed(k,p){if(others.has(k)||blocked.has(k))return false;if(!old.has(k)){let neighbors=D.filter(d=>allOld.has(K(add(p,d)))).length;if(neighbors>=5)return false}return true}
  for(let a=min;a<=max;a++){if(!ranges[a])continue;let t=(a-min+.5)/(max-min+1),w=Math.sin(Math.PI*t),smooth=[0,1].map(i=>{let arr=[a-1,a,a+1].filter(k=>ranges[k]);return [mean(arr.map(k=>ranges[k][i][0])),mean(arr.map(k=>ranges[k][i][1]))]});
    let [[cu,ru],[cv,rv]]=smooth;let taper=family==="wedge"?(.67+.65*t):family==="bell"?(.72+.46*w):1;ru=Math.max(.65,ru*taper*(family==="rounded"?1.12:family==="faceted"?1.15:family==="photo_hull"?1.22:1));rv=Math.max(.65,rv*(family==="wedge"?(1.25-.4*t):family==="rounded"?1.10:family==="photo_hull"?1.22:1));if(family==="wedge")cv+=(t-.5)*rv*.34;
    for(let i=Math.floor(cu-ru);i<Math.ceil(cu+ru);i++)for(let j=Math.floor(cv-rv);j<Math.ceil(cv+rv);j++){
      let x=Math.abs((i+.5-cu)/ru),y=Math.abs((j+.5-cv)/rv),ok=family==="rounded"?x*x+y*y<=1:family==="faceted"?Math.max(x,y)<=1&&x+y<=1.48:family==="wedge"?Math.max(x,y)<=1&&x+y<=1.58:family==="bell"?Math.max(x,y)<=1&&x+y<=1.7:Math.max(x,y)<=1&&x+y<=1.85;if(!ok)continue;
      let p=[];p[axis]=a;p[u]=i;p[v]=j;let k=K(p);if(s.has(k)||!allowed(k,p))continue;
      if(family==="photo_hull"&&inPhoto(p)<(old.has(k)?.50:1))continue;
      s.set(k,old.get(k)||dominant);
    }
  }
  let comps=lib.components(s);if(comps.length>1){for(let c of comps.slice(1)){if(c.some(k=>collar.has(k))||c.length>Math.max(10,Math.round(s.size*.03)))return null;for(let k of c)s.delete(k)}}
  if(!s.size||s.size<old.size*.55||s.size>old.size*1.55)return null;let delta=change(old,s);if(delta<Math.max(35,old.size*.12))return null;
  return {map:s,delta,before:old.size,after:s.size};
 }
 const out=[];
 for(const input of inputs){let {id,source,review}=input,spec=lib.clone(input.spec),baseMaps=lib.raster(spec),maps={...baseMaps},baseQa=lib.audit(spec,maps),baselineSamples=samples(spec,maps),blocked=new Set(baselineSamples.filter(x=>x.clear).flatMap(x=>x.keys)),trials=[],selected=[],proposals=[],reg=[],initial=null,current=null;try{
  if(baseQa.faults.length)throw Error("baseline fails neutral audit");
  if(review?.photos?.length){let by=new Set(spec.parts.map(p=>p.name)),r=lib.clone(review);for(let p of r.photos){p.regions=p.regions.filter(z=>z.parts.some(n=>by.has(n))).map(z=>({...z,parts:z.parts.filter(n=>by.has(n))}));p.chains=(p.chains||[]).filter(z=>by.has(z.root)&&by.has(z.child))}r.photos=r.photos.filter(p=>p.regions.length&&Object.keys(p.rigid||{}).filter(k=>r.anchors[k]).length>=3);if(r.photos.length)reg=R.register(spec,r)}
  if(reg.length){initial=R.measure(spec,maps,reg);current=initial}
  const eligible=spec.parts.filter(p=>/^(ct|hd|[lr]t|[lr]a(_forearm)?|[lr]l(_shin|_tarsus|_foot)?)$/.test(p.name)&&maps[p.name].size>=80);
  const rank=eligible.map(p=>{let scores=reg.flatMap((r,i)=>r.photo.regions.filter(z=>z.parts.includes(p.name)).map(z=>initial[i].regions[z.name]?.iou).filter(Number.isFinite));return {name:p.name,score:scores.length?mean(scores):null,cells:maps[p.name].size}}).sort((a,b)=>((a.score??2)-(b.score??2))||b.cells-a.cells);
  let targets=reg.length?rank.filter(x=>x.score!=null).slice(0,3):[...rank.filter(x=>x.name==="ct"),...rank.filter(x=>x.name==="hd"),...rank.filter(x=>x.name==="ll_shin")].slice(0,3);
  for(let {name} of targets){let best=null,prior=maps[name],priorScore=current;for(let family of ["rounded","faceted","wedge","bell",...(reg.length?["photo_hull"]:[])]){
   let c=candidate(spec,maps,name,family,reg,blocked);if(!c){trials.push({part:name,family,status:"insufficient change or shell connectivity/reference"});continue}
   let test={...maps,[name]:c.map},qa=lib.audit(spec,test);if(qa.faults.length){trials.push({part:name,family,delta:c.delta,status:"structural rejection",faults:qa.faults.slice(0,3)});continue}
   let scores=reg.length?R.measure(spec,test,reg):null,score=scores?R.mean(scores):null,oldScore=priorScore?R.mean(priorScore):null;
   let perView=scores?scores.map((v,i)=>R.mean([v])-R.mean([priorScore[i]])):[],worstRegion=scores?Math.min(...scores.flatMap((v,i)=>Object.entries(v.regions).map(([k,x])=>x.iou-priorScore[i].regions[k].iou))):0;
   let local=scores?mean(scores.flatMap((v,i)=>reg[i].photo.regions.filter(z=>z.parts.includes(name)).map(z=>v.regions[z.name].iou-priorScore[i].regions[z.name].iou))):null;
   const ok=scores?score>oldScore+.0005&&local>0&&perView.every(x=>x>=-.005)&&worstRegion>=-.045:true;
   let trial={part:name,family,delta:c.delta,before:c.before,after:c.after,score,local,perView,worstRegion,status:ok?(scores?"eligible":"unranked structural pass"):"photo rejection"};trials.push(trial);
   if(ok&&(!best||(scores?score>best.score:c.delta>best.c.delta)))best={family,c,scores,score,trial}
  }
  if(best){if(reg.length){writeDelta(spec,name,prior,best.c.map);maps={...maps,[name]:best.c.map};current=best.scores;selected.push(best.trial)}else{let candidateSpec=lib.clone(spec);writeDelta(candidateSpec,name,prior,best.c.map);let replay=lib.raster(candidateSpec),check=lib.audit(candidateSpec,replay);if(!check.faults.length&&change(replay[name],best.c.map)===0)proposals.push({part:name,family:best.family,delta:best.c.delta,spec:candidateSpec})}}
  }
  let remap=lib.raster(spec),qa=lib.audit(spec,remap),same=Object.keys(maps).every(n=>change(maps[n],remap[n])===0),afterSamples=samples(spec,remap),newBlocks=baselineSamples.filter((p,i)=>p.clear&&!afterSamples[i]?.clear).length;
  let before=initial?R.mean(initial):null,after=current?R.mean(current):null,perView=initial?current.map((v,i)=>({name:v.view,before:R.mean([initial[i]]),after:R.mean([v]),cameraRms:reg[i].camera.rmse})):[];let reject=!same||qa.faults.length||newBlocks||perView.some(v=>v.after<v.before-.005);
  if(reject){selected=[];spec=lib.clone(input.spec);after=before}
  let status=reg.length?(reject?"rejected":selected.length?"photo-scored replacement":"retained control"):(proposals.length?"unranked structural alternatives":"no structural alternative");
  out.push({id,spec,proposals,summary:{id,source,status,views:reg.length,before,after,perView,targets,selected,trials,changed:selected.reduce((n,t)=>n+t.delta,0),faults:reject?baseQa.faults.length:qa.faults.length,clearBefore:baselineSamples.filter(x=>x.clear).length,clearAfter:reject?baselineSamples.filter(x=>x.clear).length:afterSamples.filter(x=>x.clear).length,muzzleTotal:baselineSamples.length,roundTrip:same,unranked:proposals.map(({part,family,delta})=>({part,family,delta}))}})
 }catch(e){out.push({id,spec:input.spec,proposals:[],summary:{id,source,status:"blocked",reason:String(e),trials,selected:[],changed:0}})}
 }return out;
}
;reconstructBatch
