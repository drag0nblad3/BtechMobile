// Independent reference-led provisional source assemblies.
function build(lib,base,row){
 const {L,B,cyl,loft,ellipse}=lib,p=row.profile,[id,name,pitch,legs,w,h,tw,fd,bd,top,th,sh,aw,fw]=p,s=base(lib,{profile:p,reference:row.ref}),P=n=>s.parts.find(x=>x.name===n),Y=(a,m="plate")=>L("y",a,m),Z=(a,m="plate")=>L("z",a,m);
 const part=(name,loc,parent,pivot,shapes)=>s.parts.push({name,loc,parent,pivot,shapes});
 const yr=(y,x,r,z,d,ch=.2)=>[y,x-r,x+r,z-d,z+d,ch];
 const armx=tw+5,sy=top-5,e=sy-8,gy=e-4;
 if(id==="solitaire")P("ct").shapes=[Y([[w+3,-5,5,-3,4,.1],[w+6,-5.8,5.8,-4,3.5,.28],[top-8,-tw,tw,-4.5,3.8,.28],[top-3,-tw,tw,-4,3,.22],[top,-5,5,-3,3,.2]],"armor")];
 if(id==="vulture_mk_iv"){P("hd").shapes=[Z([[-fd-10,-2.2,2.2,top-13,top-10,.22],[-fd-6,-4.2,4.2,top-13,top-7,.24],[-fd-2,-5.2,5.2,top-12,top-4,.2],[-fd+3,-5.4,5.4,top-10,top-3,.18]]),B([-2,top-12,-fd-10],[2,top-10,-fd-7],"glass","paint")]}
 if(id==="koshi_standard"){let y=top-6;P("hd").shapes=[loft("z",[[-fd-7,ellipse(0,y,2,2,20)],[-fd-5,ellipse(0,y,4,4,20)],[-fd-2,ellipse(0,y,5,5,20)],[-fd+2,ellipse(0,y,3.9,4,20)]],"plate"),B([-3,y-1,-fd-7],[3,y+2,-fd-4],"glass","paint")];}
 if(id==="hawkwolf_hwk4f")P("ct").shapes=[Y([[w+3,-5,5,-3,4,.1],[w+5,-5.6,5.6,-4,4,.2],[top-8,-tw,tw,-fd,bd,.12],[top-2,-tw,tw,-fd,bd,.18],[top,-5.8,5.8,-4,4,.2]],"armor")];
 if(id==="dominator")P("hd").shapes=[loft("y",[[top-1,ellipse(0,-1,3.7,3,16)],[top+1,ellipse(0,-1,4.2,3.6,16)],[top+3,ellipse(0,-1,3.8,3.3,16)],[top+5,ellipse(0,-1,2.4,2.5,16)]],"plate"),B([-2.4,top+1,-5],[2.4,top+3,-3],"glass","paint")];
 for(let [i,q] of ["l","r"].entries()){
  let k=i?1:-1,x=k*armx,loc=q.toUpperCase()+"A",tor=q.toUpperCase()+"T",count=row.arm[i];
  if(count>1){let cols=count===15?3:4,rows=Math.ceil(count/cols),rw=cols+1,ry=rows+1,front=id==="koshi_standard"?(i?-10:-17):id==="hawkwolf_hwk4f"?-14:-12,back=-Math.floor(aw*.8);let pts=Array.from({length:count},(_,j)=>[x+2*(j%cols-(cols-1)/2),gy+2*(Math.floor(j/cols)-(rows-1)/2),front]);P(q+"a_weapon").shapes=[Z([[front,x-rw,x+rw,gy-ry,gy+ry,.13],[front+3,x-rw,x+rw,gy-ry,gy+ry,.17],[back+1,x-aw*.78,x+aw*.78,gy-aw*.78,gy+aw*.78,.18]]),...pts.map(([a,b])=>cyl("z",front,front+3,a,b,.8,.8,"gun","subtract"))];s.muzzles[loc]=pts;}
  let n=row.torso[i];if(n){let cols=n===12?4:n===6?3:n===5?3:n===4?2:n,rows=Math.ceil(n/cols),xx=k*(tw-.7),yy=id==="vulture_mk_iv"?top-4:top-6,front=id==="vulture_mk_iv"?-fd-4:id==="dominator"&&i===1?-fd-10:-fd-3,back=-fd+3,rw=Math.max(2.3,cols+1),rh=Math.max(2.4,rows+1),pts=Array.from({length:n},(_,j)=>[xx+2*(j%cols-(cols-1)/2),yy+2*(Math.floor(j/cols)-(rows-1)/2),front]);part(q+"t_battery",tor,q+"t",[xx,yy,back],[Z([[front,xx-rw,xx+rw,yy-rh,yy+rh,.15],[front+3,xx-rw,xx+rw,yy-rh,yy+rh,.12],[back,xx-rw*.8,xx+rw*.8,yy-rh*.85,yy+rh*.85,.18]]),...pts.map(([a,b])=>cyl("z",front,front+3,a,b,n===1?1:.8,n===1?1:.8,"gun","subtract"))]);s.muzzles[tor]=pts;}
  if(id==="hellhound_conjurer"){let xx=k*2.4;part(q+"h_horn","HD","hd",[xx,top+3,0],[Y([[top+3,xx-1.4,xx+1.4,-1.5,1.4,.1],[top+6,xx-1.1,xx+1.1,-.8,1.4,.13],[top+9,xx+k*.5-.9,xx+k*.5+.9,-.3,1.5,.12]])]);}
  if(id==="koshi_standard"){let xx=k*4.8;part(q+"t_vent",tor,"ct",[xx,top-1,2],[Y([[top-2,xx-2.8,xx+2.8,1,5,.12],[top+3,xx-2.8,xx+2.8,1,5,.12],[top+6,xx-2.3,xx+2.3,2,5,.2]]),B([xx-1.8,top+1,1],[xx+1.8,top+4,2],"frame","paint")]);}
  if(id==="hawkwolf_hwk4f"){let n=q+"l_shin",px=k*(h+1.5),knee=Math.round(w*.56);P(n).shapes=[Y([yr(4,k*(h+2),sh*.7,0,sh*.7,.12),yr(7,px,sh*.88,-1,sh*.86,.22),yr(knee-3,px,sh*.92,-.6,sh*.8,.25),yr(knee,k*(h+1),th*.7,0,th*.7,.08)])];}
 }
 if(id==="solitaire"){part("hd_antenna","HD","hd",[1,top+3,0],[Y([[top+3,0,2,-.5,1.5,.05],[top+7,.5,2.5,0,2,.12]],"frame")]);}
 s.unit=id;s.reference=row.ref;s.notes="Independent source-cell study, no production mapping; not calibrated.";return s;
}
;build
