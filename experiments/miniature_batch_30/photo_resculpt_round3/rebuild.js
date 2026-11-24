// Major anatomy alternatives from inspected miniature photographs. The original joint pivots
// remain fixed so the frozen-camera comparisons do not silently move landmarks.
function rebuild(lib,source,v){
 const s=lib.clone(source),{L,B,cyl,loft,ellipse}=lib,P=n=>s.parts.find(p=>p.name===n),Y=(a,m="plate")=>L("y",a,m),Z=(a,m="plate")=>L("z",a,m),X=(a,m="plate")=>L("x",a,m);
 const set=(n,shapes)=>P(n).shapes=shapes;
 function limb(q,rows){let p=P(q);if(p)p.shapes=[Y(rows,"armor")]}
 function pod(q,x,y,z,n,rx,ry,cols=2,step=2.1,back=-2){
 let pts=Array.from({length:n},(_,i)=>[x+(i%cols-(cols-1)/2)*step,y+(Math.floor(i/cols)-(Math.ceil(n/cols)-1)/2)*step,z]);
 set(q+"a_weapon",[Z([[z,x-rx,x+rx,y-ry,y+ry,.18],[z+4,x-rx-.4,x+rx+.4,y-ry-.4,y+ry+.4,.15],[back,x-rx*.8,x+rx*.8,y-ry*.75,y+ry*.75,.16]],"plate"),...pts.map(([a,b,c])=>cyl("z",c,c+3,a,b,.78,.78,"gun","subtract"))]);s.muzzles[q.toUpperCase()+"A"]=pts;
 }
 function shoulder(q,x,y,r,span){let a=x-span,b=x+span;set(q+"a",[loft("x",[[a,ellipse(y,0,r*.88,r*.95,16)],[a+1,ellipse(y,0,r,r,16)],[b-1,ellipse(y,0,r,r,16)],[b,ellipse(y,0,r*.86,r*.9,16)]],"plate"),Y([[y-8,x-2,x+2,-2,2,.12],[y-3,x-2.5,x+2.5,-2.5,2.5,.15],[y,x-2.4,x+2.4,-2.5,2.5,.12]],"frame")]);}
 function visor(z,r,y,depth){return [Z([[z,-r*.5,r*.5,y-3,y+1,.22],[z+3,-r,r,y-4,y+3,.25],[z+depth,-r*.9,r*.9,y-3,y+5,.18]],"plate"),B([-r*.48,y-1,z+1],[r*.48,y+2,z+4],"glass","paint")];}
 if(s.id==="nova"){
 const w=v===1?9:10;
 set("ct",[Y([[25,-5,5,-3,4,.1],[28,-w,w,-4,5,.18],[34,-w,w,-7,7,.12],[38,-w,w,-6,6,.18],[40,-w*.8,w*.8,-4,5,.18]],"armor")]);set("hd",visor(-16,4.5,31,9));
 for(let k of [-1,1]){let q=k<0?"l":"r",x=k*15;shoulder(q,x,34,4.8,2.6);
 pod(q,x,21,-11,6,4.3,5.0,2,2.5);
 let l=k*8;limb(q+"l_shin",[[8,l-2.4,l+2.4,-2,2.5,.14],[11,l-3.2,l+3.2,0,5,.18],[12,l-3,l+3,3,9,.16]]);
 limb(q+"l_tarsus",[[4,k*9-2.5,k*9+2.5,-3,2.5,.15],[6,k*9-3.2,k*9+3.2,-3,3,.18],[8,l-2.4,l+2.4,-2,2.5,.14]]);
 }}
 else if(s.id==="nightstar"){
 const w=v===1?12:13;
 set("ct",[Z([[-13,-5,5,33,38,.23],[-9,-w*.8,w*.8,31,42,.25],[-2,-w,w,30,43,.23],[7,-w,w,31,43,.23],[13,-w*.7,w*.7,34,41,.25]],"armor"),Y([[27,-5,5,-3,4,.1],[31,-7,7,-4,5,.15]],"frame")]);
 set("hd",visor(-17,4.2,34,8));
 for(let k of [-1,1]){let q=k<0?"l":"r",x=k*17;shoulder(q,x,36,4.5,2.8);
 pod(q,x,25,-20,2,4.1,3.4,1,3.0,-1);
 let l=k*11;limb(q+"l_shin",[[8,l-3,l+3,-4,3,.15],[11,l-4,l+4,-1,5,.18],[13,k*10-3.4,k*10+3.4,3,9,.16]]);
 limb(q+"l_tarsus",[[4,l-3.2,l+3.2,-3,2.5,.14],[8,l-3,l+3,-4,3,.14]]);}
 }
 else if(s.id==="marauder_ii"){
 const w=v===1?10:12;
 set("ct",[Z([[-14,-4,4,34,38,.25],[-8,-w+2,w-2,31,41,.2],[0,-w,w,31,43,.22],[8,-w,w,33,44,.22],[13,-w+2,w-2,35,42,.2]],"armor"),Y([[28,-5,5,-3,4,.1],[32,-7,7,-4,5,.15]],"frame")]);
 set("hd",visor(-17,4.3,35,10));
 for(let k of [-1,1]){let q=k<0?"l":"r",x=k*16;shoulder(q,x,37,3.7,2.4);pod(q,x,25,-14,2,3.5,4.0,1,3,-2);
 let l=k*11;limb(q+"l_shin",[[8,l-3,l+3,-3,2,.15],[11,l-3.5,l+3.5,0,5,.15],[14,k*10-3.2,k*10+3.2,3,9,.14]]);
 }}
 else if(s.id==="fire_moth"){
 const w=v===1?5:6;
 set("ct",[Y([[29,-4,4,-3,4,.12],[31,-w,w,-4,4,.2],[35,-w,w,-5,4,.18],[39,-w*.85,w*.85,-2,4,.2]],"armor")]);set("hd",visor(-10,2.7,34,6));
 // Raised arm pods remain above shoulders; shorten extreme forward projection.
 for(let k of [-1,1]){let q=k<0?"l":"r",x=k*11;
 set(q+"a",[X([[Math.min(k*7,k*11),37,43,-3,3,.12],[Math.max(k*7,k*11),37,43,-3,3,.12]],"frame")]);
 set(q+"a_forearm",[Z([[-7,x-2,x+2,38,42,.12],[-2,x-2,x+2,38,42,.12],[1,x-2,x+2,38,42,.12]],"frame")]);
 pod(q,x,40,-13,q==="l"?2:6,q==="l"?2.9:3.8,3.1,2,2.1,-5);
 let l=k*5;limb(q+"l_shin",[[4,k*6-1.8,k*6+1.8,-2,2,.14],[8,l-2.6,l+2.6,-2,2.8,.16],[12,l-2.3,l+2.3,-2.3,2.3,.14],[15,l-2.3,l+2.3,-2.3,2.3,.14]]);
 }}
 else if(s.id==="timber_wolf"){
 let w=v===1?9:10;set("ct",[Z([[-11,-5,5,28,35,.24],[-6,-w,w,27,39,.22],[4,-w,w,27,40,.22],[10,-w+2,w-2,29,38,.22]],"armor"),Y([[26,-5,5,-3,4,.12],[29,-7,7,-4,5,.15]],"frame")]);
 set("hd",[loft("z",[[-20,ellipse(0,32,3.5,3,20)],[-16,ellipse(0,32,5.5,4.8,20)],[-11,ellipse(0,32,6,5.8,20)],[-7,ellipse(0,32,5.5,5.5,20)]],"plate"),B([-3,32,-20],[3,35,-16],"glass","paint")]);
 for(let k of [-1,1]){let q=k<0?"l":"r",x=k*14;pod(q,x,22,-11,2,3.5,4.2,1,3,-2);
 let t=k*8.0,y=43,z=-9,pts=Array.from({length:20},(_,i)=>[t+(i%4-1.5)*2,y+(Math.floor(i/4)-2)*2,z]);
 set(q+"t_rack",[B([t-2,35,-2],[t+2,42,4],"frame"),Z([[z,t-4.7,t+4.7,y-5.6,y+5.6,.08],[2,t-4.7,t+4.7,y-5.6,y+5.6,.1],[5,t-4.2,t+4.2,y-5.2,y+5.2,.12]],"plate"),...pts.map(([a,b,c])=>cyl("z",c,c+3,a,b,.76,.76,"gun","subtract"))]);s.muzzles[q.toUpperCase()+"T"]=pts;
 let l=k*10;limb(q+"l_shin",[[8,l-2.6,l+2.6,-2,2.5,.15],[10,l-3.6,l+3.6,-1,4,.25],[12,k*9-3.5,k*9+3.5,2,8,.2],[13,k*9-3.2,k*9+3.2,3,9,.14]]);
 }}
 else if(s.id==="longbow"){
 let w=v===1?9:10;set("ct",[Z([[-9,-5,5,29,35,.2],[-4,-w,w,27,38,.22],[4,-w,w,27,39,.2],[9,-w*.8,w*.8,29,37,.22]],"armor"),Y([[25,-5,5,-3,4,.1],[28,-7,7,-4,5,.15]],"frame")]);set("hd",visor(-13,3,31,8));
 for(let k of [-1,1]){let q=k<0?"l":"r",x=k*15;pod(q,x,22,-9,20,5.6,6,4,2.1,8);
 // Rear flared missile drum; not an elongated barrel.
 let t=k*7,y=41,z=-5,pts=Array.from({length:5},(_,i)=>[t+(i%3-1)*1.8,y+(Math.floor(i/3)-.5)*2,z]);
 set(q+"t_rack",[B([t-1.8,35,0],[t+1.8,42,4],"frame"),cyl("z",z,8,t,y,3.6,3.6,"plate"),...pts.map(([a,b,c])=>cyl("z",c,c+3,a,b,.65,.65,"gun","subtract"))]);s.muzzles[q.toUpperCase()+"T"]=pts;
 }}
 return s;
}
;rebuild