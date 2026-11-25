# Promotion of the remaining-149 experimental sculpt selections

This is a production geometry transfer, not a merge of experimental previews.
The 149 source candidates in PR #314 were replayed against their exact main
blob SHAs; the separately selected photo/structural deltas from PR #316 were
applied only when the input count and final strict source diagnostic matched.
The per-chassis manifest is `experimental-sculpt-promotion-20261124.json`.

- 134 source sculpts materialized, with exact per-part occupied-cell/material
  verification against the selected neutral diagnostic.
- 86 detailed recipes already reference the modified source; 34 independently
  authored detailed recipes had matching coarse geometry and were transferred
  without discarding their fine-grid details. 14 detailed recipes differ and
  were deliberately left intact pending a separate reconciliation.
- 35 selected follow-up photo/structural deltas included.
- 15 candidates held because physical, backed joint, part-local or sampled
  weapon opening diagnostics did not all pass.

The original authored lofts, rig metadata, muzzle and jet coordinates remain
present. Selected native loft changes are kept, then exact inclusive-box
residuals are applied in mirror dependency order to reproduce the selected
source occupancy. The former generic heuristic art pass is not rerun over
these already selected explicit geometries.

The verification is a neutral coarse source-cell replay, not a Godot runtime
or photographic fidelity certification. Some photo references are unofficial
or single-view proxies. No unit designs, rules, animation pivots or APK are
modified. Historical experimental branches remain available for further
reconstruction and review.
