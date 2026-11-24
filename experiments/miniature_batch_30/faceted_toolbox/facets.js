// Explicit hard-surface lofts. No automatic bevel, corner rounding or smoothing.
function makeFacets(lib){
 const {loft}=lib;
 function poly(axis,sections,mat="plate",op="add"){
  if(!["x","y","z"].includes(axis)||sections.length<2)throw Error("invalid loft");
  const n=sections[0][1].length;
  if(n<3||sections.some(([t,p],i)=>!Number.isFinite(t)||p.length!==n||p.some(v=>v.length!==2||!v.every(Number.isFinite))||(i&&t<=sections[i-1][0])))throw Error("invalid section topology");
  return loft(axis,sections,mat,op);
 }
 // Corners in order: lower-left, lower-right, upper-right, upper-left.
 // Each pair is an independent u/v inset. A zero pair preserves a sharp corner.
 function corners(a,b,c,d,cut=[[0,0],[0,0],[0,0],[0,0]]){
  const [ll,lr,ur,ul]=cut;
  if(b<=a||d<=c||cut.some(([x,y])=>x<0||y<0)||ll[0]+lr[0]>b-a||ul[0]+ur[0]>b-a||ll[1]+ul[1]>d-c||lr[1]+ur[1]>d-c)throw Error("invalid corner cut");
  return [[a+ll[0],c],[b-lr[0],c],[b,c+lr[1]],[b,d-ur[1]],[b-ur[0],d],[a+ul[0],d],[a,d-ul[1]],[a,c+ll[1]]];
 }
 function armor(axis,rows,mat="plate",op="add"){return poly(axis,rows.map(([t,a,b,c,d,cut])=>[t,corners(a,b,c,d,cut)]),mat,op)}
 function prism(axis,a,b,outline,mat="plate",op="add"){return poly(axis,[[a,outline],[b,outline]],mat,op)}
 function wedge(axis,a,b,near,far,mat="plate",op="add"){return poly(axis,[[a,near],[b,far]],mat,op)}
 // An intentional shoulder/armor step, not an interpolated rounded shoulder.
 function step(axis,rows,mat="plate",op="add"){return poly(axis,rows,mat,op)}
 function reflect(shape){let s=lib.clone(shape);if(s.axis==="x"){s.sections=s.sections.map(q=>({...q,at:-q.at})).reverse()}else for(let sec of s.sections)sec.polygon=sec.polygon.map(([u,v])=>[-u,v]);return s}
 return {poly,corners,armor,prism,wedge,step,reflect};
}
;makeFacets