# Additional loading and combat optimizations

- Startup worker calculates immutable paint bounds alongside surface arrays; cached chassis reuse those bounds instead of rescanning cells on the main thread.
- Shared terrain prism and noise texture survive map transitions; elevation range is computed once per terrain build. Intact bridge meshes reuse an exact geometry key (rise, open edges, variant), with a bounded 48-entry cache. Scarred meshes remain per-instance.
- Damage presentation ignores exact duplicate location fractions and removal masks before scanning cells. Repair and replay reversals remain supported.
- Stationary voxel rigs reuse leg IK when crouch and kick inputs are unchanged; walking and pose transitions still solve each relevant frame. Hidden rigs skip cosmetic processing.
- Fire/smoke updates replace only the environmental layer, once per synchronous event burst. Collapse retains the full map redraw and scar preservation.
- Visible selected record sheets refresh once per synchronous damage burst.

These are view-only changes. Physical Android timing is not measured. Existing Godot checks and an extended mesh identity/repair regression validate behavior; no brittle timing threshold.
