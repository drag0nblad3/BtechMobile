# Commando plastic-miniature reconstruction — trial cycle

Target: CGL A Game of Armored Combat (2019), COM-2D. Sources: [four-angle gallery](https://jadedfalconer.com/Pages/1Light/commando), [unpainted miniature](https://business.walmart.com/ip/BattleTech-Commando/258199458), [painted example](https://merlinsminiatures.co.uk/products/battletech-commando-mech-battletech-catalyst-miniature-games-x17362). The two independently hand-marked front-quarter photographs are stored as pixel polygons and landmarks, not redistributed photographs. Rear gallery views informed the backpack but were not quantitatively registered.

V1: 23 physical parts; rounded low helmet, narrow waist, separate pelvis, shoulder/upper arm/forearm/hand geometry, chest and arm missile housings with subtractive bores, separately owned thighs/shins/feet. All eight hit locations retained. V2: fuller thighs and knee/calf contours, asymmetric forearm widths and lower torso front contour.

A source-cell audit (six-neighbor islands, exclusive cell ownership, backed 2x2 child-parent interfaces) found zero faults in both trials. V1: 3597 occupied cells. V2: 3722. These were evaluated by a separate JavaScript raster and audit implementation in the authoring session. The Python/Godot test suites were not run locally; use the existing experimental compiler and tests for further verification.

The scorecard records a perspective camera and independent shoulder/elbow and hip/knee poses fitted to manually marked landmarks on V1 and frozen across V2. Distances are grid units, scale and offsets in pixels; joint rotations in degrees. The four part-mask overlaps per view are preliminary visible-mask vs amodal-projection diagnostics, not a fidelity acceptance score. Pose residuals of up to 40 px and imperfect camera registration mean these are weak comparisons. V2 does not consistently improve the knee masks, so retain both candidates and do not install either on main.

Four-angle occupied-cell renders are under generated/. Neither is an in-engine Godot screenshot. No game recipe, rules, or unit design has been changed.
