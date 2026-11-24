// One-time promotion of selected, strictly clean experimental model recipes.
// Run from the repository root on the promotion branch, with all refs fetched.
const fs = require("node:fs");
const cp = require("node:child_process");
const ORIGINAL = "00d4f7db1c60e7559a375e6e6234deb63a88ce19";
const EXP = "a23eeb349ada0682d2938aeedc8dedcbf165315b";
const PHOTO = "23bc9935d5f4076c306702c35ded8b4c733f5558";
const ROOT = "experiments/miniature_batch_30/remaining_149/";
const P = ROOT + "calibrated_photo/";
const git = (...args) => cp.execFileSync("git",args,{encoding:"utf8",maxBuffer:20*1024*1024});
const get = (ref,path) => JSON.parse(git("show",ref+":"+path));
const lib = eval(fs.readFileSync("tools/promote_experimental_sculpts.js","utf8")+"\npromotion()");
const strict = q => q && q.physical===0 && q.weak===0 && q.partIslands===0 && q.clear===q.total;
const summary = get(EXP,ROOT+"selected_summary.json");
const photos = new Map();
function photo(id,patches,after,before,from,selectedFrom){
 if(!id||!patches?.length||!strict(after)||!before)return;
 const existing=photos.get(id);
 // Different study files must never be blindly stacked. Each is a patch
 // from the exact #314 selection, with a separate final diagnostic.
 if(!existing||from>existing.from)photos.set(id,{patches,after,before,from,selectedFrom});
}
for(const path of ["batch_02_selected.json","batch_04_selected.json","batch_06_summary.json","batch_07_summary.json","batch_08_summary.json","batch_09_summary.json","batch_10_summary.json","batch_05_a.json","batch_05_b.json","batch_05_c.json"]){
 const d=get(PHOTO,P+path);
 for(const x of d.rows||[])photo(x.id,x.patches,x.after,x.before,path,x.selectedFrom);
}
const b3=get(PHOTO,P+"batch_03_summary.json");
for(const row of b3.results||[]){
 if(!row.patchFile||!row.changed||!strict(row.after))continue;
 const x=get(PHOTO,P+row.patchFile).rows.find(q=>q.id===row.id);
 if(x)photo(row.id,x.selected?.patches,row.after,row.before,row.patchFile,x.selectedFrom);
}
const pil=get(PHOTO,P+"pilot_and_coverage.json");
for(const x of pil.rows||[])photo(x.id,x.selected?.patches,x.selected?.q,x.before,"pilot_and_coverage.json",x.selectedFrom);
const cache = new Map(), report = [];
for(const row of summary.rows){
 let extra=photos.get(row.id), q=row.final;
 if(extra&&(extra.before.cells!==q.cells||(extra.selectedFrom&&extra.selectedFrom!==row.selectedFrom)))extra=null;
 if(extra)q=extra.after;
 if(!strict(q)){report.push({id:row.id,status:"held: source defects",final:q});continue;}
 try{
  const actual=git("rev-parse",ORIGINAL+":"+row.source).trim();
  if(actual!==row.sha)throw Error("source blob mismatch");
  const src=get(ORIGINAL,row.source);
  if(!cache.has(row.selectedFrom))cache.set(row.selectedFrom,get(EXP,ROOT+row.selectedFrom));
  let rec=cache.get(row.selectedFrom).find(x=>x.id===row.id);
  if(!rec||rec.sha!==row.sha)throw Error("missing exact source selection");
  rec={...rec,selectedFrom:row.selectedFrom};
  if(extra)rec={...rec,patches:[...rec.patches,...extra.patches],final:q,selectedFrom:row.selectedFrom+" + "+extra.from};
  let promoted;
  try{promoted=lib.promote(src,rec);}catch(e){
   if(!extra||!strict(row.final))throw e;
   extra=null;rec=cache.get(row.selectedFrom).find(x=>x.id===row.id);
   rec={...rec,selectedFrom:row.selectedFrom};
   promoted=lib.promote(src,rec);q=row.final;
  }
  const candidate=promoted.candidate;
  if(extra)candidate.source_sculpt_promotion.photo_selection=extra.from;
  const path=row.source.replace("_shape.json",".json");
  let high=null;try{high=get(ORIGINAL,path);}catch{}
  let status="shape only: detailed recipe differs";
  if(high?.source==="res://"+row.source)status="linked detailed recipe";
  else if(high&&lib.compatible(src,high)){
   fs.writeFileSync(path,JSON.stringify(lib.transfer(high,candidate),null,2)+"\n");
   status="transferred detailed recipe";
  }
  fs.writeFileSync(row.source,JSON.stringify(candidate,null,2)+"\n");
  report.push({id:row.id,status,source:row.source,source_blob:row.sha,cells:q.cells,selectedFrom:rec.selectedFrom,photo:extra?.from||null,residual_ops:promoted.edits});
 }catch(e){report.push({id:row.id,status:"held: replay failed",error:String(e)});}
}
const counts={};for(const row of report)counts[row.status]=(counts[row.status]||0)+1;
const manifest={baseline:ORIGINAL,experimental:EXP,photo:PHOTO,counts,photoSelected:report.filter(x=>x.photo).length,rows:report};
fs.writeFileSync("docs/graphics/experimental-sculpt-promotion-20261124.json",JSON.stringify(manifest,null,2)+"\n");
console.log("PROMOTION_RESULT|"+JSON.stringify({counts,photoSelected:manifest.photoSelected}));
if(!report.some(x=>x.source))process.exit(1);
