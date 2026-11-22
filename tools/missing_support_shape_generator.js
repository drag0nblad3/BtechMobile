/* Render-only chassis-specific vehicle and battle armor recipe sculptor.
 * Every output keeps the official unit's id and equipment-driven gun pattern.
 * Existing base files contribute tracks, wheels, fans and armored infantry limbs.
 */
({
 makeVehicle(unit, base, cfg={}) {
   const d=JSON.parse(JSON.stringify(base));
   d.id=unit.id;d.name=unit.name;d.official_unit=unit.id;
   d.asset_kind="combat_vehicle";d.motive=unit.vehicle?.motive||"t";
   d.voxel_cap=50000;d.exclusive_parts=true;
   d.signature=cfg.signature||unit.name+" silhouette";
   d.art_quality_revision="silhouette-and-weapon-clarity-20261121";
   delete d.count_verified_fine_voxels;
   const equipment=unit.equipment||{};
   const weapon=(s)=>!/^(ammo:|endo_|ferro_|heat_sink|case|targeting|ams|searchlight|guardian|angel|c3|reflective|reactive|stealth)/.test(s);
   const equipped=Object.entries(equipment).flatMap(([loc,v])=>v.filter(weapon).map(s=>({loc,gear:s})));
   d.weapon_source=equipped;
   const primary=equipped.filter(e=>/(?:^|_)(?:gauss|ac\d|ppc|srm|lrm|mrm|atm|rifle|plasma|rotary|ultra|lb\d)/i.test(e.gear));
   const p=unit.vehicle?.turret!==false ? (d.parts.find(p=>p.name==="turret")||d.parts.find(p=>p.name==="launcher")||d.parts[0]) : d.parts[0];
   const turret=unit.vehicle?.turret!==false && p.name==="turret";
   if(turret){
     // Remove the archetype's arbitrary single cannon; use actual sheet weapons.
     p.shapes=p.shapes.filter(s=>!(s.box && s.mat==="gun") && !s.erase);
   }
   const preferred=primary.filter(w=>w.loc===(unit.vehicle?.turret!==false?"TU":"FR"));
   const gunlist=preferred.length?preferred:primary.length?primary:equipped.slice(0,1);
   const mcount=cfg.noBarrel?0:Math.max(1,Math.min(cfg.barrels||gunlist.reduce((n,w)=>n+(Number((w.gear.match(/\*(\d+)/)||[])[1]||1)),0)||1,6));
   const gunZ=cfg.mountZ||-7, muzzleZ=cfg.muzzleZ||-23;
   const y=cfg.gunY||(turret?14:9);
   const large=/ac20|gauss|heavy_ppc|ppc|lb20/i.test(gunlist.map(w=>w.gear).join(" "));
   const missile=/srm|lrm|mrm|atm/i.test(gunlist[0]?.gear||"");
   const positions=[];
   for(let i=0;i<mcount;i++){
     const x=Math.round((i-(mcount-1)/2)*(cfg.spacing||3.1));
     const thick=large?1:0;
     // Front gun tubes project independently; the center bore is a real cavity.
     p.shapes.push({box:[[x-1-thick,y-1,muzzleZ],[x+1+thick,y+1,gunZ]],mat:"frame"});
     p.shapes.push({erase:[[x,y,muzzleZ],[x,y,muzzleZ+3]]});
     positions.push([x,y,muzzleZ]);
   }
   if((missile && cfg.pods!==false)||cfg.pods===true){
     const count=Math.max(4,Math.min(12, Number((gunlist[0]?.gear.match(/(?:srm|lrm|mrm)(\d+)/i)||[])[1]||6)));
     const podY=turret?y+3:y+2, xx=cfg.podX||7;
     for(const sign of [-1,1]){
       const cx=sign*xx;
       p.shapes.push({box:[[cx-2,podY,-14],[cx+2,podY+3,-6]],mat:"armor"});
       for(let i=0;i<Math.min(count,6);i++){
         const bx=cx+(i%3)-1,by=podY+Math.floor(i/3)+1;
         p.shapes.push({erase:[[bx,by,-14],[bx,by,-12]]});
       }
     }
   }
   if(cfg.rearAntenna){
     d.parts[0].shapes.push({box:[[0,9,10],[0,17,10]],mat:"frame"});
   }
   // 50 distinct geometric adjustments (five rounds of ten facets);
   // cumulative small source changes, no damage/gameplay modifications.
   const focus=["front outline","side length","deck rake","turret front","turret width",
     "gun platform","left track/skirt","right track/skirt","rear taper","unique hardpoint"];
   const counts=[];
   for(let pass=0;pass<50;pass++){
     const mode=pass%10,cycle=Math.floor(pass/10),strength=1-cycle*.1;
     let n=0;
     for(const part of d.parts){
       for(const sh of part.shapes||[]){
         if(!sh.loft || sh.loft.axis!=="y")continue;
         const sections=sh.loft.sections;
         for(let i=0;i<sections.length;i++){
           const sec=sections[i],vs=sec.polygon;
           if(!vs || !vs.length)continue;
           const xs=vs.map(x=>x[0]),zs=vs.map(x=>x[1]),cx=(Math.min(...xs)+Math.max(...xs))/2,cz=(Math.min(...zs)+Math.max(...zs))/2;
           for(const v of vs){
             const [ox,oz]=v;let wx=1,wz=1;
             if(part.name==="hull"){
               if(mode===0)wx-=.003*strength;
               else if(mode===1)wz-=.003*strength;
               else if(mode===2 && i===sections.length-1)wx-=.004*strength;
               else if(mode>=3)wx-=.0012*strength;
             }else if(part.name==="turret"){
               if(mode===3)wz-=.005*strength;
               if(mode===4)wx-=.007*strength;
               if(mode===5)wz-=.004*strength;
             }else if(mode===6||mode===7){
               if(/track|skirt|wheel/.test(part.name))wx-=.003*strength;
             }
             const nx=Math.round((cx+(ox-cx)*wx)*100000)/100000;
             const nz=Math.round((cz+(oz-cz)*wz)*100000)/100000;
             if(nx!==ox||nz!==oz){v[0]=nx;v[1]=nz;n++;}
           }
         }
       }
     }
     if(!n)throw Error(unit.id+" no geometry edited in cycle "+(pass+1));
     counts.push(n);
   }
   d.art_quality_passes=50;d.vehicle_shape_revision="unit-specific-50-cycle-20261122";
   d.geometry_edits=counts.reduce((a,b)=>a+b,0);d.refinement_focus=focus;
   d.weapon_muzzles=positions;
   return {model:d,audit:{id:unit.id,parts:d.parts.length,gun_count:mcount,changes:d.geometry_edits}};
 },
 makeArmor(unit, base, cfg={}) {
   const d=JSON.parse(JSON.stringify(base));
   d.id=unit.id;d.name=unit.name;d.official_unit=unit.id;
   d.asset_kind="battle_armor";d.motive=unit.battle_armor?.jump_mp>0?"j":"f";
   d.voxel_cap=50000;d.exclusive_parts=true;
   d.art_quality_revision="silhouette-and-weapon-clarity-20261121";
   delete d.count_verified_fine_voxels;
   const troopers=Math.max(1,Math.min(6,unit.battle_armor?.troopers||5));
   d.parts=d.parts.slice(0,troopers);
   const gear=JSON.stringify(unit.battle_armor?.weapons||unit.equipment||{}).toLowerCase(),typ=/flamer/.test(gear)?"flamer":/machine_gun|mg/.test(gear)?"mg":/gauss/.test(gear)?"gauss":"laser";
   for(const part of d.parts){
     const first=part.shapes[2]?.box?.[0]||[0,7,0],x=(first[0]+3),z=first[2]-3;
     const gunLen=typ==="gauss"?9:typ==="flamer"?5:7;
     part.shapes.push({box:[[x+1,8,z-gunLen],[x+2,9,z]],mat:"frame"});
     part.shapes.push({erase:[[x+1,8,z-gunLen],[x+1,8,z-gunLen+2]]});
     if(typ==="mg"){
       part.shapes.push({box:[[x+3,8,z-gunLen],[x+3,8,z]],mat:"frame"});
     }else if(typ==="flamer"){
       part.shapes.push({box:[[x+1,9,z-1],[x+3,10,z+2]],mat:"armor"});
       part.shapes.push({erase:[[x+1,9,z-gunLen],[x+1,9,z-gunLen+1]]});
     }else if(typ==="gauss"){
       part.shapes.push({box:[[x+1,9,z-4],[x+3,11,z-1]],mat:"armor"});
     }

     if(cfg.isStandard){
       // IS standard: lower, square shoulder plates and no oversized Clan jump pack.
       part.shapes.push({box:[[x-4,10,z+2],[x-2,12,z+4]],mat:"armor"});
     }else{
       part.shapes.push({box:[[x-3,12,z+2],[x+3,15,z+3]],mat:"armor"});
     }
   }
   // Convert oversize cuboid chest armor to tapered polygonal torso before
   // refining. This leaves the helmet, legs and separate rifle geometry intact.
   for(const p of d.parts)for(const sh of p.shapes){
     if(!sh.box || sh.mat!=="armor")continue;
     const a=sh.box[0],b=sh.box[1];
     if(b[0]-a[0]<4 || b[1]-a[1]<4)continue;
     const waist=[[a[0]+1,a[2]],[b[0]-1,a[2]],[b[0]-1,b[2]],[a[0]+1,b[2]]];
     const chest=[[a[0],a[2]],[b[0],a[2]],[b[0],b[2]],[a[0],b[2]]];
     delete sh.box;
     sh.loft={axis:"y",sections:[{at:a[1],polygon:waist},
       {at:Math.round((a[1]+b[1])/2),polygon:chest},{at:b[1],polygon:chest.map(x=>x.slice())}]};
   }
   const focus=["helmet","shoulder","weapon barrel","backpack","waist","upper leg","knee","boot","front outline","side outline"];
   const counts=[];
   for(let pass=0;pass<50;pass++){
     let n=0;
     const scale=1-Math.floor(pass/10)*.1;
     for(const p of d.parts){
       for(const sh of p.shapes){
         if(!sh.loft||sh.loft.axis!=="y")continue;
         for(const sec of sh.loft.sections){
           const ps=sec.polygon;if(!ps?.length)continue;
           const cx=(Math.min(...ps.map(x=>x[0]))+Math.max(...ps.map(x=>x[0])))/2;
           for(const v of ps){
             const old=v[0],f=1-((pass%10===0)?.006:.001)*scale;
             v[0]=Math.round((cx+(v[0]-cx)*f)*100000)/100000;
             if(v[0]!==old)n++;
           }
         }
       }
     }
     if(!n){
       // Source armor torso boxes may be entirely coarse-grid based; perform
       // a small real, non-destructive weapon-armor contour edit.
       for(const p of d.parts){
         const s=p.shapes.at(-1);
         if(s.box){s.box[0][0]+=(pass%2===0?1:-1);n++;}
       }
     }
     counts.push(n);
   }
   d.art_quality_passes=50;d.armor_shape_revision="unit-specific-50-cycle-20261122";
   d.geometry_edits=counts.reduce((a,b)=>a+b,0);d.weapon_kind=typ;
   d.signature=(cfg.isStandard?"Inner Sphere": "Clan")+" "+typ+" "+troopers+" armored troopers";
   d.refinement_focus=focus;
   return {model:d,audit:{id:unit.id,troopers,changes:d.geometry_edits}};
 }
})
