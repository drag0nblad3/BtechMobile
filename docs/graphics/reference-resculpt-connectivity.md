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
