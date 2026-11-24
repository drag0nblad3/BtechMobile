#!/usr/bin/env python3
"""Recover physical joints after miniature resculpting, never auto-fill gaps.

A disconnected part after a loft change is a reattachment task, NOT an
automatic reason to abandon good anatomy. Select an authored cut plane,
verify two solid masses, supported face contacts and downstream attachment,
then move pivots to real anatomical centers. Does NOT add geometry.
"""
import math

import miniature_lab as geo
import subassembly as seams


def partition(cells, pitch, normal, origin):
    """Split immutable occupied cells into new knee/armor and retained shell."""
    normal = seams.normalize(normal)
    claimed, retained = {}, {}
    for cell, material in cells.items():
        xyz = tuple((v + .5)*pitch for v in cell)
        offset = tuple(xyz[i]-origin[i] for i in range(3))
        (claimed if seams.dot(offset,normal) >= -1e-8 else retained)[cell] = material
    return retained, claimed


def contact_angle(claimed, retained, expected):
    report = seams.normal_report(claimed, retained)
    if not report["area"]:
        return float("inf")
    d = seams.dot(seams.normalize(report["normal"]),
                  seams.normalize(expected))
    return math.degrees(math.acos(max(-1.,min(1.,d))))


def inspect(cells, pitch, cut, downstream=(), tolerance=38):
    """Require strong connections to parent AND any existing downstream limb."""
    retained, claimed = partition(cells,pitch,cut["normal"],cut["origin"])
    answer = {"cut": cut, "retained": retained, "claimed": claimed,
              "errors": [], "contact_area": 0, "angle_degrees": None}
    for name, part in (("retained",retained),("claimed",claimed)):
        if not part or geo.components(part) != 1:
            answer["errors"].append(name+": disconnected after repartition")
    if answer["errors"]:
        return answer
    if not geo.strong_contact(claimed, retained):
        answer["errors"].append("no load-bearing parent contact patch")
    area = seams.normal_report(claimed,retained)["area"]
    answer["contact_area"] = area
    expected = [-v for v in seams.normalize(cut["normal"])]
    direction = contact_angle(claimed,retained,expected)
    answer["angle_degrees"] = direction
    if direction > tolerance:
        answer["errors"].append("interface contact direction is incorrect")
    for i,child in enumerate(downstream):
        if not geo.strong_contact(child,claimed):
            answer["errors"].append(f"downstream child {i}: no backed patch")
    return answer


def find_reattachment(cells, pitch, authored_planes, downstream=(),
                      target=None, tolerance=38):
    """Choose an anatomically local, sound interface, not a filler bridge.

    Call AFTER the resculpt, with possible pivots and inclined cuts
    authored around the actual new mechanical joint. A failure is a
    precise unresolved reattachment defect, not a sculpt rejection.
    """
    valid = []
    for cut in authored_planes:
        report = inspect(cells,pitch,cut,downstream,tolerance)
        if report["errors"]:
            continue
        distance = (math.dist(cut["origin"],target) if target is not None
                    else 0.)
        # Anatomy-first: minimize intended joint-center displacement,
        # then respect measured normal; large face areas do not license
        # displacing the joint to a fake oversized connector.
        valid.append((distance, report["angle_degrees"],
                      -report["contact_area"], report))
    if not valid:
        raise ValueError("No sound reattachment at authored interfaces; "
                         "resculpt a true mating surface or change pivot")
    return min(valid,key=lambda row:row[:3])[-1]


def apply_to_spec(spec, claim_name, cut, pivot=None, downstream_pivots=None):
    """Apply the physically verified joint to an experimental spec only."""
    parts = {p["name"]:p for p in spec["parts"]}
    if claim_name not in parts or not parts[claim_name].get("claim_from"):
        raise ValueError("must reattach an existing claimed assembly")
    part = parts[claim_name]
    part["partition"]["planes"] = [cut]
    part["attach_normal"] = [-x for x in seams.normalize(cut["normal"])]
    if pivot is not None:
        part["pivot"] = list(pivot)
    for name, new_pivot in (downstream_pivots or {}).items():
        if name not in parts:
            raise ValueError("missing downstream part "+name)
        parts[name]["pivot"] = list(new_pivot)
    return spec
