# Major anatomy reconstruction round 2 — King Crab and Mad Dog

King Crab: retraced the two previously used verified plastic photographs, now separating the two fins rather than tracing their intervening gap. Mad Dog: two newly inspected individual photographs of the Clan Heavy Striker Star plastic sculpt. URLs, manually estimated polygons and landmark coordinates are in annotations.json. Expanded camera elevation search to -55..45 degrees; camera and arm/leg pose then fixed for each candidate comparison. Two major alternatives per chassis were rasterized, evaluated and structurally audited; first alternative retained for experimental follow-up in both cases. Prior controls unchanged.

| Chassis / view | Control | Candidate |
|---|---:|---:|
| King Crab / elevated | 36.86% | 38.30% |
| King Crab / quarter | 36.13% | 37.89% |
| Mad Dog / quarter | 40.53% | 41.41% |
| Mad Dog / near frontal | 36.61% | 38.82% |

King Crab: rebuilt curved sloping carapace and recessed lower head, segmented shoulder/arm links, broad claw housings, feet, paired dorsal fins, asymmetric dorsal weapon housings. Removed two detached dorsal-gun cells and recut obstructed muzzle sample cells. 23 parts, 15,420 cells, zero neutral audit faults. Mad Dog: replaced the central descending narrow beak, sloped launcher banks, arm links, asymmetric-length twin gun tubes and toe plates. 21 parts, 10,441 cells, zero neutral audit faults. 

All 62 three-cell axial samples are clear, but samples may lie ahead of the sloped housing surface and do not certify continuous weapon bores. Dorsal weapon configuration and variant mapping need confirmation. King Crab's scores are not comparable to round 1's scores because the masks and camera search changed. Rigid landmark RMS 4.74–14.98 px; limb landmark RMS reaches 36.42 px, so this is weak provisional evidence rather than proof of likeness. True rear and side views still missing. 

[King Crab neutral before/after](king_crab_before_after.svg) • [Mad Dog neutral before/after](mad_dog_before_after.svg). Each contains front, quarter and side source projections, not game renders. Final candidate specs and per-view region scores in *_final.json. Full alternatives and registration data in *_trials.json. Production assets, rules, rigs and APK untouched; no Godot runtime tests. 45 of the recent 48 chassis still await individual photo comparisons; King Crab and Mad Dog still need stronger calibration and refinement.