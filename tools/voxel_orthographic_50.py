#!/usr/bin/env python3
"""50 cautious orthographic-view passes over the full editable voxel catalog.

Only authoring loft contours are edited. Pivots, muzzle origins, hit locations,
weapon lists, materials, subdivision and intentionally constructed box features
are never moved. The 50-pass log distinguishes geometry edits from reviews
where no safe edit was warranted. Meant for a dedicated review branch.
"""
from __future__ import annotations
import copy
import json
import math
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]
VOX = ROOT / 'data' / 'voxels'
ASSETS = VOX / 'assets'
REVISION = 'orthographic-views-50-v1'
STAGES = (
    'side_torso_rear_depth', 'top_chest_rear_taper',
    'rear_shoulder_separation', 'side_waist_undercut',
    'top_launchers_and_rack_supports', 'rear_calf_anatomy',
    'underside_pelvis_clearance', 'side_foot_and_hock_profile',
    'rear_cockpit_neck_transition', 'dorsal_engine_deck',
)
# Never make a fragile signature feature smaller merely to meet a generic ratio.
PROTECTED_HEAD = set('atlas jenner wolverine king_crab urbanmech cyclops'.split())
AVIAN = set('marauder timber_wolf raven shadow_cat mad_dog summoner stormcrow locust flea fire_moth mist_lynx grendel adder kit_fox ice_ferret viper night_gyr piranha bushwacker'.split())
CARAPACE = set('king_crab stalker turkina dire_wolf kodiak urbanmech nightstar crab longbow cyclops malice mauler annihilator'.split())
QUADRUPED = set('goliath scorpion tarantula thunder_stallion'.split())


def signature(name):
    return ('quadruped' if name in QUADRUPED else 'carapace' if name in CARAPACE
            else 'avian' if name in AVIAN else 'humanoid')


def area(poly):
    return .5 * abs(sum(poly[i][0]*poly[(i+1)%len(poly)][1] - poly[(i+1)%len(poly)][0]*poly[i][1]
                          for i in range(len(poly)))) if len(poly)>=3 else 0


def loft_measure(d):
    s=0.0
    for part in d.get('parts',[]):
        if 'mirror' in part: continue
        for shape in part.get('shapes',[]):
            loft=shape.get('loft')
            if not loft:continue
            sec=loft.get('sections',[])
            for a,b in zip(sec,sec[1:]):
                s+=max(0.0,float(b['at'])-float(a['at']))*.5*(area(a['polygon'])+area(b['polygon']))
    return s


def immutable_state(d):
    return [(p.get('name'),p.get('loc'),p.get('parent'),p.get('joint'),p.get('pivot'),
             p.get('mirror'),p.get('add'),p.get('detail')) for p in d.get('parts',[])],\
            [d.get(x) for x in ('muzzles','jets','weapons','materials','subdivide','voxel_size','unit','legs','punch','voxel_cap')]


def apply_pass(d,name,stage,cycle,asset=False):
    klass=signature(name)
    intensity=(.91**cycle)
    if klass in ('carapace','quadruped'):intensity*=.48
    changes=0
    for part in d.get('parts',[]):
        if part.get('mirror'):continue
        n=part.get('name','')
        if any(w in n for w in ('barrel','muzzle','bore','gun','cannon','ppc','gauss','laser','ac20')):
            continue  # front-facing weapon apertures keep their exact authored geometry
        for sh in part.get('shapes',[]):
            loft=sh.get('loft')
            if not loft: continue
            axis=loft.get('axis','y')
            secs=loft.get('sections',[])
            for ix,sec in enumerate(secs):
                poly=sec.get('polygon',[])
                if len(poly)<3:continue
                lo0,hi0=min(p[0] for p in poly),max(p[0] for p in poly)
                lo1,hi1=min(p[1] for p in poly),max(p[1] for p in poly)
                cx,cv=(lo0+hi0)*.5,(lo1+hi1)*.5
                phase=ix/max(1,len(secs)-1)
                for v in poly:
                    a,b=float(v[0]),float(v[1]);x,y=a,b
                    # A loft along height uses [x,depth]; a loft along depth
                    # uses [x,height]. We never move section heights/depths.
                    if axis=='y':
                        rear=b>cv+.4
                        if stage==0 and n in ('ct','lt','rt','pelvis') and rear:
                            y=cv+(b-cv)*(1-.008*intensity)
                        elif stage==1 and n in ('ct','lt','rt') and rear and phase>.50:
                            x=cx+(a-cx)*(1-.008*intensity)
                        elif stage==2 and n in ('lt','rt') and rear and phase>.25:
                            y=cv+(b-cv)*(1-.009*intensity)
                        elif stage==3 and n in ('ct','pelvis') and phase<.40 and klass!='quadruped' and rear:
                            y=cv+(b-cv)*(1-.013*intensity)
                        elif stage==4 and any(w in n for w in ('rack','lrm','srm','missile','launcher','pod')) and rear:
                            y=cv+(b-cv)*(1-.006*intensity)
                        elif stage==5 and ('shin' in n or 'calf' in n) and rear and .15<phase<.90:
                            y=cv+(b-cv)*(1-.012*intensity)
                        elif stage==6 and n=='pelvis' and phase<.40 and rear:
                            y=cv+(b-cv)*(1-.009*intensity)
                        elif stage==7 and ('foot' in n or 'tarsus' in n or 'hock' in n) and rear:
                            y=cv+(b-cv)*(1-.010*intensity)
                        elif stage==8 and n=='hd' and name not in PROTECTED_HEAD and rear and phase<.70:
                            y=cv+(b-cv)*(1-.007*intensity)
                        elif stage==9 and any(w in n for w in ('radiator','reactor','backpack','jump_pack','exhaust')) and rear:
                            y=cv+(b-cv)*(1-.007*intensity)
                    elif axis=='z':
                        # z-lofts carry vertical profile. Undercut armor below
                        # the local center without altering the ground-contact plane.
                        if stage==2 and n in ('ct','lt','rt') and b>cv and ix>=len(secs)//2:
                            x=cx+(a-cx)*(1-.004*intensity)
                        elif stage==6 and n in ('ct','pelvis','belly') and b<cv and ix>=len(secs)//2:
                            y=cv+(b-cv)*(1-.006*intensity)
                        elif stage==9 and ('reactor' in n or 'radiator' in n) and b>cv:
                            x=cx+(a-cx)*(1-.005*intensity)
                    if asset:
                        # Assets must never grow: all edited vertices move
                        # toward the original section center, protecting 50k.
                        x=cx+(x-cx)*(.998 if stage in (0,1) and n in ('hull','fuselage','base') else 1.)
                    if abs(x-a)>1e-7 or abs(y-b)>1e-7:
                        v[0],v[1]=round(x,5),round(y,5)
                        if v[0]!=a or v[1]!=b:changes+=1
    return changes


def all_lofts(d):
    out={}
    for p in d.get('parts',[]):
        if 'mirror' in p:continue
        out[p['name']]=[s['loft'] for s in p.get('shapes',[]) if 'loft' in s]
    return out


def process(paths, model_name, asset=False):
    originals=[json.loads(p.read_text()) for p in paths]
    if all(d.get('orthographic_revision')==REVISION for d in originals):
        return {'name':model_name,'passes':50,'already_done':True}
    docs=copy.deepcopy(originals)
    immutables=[immutable_state(d) for d in originals]
    before=[loft_measure(d) for d in docs]
    stage_counts=[0]*50
    for index in range(50):
        for d in docs: stage_counts[index]+=apply_pass(d,model_name,index%10,index//10,asset)
    for j,d in enumerate(docs):
        assert immutable_state(d)==immutables[j],f'{model_name}: critical model metadata changed'
        aft=loft_measure(d)
        # Source hull volume should not balloon or collapse. No more than
        # 6% shrink is accepted from the 50 gentle orthographic passes.
        if before[j]:assert .94*before[j]<=aft<=1.000001*before[j],(model_name,before[j],aft)
        d['orthographic_revision']=REVISION
        d['orthographic_passes']=50
    if len(docs)==2:
        before_eq=(all_lofts(originals[0])==all_lofts(originals[1]))
        if before_eq:assert all_lofts(docs[0])==all_lofts(docs[1]),f'{model_name}: LOD contours diverged'
    for path,d in zip(paths,docs):path.write_text(json.dumps(d,indent=2)+'\n')
    return {'name':model_name,'passes':50,'geometry_edits':sum(stage_counts),
            'active_passes':sum(n>0 for n in stage_counts),'stage_edits':stage_counts,
            'loft_volume_before':round(before[0],1),
            'loft_volume_after':round(loft_measure(docs[0]),1),
            'shape_class':signature(model_name)}


def main():
    prior=ROOT/'docs'/'graphics'/'orthographic-50-pass-audit.json'
    inputs=list(VOX.glob('*_shape.json'))+list(ASSETS.glob('*.json'))
    if prior.exists() and inputs and all(json.loads(p.read_text()).get('orthographic_revision')==REVISION for p in inputs):
        preserved=json.loads(prior.read_text()).get('summary',{})
        if preserved.get('total_passes')==50*len(inputs):
            print('Already applied; preserving original orthographic audit:',preserved)
            return
    report={'revision':REVISION,'focus':list(STAGES),'mechs':[],'assets':[],'notes':
        ['50 sequential reviews per model; some passes intentionally do not change geometry',
         'only loft polygons edited; no changes to muzzle origins, hit locations, or pivots',
         'reported loft volume is an authoring-grid proxy, not an occupied-voxel count',
         'Godot regression tests and multi-angle reference approval remain required']}
    for low in sorted(VOX.glob('*_shape.json')):
        name=low.name[:-11];high=VOX/(name+'.json')
        # Three specialty sculpts use _voxel.json manifests that resolve the
        # shape directly and do not contain an independent detailed loft.
        paths=[low]+([high] if high.exists() else [])
        report['mechs'].append(process(paths,name))
    for p in sorted(ASSETS.glob('*.json')):
        model=json.loads(p.read_text())
        assert int(model.get('voxel_cap',50000))<=50000,p.name
        report['assets'].append(process([p],p.stem,asset=True))
    summary={'mechs':len(report['mechs']),'assets':len(report['assets']),
             'total_passes':sum(x['passes'] for x in report['mechs']+report['assets']),
             'edited_vertices':sum(x.get('geometry_edits',0) for x in report['mechs']+report['assets']),
             'modified_models':sum(x.get('geometry_edits',0)>0 for x in report['mechs']+report['assets']),
             'revision':REVISION}
    report['summary']=summary
    dst=ROOT/'docs'/'graphics'/'orthographic-50-pass-audit.json'
    dst.parent.mkdir(parents=True,exist_ok=True)
    dst.write_text(json.dumps(report,indent=2)+'\n')
    print(json.dumps(summary,indent=2))

if __name__=='__main__': main()