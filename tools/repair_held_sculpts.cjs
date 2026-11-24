// Replay the 15 held experimental models, repair their exact source geometry,
// and emit production recipes only when all strict neutral diagnostics pass.
const fs=require("node:fs"),cp=require("node:child_process");
const EXP="a23eeb349ada0682d2938aeedc8dedcbf165315b",ORIGINAL="00d4f7db1c60e7559a375e6e6234deb63a88ce19";
const ROOT="experiments/miniature_batch_30/remaining_149/";
const git=(...a)=>cp.execFileSync("git",a,{encoding:"utf8",maxBuffer:32*1024*1024});
const get=(ref,path)=>JSON.parse(git("show",ref+":"+path));
const helper=fs.readFileSync("tools/promote_experimental_sculpts.js","utf8").replace("return {promote,compatible,transfer};","return {promote,compatible,transfer,native,own,paint,delta,K,V,D,plus};");
const L=eval(helper+"\npromotion()"),{K,V,D,plus}=L;
const clone=x=>JSON.parse(JSON.stringify(x));
const summary=get(EXP,ROOT+"selected_summary.json");
const manifest=JSON.parse(fs.readFileSync("docs/graphics/experimental-sculpt-promotion-20261124.json"));
const held=manifest.rows.filter(x=>x.status.startsWith("held"));
const group=m=>{let left=new Set(m.keys()),out=[];while(left.size){let q=[left.values().next().value];left.delete(q[0]);for(let i=0;i<q.length;i++)for(const d of D){let k=K(plus(V(q[i]),d));if(left.delete(k))q.push(k);}out.push(q);}return out.sort((a,b)=>b.length-a.length);};
const owner=maps=>new Map(Object.entries(maps).flatMap(([n,m])=>[...m.keys()].map(k=>[k,n])));
const patch=(c,d)=>{let ax=[0,1,2].filter(i=>!d[i]);return [[0,0],[1,0],[0,1],[1,1]].map(([u,v])=>{let p=c.slice();p[ax[0]]+=u;p[ax[1]]+=v;return p;});};
function strong(a,b){for(const k of a.keys()){let c=V(k);for(const d of D){if(!b.has(K(plus(c,d))))continue;if(patch(c,d).every(p=>a.has(K(p))&&a.has(K(plus(p,d,-1)))&&b.has(K(plus(p,d)))&&b.has(K(plus(p,d,2)))))return true;}}return false;}
const ports=src=>Object.entries(src.muzzles||{}).flatMap(([loc,v])=>(Array.isArray(v[0])?v:[v]).map(p=>({loc,p,keys:[0,1,2].map(z=>K([Math.floor(p[0]),Math.floor(p[1]),Math.floor(p[2])+z]))})));
function audit(parts,maps,points){let o=owner(maps),faults=[],p=group(o);for(let x of parts){let c=group(maps[x.name]);if(c.length!==1)faults.push([x.name,"islands",c.map(q=>q.length)]);if(x.parent&&maps[x.parent]&&!strong(maps[x.name],maps[x.parent]))faults.push([x.name,"weak",x.parent]);}return {cells:o.size,parts:parts.length,physical:Math.max(0,p.length-1),physicalGroups:p.slice(1).map(x=>x.length),partIslands:faults.filter(f=>f[1]==="islands").reduce((n,f)=>n+Math.max(1,f[2].length-1),0),weak:faults.filter(f=>f[1]==="weak").length,faults,clear:points.filter(p=>p.keys.every(k=>!o.has(k))).length,total:points.length};}
const strict=q=>q.physical===0&&q.partIslands===0&&q.weak===0&&q.clear===q.total;
function repair(src,parts,maps,voids,points){let log=[],guard=new Set([...voids,...points.flatMap(p=>p.keys)]),by=Object.fromEntries(parts.map(p=>[p.name,p]));
 // A sampled bore may only be recut in its own weapon housing, not another
 // damage location or the cockpit glazing. No emitter relocation.
 for(let p of points){let o=owner(maps),blocked=p.keys.filter(k=>o.has(k));if(!blocked.length)continue;
 let allowed=blocked.every(k=>{let n=o.get(k),mat=maps[n].get(k);return by[n]?.loc===p.loc&&(/weapon|housing|ppc|pulse|lrm|srm|gun/.test(n)||mat==="gun"||mat==="frame")&&!["glass","glow"].includes(mat);});
 if(!allowed){log.push({kind:"blocked bore retained",loc:p.loc,point:p.p,owners:blocked.map(k=>[k,o.get(k),maps[o.get(k)].get(k)])});continue;}
 for(let k of blocked)maps[o.get(k)].delete(k);log.push({kind:"owning weapon bore recut",loc:p.loc,point:p.p,cells:blocked.length});
 }
 // Reconnect a disconnected part using a 2x2 backed rectangular section.
 // Both endpoints need a real 2x2 contact area; do not cross other owners
 // or authored voids. A small same-location rigid panel may be reassigned
 // to its actual support when the reassignment preserves geometry.
 const rigid=n=>{let p=by[n];while(p?.parent&&!p.joint)p=by[p.parent];return p?.name||n;};
 for(let pass=0;pass<4;pass++)for(const p of parts){let m=maps[p.name],cs=group(m);if(cs.length<=1)continue;
 for(const g of cs.slice(1)){let o=owner(maps),main=new Set(cs[0]),island=new Set(g),best=null;
 for(const k of g){let c=V(k);for(const d of D){let face=patch(c,d);if(!face.every(q=>island.has(K(q))))continue;
 for(let step=1;step<=5;step++){let end=face.map(q=>K(plus(q,d,step)));if(end.every(k=>main.has(k))){let fill=[];for(let t=1;t<step;t++)for(let q of face)fill.push(K(plus(q,d,t)));if(fill.length&&fill.every(k=>!o.has(k)&&!guard.has(k))&&(!best||fill.length<best.length))best=fill;break;}if(end.some(k=>o.has(k)||guard.has(k)))break;}}}
 if(best){for(let k of best)m.set(k,"frame");log.push({part:p.name,kind:"2x2 backed internal mount",cells:best.length});continue;}
 // Reassign an existing fragment to a same-location rigid support, without
 // moving or deleting a cell. Require the merged support to be connected.
 let neighbors=new Map();for(let k of g)for(let d of D){let n=o.get(K(plus(V(k),d)));if(n&&n!==p.name&&by[n].loc===p.loc&&rigid(n)===rigid(p.name))neighbors.set(n,(neighbors.get(n)||0)+1);}
 let moved=false;for(let [n,c] of [...neighbors].sort((a,b)=>b[1]-a[1])){if(c<2)continue;let t=new Map(maps[n]);for(let k of g)t.set(k,m.get(k));if(group(t).length>group(maps[n]).length)continue;for(let k of g)m.delete(k);maps[n]=t;log.push({part:p.name,support:n,kind:"same-rigid material ownership correction",cells:g.length});moved=true;break;}
 if(moved)continue;
 // Tiny armor flakes may be dropped only if genuinely unsupported by any
 // adjacent geometry. Do not delete a substantial armor/weapon assembly.
 if(g.length<=3&&g.every(k=>["armor","plate","edge"].includes(m.get(k)))&&g.every(k=>D.every(d=>!o.has(K(plus(V(k),d)))||island.has(K(plus(V(k),d))))){for(let k of g)m.delete(k);log.push({part:p.name,kind:"unsupported armor flake",cells:g.length});continue;}
 // A local collar can connect thin armor to its own mass. Test two
 // parallel paths to form a backed rectangular rib, never a long rod.
 let best2=null;
 for(let k of g){let c=V(k);for(let d of D){for(let step=1;step<=3;step++){let target=K(plus(c,d,step));if(!main.has(target))continue;for(let side of D.filter(x=>x.some((v,i)=>v&&d[i]===0))){let fill=new Set();let ok=true;for(let t=0;t<=step;t++)for(let q of [plus(c,d,t),plus(plus(c,d,t),side)]){let k=K(q);if(m.has(k))continue;if(o.has(k)||guard.has(k)){ok=false;break;}fill.add(k);}if(ok&&fill.size&&fill.size<=8&&(!best2||fill.size<best2.size))best2=fill;}break;}}}
 if(best2){let t=new Map(m);for(let k of best2)t.set(k,"frame");if(group(t).length<group(m).length){for(let k of best2)m.set(k,"frame");log.push({part:p.name,kind:"short reinforced internal rib",cells:best2.size});}}
 }}
 // Explicit parent interfaces: a solid 2x2 face and two backing layers on
 // both sides. Try a small collar on child and parent in free space.
 for(let pass=0;pass<3;pass++)for(const p of parts){if(!p.parent||!maps[p.parent])continue;let a=maps[p.name],b=maps[p.parent];if(strong(a,b))continue;let o=owner(maps),best=null;
 for(let k of b.keys()){let c=V(k);for(let d of D){if(b.has(K(plus(c,d))))continue;let face=patch(c,d);
 for(let offset=1;offset<=4;offset++){let pa=new Set(),ch=new Set(),ok=true,hits=0,back=0;
 for(let q of face){for(let t of [-1,0]){let k=K(plus(q,d,t));if(b.has(k)){back++;continue;}if(o.has(k)||guard.has(k)){ok=false;break;}pa.add(k);}
 for(let t=1;t<=offset+1;t++){let k=K(plus(q,d,t));if(a.has(k)){hits++;continue;}if(o.has(k)||guard.has(k)){ok=false;break;}ch.add(k);}}
 if(!ok||back<4||hits<2||pa.size+ch.size>22)continue;
 let aa=new Map(a),bb=new Map(b);for(let k of ch)aa.set(k,"frame");for(let k of pa)bb.set(k,"frame");if(!strong(aa,bb)||group(aa).length>group(a).length||group(bb).length>group(b).length)continue;let cost=ch.size+pa.size+0.01*face.reduce((s,q)=>s+q.reduce((v,x,i)=>v+(x-p.pivot[i])**2,0),0);if(!best||cost<best.cost)best={ch,pa,cost};}
 }}
 if(best){for(let k of best.ch)a.set(k,"frame");for(let k of best.pa)b.set(k,"frame");log.push({part:p.name,parent:p.parent,kind:"solid backed joint collar",cells:best.ch.size+best.pa.size});}
 }
 return log;
}
let cache=new Map(),out=[];
for(let h of held){let row=summary.rows.find(x=>x.id===h.id),path=row.source,src=get(ORIGINAL,path);if(!cache.has(row.selectedFrom))cache.set(row.selectedFrom,get(EXP,ROOT+row.selectedFrom));let rec=cache.get(row.selectedFrom).find(x=>x.id===row.id);let n=L.native(src),base=L.own(n.maps).maps,maps=Object.fromEntries(Object.entries(base).map(([k,v])=>[k,new Map(v)]));for(let p of rec.patches)L.paint(maps[p.part],p.shapes,new Set());let points=ports(src),before=audit(n.parts,maps,points);if(before.cells!==rec.final.cells)throw Error("selection replay "+h.id);let log=repair(src,n.parts,maps,n.voids,points),after=audit(n.parts,maps,points);let status="held";if(strict(after)){let patches=[];for(let p of n.parts){let d=L.delta(base[p.name],maps[p.name]);if(d.count)patches.push({part:p.name,shapes:d.out});}let candidate=L.promote(src,{...rec,patches,final:after,selectedFrom:row.selectedFrom+" + defect repair"}).candidate;candidate.source_sculpt_promotion.defect_repair=true;let highPath=path.replace("_shape.json",".json"),high=get(ORIGINAL,highPath);if(high.source==="res://"+path){status="linked";}else if(L.compatible(src,high)){fs.writeFileSync(highPath,JSON.stringify(L.transfer(high,candidate),null,2)+"\n");status="transferred";}else status="shape-only divergent";fs.writeFileSync(path,JSON.stringify(candidate,null,2)+"\n");}out.push({id:h.id,status,before,after,log});console.log("DEFECT|"+h.id+"|"+status+"|"+JSON.stringify(after));}
fs.writeFileSync("docs/graphics/held-sculpt-repair-20261124.json",JSON.stringify({rows:out},null,2)+"\n");
console.log("DEFECT_SUMMARY|"+JSON.stringify(out.reduce((m,x)=>(m[x.status]=(m[x.status]||0)+1,m),{})));
