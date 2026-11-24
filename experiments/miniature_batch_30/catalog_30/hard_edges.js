// Preserve near-square and square armor stations for angular chassis; round components unchanged.
function hardEdges(lib,s,row){
 const style=row.at(-1),id=s.id, angular=["squared","prow","fins","twin_tower","sword","pod"].includes(style)||id==="scorpion";if(!angular)return [];
 let notes=[];for(let p of s.parts){if(!["ct","lt","rt","la","ra","ll_shin","rl_shin","la_shin","ra_shin","ll_foot","rl_foot","la_foot","ra_foot"].includes(p.name)&&!p.name.endsWith("_battery")&&!p.name.endsWith("_fin"))continue;
  for(let sh of p.shapes){if(sh.op!=="add"||!["armor","plate"].includes(sh.mat))continue;let count=0;for(let sec of sh.sections){let q=sec.polygon;if(q.length!==8)continue;let xs=q.map(x=>x[0]),ys=q.map(x=>x[1]),a=Math.min(...xs),b=Math.max(...xs),c=Math.min(...ys),d=Math.max(...ys);if(!(b>a&&d>c))continue;let k=p.name.endsWith("_battery")?.025:p.name.endsWith("_fin")?0:.045;sec.polygon=lib.oct(a,b,c,d,k);count++;}if(count)notes.push({part:p.name,stations:count});}
 }return notes;
}
;hardEdges
