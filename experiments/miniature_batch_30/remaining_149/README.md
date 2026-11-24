# Remaining 149 — source-geometry refit and structural repair sweep

This experiment is stacked on #313. It inventories 281 distinct `*_shape.json` files at main commit `00d4f7db1c60e7559a375e6e6234deb63a88ce19`, subtracts the 132 covered by known prior experimental cohorts (including siblings #286–#299), and executes on all 149 remainder entries. Standalone designs from #311 and variant overlays are not counted as remaining chassis. No production files or existing merged models changed.

## Method

- Read each exact main source recipe, preserving its individual geometry, rig names, material and weapon assignments; expand mirrored parts and apply exclusive ownership using the native coarse-source raster convention. This diagnostic is not an exact substitute for Godot's refined/art-quality loader.
- Use prior **unverified** plastic photo or legacy illustration band observations to direct edits of original polygonal loft stations, retaining endpoints, vertices, hard edges and existing asymmetry. Do not treat a band lead as a measured photo match. For the 13 models with no directional lead, study rear depth only.
- Keep candidate geometry only if neutral assembly, weak-interface, part-island and clear sample counts do not regress; protect authored voids on repair additions. First pass selected 111 loft refits and additional structural repairs.
- On 78 difficult or retained controls, replay and trial backed module collars, recuts of only the owning gun location's sampled bore, and 33 alternate sharp planar face studies. Source-only studies are provisional, not independent evidence of better likeness.
- On 28 remaining structural/port cases, re-seat thin armor plates on broad two-layer-backed hull faces, recut backed square joint seams, or reconnect entire limb roots with a small backed collar; 14 chassis received selected third-pass changes. Jackal's initial third-pass network failure was retried successfully. No unsupported connector, arbitrary smoothing or global shared body substitution.

## Final audit

| Metric | Baseline | Selected |
|---|---:|---:|
| Physically detached groups | 63 | 5 |
| Weak explicit parent interfaces (strict backed 2x2) | 74 | 19 |
| Part-local disconnected groups (includes some supported through other parts) | 98 | 49 |
| Clear modeled axial muzzle samples | 1263/1291 | 1285/1291 |

149/149 chassis have selected geometry modifications, 2465 components, 824282 occupied source cells, 23744 changed source cells. 145 chassis have no physically floating islands, 138 have zero physical islands and zero weak interfaces, and 118 pass the stricter combination including part-local islands and modeled sample clearance. No claim of fully validated rigging, full barrel-channel verification or photo fidelity.

## Outstanding physical, backed-interface and sample defects

| Chassis | Physical islands (sizes) | Weak interfaces | Blocked samples |
|---|---|---:|---:|
| argus | None | 2 | 0 |
| hellspawn | None | 2 | 0 |
| hollander | 13 | 0 | 0 |
| jackal | None | 0 | 1 |
| jackalope | 8, 8 | 0 | 0 |
| jinggau | None | 0 | 1 |
| pack_hunter | None | 2 | 0 |
| piranha | None | 2 | 0 |
| quickdraw | 6 | 2 | 0 |
| raptor | None | 0 | 1 |
| rattlesnake_ii | None | 0 | 1 |
| sagittaire | None | 1 | 0 |
| shadow_hawk_iic | None | 0 | 1 |
| tarantula | None | 5 | 0 |
| tempest | None | 0 | 1 |
| thunder_stallion | None | 3 | 0 |
| vulcan | 36 | 0 | 0 |

Strictly clean candidates: 118; 31 still need some repair/validation. In particular, Vulcan's large detached leg was reconnected but one side module remains detached; do not drop it to force a passing score. Six sample points remain obstructed, and 19 backed interface faults are unresolved. Do not equate three axial sampled cells with a complete weapon aperture or variant certification.

## Replay and inspection

Use `selected_summary.json` as the definitive per-chassis manifest; `selectedFrom` points to the chosen batch record. Fetch the pinned source from `inventory.json`, expand mirroring and exclusive ownership with runner.js; apply the selected record's inclusive-box `patches` by part. The native loft edits and rejected trial details are saved in first-pass files, later selections preserve their resulting occupancy and append structural/alternate study changes. Earlier `final_summary.json` is the second-pass checkpoint. The repair pass files record exact operations; third-pass selections replace earlier previews.

- [Sheet 1: Albatross–Eris](contact_sheet_1.svg)
- [Sheet 2: Excalibur–Hussar](contact_sheet_2.svg)
- [Sheet 3: Imp–Phoenix](contact_sheet_3.svg)
- [Sheet 4: Pillager–Talon](contact_sheet_4.svg)
- [Sheet 5: Talos–Yu Huang](contact_sheet_5.svg)
- [Revised third-pass projections](contact_sheet_repaired.svg) (supersede the corresponding 14 rows above).

These are neutral, coarse source-cell projections, not Godot screenshots. No new images were inspected or registered in this sweep; prior reference leads are **not** fresh photographic comparisons. No Godot runtime, pose collision, independent variant verification, new photo-mask registration or production tests were performed here. Keep draft separate from main until validated.