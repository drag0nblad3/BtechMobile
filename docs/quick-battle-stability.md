# Quick battle camera stability

A reported Android crash after deployment and while moving the camera is not yet reproduced with an Android crash trace. The following mitigations address likely presentation risks and concrete input/geometry issues without changing combat rules.

* Retain nameplate panels and text labels, update their contents only on changes and keep smooth collision offsets. Reject nonfinite or offscreen projections before submitting canvas geometry.
* Ignore invalid camera gesture values and unmatched/canceled touches; keep yaw bounded.
* Android-only rendering budget: no MSAA, 85% 3D resolution (HUD remains full size), 1024 directional shadows; keep the Mobile renderer and the same model assets. Drop stale voxel mesh cache entries before the next Android battle. Intact voxel parts share their immutable original cells until damage creates a private replacement.
* CI exercises an actual Mobile Vulkan renderer under Mesa software rendering with a deterministic eight-unit QuickBattle and camera gestures, without taking a turn. This complements headless tests; it is not Android GPU verification.

If crashes persist, the decisive evidence is Android logcat around the exit (native signal, Vulkan device lost, low-memory kill, or script errors), the phone model, map theme/seed, and graphics settings.
