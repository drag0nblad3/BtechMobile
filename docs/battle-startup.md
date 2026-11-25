# Staged battle startup

The force builder displays deployment progress before generating a map and
handing off the rules state. All battle entry points (skirmish, campaign,
training, saved battle) then use the same loading cover. Terrain layers,
structures and individual unit views yield between work items. Control
input and bot turns cannot begin while setup is in progress. A first-turn
save is still performed by the normal event path.

Invisible off-field views (including reinforcements) are registered without
materializing voxel geometry; their model is constructed when revealed.
No rules state, dice order or model resolution is changed.

Progress is based on completed stages, not a time estimate. Large individual
uncached voxel meshes and city geometry still run on the main thread, so a
single expensive stage can pause the animation. No threading assumptions or
unverified frame-rate promises are made. The normal headless path remains
synchronous for existing smoke tools; the dedicated staged loading smoke
explicitly exercises yielding and the startup readiness gate.

Run `godot --headless -s tools/battle_loading_smoke.gd` after import.
Device verification: start cold/warm skirmishes, city maps, saved battles and
campaign missions; watch for progress changes and correct first-turn state.


## Background geometry

The deployment worker begins before terrain construction and prepares one
unique visible chassis at a time: JSON, occupied cells, joint contact,
culled faces and greedy vertex/normal/color/UV arrays. It never touches
the scene tree, rendering resources, settings or live GameState. The
main thread joins a completed job, constructs the rig, uploads arrays,
and starts the next job before uploading the current result. The cache
remains bounded; a failed thread start falls back to synchronous assembly.
On scene teardown the outstanding job is joined. A single worker bounds
temporary memory and avoids saturating mobile CPU cores. Damage rebuilds
use the identical surface algorithm; no resolution reduction is needed.
