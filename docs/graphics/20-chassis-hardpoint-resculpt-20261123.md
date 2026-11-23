# 20-chassis source-anatomy and weapon-hardpoint resculpt, November 23 2026

This batch continues the reference/camera silhouette refinement effort without
altering any record sheet, armor total, dice roll, save file, or combat rule.

## Chassis and distinctive changes

| Chassis | Physical geometry edited to distinguish the design |
| --- | --- |
| Locust | Tapered back and separate paired side machine-gun noses |
| Raven | Leaner rear hull, tall side ECM antenna, RT SRM-6 pod and RA twin lasers |
| Crab | Narrowed upper carapace and two actual claw-laser subassemblies |
| King Crab | Paired armored AC/20 claws with recessed firing channels |
| Centurion | Independent right AC/10 forebarrel and ten left-shoulder LRM tubes |
| Griffin | Right PPC forebarrel and ten right-shoulder LRM tubes |
| Rifleman | Less torso depth, physically independent mirrored AC/5 and large-laser guns |
| Black Knight | Reduced rear armor mass, articulated PPC barrel and twin chest lasers |
| Stalker | Rear hull taper and independently modeled arm LRM-10 batteries |
| Trebuchet | Two fifteen-bore missile pods, moved source launcher front from enclosing hull |
| Panther | Separate RA PPC and recessed central four-port SRM-4 |
| Commando | Distinct right SRM-4 and central SRM-6, a single left laser |
| UrbanMech | Dorsal exhaust and separately fitted AC/10; preserves deliberate squat proportions |
| Bushwacker | Thin rear of long beak, independent ER large laser, two LRM-5s and arm AC/10 |
| Kodiak | Keep bear-claw emitter fists but isolate RT UAC/20 and LT paired Streak SRM-6s |
| Longbow | Broad circular LRM-20 arm faces with twenty distinct ports each and twin torso LRM-5s |
| Hatchetman | Hatchet blade follows RA as a separate weapon mass, detached RT autocannon housing |
| Javelin | Thinner upper hull and two six-port shoulder SRM launchers |
| Spider | Lighter waist and two physically supported CT laser emitters; no added arm guns |
| Wolfhound | Thinner rear, separate chest lasers and right arm large laser |

Each chassis was edited in BOTH the source `_shape.json` recipe and the
detailed in-game `.json` recipe, not a render-only replacement. New children
inherit their original chassis damage location and articulated parent. Mirrored
components use mirrored rig ancestry. Source center/side anatomy loft parity
was independently checked for all twenty pairs.

The missile arrays were matched against existing official record-sheet equipment
in `data/units/`; the new geometry doesn't add gameplay weapons. Paint roles
are unchanged and damage remains driven by the combat unit record.

## Source-level QA and remaining acceptance conditions

The authored box/loft occupancy checks found physically disconnected independent
optical banks on the Spider; these were split into two supported parts. The
Trebuchet initially had overlapping arm/pod hulls; old frontal launcher lofts
were transferred to the new child geometry, leaving face-connected housings.
Other large existing launcher lofts were transferred out of parents as needed
on Commando, Javelin and Kodiak. Structural boxes were strengthened at the
Hatchetman and Wolfhound weapon sockets.

Tests in `tests/unit/test_vx_resculpt_next20.gd` require matching low/high
primary contour lofts, full damage-location coverage, legal rig ordering,
all specified launcher-tube counts, and real open mouths in representative
physically connected launcher parts.

**Not yet verified:** human-reviewed multi-angle matches to verified modern
plastic photos, post-raster completely overlap-free geometry on all twenty
chassis, Android performance, actual in-engine appearance, or the full Godot
regression run. Treat this as a source-geometry resculpt cycle requiring CI
and visual review, not a claim of 85+ reference silhouette scores. The existing
334-recipe scorecard's approved per-angle scores remain separate.
