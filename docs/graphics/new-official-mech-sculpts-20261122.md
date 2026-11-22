# New official BattleMech geometry — source-first sculpt pass

**Date:** 2026-11-22. **Status:** first six source sculpts; reference and high-detail audits are ongoing. This is not a claim that the whole newly imported roster has finished geometry.

## Context and limits

- Data import finished in three distinct 50-design batches: PR #221, #226 and #228. These are 150 **official record-sheet designs**, not 150 distinct chassis or 150 separate pieces of art. The latter two PRs added the requested additional 100 units. Reuse the same chassis geometry across variants unless the specific variant has visible armament differences.
- This branch creates editable **low-resolution component geometry first** in `data/voxels/<chassis>_shape.json`. A small `<chassis>.json` manifest requests a twice-subdivided display version from the **same source**, without hand-authoring a disconnected decorative layer over the low-resolution shape.
- The geometry is view-only and does not alter the authoritative weapon loadout, hit locations, ammo, BV, `Unit`, combat logic or save state. The six are registered in the voxel showcase, **not** automatically used by the normal battle scene, where sprites/placeholder fallback remains.
- No Android APK has been requested or built.

## First six source shapes

| Chassis | Source character and art target | Actual MTF weapon placement kept in geometry |
|---|---|---|
| Yeoman YMN-6Y | Two enormous raised, recessed missile launcher towers, small low cockpit, legs that do not compete with the towers | **25 missile bores per side torso**, LT+RT |
| Jackrabbit JKR-8T | Light asymmetric skirmisher; long cannon on one side, visibly smaller missile pod opposite | 2 Streak SRM bores LA, single AC/2 bore RA; no artificial hands |
| Garm GRM-01A | Twin asymmetric shoulder weapon shapes above slender jump-capable body | 10 LRM bores LT; one long LB 5-X cannon RT; 5 jets in CT/legs |
| Hermit Crab HMC-13 | Low, broad compact carapace and articulated claw-like laser housings | Single laser muzzle each arm; 7 jump jets divided CT/LT/RT |
| Hornet HNT-151 | Largely spherical suspended fuselage with very thin insectoid legs and unobtrusive arm mounts | 5-hole LRM pod RT; smaller laser LA, larger laser RA |
| Hussar HSR-300-D | Sleek and long horizontal scout fuselage, far-forward cockpit, conspicuous dorsal laser barrel, rear stabilizers | One large laser **CT**, not a gun placed arbitrarily in an arm |

## Reference anchors

Source shape design uses official MTF record-sheet positions and multiple real-world angle references, with current Catalyst plastic references preferred when available. Public source anchors for the first difficult silhouettes include:

- **Hussar:** [3039 HSR-300-D original technical-readout profile](https://mordel.net/tro.php?a=vtbm&id=193) — long cannon aligned over the fuselage, very light legs.
- **Hornet:** [HNT-151 tabletop miniature / front view](https://www.defiance-industries-wargaming.com/listing/915541447/tro-2750wolfs-dragoons-inner-sphere) — domed upper body and narrow legs.
- **Falcon (future sculpt):** [FLC-4N MWO-style alternative concept](https://mwomercs.com/forums/topic/269487-mwo-style-falcon-flc-4n-concept-art/) and original [BattleTechWiki profile](https://www.sarna.net/wiki/Falcon_%28BattleMech%29); do not substitute fan concept for canonical reference when a plastic model exists.
- **Yeoman:** [BattleTechWiki Yeoman](https://www.sarna.net/wiki/Yeoman), original dual missile-tower outline.
- **Hermit Crab:** [BattleTechWiki Hermit Crab](https://www.sarna.net/wiki/Hermit_Crab).

Art has no copied lore/fluff text from these references.

## QA process

A dedicated geometry test `tests/unit/test_new_source_sculpts.gd` covers the **actual occupied voxel mass**, not a bounding-box intersection:

1. All eight hit locations are represented; sources load and map to a real unit id.
2. Every articulated component is one 6-face-connected mass — **no floating islands** or corner-only attachments.
3. Every parent/child has a continuous **2 × 2 voxel contact patch with one backing layer on each side**. Merely overlapping bounds, touching at a point, or placing an unsupported veneer fails.
4. Muzzles must sit inside open barrel or launcher mouths, and counted missile tubes must match the actual mounted rack size.
5. The 2× detailed preview must preserve the same solid masses (separate high-resolution test).

Render inspection matters **beyond the tests**. Preview one compact montage of front (highest priority), side, three-quarter, rear and top. Use the same 55/28/12/5 silhouette priority as the advanced multi-angle branch (PR #213), and reference newer Catalyst miniatures where available. A low silhouette-confusion score does not prove that a chassis looks right.

The first gallery showed **Hornet too humanoid and Hussar too short-fronted**; both were explicitly resculpted at the source, not merely rescaled when rendering. The newer gallery is in the temporary GitHub Actions sculpt-review run. These initial six should still be treated as **shape studies pending individual miniature-based sign-off**, not finished production-grade model art.

## Next work

Continue modeling the unrepresented chassis from imported batches, identifying their distinctive profile and gun location **before** adding detail. Test physical connectivity after every resculpt and do not normalize all torso depth or leg proportions toward a single archetype. Once the new chassis art is actually complete, continue the remaining official MTF design imports. Do not resume data import early merely because the first six models parse.

The source branch is intentionally separate from the active multi-angle sculpt branch; reconcile both art systems by source content and run audits, never by copying unverified cells or silently replacing another artist's geometry.

## Review response: segment and float correction (2026-11-22)

A visual review found that the first six studies were blobby, repetitive, undersegmented, and included substantial floating assemblies. The shape studies remain **draft**. The underlying right-leg parent bug was confirmed in every file: mirrored `rl` parts explicitly had `parent: ""`, making their entire chains independent rig roots, which the original joint test skipped. Each now attaches to CT; the tests require one CT root, every other segment to descend from it, and the combined 6-connected model to be a single mass in addition to per-part backed face joints.

The first corrective pass physically separates upper/lower arm and shin mass in all six chassis, preserving existing shoulder/knee/ankle animation joints and source weapon locations. Yeoman's launchers become independent rooted LT/RT masses; Hornet's sphere carapace becomes a rooted CT segment; Hussar's long dorsal weapon becomes its own CT barrel with a longitudinal fuselage instead of a vertical humanoid loft. **This fixes hierarchy and introduces real component divisions, not verified final silhouette likeness.** Repeat compact front/side render comparisons to originals before merging.
