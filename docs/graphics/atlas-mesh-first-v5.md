# Atlas AS7-D — mesh-first destructible sculpt pilot

**This is an isolated experiment on PR #64. It changes the Atlas only.**
The previous V4 procedural model remains available as a comparison branch;
other five lab models are unchanged by this pilot.

## References and shape brief

Two distinct design traditions inform this pilot:

1. [AS7-D Atlas original Technical Readout illustration](https://www.mordel.net/tro.php?a=vt&id=72&ut=bm) — skull-scale helmet nested between heavy shoulders, wide chest, long articulated legs, heavy claw-like hands.
2. [Catalyst-era AS7-D miniature / official CGL miniature catalog](https://www.sarna.net/wiki/Miniatures_-_Catalyst_Game_Labs) and [AS7-D Master Unit List technical art](https://masterunitlist.battletech.com/units/atlas-as7-d) — faceted independent pauldrons, pectoral armor, framed weapon apertures, and high-leg to torso proportions.

Proportions and landmarks are individually selected **for this chassis**:
small raised-cheek death's-head, two differently angled chest plates,
separate high-backed shoulder pauldrons, compact torso AC/20, distinct
five-hole LRM arrangement, hip swivel with a visibly narrow waist,
longer upper-leg armor with independent kneecaps, slim exposed shin
pistons and four segmented fist fingers. The eyes are revised as
angular and recessed slits, not circular lights.

## Actual mesh-first pipeline

- `src/view/units/atlas_source_mesh.gd` contains the *original*
  **closed triangular 3D mesh components**, authored with explicit
  polygon stations and unique armor landmarks for the Atlas. Every
  component has an independent mesh, material role and an additive,
  subtractive or inset status. This is a mesh definition, **not**
  another collection of `VoxelPart.fill_box` decorations.
- `tools/export_atlas_source_obj.gd` saves **nine editable OBJ
  meshes**, including named `CUT_...` parts intended for Boolean
  operations in standard 3D modeling software.
- `src/view/units/atlas_mesh_voxelizer.gd` slices real triangle
  surfaces into 25mm / 37.5mm occupied cells. It uses scanline
  intersections along Z; applies Boolean cutter geometry for eye
  sockets and weapon bores; then adds inset lens/tube detail. The
  sparse voxel result is cached by part and resolution to avoid
  re-voxelizing for stress-test clones.
- Every Atlas part keeps its own independent copy of the cached
  damageable voxels. Armor roles, hit selection, joint failure,
  randomized damage, body detachment and core combat rules are
  unchanged.
- **Intact Atlas parts render the authored triangular mesh** with
  vertex colors. **After that part is hit**, its visible surface
  switches to the newly damaged physical voxel mesh. Other parts
  remain intact source meshes.

## Technical and artistic acceptance gates

- Confirm that the source can actually be exported as OBJ, and that
  all nine part meshes have hundreds of triangles from genuine 3D
  geometry.
- Godot headless count must confirm the Atlas is between
  **100,000 and 150,000 real occupied cells**.
- The paired eye sockets, AC/20 central bore and recessed missile
  mouths must be physical subtractive volumes, not painted dots.
- Two instantiated Atlases must reuse the triangle rasterization
  cache while retaining independent removable cells.
- The intact part's MeshInstance must reference the source ArrayMesh;
  after damage the instance must reference a rebuilt voxel surface.
- Capture real Godot 3/4, front and side views plus a damaged torso
  render and compare them to both sources. **Passing unit tests does
  not establish satisfactory reference likeness.**

## Known limitations

**This is a technical proof of concept, not an approved final Atlas.**
The source is manually specified polygon geometry written in Godot
rather than a full hand-sculpted Blender asset. This is more editable
and distinct from the voxel lattice, but the first previews still
depart substantially from the official Atlas proportions. Most
important: switching a hit part from the smooth source to a voxel
mesh makes that entire part look abruptly rough. A shipping version
would need a localized mesh/voxel boundary blend around craters,
and better artist-led head, chest and articulated limb geometry.
20- and 60-model mobile GPU/RAM/heat performance remain unmeasured.

No production asset replacement, branch merge or Android APK was
requested or performed by this pilot.
