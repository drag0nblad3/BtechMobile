# Isolated 30-chassis source trial batch

This branch contains 30 conservative anatomy edits to existing source recipes. It is NOT a completed multi-image reconstruction cycle. No files under production data/ or src/ were changed.

- Six batch JSON files store the complete candidate recipes, source paths, altered part names, edit parameters, audit results and three neutral-angle occupied-cell masks. The failed Warhammer central-torso trial is retained in batch_06; warhammer_alternative.json is its successful calf-contour alternative.
- batch_manifest.json collects the 30 chosen candidates, exact catalog photo leads and pre-existing unverified camera/stance estimates. Several photographed variant IDs differ from game models; confirm same edition and variant before measuring.
- contact_sheet.svg is generated from actual experimental source occupancy (front, quarter, side), not Godot screenshots.
- source_trial.js is the reproducible JavaScript source-cell trial and audit logic. It uses approximate coarse exclusive ownership and does not simulate runtime detail, rig deformation, or runtime repair. It is not an assertion that reported inherited faults are present in the shipped renderer.

Results: 30/30 candidates have changed cell occupancy (2,395 symmetric-difference cells across all models). Six show no faults in this standalone audit, 24 retain inherited fault signatures, and none introduce new fault signatures. Preserve the original model, muzzle, weapon and rig definitions. No in-engine validation, multi-photo annotation, independent stance recalibration, or new fidelity scoring has been performed here. Do not promote these trials to production.

Next acceptance step for each model: same-variant multi-angle image retrieval and part masks; camera and pose fit to landmarks; frozen-camera comparison; major independent part resculpt and physical reattachment; backed-contact and overlap tests; full in-engine validation. The existing camera estimates are not an approved reference registration.
