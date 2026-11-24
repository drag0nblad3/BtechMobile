function facetedResculpt(lib,F,source){
const s=lib.clone(source),P=n=>s.parts.find(p=>p.name===n),set=(n,shapes)=>P(n).shapes=shapes;
const A=(axis,rows,mat="plate")=>F.armor(axis,rows,mat),Z=(rows,mat="plate")=>F.poly("z",rows,mat),Y=(rows,mat="plate")=>F.poly("y",rows,mat),B=lib.B,C=lib.cyl;
const rect=(a,b,c,d)=>[[a,c],[b,c],[b,d],[a,d]],cut=(a,b,c,d,u,v)=>[[a,c],[b,c],[b,d-v],[b-u,d],[a+u,d],[a,d-v]];
const add=(name,loc,parent,pivot,shapes)=>s.parts.push({name,loc,parent,pivot,shapes});
const side=(n,shapes)=>{set("r"+n,shapes);set("l"+n,shapes.map(F.reflect))};
const shin=(x,y0,y1,z0,z1,w0,w1)=>Y([[y0,rect(x-w0,x+w0,z0-2,z0+2)],[y0+2,cut(x-w1,x+w1,z0-4,z0+3,1,1)],[y1-2,cut(x-w1,x+w1,z1-4,z1+3,1,2)],[y1,rect(x-w0,x+w0,z1-2,z1+2)]] .map(([t,p])=>[t,p.length===4?[p[0],p[1],p[2],p[2],p[3],p[3]]:p]));
if(s.id==="orion"){
 set("hd",[Z([[-10,rect(-4.5,4.5,35,40)],[-7,rect(-5.5,5.5,35,43)],[1,rect(-5.5,5.5,38,46)],[6,rect(-4,4,39,45)]],"plate"),F.prism("z",-10,-8,[[-3,38],[0,39.4],[3,38],[2.8,36.4],[0,35.8],[-2.8,36.4]],"glass","paint")]);
 set("ct",[A("y",[[27,-5,5,-4,4],[31,-6,6,-5,5],[33,-8,8,-6,6],[38,-8,8,-5,6],[39,-6,6,-4,6]],"armor")]);
 side("l_shin",[A("y",[[4,7,11,-2,2],[7,5.5,12.5,-3,3],[10,5,13,-4,3],[13,5,11,-3,3]],"plate"),F.prism("x",5,12,[[5,-3],[8,-5],[12,-4],[12,-3]],"plate")]);
 // Intentional square missile housing, not a chamfered capsule.
 let p=P("lt_rack"),pts=s.muzzles.LT;
 p.shapes=[A("z",[[-8,-16,-7,31,42],[-4,-16,-7,31,42],[4,-15,-7,33,42]],"plate"),...pts.map(([x,y,z])=>C("z",z,z+3,x,y,.8,.8,"gun","subtract"))];
}else if(s.id==="marauder_ii"){
 set("ct",[Z([[-10,cut(-7,7,30,37,3,2)],[-5,cut(-11,11,30,40,3,3)],[2,cut(-11,11,30,43,4,3)],[8,cut(-8,8,31,40,2,3)]],"armor"),A("y",[[28,-5,5,-3,4],[31,-7,7,-5,5]],"frame")]);
 set("hd",[Z([[-16,cut(-2.5,2.5,30,33,1,1)],[-12,cut(-4,4,30,36,1.4,1)],[-7,cut(-5,5,31,40,2,2)],[-3,cut(-5,5,32,41,2,2)]],"plate"),B([-3,33,-12],[3,35,-9],"glass","paint")]);
 for(const k of [-1,1]){let q=k<0?"l":"r",x=k*9;add(q+"t_swept_fin",q.toUpperCase()+"T","ct",[x,39,2],[F.prism("x",Math.min(k*7,k*13),Math.max(k*7,k*13),[[36,-2],[40,-1],[44,3],[40,8],[37,6]],"plate")]);}
 side("a_weapon",[A("z",[[-19,13,19,21,29],[-13,12,20,21,29],[-3,13,19,22,28]],"plate"),C("z",-21,-17,16,26,2,2),C("z",-21,-17,16,26,1,1,"gun","subtract"),C("z",-20,-16,16,23,1.6,1.6),C("z",-20,-16,16,23,.85,.85,"gun","subtract")]);s.muzzles.RA=[[16,26,-21],[16,23,-20]];s.muzzles.LA=[[-16,26,-21],[-16,23,-20]];
 side("l_shin",[A("y",[[8,8,14,-2,3],[10,7,15,-1,6],[14,7,13,3,9]],"plate")]);
}else if(s.id==="nightstar"){
 set("ct",[Z([[-16,cut(-5,5,31,35,2,1)],[-10,cut(-11,11,30,37,3,2)],[-3,cut(-13,13,31,40,3,2)],[4,cut(-13,13,32,42,3,2)],[10,cut(-10,10,33,40,2,1)]],"armor"),A("y",[[27,-5,5,-3,4],[31,-8,8,-3,5]],"frame")]);
 set("hd",[Z([[-18,rect(-2.5,2.5,30,34)],[-15,rect(-4.5,4.5,30,35)],[-11,rect(-5,5,31,36)],[-8,rect(-5,5,31,36)]],"plate"),B([-2,31,-18],[2,33,-17],"glass","paint")]);
 side("a_weapon",[A("z",[[-16,14,20,19,28],[-9,12,22,20,29],[-3,14,20,21,27]],"plate"),C("z",-23,-12,17,25,2.6,2.6),C("z",-23,-19,17,25,1.25,1.25,"gun","subtract"),A("z",[[-24,15,19,19,22],[-12,14,20,19,23]],"gun"),C("z",-24,-20,17,20.5,.9,.9,"gun","subtract")]);s.muzzles.LA=[[-17,25,-23],[-17,20.5,-24]];s.muzzles.RA=[[17,25,-23],[17,20.5,-24]];
 side("l_shin",[A("y",[[8,8,14,-2,3],[10,6,16,-2,5],[13,7,13,3,9]],"plate")]);
}else if(s.id==="kit_fox"){
 set("ct",[A("y",[[25,-4,4,-3,4],[28,-5,5,-4,5],[32,-6,6,-4,5],[35,-5,5,-3,4]],"armor")]);
 set("hd",[Z([[-13,rect(-2,2,26,29)],[-10,rect(-3.6,3.6,25,31)],[-6,rect(-4,4,26,34)],[-2,rect(-4,4,28,34)]],"plate"),B([-2,28,-13],[2,30,-11],"glass","paint")]);
 for(let k of [-1,1]){let q=k<0?"l":"r",x=k*3.8;add(q+"t_vent",q.toUpperCase()+"T","ct",[x,34,0],[A("z",[[-4,x-1.6,x+1.6,33,38],[3,x-1.6,x+1.6,33,38]],"plate"),...Array.from({length:3},(_,i)=>B([x-1,34+i,-4],[x+1,34.5+i,-2],"gun","subtract"))]);}
 let pts=[[-13,20,-8],[-11,20,-8],[-13,22,-8],[-11,22,-8]];
 set("la_weapon",[A("z",[[-8,-15,-9,18,24],[-2,-15,-9,18,24]],"plate"),C("z",-16,-6,-12,18.5,1.9,1.9),C("z",-16,-12,-12,18.5,.85,.85,"gun","subtract"),...pts.map(([x,y,z])=>C("z",z,z+3,x,y,.7,.7,"gun","subtract"))]);s.muzzles.LA=[[-12,18.5,-16],...pts];
 side("l_shin",[A("y",[[8,6,10,-2,2],[10,5,11,-2,4],[12,5,9,3,7]],"plate")]);
}else if(s.id==="ebon_jaguar"){
 set("ct",[Z([[-9,cut(-6,6,29,35,1,2)],[-3,cut(-9,9,28,38,2,2)],[3,cut(-9,9,28,39,2,2)],[7,cut(-7,7,30,37,2,1)]],"armor"),A("y",[[27,-5,5,-3,4],[30,-7,7,-4,5]],"frame")]);
 set("hd",[Z([[-20,rect(-2,2,27,32)],[-16,rect(-3.3,3.3,28,35)],[-10,rect(-4.5,4.5,30,38)],[-4,rect(-5,5,31,39)]],"plate"),F.prism("z",-17,-12,[[-2.5,33],[0,34],[2.5,33],[2,32],[0,32.5],[-2,32]],"glass","paint")]);
 const pts=Array.from({length:12},(_,i)=>[5+(i%3-1)*1.7,41+(Math.floor(i/3)-1.5)*1.7,-8]);
 add("rt_rack","RT","ct",[5,38,0],[A("z",[[-8,2,8,37,45],[-3,2,8,37,45],[4,2.5,7.5,37,43]],"plate"),...pts.map(([x,y,z])=>C("z",z,z+3,x,y,.7,.7,"gun","subtract"))]);s.muzzles.RT=pts;
 add("lt_dorsal_dual","LT","ct",[-5,38,0],[A("z",[[-8,-8,-2,37,43],[4,-8,-2,37,42]],"plate"),...[-6.5,-3.5].flatMap(x=>[C("z",-10,-6,x,40,1.35,1.35),C("z",-10,-7,x,40,.75,.75,"gun","subtract")])]);s.muzzles.LT=[[-6.5,40,-10],[-3.5,40,-10]];
 side("a_weapon",[A("z",[[-13,11,17,20,26],[-3,10,18,20,27]],"plate"),C("z",-19,-11,14,23,1.9,1.9),C("z",-19,-15,14,23,.9,.9,"gun","subtract")]);s.muzzles.LA=[[-14,23,-19]];s.muzzles.RA=[[14,23,-19]];
}
return s;
}
;facetedResculpt