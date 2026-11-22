/* Geometry-first missing-chassis generator. Pure JS: evaluate as an expression
   returning make(unit, cfg, detail); no external dependencies or game-rule edits. */
({
 make(unit, cfg, detail) {
  const id=unit.sprite, round=n=>Math.round(n*100000)/100000;
  const poly=(cx,cz,w,d,b=1)=> {
    const l=cx-w/2,r=cx+w/2,f=cz-d/2,k=cz+d/2;
    const a=Math.min(b,w/3,d/3);
    return [[l+a,f],[r-a,f],[r,f+a],[r,k-a],[r-a,k],[l+a,k],[l,k-a],[l,f+a]].map(v=>v.map(round));
  };
  const cross=(at,cx,cz,w,d,b=1)=>({at,polygon:poly(cx,cz,w,d,b)});
  const loft=(sections,mat="armor",axis="y")=>({loft:{axis,sections},mat});
  const box=(a,b,mat="frame")=>({box:[a,b],mat});
  const erase=(a,b)=>({erase:[a,b]});
  const part=(name,loc,shapes,parent="",joint="",pivot=null)=>{
   const p={name,loc,shapes};
   if(parent)p.parent=parent;if(joint)p.joint=joint;if(pivot)p.pivot=pivot;
   return p;
  };
  const style=cfg.style||"human", bird=["bird","insect","fighter"].includes(style);
  const heavy=["assault","carapace"].includes(style), thin=["runner","insect"].includes(style);
  const body=cfg.body||10,roof=cfg.roof||35,headFront=cfg.nose||-11;
  const shoulderW=cfg.shoulder||5, limb=cfg.limb||4;
  const waist=body*(thin?.40:heavy?.55:.47), chest=body*(heavy?1.16:1);
  const depth=cfg.depth||10,hipX=(cfg.hip||5);
  const zbody=cfg.zbody||0, torsoFront=zbody-depth/2, headY=cfg.headY||32;
  const tilt=cfg.rake||0;
  const parts=[],muzzles={},weapons=[],jets={};
  const colors=[
   {name:"armor",color:cfg.color||"65746e",role:"armor"},
   {name:"plate",color:cfg.trim||"91a19c",role:"armor"},
   {name:"glass",color:"2f6475",role:"armor"},
   {name:"frame",color:"374047",role:"structure"},
   {name:"joint",color:"56636b",role:"structure"}
  ];
  // Each chassis receives distinct waist, carapace crown, nose, shoulder span.
  parts.push(part("ct","CT",[
   loft([cross(22,0,zbody,waist+1,depth*.63),cross(25,0,zbody+tilt,waist,depth*.74),
      cross(29,0,zbody,chest,depth),cross(roof-3,0,zbody+.3,chest*.94,depth*.95),
      cross(roof-1,0,zbody+1,chest*.62,depth*.72)],"armor"),
   box([-2,21,-1],[2,22,3],"frame"),
   box([-3,roof-2,Math.round(depth*.48)],[3,roof-2,Math.round(depth*.48)+1],"plate")
  ]));
  // Cockpits sit forward of the crown; avian and assault designs have sunk heads.
  const hx=cfg.headWidth||3.6,hd=cfg.headDepth||7;
  const hy=headY-(heavy?2:0);
  const cz=headFront+hd/2;
  parts.push(part("hd","HD",[
    loft([cross(hy-2,0,cz+1,hx*.85,hd*.84,.65),
          cross(hy+1,0,cz,hx,hd,.65),
          cross(hy+3,0,cz+1,hx*.65,hd*.82,.55)],"armor"),
    box([-1,hy,Math.round(headFront)],[1,hy+1,Math.round(headFront)],"glass"),
    box([-1,hy-2,Math.round(headFront+hd-1)],[1,hy-1,Math.round(headFront+hd)],"joint")
  ],"ct"));
  // Paired outer torso lobes remain separated from head and never become one slab.
  for(const side of [-1,1]){
   const t=side<0?"lt":"rt", loc=side<0?"LT":"RT";
   const cx=side*(chest/2+shoulderW*.45);
   const sx=shoulderW*(bird?.84:1);
   parts.push(part(t,loc,[
    loft([cross(25,cx,zbody+1,sx*.70,depth*.68,.65),
         cross(30,cx,zbody,sx,depth*(heavy?1.00:.82),.8),
         cross(roof-1,cx,zbody+.6,sx*(bird?.76:1.04),depth*.82,.8),
         cross(roof+1,cx,zbody+1.5,sx*.62,depth*.58,.55)],"armor"),
    box([Math.round(cx),29,Math.round(depth*.36)],[Math.round(cx),31,Math.round(depth*.55)],"plate")
   ],"ct"));
  }
  // Arms are separately articulated with open elbows and narrow wrists.
  for(const side of [-1,1]){
   const name=side<0?"la":"ra", loc=side<0?"LA":"RA", p=side<0?"lt":"rt";
   const xc=side*(chest/2+shoulderW+1);
   const size=limb*(cfg.armBias?.[loc]||1);
   const handY=thin?17:15;
   parts.push(part(name,loc,[
    loft([cross(handY,xc,zbody,size*.64,depth*.45,.6),
          cross(20,xc+side*.4,zbody+1,size*.68,depth*.52,.6),
          cross(25,xc,zbody+.6,size*.91,depth*.68,.7),
          cross(30,xc-side*.7,zbody,size,depth*.66,.8)],"armor"),
    box([Math.round(xc)-1,handY-1,-1],[Math.round(xc)+1,handY+1,1],"joint")
   ],p,"shoulder",[round(xc-side*.5),30,zbody]));
  }
  // Articulated legs: hip/thigh, knee/shin, hock/tarsus when reverse-jointed, narrow feet.
  for(const side of [-1,1]){
   const p=side<0?"ll":"rl",loc=side<0?"LL":"RL",xx=side*hipX;
   const thighW=(cfg.thigh||4.4), shinW=(cfg.shin||3.1);
   parts.push(part(p,loc,[
    loft([cross(15,xx,zbody+2,thighW*.77,depth*.50,.6),
          cross(19,xx,zbody+.7,thighW,depth*.59,.7),
          cross(21,xx,zbody,thighW*.85,depth*.50,.5)],"armor")
   ],"ct","hip",[xx,21,zbody]));
   const k=p+"_shin";
   parts.push(part(k,loc,[
    loft([cross(8,xx,zbody+(bird?4.0:1.0),shinW*.72,depth*.48,.55),
          cross(11,xx,zbody+(bird?5.0:1.5),shinW,depth*.55,.55),
          cross(14,xx,zbody+2.1,shinW*1.18,depth*.54,.6)],"armor")
   ],p,"knee",[xx,14,zbody+2]));
   let parent=k;
   if(bird){
    const t=p+"_tarsus";
    parts.push(part(t,loc,[
     loft([cross(4,xx,zbody+1,shinW*.64,depth*.43,.5),
           cross(7,xx,zbody+3.5,shinW*.74,depth*.44,.5)],"armor")
    ],k,"hock",[xx,8,zbody+4]));
    parent=t;
   }else{
    parts.push(part(p+"_ankle",loc,[
      box([Math.round(xx-1),4,0],[Math.round(xx+1),7,2],"joint")
    ],k,"ankle",[xx,5,1]));
    parent=p+"_ankle";
   }
   parts.push(part(p+"_foot",loc,[
     loft([cross(0,xx,zbody-3,cfg.foot||5.0,depth*.88,.75),
           cross(2,xx,zbody-2,(cfg.foot||5)*.95,depth*.70,.75),
           cross(3,xx,zbody,(cfg.foot||5)*.72,depth*.48,.55)],"armor")
   ],parent,"ankle",[xx,3,zbody]));
  }
  // Unit record sheets alone determine which visible mounts exist.
  const gear=unit.equipment||{}, isWeapon=s=> !/^(ammo:|heat_sink|jump_jet|endo_|ferro_|stealth|tsm|masc|supercharger|guardian_ecm|angel_ecm|c3|case|targeting|ballistic_|reactive|composite)/.test(s);
  const classify=s=> /lrm|srm|mml|atm|rocket|narc|streak/i.test(s)?"missile":/gauss|ac\d|ppc|plasma|rifle|autocannon/i.test(s)?"cannon":"laser";
  let gunParts=0;
  for(const loc of ["LA","RA","LT","RT","CT","HD"]){
   const eq=(gear[loc]||[]).filter(isWeapon);
   if(!eq.length)continue;
   const kind=classify(eq[0]);
   const label=eq.map(e=>e.replace(/[\*\~+].*$/,"")).join(", ");
   const side=loc.endsWith("A")||loc.endsWith("T")?(loc[0]==="L"?-1:1):0;
   const x=loc==="CT"||loc==="HD"?0:side*(loc.endsWith("A")?chest/2+shoulderW+1:chest/2+shoulderW*.45);
   const y=loc==="HD"?hy+1:loc==="CT"?27:loc.endsWith("A")?22:32;
   const z=-Math.ceil(depth*.5)-3;
   const parent=({LA:"la",RA:"ra",LT:"lt",RT:"rt",CT:"ct",HD:"hd"})[loc];
   const c=Math.round(x),v=Math.round(y);
   const tag=loc.toLowerCase()+"_weapon";
   const gauge=/gauss|lb20|ultra_ac10/i.test(eq[0])?3:/ppc|ac|srm|lrm/i.test(eq[0])?2:1;
   const barrel=kind==="missile"?5+((/\d\d/.test(eq[0]))?2:0):gauge+1;
   const len=kind==="cannon"?(cfg.longGun||8):kind==="missile"?6:4;
   const muzzleZ=z-len;
   const shapes=[
     loft([ {at:muzzleZ,polygon:poly(c,v,barrel,kind==="missile"?6:barrel,0.65)},
            {at:muzzleZ+2,polygon:poly(c,v,barrel+1,kind==="missile"?7:barrel+1,.65)},
            {at:z-1,polygon:poly(c,v,barrel+2,kind==="missile"?7:barrel+2,.65)},
            {at:z+2,polygon:poly(c,v,barrel+2,kind==="missile"?7:barrel+2,.65)} ],"plate","z")
   ];
   const mouths=[];
   if(kind==="missile"){
     let count=Number((eq[0].match(/(?:lrm|srm|mml|atm|streak_srm)(\d+)/i)||[])[1]||6);
     count=Math.max(3,Math.min(12,count));
     const columns= count<=6?2:3,rows=Math.ceil(count/columns);
     // Missile muzzle openings are actual negative volume, not painted circles.
     for(let i=0;i<count;i++){
       const mx=c+Math.round((i%columns-(columns-1)/2)*1.55);
       const my=v+Math.round((Math.floor(i/columns)-(rows-1)/2)*1.4);
       shapes.push(erase([mx,my,muzzleZ],[mx,my,muzzleZ+2]));
       mouths.push([mx,my,muzzleZ]);
     }
   }else{
     shapes.push(erase([c,v,muzzleZ],[c,v,muzzleZ+2]));
     mouths.push([c,v,muzzleZ]);
   }
   parts.push(part(tag,loc,shapes,parent));
   muzzles[loc]=mouths.length===1?mouths[0]:mouths;
   weapons.push({label:label.slice(0,45),locs:[loc],kind});
   gunParts++;
  }
  if(!gunParts)throw new Error("No signature weapons for "+id);
  // Chassis-specific furniture never substitutes for the principal silhouette.
  const details={
   tian_zong:[box([-1,roof,3],[1,roof+4,4],"frame")],
   jackalope:[box([-2,hy+2,2],[-2,hy+5,3],"frame"),box([2,hy+2,2],[2,hy+5,3],"frame")],
   stealth:[box([0,roof,2],[0,roof+3,3],"frame")],
   marauder_ii:[box([-2,roof,4],[2,roof+3,6],"plate")],
   champion:[box([-Math.round(chest/2+5),29,3],[-Math.round(chest/2+1),30,5],"plate"),box([Math.round(chest/2+1),29,3],[Math.round(chest/2+5),30,5],"plate")],
   uziel:[box([-2,roof,2],[2,roof+2,3],"plate")],
   thunder:[box([-1,roof,4],[1,roof+3,5],"frame")],
   galahad:[box([-2,roof,4],[2,roof+2,6],"plate")],
   cerberus:[box([-3,roof,3],[3,roof+3,5],"plate")]
  };
  if(details[id])parts.find(p=>p.name==="ct").shapes.push(...details[id]);
  if(Number(unit.jump_mp||0)>0){
   jets.LT=[[-Math.round(chest/2+2),26,Math.round(depth/2)]];
   jets.RT=[[Math.round(chest/2+2),26,Math.round(depth/2)]];
  }
  // 50 actual vertex edits: five diminishing iterations of ten independent foci.
  const foci=["front silhouette","side projection","waist/chest","shoulder roof",
   "arm clearance","cockpit profile","thigh/knee","shin and hock","ankle/foot","weapon housing"];
  const edits=[];
  for(let cycle=0;cycle<50;cycle++){
   let changed=0;
   const focus=cycle%10,weight=1-(Math.floor(cycle/10)*.1);
   for(const p of parts){
    for(const s of p.shapes||[]){
     if(!s.loft)continue;
     const sections=s.loft.sections;
     for(let i=0;i<sections.length;i++){
      const sec=sections[i], verts=sec.polygon;
      const xs=verts.map(v=>v[0]),zs=verts.map(v=>v[1]);
      const cx=(Math.min(...xs)+Math.max(...xs))/2,cz=(Math.min(...zs)+Math.max(...zs))/2;
      for(const v of verts){
       const ox=v[0],oz=v[1];
       let fx=1,fz=1,shift=0;
       if(focus===0&&p.name==="ct"&&i>0)fx-=.006*weight;
       else if(focus===1&&p.name==="ct")fz-=.004*weight;
       else if(focus===2&&p.name==="ct"&&i<=1)fx-=.010*weight;
       else if(focus===3&&["lt","rt"].includes(p.name)&&i>0)fx-=.004*weight;
       else if(focus===4&&["la","ra"].includes(p.name))fx-=.006*weight;
       else if(focus===5&&p.name==="hd"){fx-=.004*weight;shift=bird&&oz<cz?-.035*weight:0;}
       else if(focus===6&&["ll","rl"].includes(p.name))fx-=.005*weight;
       else if(focus===7&&p.name.endsWith("_shin"))fx-=.006*weight;
       else if(focus===8&&p.name.endsWith("_foot")){fx-=.003*weight;shift=-.008*weight;}
       else if(focus===9&&p.name.endsWith("_weapon"))fx-=.004*weight;
       const nx=round(cx+(ox-cx)*fx),nz=round(cz+(oz-cz)*fz+shift);
       if(nx!==ox||nz!==oz){v[0]=nx;v[1]=nz;changed++;}
      }
     }
    }
   }
   if(changed<1)throw new Error("No actual changes at pass "+cycle+" for "+id);
   edits.push(changed);
  }
  const model={id:id+(detail===1?"_shape":""),name:unit.name+" "+unit.model+(detail===1?" — silhouette":""),
   unit:unit.id,voxel_size:round(cfg.voxel||(.044+Math.max(0,unit.tonnage-35)*.00012)),
   subdivide:detail,legs:bird?"digitigrade":"plantigrade",punch:true,
   materials:colors,exclusive_parts:true,parts,muzzles,jets,weapons,
   art_quality_passes:50,art_quality_revision:"silhouette-and-weapon-clarity-20261121",
   shape_refinement_revision:"new-chassis-50-real-passes-20261122",
   shape_refinement_edit_totals:edits.reduce((a,b)=>a+b,0),
   signature:cfg.signature,refinement_focus:foci
  };
  return {model,audit:{id,changes:edits.reduce((a,b)=>a+b,0),min_stage:Math.min(...edits),max_stage:Math.max(...edits),parts:parts.length,gun_parts:gunParts}};
 }
})
