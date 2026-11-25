# Campaign command integration (#356)

The passing cartography, HQ and historical setup implementations (#354, #355,
#357) remain the source of truth. The competing branch's untyped empty
Array/Array[UnitDef] failure is removed; explicit typed force pools are used.
Retained enhancements: structured, paged after-action reports with region/day,
exact historical year, one-lance setup and Elite defender option, facilities
overlay, safe damage-aware AI repair, and preservation of formation membership
and fresh landing intelligence across regions. Existing geometry, fog-safe
motion, save defaults and published movement/repair rules are preserved.
No new supply penalties or tactical rule changes. See map-campaign-expansion.md.
