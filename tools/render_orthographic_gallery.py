#!/usr/bin/env python3
"""Rasterize editable shape primitives into side/top/rear voxel projections.
The source is actual geometry, not a painted approximation or image generator.
The 2D projections are coarse authoring grids and exclude fine subdivision.
"""
import json, math, subprocess, sys
from pathlib import Path
from PIL import Image,ImageDraw,ImageFont

ROOT=Path(__file__).resolve().parents[1]
NAMES=['atlas','jenner','wolverine','raven','shadow_cat','timber_wolf','rifleman','king_crab']


def polygon_mask(poly):
    if len(poly)<3:return []
    a=math.floor(min(p[0] for p in poly));b=math.ceil(max(p[0] for p in poly));c=math.floor(min(p[1] for p in poly));d=math.ceil(max(p[1] for p in poly))
    for x in range(a,b):
        for y in range(c,d):
            qx,qy=x+.5,y+.5;inside=False
            for i in range(len(poly)):
                xa,ya=poly[i];xb,yb=poly[i-1]
                if (ya>qy)!=(yb>qy) and qx<(xb-xa)*(qy-ya)/(yb-ya)+xa:inside=not inside
            if inside:yield x,y


def shape_cells(shape):
    if 'erase' in shape or 'box' in shape or 'shell' in shape:
        typ='erase' if 'erase' in shape else 'box' if 'box' in shape else 'shell'
        lo,hi=shape[typ]
        return {(x,y,z) for x in range(math.floor(lo[0]),math.ceil(hi[0])+1)
                         for y in range(math.floor(lo[1]),math.ceil(hi[1])+1)
                         for z in range(math.floor(lo[2]),math.ceil(hi[2])+1)}
    if 'loft' not in shape:return set()
    loft=shape['loft'];axis=loft.get('axis','y');secs=loft['sections'];cells=set()
    for s,t in zip(secs,secs[1:]):
        aa=int(s['at']);bb=int(t['at']);p=s['polygon'];q=t['polygon']
        if len(p)!=len(q):continue
        for layer in range(aa,bb+1):
            ratio=(layer-aa)/max(1,bb-aa)
            vertices=[(p[i][0]*(1-ratio)+q[i][0]*ratio,p[i][1]*(1-ratio)+q[i][1]*ratio) for i in range(len(p))]
            for x,y in polygon_mask(vertices):
                cells.add((x,layer,y) if axis=='y' else (x,y,layer))
    if shape.get('hollow'):
        return {c for c in cells if any((c[0]+dx,c[1]+dy,c[2]+dz) not in cells for dx,dy,dz in ((1,0,0),(-1,0,0),(0,1,0),(0,-1,0),(0,0,1),(0,0,-1)))}
    return cells


def model_cells(d):
    parts={};cmap={}
    for part in d['parts']:
        name=part['name']
        if 'mirror' in part:
            original=parts.get(part['mirror'],{})
            cells={(-c[0]-1,c[1],c[2]):v for c,v in original.items()}
        else:
            cells={}
            for sh in part.get('shapes',[]):
                new=shape_cells(sh)
                if 'erase' in sh:
                    for c in new:cells.pop(c,None)
                else:
                    for c in new:cells[c]=sh.get('mat','armor')
        for sh in part.get('add',[]):
            new=shape_cells(sh)
            if 'erase' in sh:
                for c in new:cells.pop(c,None)
            else:
                for c in new:cells[c]=sh.get('mat','armor')
        parts[name]=cells
        # Independent part colors matter more than source paint for silhouette depth.
        cmap.update(cells)
    return cmap


def font(n):
    try:return ImageFont.truetype('/usr/share/fonts/truetype/dejavu/DejaVuSans.ttf',n)
    except:return ImageFont.load_default()


def projection(cells,view):
    # Draw the frontmost cell at each 2D position, retaining material distinctions.
    out={}
    for (x,y,z),mat in cells.items():
        if view=='SIDE':u,v,depth=-z,y,x
        elif view=='TOP':u,v,depth=x,-z,y
        else:u,v,depth=-x,y,z
        key=(u,v)
        if key not in out or depth>out[key][0]:out[key]=(depth,mat)
    return out


def paste_model(dst,model,view,xy,area=(145,150)):
    matcolor={'gun':'#475765','recess':'#333e46','glass':'#8db7c1','trim':'#a59b7e','frame':'#5c696d',
              'armor':'#7f8d95','plate':'#a2aab0','joint':'#535f68','edge':'#c7c5b8','inside':'#52636b',
              'form':'#7c878b','glow':'#b8c9cf'}
    proj=projection(model,view)
    if not proj:return
    mnx=min(k[0] for k in proj);mxx=max(k[0] for k in proj);mny=min(k[1] for k in proj);mxy=max(k[1] for k in proj)
    cell=min((area[0]-16)/max(1,(mxx-mnx+1)),(area[1]-16)/max(1,(mxy-mny+1)))
    x0,y0=xy;xpad=(area[0]-(mxx-mnx+1)*cell)/2;ypad=(area[1]-(mxy-mny+1)*cell)/2
    draw=ImageDraw.Draw(dst)
    for (u,v),(depth,mat) in proj.items():
        xx=x0+xpad+(u-mnx)*cell; yy=y0+ypad+(mxy-v)*cell
        fill=matcolor.get(mat,'#88959a')
        draw.rectangle((int(xx),int(yy),int(xx+cell+.3),int(yy+cell+.3)),fill=fill)


def get_before(path):
    # In CI the first parent of the bot commit is the pre-refinement sources.
    # On local fixtures, pass their directory as a path via --local-before.
    local=None
    if '--local-before' in sys.argv:
        local=Path(sys.argv[sys.argv.index('--local-before')+1])
    if local is not None:return json.loads((local/path.name).read_text())
    before_ref='HEAD~1'
    if '--before-ref' in sys.argv: before_ref=sys.argv[sys.argv.index('--before-ref')+1]
    raw=subprocess.check_output(['git','show',f'{before_ref}:{path.as_posix()}'],cwd=ROOT)
    return json.loads(raw)


def main():
    canvas=Image.new('RGB',(1830,1680),'#161c21')
    draw=ImageDraw.Draw(canvas)
    f=font(18);small=font(15)
    draw.text((35,18),'BATTLETECH / 50 ORTHOGRAPHIC VIEW PASSES',font=font(29),fill='#e2e8ec')
    draw.text((35,64),'Actual coarse voxel projections  |  BEFORE / AFTER  |  SIDE, TOP, REAR',font=f,fill='#a7b9c5')
    # Two model columns; each column has 3 view pairs across 900 px.
    for idx,name in enumerate(NAMES):
        col=idx%2;row=idx//2; left=25+col*907;top=102+row*390
        p=Path('data/voxels')/(name+'_shape.json')
        pre=get_before(p);post=json.loads((ROOT/p).read_text())
        a=model_cells(pre);b=model_cells(post)
        draw.rounded_rectangle((left,top,left+885,top+377),radius=9,fill='#202830',outline='#36434e',width=2)
        draw.text((left+16,top+9),name.replace('_',' ').upper(),font=font(22),fill='#ffffff')
        for vi,view in enumerate(('SIDE','TOP','REAR')):
            draw.text((left+33+vi*289,top+42),view,font=small,fill='#b9c7d0')
            paste_model(canvas,a,view,(left+15+vi*289,top+66),(134,234))
            paste_model(canvas,b,view,(left+151+vi*289,top+66),(134,234))
            draw.text((left+47+vi*289,top+309),'BEFORE',font=small,fill='#8197a4')
            draw.text((left+176+vi*289,top+309),'AFTER',font=small,fill='#c8d8e0')
        draw.text((left+16,top+345),f'coarse occupied cells: {len(a):,} → {len(b):,}',font=small,fill='#91a7b5')
    path=ROOT/'orthographic_before_after_50.png';canvas.save(path,optimize=True)
    print(path,path.stat().st_size)

if __name__=='__main__':main()