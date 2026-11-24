// Independent lofts and neutral source seam repair. Requires reconstruction_lab.js.
function author(lib,id){
const {assembly,L,B,cyl,sidePart,loft,ellipse}=lib;
const cfg={
dragon:{name:"Dragon DRG-1N",unit:"dragon_drg1n",pitch:.05,hip:7,waist:23,knee:12,shoulder:12,sy:38,elbow:28,wrist:21,foot:4,torso:[[26,5,4,4],[30,8,6,7],[36,9,7,7],[41,7,5,6]],pelvis:10,thigh:[4,4,3],shin:[4,4.5,3],feet:[5,7,4],arm:[4,4,3.5],head:[4,5,7],side:[5,7,7],style:"round",gun:11},
cyclops:{name:"Cyclops CP-10-Z (CP-11-A photo body)",unit:"cyclops_cp10z",pitch:.055,hip:7,waist:24,knee:12,shoulder:13,sy:40,elbow:30,wrist:22,foot:4,torso:[[27,6,5,4],[31,9,8,6],[38,10,8,6],[44,8,5,5]],pelvis:10,thigh:[4,5,3.5],shin:[4,5,3.5],feet:[5,7,4],arm:[3.5,4,3.7],head:[5,5,6],side:[5,7,6],style:"square"},
griffin:{name:"Griffin GRF-1N",unit:"griffin_grf1n",pitch:.046,hip:6,waist:24,knee:12,shoulder:11,sy:39,elbow:29,wrist:21,foot:4,torso:[[27,4,4,4],[31,7,6,5],[37,8,6,5],[42,6,4,4]],pelvis:8,thigh:[3.5,4,3],shin:[3.5,4,3],feet:[4.5,6,4],arm:[3,3,3],head:[3,4,6],side:[4,5,5],style:"shield",gun:12},
wolverine:{name:"Wolverine WVR-6R",unit:"wolverine_wvr6r",pitch:.046,hip:6,waist:24,knee:12,shoulder:12,sy:38,elbow:29,wrist:21,foot:4,torso:[[27,5,4,4],[31,8,8,5],[36,9,7,6],[42,6,5,5]],pelvis:9,thigh:[3.5,4,3],shin:[4,4,3.5],feet:[4.5,7,4],arm:[3,3.5,3],head:[2.5,3,7],side:[4,5,5],style:"shield",gun:6},
firestarter:{name:"Firestarter FS9-H",unit:"firestarter_fs9h",pitch:.046,hip:5,waist:24,knee:12,shoulder:9,sy:39,elbow:30,wrist:22,foot:3,torso:[[27,3.5,3.5,3],[31,6,5,4],[37,6.5,5,4],[42,4,3,3]],pelvis:7,thigh:[2.6,3,2.2],shin:[2.5,3,2.3],feet:[3.8,5,3],arm:[2.5,2.5,2.5],head:[4,4,5],side:[3,4,4],style:"round"},
shadow_hawk:{name:"Shadow Hawk SHD-2H",unit:"shadow_hawk_shd2h",pitch:.045,hip:6,waist:24,knee:12,shoulder:11,sy:39,elbow:30,wrist:23,foot:4,torso:[[27,4,4,4],[31,7,6,4],[36,8,7,5],[42,6,5,4]],pelvis:9,thigh:[3,4,2.5],shin:[3.5,4,3],feet:[4.5,6,4],arm:[2.7,3.4,3],head:[3.5,4,6],side:[4,5,5],style:"shield"},
thunderbolt:{name:"Thunderbolt TDR-5S",unit:"thunderbolt_tdr5s",pitch:.05,hip:7,waist:23,knee:11,shoulder:13,sy:38,elbow:29,wrist:20,foot:4,torso:[[26,5.5,4,4],[30,9,8,6],[36,10,7,7],[41,8,5,6]],pelvis:10,thigh:[4,4.5,3.5],shin:[4.5,5,4],feet:[5,7,4],arm:[3.5,4,3.5],head:[3,4,5],side:[5,6,6],style:"shield",gun:12}
}[id];
const Y=(r,m)=>L("y",r,m),Z=(r,m)=>L("z",r,m),X=(r,m)=>L("x",r,m);
if(id==="marauder"){
let {spec,part}=assembly(id,"Marauder MAD-3R",.05,"digitigrade");spec.unit="marauder_mad3r";
let sym=(n,l,parent,p,sh,j)=>{for(let s of ["l","r"])sidePart(part,s,n,s.toUpperCase()+l,typeof parent==="function"?parent(s):parent,p,sh,j)};
part("pelvis","CT",null,[0,24,3],[Y([[21,-7,7,-1,9,.2],[24,-8,8,-2,9,.15],[27,-5,5,-1,7,.15]])]);
part("ct","CT","pelvis",[0,27,3],[Z([[-9,-5,5,28,36,.18],[-5,-8,8,27,40,.19],[1,-9,9,27,43,.15],[7,-8,8,29,44,.18],[12,-5,5,32,42,.22]])]);
part("hd","HD","ct",[0,33,-9],[Z([[-23,-3,3,25,30,.2],[-20,-5,5,25,32,.18],[-16,-6,6,26,35,.15],[-11,-6.5,6.5,28,37,.17],[-9,-5,5,28,36,.13]]),B([-2,30,-21],[2,31,-18],"glass","paint")]);
sym("t","T","ct",[9,36,2],[X([[8,31,41,-2,6,.13],[11,31,43,-2,8,.16],[13,31,40,-2,7,.12]],"plate")]);
sym("t_vent","T",s=>s+"t",[10,41,5],[Z([[7,8,13,34,42,.15],[11,8,13,34,42,.12],[13,9,12,35,40,.2]],"plate")]);
part("rt_cannon","RT","ct",[2,43,3],[Y([[43,-1,5,0,6,.1],[46,-1,5,0,6,.13]],"frame"),Z([[-4,0,4,45,49,.13],[3,-1,5,45,50,.14],[10,-1,5,44,49,.14],[13,0,4,45,48,.13]],"plate"),cyl("z",-21,-4,2,47,1.7,1.7,"gun"),cyl("z",-21,-18,2,47,.9,.9,"gun","subtract")]);
sym("a","A",s=>s+"t",[13,34,0],[X([[13,31,37,-3,3,.05],[16,29,37,-3,4,.15],[18,29,35,-2,3,.13]],"plate"),Y([[24,14,18,-3,2,.1],[28,14,18,-3,3,.15],[31,14,18,-2,3,.1]],"frame")],"shoulder");
sym("a_forearm","A",s=>s+"a",[16,24,-1],[Y([[19,13,19,-5,2,.12],[22,13,19,-5,3,.15],[24,14,18,-3,2,.07]],"plate")],"elbow");
sym("a_ppc","A",s=>s+"a_forearm",[16,21,-5],[Z([[-19,13,19,17,24,.18],[-15,12,20,17,25,.18],[-8,12,20,18,25,.16],[-5,13,19,19,24,.08]],"armor"),cyl("z",-19,-15,16,22,1.45,1.45,"gun","subtract"),cyl("z",-19,-16,16,19,1,1,"gun","subtract")]);
sym("l","L","pelvis",[5,21,4],[Y([[14,5,10,6,11,.1],[17,4,10,3,11,.18],[21,3,7,1,8,.08]])],"hip");
sym("l_shin","L",s=>s+"l",[8,14,8],[Y([[6,6,13,-1,4,.1],[9,6,13,0,7,.15],[12,5,12,4,11,.15],[14,5,10,6,11,.08]],"plate")],"knee");
sym("l_tarsus","L",s=>s+"l_shin",[9,6,2],[Y([[3,7,12,-1,4,.1],[6,6,13,-1,4,.08]],"frame")],"hock");
sym("l_foot","L",s=>s+"l_tarsus",[9,3,1],[Y([[0,4,14,-7,6,.17],[1.5,4,14,-6,5,.15],[3,7,12,-1,4,.08]],"plate")],"ankle");
spec.muzzles={LA:[[-16,22,-19],[-16,19,-19]],RA:[[16,22,-19],[16,19,-19]],RT:[2,47,-21]};
return {spec,anchors:{waist:[0,24,3],head:[0,29,-22],ls:[-13,34,0],rs:[13,34,0],chest:[0,38,-3],top:[2,47,3]}}
}
let {spec,part}=assembly(id,cfg.name,cfg.pitch,"plantigrade");spec.unit=cfg.unit;spec.punch=id!=="firestarter";let c=cfg,h=c.hip,k=c.knee,w=c.waist,sy=c.sy,el=c.elbow,wr=c.wrist,f=c.foot,s=c.shoulder, [th0,th1,th2]=c.thigh,[sh0,sh1,sh2]=c.shin,[fw,ff,fb]=c.feet,[aw,ad,af]=c.arm,[hw,hd,hh]=c.head,[tw,td,tb]=c.side;let m=c.torso.at(-1)[0],max=Math.max(...c.torso.map(t=>t[1])),attach=max-2;
let sym=(n,l,parent,p,sh,j)=>{for(let q of ["l","r"])sidePart(part,q,n,q.toUpperCase()+l,typeof parent==="function"?parent(q):parent,p,sh,j)};
let yrow=(a,x,half,z,dep,k=.16)=>[a,x-half,x+half,z-dep,z+dep,k];
part("pelvis","CT",null,[0,w,0],[Y([[w-4,-c.pelvis+2,c.pelvis-2,-3,4,.16],[w,-c.pelvis,c.pelvis,-4,4,.14],[w+3,-4,4,-3,3,.12]])]);
part("ct","CT","pelvis",[0,w+3,0],[Y(c.torso.map(([y,x,z,b])=>[y,-x,x,-z,b,.14]))]);
part("ct_breast","CT","ct",[0,sy-4,-5],[Z([[-c.torso[1][2]-2,-max+3,max-3,w+7,sy+1,.2],[-c.torso[1][2],-max+1,max-1,w+6,sy+2,.15],[-3,-max+2,max-2,w+7,sy+1,.12]],"plate")]);
const headx=id==="thunderbolt"?4:0,hy=id==="thunderbolt"?m-3:m;
if(id==="dragon"){
part("hd","HD","ct",[0,40,-3],[Y([[39,-4,4,-4,2,.16],[42,-4,4,-6,3,.15],[45,-3,3,-4,2,.2]],"plate"),B([-3,41,-6],[3,43,-4],"glass","paint")]);
part("ct_snout","CT","ct",[0,34,-7],[Z([[-17,-4,4,29,35,.14],[-13,-5,5,29,37,.18],[-9,-7,7,29,39,.17],[-5,-6,6,30,39,.12]],"armor"),...Array.from({length:10},(_,i)=>cyl("z",-17,-15,[-2.7,-.9,.9,2.7][i%4],30+Math.floor(i/4)*1.7,.65,.65,"gun","subtract"))]);
for(let d of [-1,1])part(d<0?"lt_horn":"rt_horn","CT","hd",[d*3,45,0],[Y([[45,d*3-1,d*3+1,-.5,1.5,.06],[48,d*3-1,d*3+.5,0,1,.05],[49,d*3-.6,d*3+.3,0,.8,.02]],"plate")]);
spec.muzzles.CT=Array.from({length:10},(_,i)=>[[-2.7,-.9,.9,2.7][i%4],30+Math.floor(i/4)*1.7,-17]);
}else{
const shape=id==="firestarter"?loft("y",[[hy,ellipse(headx,-1,hw*.75,hd*.7,16)],[hy+2,ellipse(headx,-1,hw,hd,16)],[hy+4,ellipse(headx,0,hw*.85,hd*.85,16)],[hy+hh,ellipse(headx,0,hw*.45,hd*.45,16)]],"plate"):Y([[hy,headx-hw*.8,headx+hw*.8,-hd,2,.1],[hy+2,headx-hw,headx+hw,-hd-1,3,.16],[hy+hh-1,headx-hw*.8,headx+hw*.8,-hd+.5,3,.17],[hy+hh,headx-hw*.6,headx+hw*.6,-hd+1,2,.15]],"plate");
part("hd","HD","ct",[headx,hy,-1],[shape,B([headx-hw*.6,hy+1,-hd-1],[headx+hw*.6,hy+3,-hd+.1],"glass","paint")]);
}
sym("t","T","ct",[attach+1,sy,0],[X([[attach,sy-6,sy+3,-td,tb,.09],[s-1,sy-6,sy+3,-td+1,tb,.14],[s,sy-5,sy+2,-td+1,tb-1,.12]],"armor")]);
sym("t_back","T",q=>q+"t",[s-2,sy-3,tb-1],[Z([[tb-1,s-4,s,sy-7,sy+1,.1],[tb+2,s-5,s,sy-6,sy+1,.14],[tb+4,s-4,s-1,sy-5,sy,.17]],"plate")]);
let armx=s+3,shoulderwidth=c.style==="round"?aw+1:aw+.7;
let cap=c.style==="round"?loft("x",[[s,ellipse(sy,0,4.4,ad+1,16)],[s+2,ellipse(sy,0,5.8,ad+1.5,16)],[s+5,ellipse(sy,0,5.5,ad+1,16)],[s+7,ellipse(sy,0,3.4,ad*.8,16)]],"plate"):X([[s,sy-4,sy+4,-ad,ad,.12],[s+2,sy-5,sy+5,-ad-1,ad+1,.11],[s+6,sy-5,sy+4,-ad-1,ad+1,.2],[s+7,sy-3,sy+2,-ad,ad,.16]],"plate");
sym("a","A",q=>q+"t",[s,sy,0],[cap,Y([yrow(sy-7,armx,aw*.66,0,ad*.7,.1),yrow(sy-3,armx,aw*.7,0,ad*.7,.08)],"frame")],"shoulder");
sym("a_upper","A",q=>q+"a",[armx,sy-7,0],[Y([yrow(el,armx,aw*.65,0,ad*.65,.08),yrow(el+2,armx,aw*.85,0,ad*.8,.12),yrow(sy-7,armx,aw*.66,0,ad*.7,.08)],"armor")]);
sym("a_forearm","A",q=>q+"a_upper",[armx,el,0],[Y([yrow(wr,armx,af,-1,ad*.8,.14),yrow(wr+3,armx,af+.3,-1,ad+1,.15),yrow(el,armx,aw*.65,0,ad*.65,.08)],"plate")],"elbow");
if(id!=="firestarter"){sym("a_hand","A",q=>q+"a_forearm",[armx,wr,-1],[Y([yrow(wr-4,armx,af*.78,-1,ad*.7,.2),yrow(wr-2,armx,af*.9,-1,ad*.8,.15),yrow(wr,armx,af,-1,ad*.8,.1)],"frame")]);}
if(c.gun){const gunx=armx,gy=wr+2,start=-ad-1,end=start-c.gun;part("ra_gun","RA","ra_forearm",[gunx,gy,start],[Z([[end,gunx-1.5,gunx+1.5,gy-1.5,gy+1.5,.2],[end+3,gunx-1.8,gunx+1.8,gy-1.8,gy+1.8,.17],[start-4,gunx-2.7,gunx+2.7,gy-2.5,gy+2.5,.15],[start,gunx-2.8,gunx+2.8,gy-2.5,gy+2.5,.1]],"gun"),B([gunx-2,gy-2,start-1],[gunx+2,gy+2,start+2],"frame"),cyl("z",end,end+3,gunx,gy,1,1,"gun","subtract")]);spec.muzzles.RA=[gunx,gy,end]}
if(id==="firestarter"){for(let q of ["l","r"]){const x=q==="r"?armx:-armx;part(q+"a_flamers",q.toUpperCase()+"A",q+"a_forearm",[x,wr+2,-3],[Z([[-13,x-3,x+3,wr-1,wr+4,.18],[-8,x-3,x+3,wr-1,wr+5,.15],[-3,x-2.5,x+2.5,wr,wr+4,.1]],"plate"),...[-1.5,1.5].map(dx=>cyl("z",-13,-10,x+dx,wr+1.5,.85,.85,"gun","subtract"))]);spec.muzzles[q.toUpperCase()+"A"]=[[-1.5,1.5].map(dx=>[x+dx,wr+1.5,-13])].flat()}}
if(id==="griffin"||id==="wolverine"||id==="thunderbolt"){
const sg=id==="griffin"?1:-1,xx=sg*(id==="thunderbolt"?6:5),yy=id==="thunderbolt"?m+3:m+2,n=id==="griffin"?10:id==="wolverine"?6:15;
const pts=n===15?Array.from({length:15},(_,i)=>[xx+(i%5-2)*1.6,yy+(Math.floor(i/5)-1)*1.8]):Array.from({length:n},(_,i)=>[xx+(i%2-.5)*2.1,yy+(Math.floor(i/2)-(n/2-1)/2)*1.7]);
const r=n===15?5.3:n===10?4.7:3.5,lo=-11,hi=0,parent=sg===1?"rt":"lt";
part(parent+"_rack",parent.toUpperCase(),"ct",[xx,m-1,0],[B([xx-2,m-2,-2],[xx+2,m+2,2],"frame"),...(id==="wolverine"?[Z([[lo,xx-r,xx+r,yy-r,yy+r,.16],[hi,xx-r,xx+r,yy-r,yy+r,.14]],"plate")]:[cyl("z",lo,hi,xx,yy,r,r,"plate")]),...pts.map(([x,y])=>cyl("z",lo,lo+3,x,y,.63,.63,"gun","subtract"))]);spec.muzzles[parent.toUpperCase()]=pts.map(([x,y])=>[x,y,lo])
}
if(id==="shadow_hawk"){const xx=-7,yy=m+1;part("lt_cannon","LT","lt",[xx,sy+1,0],[B([xx-2,sy+1,-1],[xx+2,yy+1,3],"frame"),cyl("z",-20,5,xx,yy,1.5,1.5,"gun"),cyl("z",-20,-17,xx,yy,.85,.85,"gun","subtract"),Z([[-4,xx-2.5,xx+2.5,yy-2.5,yy+2.5,.15],[5,xx-2.5,xx+2.5,yy-2.5,yy+2.5,.12]],"plate")]);spec.muzzles.LT=[xx,yy,-20];
part("rt_missiles","RT","ct",[5,sy-3,-6],[B([3,sy-5,-10],[7,sy,-4],"plate"),...[[4,sy-4],[6,sy-4],[4,sy-2],[6,sy-2],[5,sy-1]].map(([x,y])=>cyl("z",-10,-8,x,y,.65,.65,"gun","subtract"))]);spec.muzzles.RT=[[4,sy-4,-10],[6,sy-4,-10],[4,sy-2,-10],[6,sy-2,-10],[5,sy-1,-10]]}
if(id==="cyclops"){let x=5,yy=sy-5;part("rt_cannon","RT","ct",[x,yy,-6],[Z([[-15,x-2.6,x+2.6,yy-2.6,yy+2.6,.22],[-10,x-3,x+3,yy-3,yy+3,.15],[-5,x-3,x+3,yy-3,yy+3,.1]],"gun"),cyl("z",-15,-11,x,yy,1.4,1.4,"gun","subtract")]);let xx=-6;part("lt_rack","LT","ct",[xx,sy-3,-6],[B([xx-2.5,sy-7,-10],[xx+2.5,sy+2,-5],"plate"),...Array.from({length:10},(_,i)=>cyl("z",-10,-8,xx+(i%2-.5)*2,sy-6+Math.floor(i/2)*1.7,.65,.65,"gun","subtract"))]);spec.muzzles.RT=[x,yy,-15];spec.muzzles.LT=Array.from({length:10},(_,i)=>[xx+(i%2-.5)*2,sy-6+Math.floor(i/2)*1.7,-10]);part("hd_antenna","HD","hd",[2,hy+hh,1],[Y([[hy+hh,1,3,0,2,.05],[hy+hh+5,1.5,2.7,1,2,.05]],"frame")])}
if(id==="thunderbolt"){part("ct_srm","CT","ct",[3,sy-6,-5],[B([1,sy-8,-10],[5,sy-4,-5],"plate"),cyl("z",-10,-8,2,sy-6,.7,.7,"gun","subtract"),cyl("z",-10,-8,4,sy-6,.7,.7,"gun","subtract")]);spec.muzzles.CT=[[2,sy-6,-10],[4,sy-6,-10]]}
sym("l","L","pelvis",[h,w-4,0],[Y([yrow(k,h+1,th2,0,th2,.1),yrow(k+3,h+.8,th0,0,th1,.18),yrow(w-4,h,Math.min(th0,c.pelvis-h+1),0,3,.09)],"armor")],"hip");
sym("l_shin","L",q=>q+"l",[h+1,k,0],[Y([yrow(f,h+2,sh2,0,sh2,.1),yrow(f+3,h+2,sh0,0,sh1,.19),yrow(k-2,h+1.2,sh0*.9,-.7,sh1*.9,.13),yrow(k,h+1,th2,0,th2,.08)],"armor")],"knee");
sym("l_kneecap","L",q=>q+"l_shin",[h+1,k-2,-th2],[Z([[-sh1-1,h+1-sh0*.62,h+1+sh0*.62,k-4,k-.5,.15],[-sh1+.3,h+1-sh0*.72,h+1+sh0*.72,k-4,k,.13],[-1,h+1-sh0*.65,h+1+sh0*.65,k-4,k-.5,.1]],"plate")]);
sym("l_foot","L",q=>q+"l_shin",[h+2,f,0],[Y([[0,h+2-fw,h+2+fw,-ff,fb,.15],[2,h+2-fw,h+2+fw,-ff+1,fb,.14], [f,h+2-sh2,h+2+sh2,-sh2,sh2,.09]],"plate")],"ankle");
return {spec,anchors:{waist:[0,w+1,0],head:[headx,hy+2,-hd],ls:[-s,sy,0],rs:[s,sy,0],chest:[0,sy-5,-c.torso[1][2]],top:[headx,hy+hh,0]}}
}
function repair(lib,spec){
const {B,raster,audit,components,backed}=lib, D=[[1,0,0],[-1,0,0],[0,1,0],[0,-1,0],[0,0,1],[0,0,-1]],K=x=>x.join(","),V=x=>x.split(",").map(Number),add=(a,b,n=1)=>a.map((x,i)=>x+n*b[i]);let maps=raster(spec),own=new Map(),cuts={},history=[];
function writeCells(p,ks,op,mat="frame"){let rows={};for(let k of ks){let [x,y,z]=V(k);(rows[y+","+z]??=[]).push(x)}for(let [k,xs] of Object.entries(rows)){let [y,z]=V(k);xs.sort((a,b)=>a-b);let start=xs[0],last=start;for(let x of [...xs.slice(1),null]){if(x===last+1){last=x;continue}p.shapes.push(B([start,y,z],[last+1,y+1,z+1],mat,op));start=last=x}}}
for(let p of spec.parts){for(let k of maps[p.name].keys()){if(own.has(k)){(cuts[p.name]??=[]).push(k);maps[p.name].delete(k)}else own.set(k,p.name)}}
for(let p of spec.parts)if(cuts[p.name]?.length){writeCells(p,cuts[p.name],"subtract");history.push({part:p.name,op:"exclusive seam recut",cells:cuts[p.name].length})}
function addCells(p,keys){let n=0;for(let k of keys){if(!maps[p.name].has(k)){maps[p.name].set(k,"frame");own.set(k,p.name);n++}}writeCells(p,keys,"add");history.push({part:p.name,op:"backed local socket",cells:n})}
for(let p of spec.parts){let m=maps[p.name],cs=components(m);if(cs.length>1&&cs.slice(1).every(a=>a.length<=3)){let ks=cs.slice(1).flat();for(let k of ks){m.delete(k);own.delete(k)}writeCells(p,ks,"subtract");history.push({part:p.name,op:"trim isolated slivers <=3 cells",cells:ks.length})}}
for(let p of spec.parts){if(!p.parent)continue;let m=maps[p.name],par=maps[p.parent];if(backed(m,par).patches)continue;let best=null;
for(let k of par.keys()){let c=V(k);for(let d of D){if(par.has(K(add(c,d))))continue;let ax=[0,1,2].filter(i=>!d[i]);let base=[[0,0],[1,0],[0,1],[1,1]].map(([u,v])=>{let t=c.slice();t[ax[0]]+=u;t[ax[1]]+=v;return t});if(!base.every(t=>par.has(K(t))&&par.has(K(add(t,d,-1)))))continue;for(let depth=2;depth<=4;depth++){let keys=[];let ok=true,touch=0;for(let a=1;a<=depth;a++)for(let t of base){let q=K(add(t,d,a)),owner=own.get(q);if(owner&&owner!==p.name)ok=false;if(m.has(q))touch++;else keys.push(q)}if(!ok||!touch||keys.length>14||!keys.length)continue;let dist=base.reduce((n,t)=>n+t.reduce((s,x,i)=>s+(x-p.pivot[i])**2,0),0)/4,score=keys.length+.04*dist;if(!best||score<best.score)best={keys,score}}}}
if(best)addCells(p,best.keys)}
return {spec,history,qa:audit(spec,raster(spec))}
}
;({author,repair})
