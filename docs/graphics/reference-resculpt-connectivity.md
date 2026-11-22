# Reference-driven major resculpt and per-part connectivity gates

This audit is specifically **not** an assertion that the entire mesh is connected.
It rasterizes each authored coarse part and checks:
1. 6-face-connected islands **within** the part, with island size in cells.
2. Face-connected or shared-voxel contact with the named parent part.
3. Empty parts, missing parent nodes, and loader errors.
4. Chassis-specific silhouette/weapon placement regression checks separately.

Run `godot --headless --path . --script res://tools/audit_voxel_parts.gd`.
The complete JSON report is written to `user://voxel_part_connectivity_report.json`;
`VOXEL_PART_AUDIT_SUMMARY` and per-model warning lines appear in CI logs.

The catalog contains legacy disjoint decorative pieces and author-authored erasures;
**warnings are not silently repaired or mislabeled as acceptable**. The strict
six-face rule is intentional: corner contact does not make a structural joint.
Detailed models should also be checked after refinement because beveling and
exclusive cell ownership can sever coarse connections. Vehicles and infantry
retain their 50,000-final-voxel runtime cap.

Use current Catalyst plastic miniatures from multiple angles as the leading
visual reference; line art is secondary. Do not add duplicate hidden arms,
enlarge hulls indiscriminately, or replace distinct cockpit silhouettes with a
unified family template.


## Reference surgery and first whole-catalog audit (2026-11-22)

References consulted include the current Catalyst/ForcePack plastic silhouettes
for Raven, King Crab, Locust, Rifleman and Hunchback, plus Shadow Cat and
quadruped documentation. The sculpting emphasis is a recognisable cockpit,
distinct weapon housings and correct plan/side depth, **not** a generic taper.
Nonuniform contour operations were applied to both low and detailed source
models on seven chassis: Raven, Shadow Cat, King Crab, Locust, Rifleman,
Hunchback IIC and Goliath. A proposed Scorpion hull edit was rejected because
it created detached or overlapping pieces.

On the offline 146-chassis shape-study set, the pre-repair geometry had
1,838 named parts, 32 detached intra-part islands and 2 parent gaps. The
component-specific repair added minimal supports or removed stray cells,
rather than dilating whole arms/hulls. The combined offline audit then reported
zero loose islands, zero parent gaps, zero empty parts and zero overlapping
cells **at coarse resolution only**. This is not an engine-level approval.

The companion Godot workflow writes an artifact with one JSON record per part
and checks the full Godot catalog, including the five high-fidelity standalone
shape sculpts. It may expose further differences, particularly under refined
voxel ownership and beveling. Keep any failures visible and repair them in the
source; do not weaken the assertions to turn CI green.
