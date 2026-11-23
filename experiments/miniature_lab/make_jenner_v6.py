"""Generate isolated Jenner v6 subassemblies with higher-polygon contours.

No production source is read. Split pieces inherit existing material volumes,
and each slanted interface is required to be load bearing.
"""
import copy
import json
from pathlib import Path

HERE = Path(__file__).resolve().parent


def tapered_corners(poly, portion=.13):
    out = []
    for i, p in enumerate(poly):
        before = poly[(i - 1) % len(poly)]
        after = poly[(i + 1) % len(poly)]
        out.append([round(p[d] * (1 - portion) + before[d] * portion, 5)
                    for d in (0, 1)])
        out.append([round(p[d] * (1 - portion) + after[d] * portion, 5)
                    for d in (0, 1)])
    return out


def subdivide_curve(poly):
    """Catmull-Rom intermediate controls, not redundant straight midpoints."""
    out = []
    for i, a in enumerate(poly):
        p0 = poly[(i - 1) % len(poly)]
        b = poly[(i + 1) % len(poly)]
        p3 = poly[(i + 2) % len(poly)]
        out.append(a)
        out.append([round((-p0[d] + 9*a[d] + 9*b[d] - p3[d]) / 16, 5)
                    for d in (0, 1)])
    return out


def piece(name, loc, parent, source, planes, normal, pivot,
          max_angle=38, kind='rigid'):
    return dict(name=name, loc=loc, parent=parent, claim_from=source,
                pivot=pivot, subassembly_kind=kind,
                attachment_angle_basis='world_space',
                attach_normal=normal, angle_tolerance_deg=max_angle,
                partition={'planes': [{'normal': n, 'origin': origin}
                                      for n, origin in planes]}, shapes=[])


def build():
    spec = copy.deepcopy(json.loads((HERE / 'jenner_assembly_v5.json').read_text()))
    spec['shape_refinement_revision'] = 'miniature-first-v6-polygon-subassembly-20261123'
    spec['assembly_guide'] = {
        'cut_policy': 'transfer-owner-only: preserve occupied voxels, forbid bridge repairs',
        'camera_and_stance': 'experimental; no claim of calibrated matching',
        'structural_rule': 'backed 2x2 face patch and oriented connection normal',
        'reference_sculpt': 'Catalyst 2021 Jenner CAT35729',
        'editorial_note': 'All parts unique to this Jenner, not shared generic mech geometry'}

    for part in spec['parts']:
        for shape in part['shapes']:
            if shape['op'] == 'subtract':
                continue
            for section in shape['sections']:
                contour = section['polygon']
                if len(contour) in (12, 16) and shape['mat'] in ('armor','structure'):
                    section['polygon'] = subdivide_curve(contour)
                elif len(contour) == 8 and shape['mat'] == 'armor':
                    section['polygon'] = tapered_corners(contour, .11)

    parts = spec['parts']
    def add(**kwargs):
        parts.append(piece(**kwargs))

    add(name='hd_nose_shell', loc='HD', parent='hd', source='hd',
        planes=[([0, 0, -1], [0, 0, -.92])],
        normal=[0, 0, 1], pivot=[0, 1.55, -.92], kind='nose_cowling')
    add(name='hd_crown', loc='HD', parent='hd', source='hd',
        planes=[([0, 1, -.18], [0, 1.67, -.74])],
        normal=[0, -1, .18], pivot=[0, 1.70, -.72], kind='cockpit_crown')
    add(name='ct_dorsal', loc='CT', parent='ct', source='ct',
        planes=[([0, 1, -.14], [0, 2.12, 0])],
        normal=[0, -1, .14], pivot=[0, 2.145, 0], kind='dorsal_plate')

    for side, prefix, torso, arm, thigh, shin, foot, loc_t, loc_a, loc_l in [
        (-1,'l','lt','la','ll','ll_shin','ll_foot','LT','LA','LL'),
        (1,'r','rt','ra','rl','rl_shin','rl_foot','RT','RA','RL')]:
        add(name=torso+'_upper_armor', loc=loc_t, parent=torso, source=torso,
            planes=[([0, 1, .28], [0, 2.02, -.06])],
            normal=[0, -1, -.28], pivot=[side*.44, 2.0, 0], kind='shoulder_cap')
        add(name=arm+'_outer_cowl', loc=loc_a, parent=arm, source=arm,
            planes=[([side, .14, .10], [side*.91, 1.8, 0])],
            normal=[-side, -.14, -.10], pivot=[side*.92, 1.78, .02], kind='pod_endcap')
        add(name=thigh+'_knee_armor', loc=loc_l, parent=thigh, source=thigh,
            planes=[([0, -1, .12], [0, .805, -.09])],
            normal=[0, 1, -.12], pivot=[side*.37, .81, -.08], kind='thigh_knee_cuff')
        add(name=shin+'_calf_plate', loc=loc_l, parent=shin, source=shin,
            planes=[([0, -1, -.22], [0, .44, 0])],
            normal=[0, 1, .22], pivot=[side*.4, .45, .02], kind='angled_calf')
        add(name=foot+'_toe', loc=loc_l, parent=foot, source=foot,
            planes=[([0, -.14, -1], [0, .105, -.1])],
            normal=[0, .14, 1], pivot=[side*.42, .1, -.10], kind='foot_toe')
        for p in parts:
            if p['name'] == shin:
                p['parent'] = thigh+'_knee_armor'
            if p['name'] == foot:
                p['parent'] = shin+'_calf_plate'
    return spec


if __name__ == '__main__':
    out = HERE / 'jenner_assembly_v6.json'
    obj = build()
    out.write_text(json.dumps(obj, indent=2) + '\n')
    print(out, 'parts', len(obj['parts']))
