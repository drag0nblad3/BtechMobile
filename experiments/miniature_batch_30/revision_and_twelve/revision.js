function revised(lib,author,repair,id,variant){
 const {B,L,cyl,ellipse,loft}=lib,{spec,anchors}=author(lib,id);
 const p=n=>spec.parts.find(x=>x.name===n),Y=(r,m)=>L("y",r,m),Z=(r,m)=>L("z",r,m),X=(r,m)=>L("x",r,m);
 function shift(n,delta){let a=p(n);for(let s of a.shapes){const ax={x:[0,1,2],y:[1,0,2],z:[2,0,1]}[s.axis];for(let q of s.sections){q.at+=delta[ax[0]];for(let xy of q.polygon){xy[0]+=delta[ax[1]];xy[1]+=delta[ax[2]]}}}a.pivot=a.pivot.map((x,i)=>x+delta[i])}
 function mirror(sh){let a=lib.clone(sh);if(a.axis==="x"){a.sections=a.sections.map(s=>({...s,at:-s.at})).reverse()}else for(let q of a.sections)for(let xy of q.polygon)xy[0]*=-1;return a}
 function sym(n,sh){p("r"+n).shapes=sh;p("l"+n).shapes=sh.map(mirror)}
 function add(name,loc,parent,pivot,shapes,joint){let part={name,loc,parent,pivot,shapes};if(joint)part.joint=joint;spec.parts.push(part)}
 if(id==="marauder"){
 // Distinct long wedge: low forward glacis, stepped broad aft shoulder, visible hip clearance.
 p("ct").shapes=[Z([[-9,-5,5,28,34,.15],[-5,-7,7,27,37,.18],[0,-9,9,27,40,.16],[6,-9,9,29,42,.18],[12,-6,6,32,40,.2]],"armor")];
 p("hd").shapes=[Z([[-23,-3,3,26,29,.21],[-20,-4.8,4.8,25,31,.23],[-16,-6,6,26,33,.19],[-11,-6.5,6.5,28,35,.15],[-9,-5,5,28,34,.12]],"armor"),B([-2.5,28,-23],[2.5,30,-20],"glass","paint")];
 sym("t",[X([[8,31,39,-2,7,.1],[11,31,41,-2,8,.15],[13,31,39,-1,7,.1]],"plate")]);
 // Independently layered arm gun jackets, distinct actual openings.
 sym("a_ppc",[Z([[-22,13,19,18,24,.23],[-19,12,20,17,25,.18],[-13,12,20,17,25,.14],[-8,13,19,18,25,.14],[-5,13,19,19,24,.1]],"armor"),cyl("z",-22,-18,16,22,1.5,1.5,"gun","subtract"),cyl("z",-22,-18,16,19,1,1,"gun","subtract"),B([13,23,-14],[19,25,-10],"plate","paint")]);
 p("rt_cannon").shapes=[Y([[41,-1,5,0,6,.1],[45,-1,5,0,6,.13]],"frame"),Z([[-4,0,4,45,49,.13],[3,-1,5,45,50,.14],[10,-1,5,44,49,.14],[13,0,4,45,48,.13]],"plate"),cyl("z",-24,-4,2,47,1.6,1.6,"gun"),cyl("z",-24,-20,2,47,.85,.85,"gun","subtract")];p("rt_cannon").pivot=[2,41,3];
 spec.muzzles={LA:[[-16,22,-22],[-16,19,-22]],RA:[[16,22,-22],[16,19,-22]],RT:[2,47,-24]};
 sym("l_shin",[Y([[6,6,13,-1,4,.1],[9,6,13,0,7,.13],[12,5,12,4,11,.2],[14,5,10,6,11,.08]],"armor")]);
 for(let sign of [-1,1]){let s=sign<0?"l":"r";let sh=Z([[10,6,11,8,12,.1],[12,6,11,8,12,.14],[13,7,10,9,11,.1]],"plate");add(s+"l_calf",s.toUpperCase()+"L",s+"l_shin",[sign*8,11,10],sign<0?[mirror(sh)]:[sh])}
 if(variant===1){p("ct").shapes[0].sections[2].polygon.forEach(x=>x[1]=27+(x[1]-27)*.88);p("hd").shapes[0].sections[1].polygon.forEach(x=>x[0]*=.88)}
 }
 if(id==="firestarter"){
 // Firestarter has split chest armor, small angular helmet with visor and mast, tall shoulder pads.
 p("ct").shapes=[Y([[27,-3.5,3.5,-3,3,.14],[30,-4.5,4.5,-4,3,.12],[35,-6.5,6.5,-5,4,.18],[40,-6,6,-4,3,.16],[42,-4,4,-3,3,.15]],"armor")];
 p("ct_breast").shapes=[Z([[-8,-4,4,30,37,.24],[-6,-6,6,29,40,.18],[-3,-5,5,30,40,.15]],"plate")];
 p("hd").shapes=[loft("y",[[42,ellipse(0,-1,3.2,3.2,16)],[44,ellipse(0,-1,4.2,4,16)],[46,ellipse(0,0,4,3.8,16)],[47.5,ellipse(0,0,2.4,2.4,16)]],"plate"),B([-3,43,-5],[3,45,-3],"glass","paint")];
 add("hd_antenna","HD","hd",[-2,46,1],[Y([[46,-3,-1,0,2,.05],[50,-3,-1,0,2,.08],[52,-2.7,-1.3,0,1.5,.08]],"frame")]);
 sym("a",[X([[9,35,42,-2.5,3,.15],[11,34,44,-3,3,.16],[14,34,43,-3,3,.2],[16,35,41,-2,2,.15]],"plate"),Y([[32,10.5,13.5,-2,2,.1],[36,10.5,13.5,-2,2,.1]],"frame")]);
 sym("a_upper",[Y([[30,10.3,13.7,-1.8,1.8,.1],[32,10.5,13.5,-2,2,.08]],"frame")]);
 sym("a_forearm",[Y([[22,9.7,14.3,-3,2,.14],[25,9.3,14.7,-3,3,.18],[30,10.3,13.7,-1.8,1.8,.1]],"armor")]);
 for(let s of ["l","r"]){let sign=s==="r"?1:-1,x=12*sign;
 p(s+"a_flamers").shapes=[Z([[-14,x-3,x+3,21,25,.18],[-10,x-3,x+3,21,26,.17],[-3,x-2.5,x+2.5,22,26,.1]],"plate"),...[-1.5,1.5].map(dx=>cyl("z",-14,-11,x+dx,23,.85,.85,"gun","subtract"))];spec.muzzles[s.toUpperCase()+"A"]=[[-1.5,1.5].map(dx=>[x+dx,23,-14])].flat();
 let side=Z([[-6,2,5,33,37,.12],[-4,1,6,32,38,.12],[-3,1,5,32,38,.14]],"plate");add(s+"t_front","CT","ct_breast",[sign*3,35,-5],s==="l"?[mirror(side)]:[side]);
 }
 if(variant===1){for(let s of ["l","r"])p(s+"a").shapes[0].sections[1].polygon.forEach(x=>x[0]-=.6)}
 }
 if(id==="thunderbolt"){
 // Reference rack sits right, offset cockpit is sunk at front left of broad sloped chest.
 const rack=p("lt_rack");rack.name="rt_rack";rack.loc="RT";rack.pivot[0]*=-1;rack.shapes=rack.shapes.map(mirror);spec.muzzles.RT=spec.muzzles.LT.map(v=>[-v[0],v[1],v[2]]);delete spec.muzzles.LT;
 p("hd").shapes=p("hd").shapes.map(mirror);p("hd").pivot[0]*=-1;anchors.head[0]*=-1;anchors.top[0]*=-1;
 p("ct").shapes=[Y([[26,-5.5,5.5,-4,4,.14],[30,-9,9,-8,6,.16],[36,-10,10,-7,7,.13],[40,-8,8,-5,6,.18],[41,-6,6,-3,4,.13]],"armor")];
 p("ct_breast").shapes=[Z([[-11,-7,7,29,34,.2],[-9,-9,9,29,36,.15],[-6,-9,9,30,39,.15],[-3,-7,7,31,39,.14]],"plate")];
 p("hd").shapes=[Z([[-10,-8,-3,37,40,.2],[-7,-8,-2,37,43,.13],[-3,-8,-2,38,44,.17],[-1,-7,-3,39,44,.14]],"plate"),B([-7,39,-10],[-4,41,-7],"glass","paint")];p("hd").parent="ct_breast";p("hd").pivot=[-5,39,-5];
 p("ct_srm").parent="ct_breast";shift("ct_srm",[0,0,-5]);spec.muzzles.CT=spec.muzzles.CT.map(v=>[v[0],v[1],v[2]-5]);
 sym("a",[X([[13,34,42,-4,4,.1],[15,32,44,-5,5,.11],[19,33,43,-4,5,.15],[20,34,41,-3,3,.16]],"armor"),Y([[31,13.7,18.3,-3,3,.1],[35,13.7,18.3,-3,3,.08]],"frame")]);
 sym("a_upper",[Y([[29,13.7,18.3,-2.6,2.6,.1],[31,13.7,18.3,-3,3,.08]],"armor")]);
 for(let s of ["l","r"]){let sh=X([[20,34,41,-3,3,.08],[21.5,33,42,-4,4,.18],[22,35,40,-3,3,.15]],"plate");add(s+"a_shield",s.toUpperCase()+"A",s+"a",[(s==="l"?-1:1)*20,38,0],s==="l"?[mirror(sh)]:[sh])}
 if(variant===1){p("ct_breast").shapes[0].sections[1].polygon.forEach(q=>q[1]-=.6)}
 }
 return { ...repair(lib,spec),anchors};
}
;revised
