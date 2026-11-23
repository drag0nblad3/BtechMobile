# Reference geometry — Batch 8 (23 November 2026)

Twenty additional imported BattleMech source shapes were adjusted in
their authored lofts:

Hound, Initiate, Jackal, Jackrabbit, JagerMech III, Juggernaut, Kabuto,
Koschei, Koto, Lightray, Lineholder, Lynx, Marshal, Nexus, Night Hawk,
Onslaught, Orochi, Phoenix, Raijin, Rampage.

Each design received a tailored reduction of exaggerated positive-Z
(backward) CT, LT and arm/leg primary armor geometry. The heavy Juggernaut
and Orochi were kept broad; Jackal, Jackrabbit and Phoenix changes preserve
their smaller or faster body plans. No forward-facing weapon bore, launcher
housing, head polygon, parent or pivot was deleted.

The Jackrabbit left torso is **not a loft**: it is a separately supported
shell-and-frame construction. This was left intact rather than imposing
the standard humanoid contour algorithm. Jackal, Nexus and Phoenix retain
their digitigrade gait signatures.

All authored high-detail source links remain intact. The new
`tests/unit/test_vx_reference_batch_eight.gd` checks source provenance,
positive-area geometry, articulated hit locations and these special rigs.

**Limits:** Godot CI, physical connectivity audit and multi-angle
source-versus-Catalyst miniature rendered review are required before
declaring these exact visual matches. These edits do not change
unit record sheets, game rules or APK exports.

Reference catalog: https://www.sarna.net/wiki/Miniatures_-_Catalyst_Game_Labs
