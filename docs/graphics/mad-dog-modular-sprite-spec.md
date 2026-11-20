# Mad Dog / Vulture — Modular Sprite & Walk Animation Specification v1.0

**Project:** BtechMobile  
**Status:** Proposed implementation spec, not yet validated in-engine  
**Related:** [BattleMech 2D Graphics Design Goal](mech-sprite-standard.md)

This is an **asset/layer specification for finished game graphics**, not a 3D-modeling or artist-reference workflow. Reuse authored leg frames, composite mostly static upper-body sprites, support faction palette swaps, and add restrained runtime upper-body motion. The first test is a single right-facing side-angle prototype.

## 1. Sprite layer contract

| Component layer | Authored frames per facing | Notes |
| --- | ---: | --- |
| `legs` / lower body | **6** | Both legs, feet and hip articulations as one frame-controlled unit |
| `torso` / cockpit | **1** | Main chassis; small runtime settle |
| `arm_left` | **1** | Distinct variant/damage component, runtime rotation |
| `arm_right` | **1** | Distinct variant/damage component, runtime rotation |
| `pod_left` | **1** | Modular missile/weapon pod |
| `pod_right` | **1** | Modular missile/weapon pod |

These are the **logical layers**, not a guarantee that six flat planes will always compose without occlusion artifacts. Optional front/back split layers or per-facing z-order rules can be added if necessary. Keep torso and weapon details stable from frame to frame; animate them with small runtime transforms instead of re-rendering every pose.

## 2. Views and naming

Each component is authored against the same seven-view baseline:

| View code | Horizontal orientation |
| --- | --- |
| `f000` | 0° / forward |
| `f060` | 60° |
| `f120` | 120° |
| `f180` | 180° / rear |
| `f240` | 240° |
| `f300` | 300° |
| `top` | True overhead / 90° camera elevation |

Six directional views use a shared **approximately 15° elevation** as the current *provisional* visual target. The overhead view is orthographic and can be rotated in the game. Precise facing sign conventions and the world-to-sprite conversion must be fixed during integration.

All sprites must share a common reference scale, frame size or canonical placement coordinates, a ground/root anchor and suitable component attachment anchors. No baked ground shadows or backgrounds.

### Proposed repository layout

```text
assets/mechs/mad_dog/
  sprites/
    f000/
      legs_00.png
      legs_01.png
      legs_02.png
      legs_03.png
      legs_04.png
      legs_05.png
      torso.png
      arm_left.png
      arm_right.png
      pod_left.png
      pod_right.png
    f060/       # same component names
    f120/
    f180/
    f240/
    f300/
    top/
  palettes/
    default.json
    factions.json
    # color-region masks may be per component and facing
  animation/
    walk.json
  manifest.json
```

Use transparent RGBA PNG source sprites; generate packed texture atlases later if desirable. Color masks, damage variants, and extra compositing sublayers should follow the same facing/component naming convention.

## 3. Authored six-pose walk cycle

Frame indexes are **zero-based**. Both feet and knees must maintain a convincing reverse-jointed, heavy mechanical gait; symmetry is preferred except where design or damage requires otherwise.

| Index | Pose ID | Legs and feet | Duration |
| ---: | --- | --- | ---: |
| `00` | `left_contact` | Left foot newly plants forward; right leg trails and finishes push-off | **90 ms** |
| `01` | `left_load` | Left knee compresses under weight; left foot remains planted; right foot lifts and begins swing | **115 ms** |
| `02` | `right_pass` | Left leg supports and extends; right leg folds and passes forward, foot clear of ground | **90 ms** |
| `03` | `right_contact` | Right foot newly plants forward; left leg trails and finishes push-off | **90 ms** |
| `04` | `right_load` | Right knee compresses under weight; right foot remains planted; left foot lifts and begins swing | **115 ms** |
| `05` | `left_pass` | Right leg supports and extends; left leg folds and passes forward, foot clear of ground | **90 ms** |

Loop: `00 → 01 → 02 → 03 → 04 → 05 → 00`.  
**Total duration:** 590 ms per full six-pose cycle (two steps). This is a test starting point, not a fixed gait speed. Frames **01 and 04** are held ~1.28× longer than ordinary frames to give a subtle weight-bearing pause. The held frame should be the **compression/load pose**, rather than duplicating the landing/contact pose.

On the initial prototype, render and compare equal timing versus weighted timing, and tune animation speed to actual world movement. If the runtime only permits fixed durations, repeated load frames `00,01,01,02,03,04,04,05` can approximate the pause (with coarser hold granularity).

### Foot planting

For the conceptual gait, left is the supporting foot across `00–02` and right across `03–05`. For an actual moving actor, ensure the screen-space planted foot **does not skate**: root movement, foot placement, step length and phase have to be coordinated. A discrete sprite cycle cannot guarantee zero sliding by itself.

## 4. Runtime upper-body transforms

Apply subtle transformations to the separate upper-body layers. Values below are **starting examples at a reference sprite scale**; offsets must be scaled/adjusted for the final sprite dimensions. Positive torso vertical displacement below means **downward in the image plane** (avoid ambiguity with 3D world-up).

| Frame | Torso vertical | Forward settle | Left arm rotation | Right arm rotation |
| ---: | ---: | ---: | ---: | ---: |
| `00` | +0.5 px | +0.5° | +1° | −1° |
| `01` | +1.0 px | +1.5° | +2° | −2° |
| `02` | 0 px | 0° | 0° | 0° |
| `03` | +0.5 px | +0.5° | −1° | +1° |
| `04` | +1.0 px | +1.5° | −2° | +2° |
| `05` | 0 px | 0° | 0° | 0° |

- Smooth/interpolate upper-body movement independently of the discrete leg sprite switches.
- Treat **forward settle** as a small apparent pitch/dip. Since a flat 2D sprite cannot truly pitch in 3D, implement with suitable projected offsets or very restrained sprite transforms; inspect results at each facing.
- Arms counter-sway slightly to stabilize. Keep the cockpit and missile assemblies nearly steady; optional shoulder pod lag/settle should be `0–0.5 px` or disabled.
- Test transforms around actual component pivots, never image bounding-box centers by default. Reduce motion if barrels or missile pods appear to swing unnaturally.

## 5. Attachment points and compositing

A per-facing manifest should identify:

- `root`: ground/world placement and rotation origin.
- `hip`: leg/lower-body to torso connection.
- `torso`: torso pivot and connection to lower body.
- `arm_left` and `arm_right`: separate weapon arm pivots.
- `pod_left` and `pod_right`: shoulder pod mounts.
- `top_rotation_pivot`: explicit overhead rotation center.

Record component-local coordinates, origin conventions, and draw/z order so equipment attaches accurately. Anchors may move **relative to the legs frame**, but must be authored consistently. No pixel-perfect numeric anchors are assigned before aligned assets exist. Test for gaps and inconsistent overlaps throughout every walk cycle and viewing direction.

## 6. Palette swapping

All factions should use the **same geometry and animation frames**. Use indexed color regions or per-component/facing masks to recolor:

| Region | Rule |
| --- | --- |
| Primary armor | Faction primary |
| Secondary armor | Faction secondary |
| Accent plates | Faction accent |
| Inner frame/joints | Usually remain dark steel |
| Cockpit glass | Separate, independently configurable |
| Launcher ports/weapon interiors | Separate, independently configurable |

Preserve original luminance/shading and contour linework within each region when applying faction colors. The earlier `armor_mask.png` layout is only a placeholder name; real masks must be aligned **per relevant image/frame or via a canonical packed mask representation**.

## 7. Variants, damage and destroyed states

Keep arms, pods and other attachments modular so Prime and other configurations can share the leg and torso animation. Add replacement sprites/overlays for **intact, damaged and destroyed** components, aligned to the same anchors and palette rules. Leg damage may later justify special limp/disabled animations; do not require unique walk cycles for every arm or launcher damage state.

## 8. Initial asset budget

For all **seven view sets**, baseline unique PNGs before extra front/back layering, mask textures, weapon variants, damage or wreck art:

- `6 leg poses × 7 views = 42` leg images.
- `5 static upper-body components × 7 views = 35` body/arm/pod images.
- **77 base sprite images** total.

This is a planning count, not a production minimum: unused/occluded components can sometimes be omitted for a given view; additional overlap corrections can increase the count. At least one mask/region definition is needed for every recolorable appearance.

## 9. Validation plan and acceptance

Start with **one right-facing side-angle view**, then expand to the other five directional views and true top-down:

1. Generate six aligned, transparent leg poses plus torso, two arms and two pods for that facing.
2. Verify pivot/anchor consistency, layering, clear foot support, clean reverse-jointed motion, and loop continuity.
3. Animate at the proposed **90/115/90/90/115/90 ms** timing; compare with uniform timing at the same total cycle duration.
4. Add restrained runtime torso/arm motion; ensure the chosen offsets preserve attachment integrity.
5. Apply two or more faction palettes through the same color-zone masks with no changes to shape or pose.
6. Test in the intended movable-camera 3D scene and tune feet, motion, transparency/halos, view switching and frame scale.
7. Extend the accepted implementation to six hex facings, top-down, equipment variants and damage states.

**Acceptance criteria:** convincing heavy two-step loop; no obvious foot sliding, pivot gaps, sprite flicker or geometry drift; strong Mad Dog recognition; preserved mechanical shading under faction recolors; readable weapons and legs at game size; usable performance in-engine.

**Open decisions:** exact sprite resolution, image-plane sign conventions, per-facing draw order, final directional camera elevation, world-speed synchronization and optional additional elevation bands.
