extends RefCounted
## The catalogue sheet's art (ui_kit_catalogue.gd): the shipped atlas's skins
## switched on, and the overlays, the dot and the locked faces the sheet draws
## from it itself.

const MANIFEST := "res://ui/art/kit.json"
## A face's state letter and the piece state it is baked in (section 5).
const FACES := {"N": "normal", "P": "pressed", "D": "disabled", "L": "locked"}
## The overlays section 3 lays over a state, each one piece in its normal
## state, drawn from the atlas when it has them: selected's rim, locked's
## lock mark, loading's spinner. Their skins are not switched on, since no
## material draws them as a face.
const OVERLAYS := {"S": "selected__rim__normal", "L": "locked__lock__normal", "Ld": "spinner__ring__normal"}
## K27's dot: the badge skin's second face, drawn as a sprite.
const DOT := "badge__dot__normal"

## The overlay pieces (OVERLAYS, DOT) the last lay_out() drew from the atlas.
static var drawn: Array[String] = []
## The shipped manifest's pieces, from art_on().
static var pieces: Dictionary = {}


## Returns every skin that has pieces in the shipped manifest, read from its
## files, and switches on each of them that has a face a material draws (its
## `box`, its parchment face, or one named after one of its materials): the
## sheet shows the baked faces (all skins ship off). A skin whose pieces are
## only overlays (OVERLAYS) stays off; the sheet draws those itself.
static func art_on() -> Array[String]:
	var on: Array[String] = []
	KitSkin.reset()
	pieces = {}
	if not KitSkin.use_files(MANIFEST):
		return on
	var kit: Variant = JSON.parse_string(FileAccess.get_file_as_string(MANIFEST))
	pieces = (kit as Dictionary).get("pieces", {})
	for key: String in pieces:
		var skin := key.get_slice("__", 0)
		if skin not in on:
			on.append(skin)
		var face := key.get_slice("__", 1)
		if face in ["box", "parchment"] or KitSkin.skin(face) == skin:
			KitSkin.switch(skin, true)
	return on


## Whether the shipped atlas holds a piece of `skin` in `state`.
static func _baked(skin: String, state: String) -> bool:
	for key: String in pieces:
		if key.begins_with(skin + "__") and key.ends_with("__" + state):
			return true
	return false


## Overlay piece `key` cut from the atlas (its high-contrast twin in high
## contrast), recorded in `drawn`; null when the atlas lacks it.
static func overlay(key: String) -> AtlasTexture:
	if not pieces.has(key):
		return null
	var p: Dictionary = pieces[key]
	var tex := KitSkin.texture(p)
	if tex == null:
		return null
	var out := AtlasTexture.new()
	out.atlas = tex
	out.region = Rect2(float(p["x"]), float(p["y"]), float(p["w"]), float(p["h"]))
	if key not in drawn:
		drawn.append(key)
	return out


## The atlas's selected rim over `target`, a 9-slice at the kit's scale.
static func rim(target: Control, over: Control) -> void:
	var tex := overlay(OVERLAYS["S"])
	var p: Dictionary = pieces[OVERLAYS["S"]]
	var slice: Dictionary = p["slice"] if p.get("slice") is Dictionary else {"l": 0, "t": 0, "r": 0, "b": 0}
	var nine := NinePatchRect.new()
	nine.mouse_filter = Control.MOUSE_FILTER_IGNORE
	nine.texture = tex
	nine.patch_margin_left = int(slice["l"])
	nine.patch_margin_top = int(slice["t"])
	nine.patch_margin_right = int(slice["r"])
	nine.patch_margin_bottom = int(slice["b"])
	var s := KitSkin.scale()
	var r := target.get_global_rect()
	over.add_child(nine)
	nine.position = r.position - over.get_global_rect().position
	nine.scale = Vector2(s, s)
	nine.size = r.size / s


## The locked face (section 5): the atlas's locked piece when the skin has
## art, else the locked material.
static func lock(target: Control) -> void:
	var box := RbBox.of(target)
	if box == null:
		target.modulate.a = 0.6
		return
	# Section 3's locked face is the locked material; a skin draws its own
	# only when its locked state is baked.
	var skin := KitSkin.skin(box.look)
	var p := KitSkin.piece(box.look, "locked", KitSkin.ground_of(target)) \
		if KitSkin.is_on(skin) and _baked(skin, "locked") else {}
	var face: Control = box.get("_face")
	if p.is_empty() or face == null:
		box.set_look("locked")
		return
	if face.draw.is_connected(Callable(box, "_draw_face")):
		face.draw.disconnect(Callable(box, "_draw_face"))
	face.draw.connect(_draw_piece.bind(box, face, p))
	face.queue_redraw()


## Draws atlas piece `p` on `face` over `box`'s rect, as RbBox draws a face.
static func _draw_piece(box: RbBox, face: Control, p: Dictionary) -> void:
	var tex := KitSkin.texture(p)
	if tex == null:
		return
	var s := KitSkin.scale()
	var reach: float = box.get("_reach")
	var r := box.quad().grow(-reach)
	var region := Rect2(float(p["x"]), float(p["y"]), float(p["w"]), float(p["h"]))
	face.draw_set_transform(r.position, 0.0, Vector2(s, s))
	var at := Rect2(Vector2.ZERO, r.size / s)
	var slice: Variant = p.get("slice")
	if slice is Dictionary:
		var sb := StyleBoxTexture.new()
		sb.texture = tex
		sb.region_rect = region
		sb.texture_margin_left = float(slice["l"])
		sb.texture_margin_top = float(slice["t"])
		sb.texture_margin_right = float(slice["r"])
		sb.texture_margin_bottom = float(slice["b"])
		face.draw_style_box(sb, at)
	else:
		face.draw_texture_rect_region(tex, at, region)
	face.draw_set_transform(Vector2.ZERO)


## K27's dot: the atlas's dot sprite at the kit's scale, else the code's.
static func dot() -> Control:
	var tex := overlay(DOT)
	if tex == null:
		return KitStatus.badge("")
	var sprite := TextureRect.new()
	sprite.texture = tex
	sprite.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	sprite.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	sprite.custom_minimum_size = tex.region.size * KitSkin.scale()
	sprite.size_flags_horizontal = Control.SIZE_SHRINK_BEGIN
	return sprite
