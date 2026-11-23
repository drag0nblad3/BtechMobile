/* Orchestrates one small, reviewable geometry-only PR batch.
 * Use only on #242; checks the current head before committing. */
const RepairMissingMechBatch=async (tools,ids)=>{
 const repo="drag0nblad3/BtechMobile";
 const pr=(await tools.mcp__GitHub__get_pr_info({repository_full_name:repo,pr_number:242})).result;
 const [src,commit]=await Promise.all([
   tools.mcp__GitHub__fetch_file({repository_full_name:repo,path:"tools/qa/missing_mech_socket_repair.js",ref:pr.head_sha}),
   tools.mcp__GitHub__fetch({url:"https://api.github.com/repos/drag0nblad3/BtechMobile/commits/"+pr.head_sha})
 ]);
 const lib=eval(src.result.content);
 const base=JSON.parse(commit.result.content).commit.tree.sha;
 const results=await Promise.all(ids.map(async id=>{
   const [lo,hi]=await Promise.all([
     tools.mcp__GitHub__fetch_file({repository_full_name:repo,path:"data/voxels/"+id+"_shape.json",ref:pr.head_sha}),
     tools.mcp__GitHub__fetch_file({repository_full_name:repo,path:"data/voxels/"+id+".json",ref:pr.head_sha})
   ]);
   const l=JSON.parse(lo.result.content),h=JSON.parse(hi.result.content);
   if(l.parts.length!==h.parts.length||l.parts.some((p,i)=>
       p.name!==h.parts[i].name||JSON.stringify(p.shapes)!==JSON.stringify(h.parts[i].shapes)))
     return {id,error:"Shape/LOD geometry already mismatched"};
   const before=lib.raster(l),out=lib.apply(l),pct=100*out.estimatedAdded/before.owner.size;
   if(out.unresolved.length||pct>5.5)
     return {id,unresolved:out.unresolved,added:out.estimatedAdded,percent:pct.toFixed(2)};
   for(let i=0;i<h.parts.length;i++)
     h.parts[i].shapes=JSON.parse(JSON.stringify(out.recipe.parts[i].shapes));
   // Source art QA must not invent provenance, adjust design data or erase voids.
   const files=[
     {path:"data/voxels/"+id+"_shape.json",mode:"100644",type:"blob",content:JSON.stringify(out.recipe,null,2)+"\n"},
     {path:"data/voxels/"+id+".json",mode:"100644",type:"blob",content:JSON.stringify(h,null,2)+"\n"}
   ];
   return {id,files,contacts:out.changes.length,added:out.estimatedAdded,percent:pct.toFixed(2)};
 }));
 const good=results.filter(x=>x.files),skipped=results.filter(x=>!x.files);
 if(!good.length)return {committed:[],skipped};
 const tree=(await tools.mcp__GitHub__create_tree({repository_full_name:repo,base_tree_sha:base,tree_elements:good.flatMap(x=>x.files)})).result.sha;
 const newHead=(await tools.mcp__GitHub__create_commit({
   repository_full_name:repo,message:"Rebuild backed joint sockets on "+good.length+" missing BattleMechs",
   tree_sha:tree,parent_sha:pr.head_sha})).result.sha;
 const up=(await tools.mcp__GitHub__update_ref({
   repository_full_name:repo,branch_name:pr.head,sha:newHead,expected_sha:pr.head_sha})).result;
 return {commit:newHead,updated:up.success,committed:good.map(({id,contacts,added,percent})=>({id,contacts,added,percent})),skipped};
};
if(typeof module!=="undefined")module.exports=RepairMissingMechBatch;
RepairMissingMechBatch;
