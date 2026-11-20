extends RefCounted
## Loads mech sprites using the file layout in docs/graphics/mech-sprite-standard.md:
##   res://art/mechs/<chassis>/core/facing_000.png ... facing_300.png
##   res://art/mechs/<chassis>/top/top_000.png
## Any missing file is replaced by a generated placeholder, so the game runs
## before final art exists.

const FACING_COUNT := 6
const VIEW_SIZE := Vector2i(128, 192)
const TOP_SIZE := Vector2i(160, 160)

# Palette zones from the approved Mad Dog visual target.
const ARMOR := Color(0.55, 0.56, 0.58)
const PANEL := Color(0.24, 0.25, 0.27)
const ACCENT := Color(0.62, 0.58, 0.42)
const STEEL := Color(0.33, 0.35, 0.38)
const GLASS := Color(0.62, 0.85, 0.85)


## Returns {"views": Array[Texture2D] (six directional views), "top": Texture2D}.
static func load_chassis(chassis: String) -> Dictionary:
	var views: Array[Texture2D] = []
	for i in FACING_COUNT:
		var path := "res://art/mechs/%s/core/facing_%03d.png" % [chassis, i * 60]
		if ResourceLoader.exists(path):
			views.append(load(path) as Texture2D)
		else:
			views.append(make_view_placeholder(i))
	var top_path := "res://art/mechs/%s/top/top_000.png" % chassis
	var top: Texture2D
	if ResourceLoader.exists(top_path):
		top = load(top_path) as Texture2D
	else:
		top = make_top_placeholder()
	return {"views": views, "top": top}


## A blocky stand-in for one directional view. View 0 is the camera directly in
## front of the mech; each step moves the camera 60 degrees clockwise around it.
## The teal cockpit shows which way the mech is pointing, and the white pips
## along the top count the view number (1 to 6) for easy debugging.
static func make_view_placeholder(view: int) -> Texture2D:
	var img := Image.create_empty(VIEW_SIZE.x, VIEW_SIZE.y, false, Image.FORMAT_RGBA8)
	img.fill(Color(0, 0, 0, 0))
	var cx := int(VIEW_SIZE.x / 2.0)
	var angle := deg_to_rad(view * 60.0)
	var side := sin(angle)
	var front := cos(angle)
	# Legs and feet.
	img.fill_rect(Rect2i(cx - 30, 110, 14, 72), STEEL)
	img.fill_rect(Rect2i(cx + 16, 110, 14, 72), STEEL)
	img.fill_rect(Rect2i(cx - 38, 180, 28, 10), PANEL)
	img.fill_rect(Rect2i(cx + 10, 180, 28, 10), PANEL)
	# Torso.
	img.fill_rect(Rect2i(cx - 34, 60, 68, 54), ARMOR)
	img.fill_rect(Rect2i(cx - 34, 100, 68, 14), PANEL)
	# Shoulder missile pods.
	img.fill_rect(Rect2i(cx - 50, 28, 28, 34), ACCENT)
	img.fill_rect(Rect2i(cx + 22, 28, 28, 34), ACCENT)
	# Cockpit nose, hidden when the camera is behind the mech.
	if front > -0.75:
		var nose_x := cx + roundi(side * 30.0)
		img.fill_rect(Rect2i(nose_x - 12, 68, 24, 18), GLASS)
	for p in view + 1:
		img.fill_rect(Rect2i(8 + p * 10, 4, 6, 6), Color.WHITE)
	return ImageTexture.create_from_image(img)


## Stand-in for the top-down view. The nose points to the top of the image,
## which is the mech's forward axis.
static func make_top_placeholder() -> Texture2D:
	var img := Image.create_empty(TOP_SIZE.x, TOP_SIZE.y, false, Image.FORMAT_RGBA8)
	img.fill(Color(0, 0, 0, 0))
	var cx := int(TOP_SIZE.x / 2.0)
	# Feet behind and below the torso.
	img.fill_rect(Rect2i(cx - 44, 104, 24, 40), PANEL)
	img.fill_rect(Rect2i(cx + 20, 104, 24, 40), PANEL)
	# Torso and missile pods.
	img.fill_rect(Rect2i(cx - 30, 56, 60, 58), ARMOR)
	img.fill_rect(Rect2i(cx - 62, 62, 30, 40), ACCENT)
	img.fill_rect(Rect2i(cx + 32, 62, 30, 40), ACCENT)
	# Wedge-shaped cockpit nose pointing forward.
	for y in range(16, 60):
		var half := int((y - 16) * 0.6)
		img.fill_rect(Rect2i(cx - half, y, half * 2 + 1, 1), GLASS)
	return ImageTexture.create_from_image(img)
