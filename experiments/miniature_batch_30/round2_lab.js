// Round 2: deterministic component contour trials against existing hand-marked photos.
// Never write production models. Freeze cameras and actual joint poses for all trials.
function makeRound2(lib) {
const {B,raster,audit,clone,fitCamera,visibleMasks,render,exportRecipe}=lib;
const key=v=>v.join(","),vec=k=>k.split(",").map(Number);
const ax={x:[0,1,2],y:[1,0,2],z:[2,0,1]};
const deg=x=>x*Math.PI/180;
function rot(p,o,[a,b,c]){let [x,y,z]=p.map((v,i)=>v-o[i]);a=deg(a);b=deg(b);c=deg(c);[y,z]=[y*Math.cos(a)-z*Math.sin(a),y*Math.sin(a)+z*Math.cos(a)];[x,z]=[x*Math.cos(b)+z*Math.sin(b),-x*Math.sin(b)+z*Math.cos(b)];[x,y]=[x*Math.cos(c)-y*Math.sin(c),x*Math.sin(c)+y*Math.cos(c)];return [x+o[0],y+o[1],z+o[2]]}
function project(p,c){let [x,y,z]=p.map((v,i)=>v-c.target[i]),a=deg(c.yaw),b=deg(c.elev),r=deg(c.roll),u=(c.flipX?-1:1)*(x*Math.cos(a)+z*Math.sin(a)),d0=-x*Math.sin(a)+z*Math.cos(a),v=y*Math.cos(b)+d0*Math.sin(b),d=c.distance+d0*Math.cos(b)-y*Math.sin(b);return [(Math.cos(r)*u-Math.sin(r)*v)*c.scale/d+c.tx,-(Math.sin(r)*u+Math.cos(r)*v)*c.scale/d+c.ty]}
function fitActualPose(spec,photo,c){
 let by=Object.fromEntries(spec.parts.map(p=>[p.name,p])),pose={},residuals={},locked=[];
 for(let ch of photo.chains||[]){let a=by[ch.root],b=by[ch.child],h=by[ch.hock],rootOK=!!a?.joint,childOK=!!b?.joint,hockOK=!!h?.joint;if(!a||!b)continue;if(!childOK)locked.push(b.name);
 let r=ch.arm?[[-85,85],[-25,25],[-55,55],[-100,45],[-15,15],[-15,15],[-40,40]]:[[-45,45],[-20,20],[-30,30],[-65,65],[-10,10],[-10,10],[-40,40]];
 let active=[rootOK,rootOK,rootOK,childOK,childOK,childOK,hockOK];
 function loss(t){let q=[t[0],t[1],t[2]],w=[t[3],t[4],t[5]],e=[t[6],0,0],s=0;for(let m of ch.marks){let p=m.point;if(m.hock&&hockOK)p=rot(p,h.pivot,e);if(m.bend&&childOK)p=rot(p,b.pivot,w);if(rootOK)p=rot(p,a.pivot,q);let v=project(p,c);s+=(v[0]-m.pixel[0])**2+(v[1]-m.pixel[1])**2}return {s,v:s+.003*t.reduce((n,x)=>n+x*x,0)}}
 let best=Array(7).fill(0),v=loss(best).v;
 for(let x of (rootOK?[-40,0,40]:[0]))for(let y of (rootOK?[-20,0,20]:[0]))for(let z of (childOK?[-40,0,40]:[0])){let t=[x,0,y,z,0,0,0].map((x,i)=>Math.max(r[i][0],Math.min(r[i][1],x)));let l=loss(t).v;if(l<v){best=t;v=l}}
 for(let step of [15,8,4,2])for(let sweep=0;sweep<4;sweep++)for(let i=0;i<7;i++)if(active[i])for(let dir of [-1,1]){let t=best.slice();t[i]=Math.max(r[i][0],Math.min(r[i][1],t[i]+step*dir));let l=loss(t).v;if(l<v-1e-8){best=t;v=l}}
 if(rootOK)pose[a.name]=best.slice(0,3);if(childOK)pose[b.name]=best.slice(3,6);if(hockOK)pose[h.name]=[best[6],0,0];residuals[a.name]=Math.sqrt(loss(best).s/ch.marks.length);
 }return {pose,residuals,locked}
}
function register(spec,review){return review.photos.map(p=>{let camera=fitCamera(review.anchors,p);return {photo:p,camera,pose:fitActualPose(spec,p,camera)}})}
function measure(spec,maps,reg){return reg.map(({photo,camera,pose})=>({view:photo.name,regions:visibleMasks(spec,maps,photo,camera,pose.pose)}))}
function mean(scores,target){let a=scores.flatMap(v=>Object.entries(v.regions).filter(([k])=>!target||target.test(k)).map(([_,x])=>x.iou));return a.length?a.reduce((n,x)=>n+x,0)/a.length:0}
function deltaCells(a,b){let n=0;for(let p of Object.keys(a)){for(let [k,v] of a[p])if(!b[p].has(k)||b[p].get(k)!==v)n++;for(let k of b[p].keys())if(!a[p].has(k))n++}return n}
function occupied(m){return new Set(Object.values(m).flatMap(x=>[...x.keys()]))}
function protectMuzzles(spec,m){let occ=occupied(m),cells=new Set();for(let v of Object.values(spec.muzzles||{})){for(let q of (Array.isArray(v[0])?v:[v])){if(q.length!==3||q.some(x=>!Number.isFinite(x)))continue;let p=q.map(Math.floor);for(let d=-1;d<=1;d++){for(let z=-2;z<=2;z++){let k=key([p[0]+d,p[1],p[2]+z]);if(!occ.has(k))cells.add(k)}}}}return cells}
function overlaps(spec,maps,allowed){let by=Object.fromEntries(spec.parts.map(p=>[p.name,p])),owners=new Map(),cuts={};for(let p of spec.parts)for(let k of maps[p.name].keys()){if(owners.has(k)){let q=owners.get(k),target=p.parent===q?q:by[q].parent===p.name?p.name:null;if(!target||!allowed.has(target))return null;(cuts[target]??=new Set()).add(k)}else owners.set(k,p.name)}return cuts}
function socketRecut(spec,allowed){let maps=raster(spec),cuts=overlaps(spec,maps,allowed);if(!cuts)return {maps,recut:0,unresolved:true};let n=0;for(let [part,ks] of Object.entries(cuts)){let p=spec.parts.find(p=>p.name===part);for(let k of ks){let v=vec(k);p.shapes.push(B(v,v.map(x=>x+1),"frame","subtract"));n++}}return {maps:n?raster(spec):maps,recut:n}}
function editProfile(spec,edit){let names=edit.names;for(let p of spec.parts.filter(p=>names.includes(p.name))){let shape=p.shapes[edit.shape||0];if(!shape)continue;let [a,u,v]=ax[shape.axis],secs=shape.sections,lo=secs[0].at,hi=secs.at(-1).at;
 // Insert additional interpolated stations before reshaping. Endpoints remain
 // unchanged unless explicitly requested; parent joint surfaces are not globally scaled.
 let out=[];for(let i=0;i<secs.length;i++){let s=secs[i];if(i){let q=secs[i-1];if(s.at-q.at>=3&&q.polygon.length===s.polygon.length){let at=(q.at+s.at)/2;out.push({at,polygon:q.polygon.map((pt,j)=>pt.map((x,k)=>(x+s.polygon[j][k])/2))})}}out.push(clone(s))}
 let sign=p.name.startsWith("l")?-1:1;for(let s of out){let t=(s.at-lo)/(hi-lo||1),w=edit.end==="top"?t:edit.end==="bottom"?1-t:Math.sin(Math.PI*t);if(edit.end==="out")w=shape.axis==="x"?(sign===-1?1-t:t):Math.sin(Math.PI*t);let center=[0,1].map(i=>s.polygon.reduce((n,q)=>n+q[i],0)/s.polygon.length);for(let q of s.polygon){for(let i=0;i<2;i++){let axis=i===0?u:v;let scale=edit.scale?.[axis]??1;let offset=edit.shift?.[axis]??0;if(axis===0&&edit.outward)offset+=sign*edit.outward;let centerValue=edit.center?.[axis]??center[i];q[i]=+(centerValue+(q[i]-centerValue)*(1+(scale-1)*w)+offset*w).toFixed(5)}}
 s.at=+(s.at+(edit.axial||0)*w*(edit.end==="out"&&shape.axis==="x"?sign:1)).toFixed(5)}
 if(out.some((s,i)=>i&&s.at<=out[i-1].at))throw Error("nonascending sections");shape.sections=out;
}}
function translate(spec,name,shift){let p=spec.parts.find(p=>p.name===name);for(let sh of p.shapes){let [a,u,v]=ax[sh.axis];for(let s of sh.sections){s.at+=shift[a];for(let q of s.polygon){q[0]+=shift[u];q[1]+=shift[v]}}}p.pivot=p.pivot.map((x,i)=>x+shift[i])}
function evaluate(base,review,groups,opts={}){
 const reg=register(base,review),baseMap=raster(base),qa0=audit(base,baseMap),blocked=protectMuzzles(base,baseMap);
 if(qa0.faults.length)throw Error("unclean control: "+JSON.stringify(qa0.faults.slice(0,3)));
 let current=clone(base),maps=baseMap,score=measure(current,maps,reg),initial=score,history=[],alts=[];
 for(let group of groups){let prior=score,old=current,oldMaps=maps,best=null,attempts=[];let target=new RegExp(group.target||".","i");for(let v of group.variants){let s=clone(old);try{for(let e of v.edits||[])editProfile(s,e);for(let t of v.move||[])translate(s,t.name,t.shift);let r=socketRecut(s,new Set(v.recut||[])),q=audit(s,r.maps),changed=deltaCells(oldMaps,r.maps),occ=occupied(r.maps),newBlocked=[...blocked].filter(k=>occ.has(k)).length;
 if(q.faults.length||newBlocked||!changed){attempts.push({id:v.id,changed,recut:r.recut,faults:q.faults.slice(0,8),blockedMuzzleCells:newBlocked,status:"rejected structural or unchanged"});continue}
 let scores=measure(s,r.maps,reg),overall=mean(scores),local=mean(scores,target),worst=0;for(let i=0;i<scores.length;i++)for(let [k,x] of Object.entries(scores[i].regions))worst=Math.min(worst,x.iou-prior[i].regions[k].iou);
 let obj=(overall-mean(prior))+.4*(local-mean(prior,target));let accepted=overall>=mean(prior)-.00001&&local>=mean(prior,target)-.00001&&worst>=-.055&&obj>.00003;
 let result={id:v.id,changed,recut:r.recut,overall,local,worst,objective:obj,accepted,notes:v.notes||null,edits:v.edits,move:v.move};
 attempts.push(result);if(v.preserve)alts.push({group:group.name,trial:v.id,spec:s,qa:q,overall,local,score:scores,notes:v.notes||null});if(accepted&&(!best||obj>best.obj))best={s,maps:r.maps,scores,obj,result};
 }catch(e){attempts.push({id:v.id,status:"error",message:String(e)})}}
 if(best){current=best.s;maps=best.maps;score=best.scores}history.push({group:group.name,target:group.target,before:mean(prior),after:mean(score),selected:best?.result.id||"retain control",attempts});
 }
 return {spec:current,qa:audit(current,maps),baseline:mean(initial),candidate:mean(score),changedCells:deltaCells(baseMap,maps),views:reg.map(({photo,camera,pose},i)=>({view:photo.name,camera,pose,before:initial[i].regions,after:score[i].regions})),history,alternates:alts,recipe:exportRecipe(current,maps),render:render(current,maps)};
}
return {evaluate,register,measure,mean,editProfile,fitActualPose}
}
makeRound2