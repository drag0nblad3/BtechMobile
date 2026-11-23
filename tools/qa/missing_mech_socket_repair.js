/* Geometry-only local backed-socket repair for imported BattleMechs.
 * Preserve authored bores, muzzles, pivots, silhouettes and material roles.
 * Pure JS to enable pre-commit diagnostics; exported for Node + review. */
const MissingMechSockets = (() => {
  const dirs=[[1,0,0],[-1,0,0],[0,1,0],[0,-1,0],[0,0,1],[0,0,-1]];
  const key = p => p.join(",");
  const vec = k => k.split(",").map(Number);
  const add = (a,b,s=1) => a.map((v,i)=>v+b[i]*s);
  const point = (x,y,p) => {
    let inside=false;
    for(let i=0,j=p.length-1;i<p.length;j=i++){
      const [xi,yi]=p[i],[xj,yj]=p[j];
      if((yi>y)!==(yj>y) && x<(xj-xi)*(y-yi)/(yj-yi)+xi)inside=!inside;
    }
    return inside;
  };
  function paint(part){
    const cells=new Set();
    for(const shape of [...(part.shapes||[]),...(part.add||[])]){
      if(shape.loft){
        const axis=shape.loft.axis||"y",sections=shape.loft.sections;
        for(let i=0;i<sections.length-1;i++){
          const a=sections[i],b=sections[i+1];
          if(b.at<a.at||a.polygon.length!==b.polygon.length)continue;
          for(let layer=a.at;layer<=b.at;layer++){
            const t=a.at===b.at?0:(layer-a.at)/(b.at-a.at);
            const poly=a.polygon.map((v,j)=>[v[0]+(b.polygon[j][0]-v[0])*t,v[1]+(b.polygon[j][1]-v[1])*t]);
            const xs=poly.map(p=>p[0]),ys=poly.map(p=>p[1]);
            for(let x=Math.floor(Math.min(...xs));x<Math.ceil(Math.max(...xs));x++){
              for(let y=Math.floor(Math.min(...ys));y<Math.ceil(Math.max(...ys));y++){
                if(point(x+.5,y+.5,poly))cells.add(key(axis==="y"?[x,layer,y]:[x,y,layer]));
              }
            }
          }
        }
        continue;
      }
      const type=shape.box?"box":shape.shell?"shell":shape.erase?"erase":null;
      if(!type)continue;
      const a=shape[type][0].map(Math.trunc),b=shape[type][1].map(Math.trunc);
      for(let x=a[0];x<=b[0];x++)for(let y=a[1];y<=b[1];y++)for(let z=a[2];z<=b[2];z++){
        const v=key([x,y,z]);if(type==="erase")cells.delete(v);else cells.add(v);
      }
    }
    return cells;
  }
  function raster(recipe){
    const raw=recipe.parts.map(p=>({name:p.name,parent:p.parent||"",pivot:p.pivot||[0,0,0],cells:paint(p)}));
    const owner=new Map(),parts=new Map();
    for(const p of [...raw].sort((a,b)=>a.cells.size-b.cells.size||a.name.localeCompare(b.name))){
      for(const c of p.cells){if(owner.has(c))p.cells.delete(c);else owner.set(c,p.name)}
      parts.set(p.name,p);
    }
    return {parts,owner,raw};
  }
  function solid(child,parent){
    for(const k of child){
      const c=vec(k);
      for(const n of dirs){
        if(!parent.has(key(add(c,n))))continue;
        const ax=n[0]?[1,2]:n[1]?[0,2]:[0,1];
        for(const sg1 of [-1,1])for(const sg2 of [-1,1]){
          let good=true;
          for(const u of [0,1])for(const v of [0,1]){
            const at=c.slice();at[ax[0]]+=u*sg1;at[ax[1]]+=v*sg2;
            if(!child.has(key(at))||!child.has(key(add(at,n,-1)))||
               !parent.has(key(add(at,n)))||!parent.has(key(add(at,n,2))))good=false;
          }
          if(good)return true;
        }
      }
    }
    return false;
  }
  function prohibited(recipe){
    const protectedCells=new Set();
    for(const part of recipe.parts)for(const s of part.shapes||[]){
      if(!s.erase)continue;
      const [a,b]=s.erase;
      for(let x=Math.trunc(a[0]);x<=Math.trunc(b[0]);x++)
        for(let y=Math.trunc(a[1]);y<=Math.trunc(b[1]);y++)
          for(let z=Math.trunc(a[2]);z<=Math.trunc(b[2]);z++)
            protectedCells.add(key([x,y,z]));
    }
    for(const muzzle of Object.values(recipe.muzzles||{})){
      const list=Array.isArray(muzzle[0])?muzzle:[muzzle];
      for(const v of list)for(let x=Math.round(v[0])-1;x<=Math.round(v[0])+1;x++)
        for(let y=Math.round(v[1])-1;y<=Math.round(v[1])+1;y++)
          for(let z=Math.round(v[2])-2;z<=Math.round(v[2])+1;z++)
            protectedCells.add(key([x,y,z]));
    }
    return protectedCells;
  }
  function projections(cells,axis){
    const axes=[0,1,2].filter(i=>i!==axis),out=new Map();
    for(const k of cells){
      const v=vec(k);
      for(let a=-1;a<=0;a++)for(let b=-1;b<=0;b++){
        const q=key([v[axes[0]]+a,v[axes[1]]+b]);
        if(!out.has(q))out.set(q,new Set());
        out.get(q).add(v[axis]);
      }
    }
    return out;
  }
  function socket(childName,parentName,mesh,blocked,maxGap=7){
    const c=mesh.parts.get(childName),p=mesh.parts.get(parentName);
    if(!c||!p||c.cells.size===0||p.cells.size===0)return null;
    const pivot=c.pivot.map(v=>Number(v)||0);
    let best=null;
    for(const n of dirs){
      const axis=n.findIndex(v=>v!==0),sgn=n[axis],axes=[0,1,2].filter(i=>i!==axis);
      const cs=projections(c.cells,axis),ps=projections(p.cells,axis);
      for(const [proj,clist] of cs){
        const plist=ps.get(proj);
        if(!plist)continue;
        const xy=vec(proj);
        // A 2x2 internal collar; align to actual material on both sides.
        for(const ca of clist)for(const pa of plist){
          const distance=(pa-ca)*sgn;
          if(distance<1||distance>maxGap)continue;
          const plan=[],outer=distance;
          for(let depth=-1;depth<=outer;depth++){
            const owner=depth<outer-1?childName:parentName;
            // last two layers form the parent backing; the child owns all earlier layers.
            const actualOwner=depth<=outer-2?childName:parentName;
            for(let a=0;a<2;a++)for(let b=0;b<2;b++){
              const at=[0,0,0];at[axis]=ca+depth*sgn;
              at[axes[0]]=xy[0]+a;at[axes[1]]=xy[1]+b;
              plan.push({pos:at,owner:actualOwner});
            }
          }
          // parent front at pa and backing at pa+sgn; child at pa-sgn and ca-sgn.
          // For distance=1, child owns depths -1 and 0; parent owns 1 and 2.
          if(distance===1){
            plan.length=0;
            for(const depth of [-1,0,1,2]){
              for(let a=0;a<2;a++)for(let b=0;b<2;b++){
                const at=[0,0,0];at[axis]=ca+depth*sgn;
                at[axes[0]]=xy[0]+a;at[axes[1]]=xy[1]+b;
                plan.push({pos:at,owner:depth<=0?childName:parentName});
              }
            }
          }else{
            // At distance d, child spans ca-1..pa-1, parent spans pa..pa+1.
            plan.length=0;
            for(let depth=-1;depth<=distance+1;depth++){
              for(let a=0;a<2;a++)for(let b=0;b<2;b++){
                const at=[0,0,0];at[axis]=ca+depth*sgn;
                at[axes[0]]=xy[0]+a;at[axes[1]]=xy[1]+b;
                plan.push({pos:at,owner:depth<distance?childName:parentName});
              }
            }
          }
          let legal=true,added=0,anchorC=0,anchorP=0;
          for(const pt of plan){
            const k=key(pt.pos),old=mesh.owner.get(k);
            if((old&&old!==pt.owner)||(!old&&blocked.has(k))){legal=false;break}
            if(!old)added++;
            if(old===childName)anchorC++;
            if(old===parentName)anchorP++;
          }
          if(!legal||anchorC<2||anchorP<2||added>48)continue;
          const patchCenter=[0,0,0];patchCenter[axis]=(ca+pa)/2;
          patchCenter[axes[0]]=xy[0]+.5;patchCenter[axes[1]]=xy[1]+.5;
          const pivotDist=Math.abs(pivot[0]-patchCenter[0])+Math.abs(pivot[1]-patchCenter[1])+Math.abs(pivot[2]-patchCenter[2]);
          const score=added*10+pivotDist*.2 + distance;
          if(!best||score<best.score)best={score,plan,added,axis,direction:sgn,child:childName,parent:parentName,gap:distance-1};
        }
      }
    }
    return best;
  }
  function insertShape(part,shape){
    const index=(part.shapes||[]).findIndex(x=>x.erase);
    if(index<0)part.shapes.push(shape);
    else part.shapes.splice(index,0,shape);
  }
  function apply(recipe,options={}){
    const d=JSON.parse(JSON.stringify(recipe)),changes=[],failed=[];
    const blocked=prohibited(d);let mesh=raster(d);
    for(let pass=0;pass<3;pass++){
      let updated=0;
      for(const p of d.parts){
        if(!p.parent)continue;
        const ch=mesh.parts.get(p.name),pa=mesh.parts.get(p.parent);
        if(!ch||!pa||solid(ch.cells,pa.cells))continue;
        const fix=socket(p.name,p.parent,mesh,blocked,options.maxGap||7);
        if(!fix){if(pass===2)failed.push(p.name+"->"+p.parent);continue;}
        const by=new Map();
        for(const pt of fix.plan){
          if(mesh.owner.has(key(pt.pos)))continue;
          if(!by.has(pt.owner))by.set(pt.owner,[]);
          by.get(pt.owner).push(pt.pos);
        }
        // Keep the authored patch compact: at most one axis-aligned 2x2 collar per owner.
        for(const [owner,positions] of by){
          const lo=[Infinity,Infinity,Infinity],hi=[-Infinity,-Infinity,-Infinity];
          for(const at of positions)for(let i=0;i<3;i++){lo[i]=Math.min(lo[i],at[i]);hi[i]=Math.max(hi[i],at[i]);}
          if(lo.every(Number.isFinite)){
            const target=d.parts.find(x=>x.name===owner);
            insertShape(target,{box:[lo,hi],mat:"joint"});
          }
        }
        // If the proposed box intersects an already-owned cell of the same part,
        // it remains structurally backed and the original colors may change locally.
        changes.push({part:p.name,parent:p.parent,added:fix.added,gap:fix.gap,axis:fix.axis});
        mesh=raster(d);updated++;
      }
      if(!updated)break;
    }
    const unresolved=[];
    for(const p of d.parts)if(p.parent){
      const c=mesh.parts.get(p.name),parent=mesh.parts.get(p.parent);
      if(!c||!parent||!solid(c.cells,parent.cells))unresolved.push(p.name+"->"+p.parent);
    }
    return {recipe:d,changes,unresolved,estimatedBefore:changes.length+unresolved.length,estimatedAdded:changes.reduce((sum,c)=>sum+c.added,0)};
  }
  return {paint,raster,solid,prohibited,socket,apply};
})();
if(typeof module!=="undefined")module.exports=MissingMechSockets;
MissingMechSockets;
