// Repair bounded isolated slivers, rebuild weak mounts, and audit axial samples.
function finish(lib,repair,row){
 const s=lib.clone(row.spec),history=[],K=v=>v.join(","),V=k=>k.split(",").map(Number);
 function trim(){let m=lib.raster(s);for(let p of s.parts){let cs=lib.components(m[p.name]);if(cs.length>1&&cs.slice(1).every(c=>c.length<=6)){for(let k of cs.slice(1).flat()){let v=V(k);p.shapes.push(lib.B(v,v.map(x=>x+1),"frame","subtract"))}history.push({part:p.name,action:"remove detached sliver",cells:cs.slice(1).flat().length})}}}
 trim();
 if(s.id==="devastator"){for(let q of ["l","r"]){let p=s.parts.find(x=>x.name===q+"t_battery"),k=q==="l"?-1:1,x=k*7,y=30,z=-10; p.pivot=[x,y,-4];p.shapes=[lib.L("z",[[z,x-2.4,x+2.4,y-2.4,y+2.4,.12],[-7,x-2.5,x+2.5,y-2.5,y+2.5,.12],[-4,x-2.5,x+2.5,y-2.5,y+2.5,.06]],"plate"),lib.B([x-2,y-2,-5],[x+2,y+2,-2],"frame"),lib.cyl("z",z,z+3,x,y,1,1,"gun","subtract")];s.muzzles[q.toUpperCase()+"T"]=[[x,y,z]];history.push({part:p.name,action:"inboard backed lower chest mount"})}let fix=repair(lib,s);history.push(...fix.history);trim()}
 function sample(spec,m){let o=new Map();for(let [n,mm] of Object.entries(m))for(let k of mm.keys())o.set(k,n);return Object.entries(spec.muzzles).flatMap(([loc,v])=>(Array.isArray(v[0])?v:[v]).map(p=>({loc,p,keys:[0,1,2].map(z=>K([Math.floor(p[0]),Math.floor(p[1]),Math.floor(p[2])+z])).filter(k=>o.has(k)).map(k=>[k,o.get(k)])})))}
 let m=lib.raster(s),before=sample(s,m),current=s;
 for(let q of before.filter(x=>x.keys.length)){let test=lib.clone(current);for(let [k,n] of q.keys){let p=test.parts.find(x=>x.name===n),v=V(k);p.shapes.push(lib.B(v,v.map(x=>x+1),"gun","subtract"))}let mm=lib.raster(test),qa=lib.audit(test,mm);if(!qa.faults.length){current=test;history.push({action:"recut sampled muzzle channel",loc:q.loc,point:q.p,cells:q.keys.length})}}
 m=lib.raster(current);let qa=lib.audit(current,m),after=sample(current,m);return {id:row.id,spec:current,qa,history,clear:after.filter(x=>!x.keys.length).length,total:after.length,blocked:after.filter(x=>x.keys.length)}
}
;finish
