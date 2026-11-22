// Fifty deliberate side, rear and top contour passes. Never alters weapons, bores, pivots, joints or erases.
function mutate(d,id){
 const protect=new Set('atlas jenner wolverine urbanmech marauder timber_wolf cyclops raven shadow_cat'.split(' ')),wide=new Set('king_crab stalker crab turkina dire_wolf annihilator nightstar kodiak cyclops malice pillager'.split(' '));
 let edits=0,changedPasses=0;
 for(let k=0;k<50;k++){const focus=k%10,weight=[1,.8,.6,.45,.3][Math.floor(k/10)]*(wide.has(id)?.55:1);let ec=0;
 for(const p of d.parts||[]){if(p.mirror)continue;const name=p.name,role=name==='ct'?'torso':(name==='lt'||name==='rt')?'shoulder':(name==='la'||name==='ra')?'arm':(name==='ll'||name==='rl')?'thigh':name.endsWith('_shin')?'shin':name.endsWith('_foot')?'foot':name==='pelvis'?'pelvis':name==='hd'?'head':'';
 if(!role||(role==='head'&&protect.has(id))||(p.shapes||[]).filter(x=>x.erase).length>24)continue;
 for(const s of p.shapes||[]){if(!s.loft||s.loft.axis!=='y')continue;const sections=s.loft.sections;
 for(let q=0;q<sections.length;q++){let frac=q/Math.max(1,sections.length-1),rate=0,way='';
 if(focus===0&&role==='torso'&&frac<.44){way='rear';rate=-.0062}
 if(focus===1&&role==='torso'&&frac>.56){way='rear';rate=-.007}
 if(focus===2&&role==='shoulder'&&frac>.5){way='width';rate=-.0065}
 if(focus===3&&role==='torso'&&frac>.68){way='rear';rate=-.0055}
 if(focus===4&&role==='shin'&&frac>.25&&frac<.83){way='rear';rate=-.010}
 if(focus===5&&role==='foot'&&frac<.67){way='rear';rate=.003}
 if(focus===6&&role==='arm'&&frac>.18){way='rear';rate=-.007}
 if(focus===7&&role==='pelvis'&&frac<.75){way='width';rate=-.004}
 if(focus===8&&role==='thigh'&&frac>.2&&frac<.8){way='rear';rate=-.006}
 if(focus===9&&role==='head'){way='rear';rate=-.0035}
 if(!way)continue;const poly=sections[q].polygon,xs=poly.map(v=>v[0]),zs=poly.map(v=>v[1]),xmin=Math.min(...xs),xmax=Math.max(...xs),zmin=Math.min(...zs),zmax=Math.max(...zs),cx=(xmin+xmax)/2,cz=(zmin+zmax)/2,span=zmax-zmin;
 if(xmax-xmin<2.25||span<2.25)continue;
 for(const v of poly){if(way==='rear'&&v[1]>cz+.1*span){let nv=Math.round((v[1]+span*rate*weight*(v[1]-cz)/Math.max(.0001,zmax-cz))*1e5)/1e5;if(nv!==v[1]){v[1]=nv;ec++}}
 else if(way==='width'){const f=Math.abs(v[0]-cx)/Math.max(.00001,(xmax-xmin)/2);if(f){const nv=Math.round((v[0]+(v[0]-cx)*rate*weight*f)*1e5)/1e5;if(nv!==v[0]){v[0]=nv;ec++}}}}
 }}}
 if(ec)changedPasses++;edits+=ec;}
 d.art_view_revision='50-side-rear-top-passes-20261122';d.art_view_passes=50;return {id,edits,changedPasses};
}
