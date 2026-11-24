// Reusable cached contour trial runner. Pass existing reconstruction lab and round2 evaluator.
function runBatch(lib0,makeRound2,sources,data){
const out=[],cache=new Map();let hits=0,misses=0;const lib={...lib0,raster(spec){const o={};for(const p of spec.parts){const k=JSON.stringify(p);let m=cache.get(k);if(m){hits++}else{m=lib0.raster({...spec,parts:[p]})[p.name];cache.set(k,m);misses++}o[p.name]=new Map(m)}return o}};const r2=makeRound2(lib);
for(const [id,d] of Object.entries(data)){
cache.clear();const h0=hits,m0=misses,base=lib.clone(sources[id]),by=Object.fromEntries(base.parts.map(p=>[p.name,p]));
const anchors={waist:by.pelvis.pivot,nose:by.hd.pivot,ls:by.la.pivot,rs:by.ra.pivot},pg={core:["ct","hd","lt","rt","pelvis"],rackL:["lt_rack"],rackR:["rt_rack"],armL:["la","la_forearm","la_weapon"],armR:["ra","ra_forearm","ra_weapon"],legL:["ll","ll_shin","ll_tarsus","ll_foot"],legR:["rl","rl_shin","rl_tarsus","rl_foot"]};
const regions=Object.entries(d.polys).map(([name,polygon])=>({name,polygon,parts:pg[name].filter(n=>by[n])})).filter(x=>x.parts.length);
const chains=Object.entries(d.limbs).map(([root,px])=>{const arm=root.endsWith("a"),child=root+(arm?"_forearm":"_shin"),hock=by[root+"_tarsus"]?root+"_tarsus":null,tip=arm?by[root+"_weapon"].pivot:by[root+"_foot"].pivot;return {root,child,hock,arm,marks:[{point:by[root].pivot,pixel:px[0]},{point:by[child].pivot,pixel:px[1]},{point:tip,pixel:px[2],bend:true,hock:!!hock}]}});
const review={anchors,photos:[{name:"front oblique thumbnail",url:d.url,size:[512,512],yaw:d.yaw,rigid:d.marks,regions,chains}]};
const groups=[];for(const [name,names0] of [["core",["ct","hd"]],["arm links",["la_forearm","ra_forearm"]],["lower legs",["ll_shin","rl_shin"]],["feet",["ll_foot","rl_foot"]]]){
const names=names0.filter(n=>{let s=by[n]?.shapes?.[0]?.sections;return s&&s.length>=2&&s.every((q,i)=>!i||q.at>s[i-1].at)&&s.every(q=>q.polygon.length===s[0].polygon.length)});if(!names.length)continue;
const edits=(axis,scale,shift=0)=>[{names,scale:{[axis]:scale},shift:{[axis]:shift}}];
groups.push({name,target:name==="core"?"core":name==="arm links"?"arm":"leg",variants:[{id:"narrow",edits:edits(0,.78)},{id:"broaden",edits:edits(0,1.22)},{id:"flatten",edits:edits(2,.72)},{id:"deepen",edits:edits(2,1.28)},{id:"front bias",edits:edits(2,1,-1.5)},{id:"rear bias",edits:edits(2,1,1.5)}]})}
const result=r2.evaluate(base,review,groups);const samples=(s,m)=>{const o=new Set(Object.values(m).flatMap(x=>[...x.keys()]));let a=[];for(let [loc,v] of Object.entries(s.muzzles||{}))for(let [i,p] of (Array.isArray(v[0])?v:[v]).entries())a.push({key:loc+":"+i,clear:[0,1,2].every(z=>!o.has([Math.floor(p[0]),Math.floor(p[1]),Math.floor(p[2])+z].join(",")))});return a};
let b=samples(base,lib.raster(base)),a=samples(result.spec,lib.raster(result.spec)),regression=b.some((p,i)=>p.clear&&!a[i]?.clear);const selected=regression?base:result.spec;
const summary={id,baseline:result.baseline,candidate:regression?result.baseline:result.candidate,changedCells:regression?0:result.changedCells,qa:lib.audit(selected,lib.raster(selected)),views:result.views,groups:result.history,cache:{hits:hits-h0,misses:misses-m0},muzzles:{before:[b.filter(p=>p.clear).length,b.length],after:[(regression?b:a).filter(p=>p.clear).length,a.length]},blockedRegression:regression,approved:false};out.push({id,review,summary,spec:selected});
}return out}
;runBatch
