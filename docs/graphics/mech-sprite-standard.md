# BtechMobile — BattleMech 2D Graphics Design Goal

**Status:** Agreed direction; camera elevation for directional sprites remains subject to in-engine tests.
**First candidate chassis:** Mad Dog / Vulture.

## Goal

Create **finished, usable in-game 2D BattleMech graphics**, not 3D models, artist reference sheets, or instructions that require an outside art pipeline. The game world and camera are 3D, but BattleMechs are represented by composited 2D sprites / textures. The game engine handles position, perspective projection, scale, camera motion, scene lighting and shadows where practical.

Aim for original visual interpretations that carry the identifying silhouette and major distinctive features of each BattleMech across historical representations, rather than directly copying any single illustration or model. Rights and licensing for use of recognizable BattleTech designs are a separate consideration before distribution.

## Seven-view baseline

Each base chassis and its necessary visible equipment states will have:

1. **Six directional views** around the mech's upright vertical axis: **0°, 60°, 120°, 180°, 240°, and 300°**. These are the six hex facings, **not** conventional front/back/left/right/top/bottom orthographic drafting views.
2. **One fully top-down view**, camera exactly **90° above the mech**, with no perspective distortion. The game can **rotate this overhead texture** as needed for heading/facing.

The six directional views use a **shared, fixed camera elevation** and **orthographic projection** in the source artwork, so environmental perspective is not baked in. That elevation is **not yet locked**. Test candidate elevations at **0°, 15°, and 25°** above horizontal using the same mech and comparable graphics in the live 3D scene, then select the best one.

All six directional views must share consistent design, scale, apparent proportions, pose, ground contact, horizontal pivot, component mounts, illumination and sprite framing. The overhead view must agree with the same chassis/equipment layout and point toward a documented forward axis.

## Modular variants

Build a reusable core chassis and layered interchangeable pieces where practical, such as arm weapons, shoulder missile pods, torso equipment and external armor. Provide **directionally matched sprites and anchor metadata** for the six views plus the top-down view wherever those components remain visible. Keep part naming stable and allow variants to share the most possible artwork.

## Damage and destruction

Support intact, damaged and destroyed presentations of gameplay-relevant components. Prefer reusable minor-damage overlays for scorch/gouge effects; use explicit replacement sprites for severed arms, ruined launchers and other major structural changes. Include a simplified collapsed/disabled/wreck state and reusable debris, smoke, fire and impact effects when needed. Align swaps with their component anchors and relevant facing.

## Game-ready output

- Transparent **PNG** sprites/atlases (no backgrounds or baked ground shadows).
- Consistent dimension, ground contact and pivot conventions.
- Asset metadata/manifest mapping chassis, variant, facing, elevation, layers, anchor points, damage state and sprite rectangle.
- Separate export-ready sprites where useful; atlases may be assembled for performance.
- Stable file naming and versioning; for example, `mad_dog/core/facing_060.png` and `mad_dog/top/top_000.png`.
- Keep every output suitable for import into the BtechMobile game rather than as a drawing guide for third-party modelers.

## Validation / decisions to settle

1. Produce a small **Mad Dog prototype** using a consistent design at **0°/15°/25°** directional-camera elevations and the exact top-down view.
2. Put example sprites into the **3D game engine**, using the intended billboard/plane selection behavior and moving camera.
3. Judge on-screen recognizability, leg/shoulder readability, component alignment, apparent scale, camera transitions and performance.
4. Choose and freeze the directional elevation; then produce all six angles, modular variant overlays, and selected damage states.
5. Test how the engine switches between directional views and top-down near steep camera elevation. Extra elevation bands can be considered later only if the seven-view baseline is insufficient.

## Scope boundaries

- **No 3D mech model or rig pipeline.**
- **No top/bottom/side engineering sheet substituted for the six hex facings.**
- **No assumed elevated view** until in-engine evaluation.
- The renderer can project a flat texture in perspective, but it **cannot reveal unseen geometry**; changing camera elevation significantly may still require sprite transitions/additional views.
- Briefs, prompts and internal design notes are production aids for generating assets; the project deliverables are finished in-game graphics.
