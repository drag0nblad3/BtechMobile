# November 23: first source-based chassis four-view review

This is a **manual diagnostic**, not an assertion of source-image pixel
alignment. The CI renderer produces `new_source_chassis_four_angles.png`
in the `connectivity-multiangle-review` artifact; views are front, side,
three-quarter and rear for each new chassis. The accompanying
`tools/voxel_multiangle_audit.gd` now checks these seven original sculpts
as well as existing low-detail `_shape` models.

## First visual observations

| Chassis | Recognizable distinctions | Remaining shape work |
| --- | --- | --- |
| Solitaire | Shoulder armor, head antenna, arm weapons | Torso and limbs still too generically humanoid; refine thinner side profile and characteristic forearm shapes |
| Vulture Mk IV | Long projecting cockpit beak, high missile cheeks, digitigrade leg joints | Shoulder pods still boxy from the front; vary height, depth and rake against the **Mk IV**, not the original Mad Dog |
| Hellhound (Conjurer) | Horned upper head and asymmetric weapons | Torso/arm outline remains close to other upright chassis; slim and re-angle shoulders against source |
| Koshi (Standard) | Circular projected head, dorsal vents and distinct podded arms | Reinforce true spherical front head and different launcher shapes; do not swap in Mist Lynx OmniMech art |
| HawkWolf HWK-4F | 15-tube arm racks and 5-tube torso racks | Front silhouette lacks distinct break between torso and giant launchers; legs/feet still generic |
| Black Hawk (Standard) | Shoulder-mounted laser nacelles and prominent arm launchers | Recheck narrow torso and limb rakes to distinguish from Nova OmniMech and Dominator |
| Dominator | Heavy asymmetric right arm PPC and tall shoulder panels | Cut generic upper-body mass and refine head/shoulder spacing |

The source-based model materials and launcher topology are intentional, but
they do not replace a reference registration run. Silhouette scores must
eventually be made after fitting each model's **rig pose and camera** to a
true source image at front, then side, quarter and top. Current CI only
guarantees that the images can be rendered and connected moving masses
survive construction; it does not assert that shape is faithful. Avoid
marking these chassis as final until multi-view source comparison and
physical-contact review have been completed.

Source priority: latest official Catalyst plastic sculpt **of the same
chassis generation** where available, then official record sheet/TRO art,
then other corroborating views. The 3145-era Vulture Mk IV must never be
scored against the original Mad Dog. The Koshi (Standard) is not the Mist
Lynx OmniMech.
