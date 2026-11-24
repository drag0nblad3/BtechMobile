function fix(lib,s){let p=n=>s.parts.find(x=>x.name===n),note=[];
if(s.id==="awesome"){p("lt_ppc_37").parent="ct";p("lt_ppc_41").parent="lt_ppc_37";note.push("Mount lower PPC to central housing and upper to shared lower carrier");}
if(s.id==="banshee"){p("lt_rack").parent="ct";p("rt_ac").parent="ct";note.push("Reparent to real load-bearing chest");}
if(s.id==="centurion"){p("lt_rack").parent="ct";note.push("Chest launcher mounted to actual chest; isolated wall fragments trimmed");}
if(s.id==="highlander"){p("lt_rack").parent="ct";note.push("Chest launcher mounted to actual chest");}
if(s.id==="hatchetman"){let h=p("ra_hatchet_handle");let [x,y,z]=h.pivot;h.shapes.push(lib.B([x-1.5,y-1.5,-13],[x+1.5,y+1.5,-9],"frame"));note.push("Thicker distal socket inside blade; thin shaft retained");}
let r=repair(lib,s);if(["catapult","centurion"].includes(s.id)){let m=lib.raster(s);for(let part of s.parts.filter(p=>p.name.endsWith("_rack"))){let g=lib.components(m[part.name]);if(g.length>1&&g.slice(1).every(x=>x.length<=12)){for(let k of g.slice(1).flat()){let v=k.split(",").map(Number);part.shapes.push(lib.B(v,v.map(x=>x+1),"frame","subtract"))}note.push("Trim detached wall slivers "+part.name+": "+g.slice(1).flat().length+" cells")}}}return {spec:s,qa:lib.audit(s,lib.raster(s)),note,repairs:r.history}}
;fix