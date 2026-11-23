# Missing 42 BattleMechs: physical socket sculpt reconciliation

Import only the 84 voxel recipes from the historical #242 Mech batch; the 29 record-sheet support assets are already on main through #249. No core rule or design JSON edits.

The previous #242 multi-angle audit reported 203 **weak joints** across all 42 Mechs (zero disjoint islands). A one-voxel touch is not enough: `VxConnectivity.solid_contact` requires a two-by-two face patch, physically backed on both sides.

`VxJointBacking` performs bounded coarse-geometry repairs on this batch only, using the existing parent and child masses. It searches 2×2 backed parent surfaces near the child volume, adds a small joint-material collar through a short free gap, and verifies actual solid contact. `VxJointKeepout` protects muzzle channels and authored erasures. It cannot grow through another part's occupied cells; failures remain in the strict multi-angle audit instead of being waived. The authored plates, muzzle points, joints, height and gait are left untouched. Maximum 40 added cells for any one socket, rather than a generic shoulder/torso slab.

**Structural repair is not artistic approval.** The historic 50 automated source passes are not equivalent to reviewed Catalyst plastic proportions. No blind source overwrite of newer chassis, and no Android APK. Rerun CI, connected-mass audit, front/side silhouette review and visual reference checks before merge.
