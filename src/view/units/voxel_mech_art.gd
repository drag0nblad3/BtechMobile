class_name VoxelMechArt
extends RefCounted
## Only the clean-slate reference designs are constructed here.
## The V2/V3 common-silhouette accumulators are intentionally NOT called.


static func torso(part: VoxelPart, shape: String) -> void:
	VoxelReferenceV4.torso(part, shape)
	part.seal()


static func arm(part: VoxelPart, _style: String, side: int,
		shape: String = "prototype") -> void:
	VoxelReferenceV4.arm(part, shape, side)
	part.seal(-2)


static func metatarsal(part: VoxelPart) -> void:
	VoxelReferenceV4.leg(part, "catapult", "metatarsal")
	part.seal()
