class_name KitSkin
extends RefCounted
## The kit's materials put on controls other tracks' skins built (the heist's
## `FxSkin`, the realm's `OverlaySheet`, the hero stage's `StageHeroSkin`):
## each skin keeps its own API and padding, and its surfaces are drawn by the
## kit's one box (`RbBox`), so every screen shares one look. A skin calls
## these instead of filling a StyleBoxFlat of its own.
##
## It also holds the switch per baked skin (kit-spec.md sections 6.7 and
## 8.2): each material maps onto one of the kit's 35 skins, and a skin
## switched on in `kit_families.json` draws its materials from the kit's
## atlas instead of the code-drawn box. A piece the atlas lacks falls back to
## the code-drawn box and is logged, so a screen is never blank. Beside the
## 35 stand the two overlay skins (`selected`, `spinner`), which no material
## maps onto: their pieces, and the other skins' marks, are `PARTS`.

## Which skins draw from the atlas: every one off until its art passes the
## gate.
const FAMILIES_FILE := "res://ui/kit_families.json"
## The kit's manifest (kit-spec.md section 6.6), beside its two atlases.
const MANIFEST := "res://ui/art/kit.json"

## kit-spec.md section 8.2: each skin and today's materials drawn in it, a
## trailing `*` standing for every material so named. A material named twice
## there takes the first row it is in (`card` the dark panel, not the new
## popup), `tag_success` is the tag's (its own shape unbaked, it is drawn as
## the tag's box), and `tab_bar` is the tab bar's, not the header's.
const SKINS := {
	"button_primary": ["gold", "gold_round", "plate_gold", "reward_gold"],
	"button_secondary": ["leather", "plate_leather"],
	"button_tertiary": ["ghost"],
	"button_danger": ["red", "banner_alarm", "tag_alarm"],
	"success": ["green", "green_muted", "banner_success", "reward_green"],
	"panel_dark": ["card", "card_selected", "card_gold", "album", "fact", "ability", "plate", "plate_dark",
		"banner_info"],
	"panel_glass": ["glass", "field_glass", "tag_dark"],
	"panel_parchment": ["parchment", "parchment_done", "sheet_parchment"],
	"well": ["well"],
	"sheet": ["sheet"],
	"popup": [],
	"frame_oak": ["frame_oak"],
	"frame_silver": ["frame_silver"],
	"frame_gold": ["frame_gold"],
	"frame_prismatic": ["frame_prismatic"],
	"header": ["name_plate"],
	"ribbon": ["chapter", "chapter_*"],
	"tab_bar": ["tab_bar"],
	"tab": ["tab", "tab_heist"],
	"tab_active": ["tab_active"],
	"segmented": ["seg", "seg_light", "seg_track", "seg_track_light"],
	"segmented_on": ["seg_on", "seg_on_light"],
	"chip": ["chip", "chip_light"],
	"chip_on": ["chip_on", "chip_on_light"],
	"bar_track": ["bar_track", "bar_track_light", "track", "tier_band"],
	"bar_fill": ["bar", "bar_line"],
	"disc": ["disc", "icon_disc", "level_disc", "gem", "round_sky", "round_violet"],
	"disc_school": ["portrait_*", "ring_*", "window_*"],
	"badge": ["badge"],
	"tag": ["tag", "tag_warn", "tag_violet", "tag_success", "price_chip", "island_label"],
	"tile": ["day_done", "day_today", "day_later", "week_*", "reward_sky", "reward_pink"],
	"locked": ["locked"],
	"pill": ["pill_gold_edge"],
	"toggle": [],
	"slider": [],
	"selected": [],
	"spinner": [],
}
## The overlay skins among `SKINS`: drawn over or beside a face, never as
## one (kit-spec.md section 5), so no material maps onto them.
const OVERLAYS := ["selected", "spinner"]
## The overlays and marks a face does not draw itself, each as [skin, shape]:
## the chosen one's rim over its card, the spinner's ring (turned in code),
## the lock over a locked card, the attention dot, a bar's tick, and a
## sheet's grab handle on its dark and its parchment face.
const PARTS := {
	"rim": ["selected", "rim"],
	"spinner": ["spinner", "ring"],
	"lock": ["locked", "lock"],
	"dot": ["badge", "dot"],
	"tick": ["bar_track", "tick"],
	"handle": ["sheet", "handle"],
	"handle_parchment": ["sheet", "handle_parchment"],
}
## The margin every piece keeps around its face for its ink line, in
## points; its lip lies below that (a 9-slice's bottom margin less its top).
const MARGIN_POINTS := 1.0
## The skins whose box keeps a wider margin for its shadow, in points as
## [left, top, right, bottom], the lip within the bottom (kit-spec.md
## section 8.2: the popup's 8 at the sides, 4 above, 12 and its 5 point lip
## below).
const MARGINS := {"popup": [8.0, 4.0, 8.0, 17.0]}
## The skins whose box is a hollow ring (a rank's frame): drawn over the
## material's code-drawn box, 4 points past its edge each side, in its
## normal state whatever the host's (as the selected rim is).
const RINGS := ["frame_oak", "frame_silver", "frame_gold", "frame_prismatic"]
const RING_REACH_POINTS := 4.0
## How far from square a host may be and still draw a sprite (a piece with
## no 9-slice), as a share of its shorter side (`fits`).
const ROUND_SLACK := 0.15
## The materials whose words do not hold on their skin's box: a light
## material (dark words) whose skin's box is dark, or a dark one whose box is
## light. Each draws only a shape baked for it (`<skin>__<material>__<state>`)
## and keeps its code-drawn box, unlogged, until it has one (kit-spec.md
## section 8.2). ui_kit_tests.gd holds this list to the atlas.
const OWN_SHAPE_ONLY := ["pill_gold_edge", "green_muted"]
## The backdrop's materials: gradients, not skins, always drawn in code.
const BACKDROP := ["night", "night_rays", "scrim"]
## The switches beside the 35 skins': the baked numerals (`num_<finish>_<glyph>`,
## kit-spec.md section 6.1), off until their art passes the gate; absent
## from kit_families.json means off.
const BESIDE := ["numerals"]

## A skin's surface names, as the kit's materials.
const SURFACES := {
	"glass": "glass",
	"card": "card",
	"parchment": "parchment",
	"leather": "leather",
	"gold": "gold",
	"alarm": "red",
	"red": "red",
	"night": "card",
	"ability": "ability",
	"hero": "card_gold",
}

## One turn of the spinner's ring.
const SPIN_SECONDS := 1.0

## The pieces a skin switched on fell back from, as "<piece>" (logged once).
static var missing: Array[String] = []

static var _on: Dictionary = {}
static var _kit: Dictionary = {}
static var _atlas: Texture2D = null
static var _atlas_hc: Texture2D = null
## Every page of the atlas from the second on (kit-spec.md section 6.6's
## `atlas.pages`), as [normal, high contrast] pairs.
static var _pages: Array = []
static var _read := false
## `cut`'s textures, by page, region and contrast mode.
static var _cuts: Dictionary = {}


## The material for a skin's surface `kind` (the kit's card for an unknown).
static func material(kind: String) -> String:
	return str(SURFACES.get(kind, kind if Tokens.materials().has(kind) else "card"))


## `box`'s content margins on a box that draws nothing, so the kit's box
## behind the control shows and the control keeps its padding.
static func clear(box: StyleBox) -> StyleBoxFlat:
	var out := UI.clear_box(0, 0)
	if box != null:
		for side: int in [SIDE_LEFT, SIDE_TOP, SIDE_RIGHT, SIDE_BOTTOM]:
			out.set_content_margin(side, box.get_content_margin(side))
	return out


## Panel `p` drawn in the kit's material for `kind`, with `radius_points`
## corners (the material's own when negative); its padding kept.
static func panel(p: PanelContainer, kind: String, radius_points := -1.0) -> RbBox:
	p.add_theme_stylebox_override("panel", clear(p.get_theme_stylebox("panel")))
	var box := UI.dress(p, material(kind), radius_points)
	p.set_meta("surface", kind)
	return box


## Button `b` drawn in the kit's material for `kind`, its words in the
## material's ink and §21.8's press; its padding kept.
static func button(b: Button, kind: String, radius_points := -1.0) -> RbBox:
	for state: String in ["normal", "hover", "pressed", "focus", "disabled"]:
		b.add_theme_stylebox_override(state, clear(b.get_theme_stylebox(state)))
	UI.set_look(b, material(kind))
	var box := RbBox.of(b)
	box.radius_points = radius_points
	box.set_look(box.look)
	if not b.has_meta("kit_press"):
		b.set_meta("kit_press", true)
		b.button_down.connect(Motion.press.bind(b, true))
		b.button_up.connect(Motion.press.bind(b, false))
	b.set_meta("surface", kind)
	UI.raise_words(b)
	return box


## The skin `material_name` is drawn in, or "" for the backdrop and a
## material the kit does not know.
static func skin(material_name: String) -> String:
	if material_name in BACKDROP:
		return ""
	for k: String in SKINS:
		for m: String in SKINS[k]:
			if m == material_name or (m.ends_with("*") and material_name.begins_with(m.trim_suffix("*"))):
				return k
	return ""


## Whether skin `name` draws from the atlas.
static func is_on(name: String) -> bool:
	_load()
	return bool(_on.get(name, false))


## The atlas piece for `material_name` in `state` ("normal", "pressed",
## "disabled" or "locked"), when its skin is switched on: the material's own
## shape first (`<skin>__<material>__<state>`), then the skin's
## (`<skin>__box__<state>`). On a parchment `ground` the skin's parchment
## face comes first (`<skin>__parchment__<state>`, kit-spec.md section 4.1);
## the tertiary has no other face there, its dark-ground face never drawn on
## parchment. Empty when the skin is off, and when the atlas lacks the piece,
## which is logged: the code-drawn box draws instead. A material of
## `OWN_SHAPE_ONLY` with no shape of its own keeps its code-drawn box,
## unlogged.
## A `shape` named by the use comes before them all (a bar's `alarm` fill).
## Named as `<skin>/<shape>` it is another skin's (the dialog's card as
## `popup/box`): that skin's piece when it is switched on, else the
## material's own as above.
static func piece(material_name: String, state := "normal", ground := "", shape_name := "") -> Dictionary:
	if shape_name.contains("/"):
		var other := face(shape_name.get_slice("/", 0), shape_name.get_slice("/", 1), state)
		if not other.is_empty():
			return other
		shape_name = ""
	var k := skin(material_name)
	if k == "" or not is_on(k) or k in RINGS:
		return {}
	var pieces: Dictionary = _kit.get("pieces", {})
	var shapes: Array = [material_name, "box"]
	if ground == "parchment":
		shapes = ["parchment"] if k == "button_tertiary" else ["parchment", material_name, "box"]
	var own_only := material_name in OWN_SHAPE_ONLY
	if own_only:
		shapes = [material_name]
	if shape_name != "":
		shapes.push_front(shape_name)
	for shape: String in shapes:
		var key := "%s__%s__%s" % [k, shape, state]
		if pieces.has(key) and texture(pieces[key]) != null:
			return pieces[key]
	if own_only:
		return {}
	var lost := "%s__%s__%s" % [k, shapes[0] if ground == "parchment" else material_name, state]
	if lost not in missing:
		missing.append(lost)
		push_warning("kit: no piece %s in %s; drawn by the code-drawn box" % [lost, MANIFEST])
	return {}


## Whether piece `p` can be the face of a host `size` pixels large. A
## 9-slice stretches to any host. A sprite (no `slice`: the disc, the gold
## round) is drawn whole, as wide as its host, so it fits only a host about
## as wide as it is tall (`ROUND_SLACK`). On any other (a bar's track, a
## pill, an oval button) it would run past the host's foot and over what
## lies below, and the code-drawn box draws the material instead.
static func fits(p: Dictionary, size: Vector2) -> bool:
	if p.is_empty() or p.get("slice") is Dictionary:
		return true
	return absf(size.x - size.y) <= ROUND_SLACK * minf(size.x, size.y)


## The untinted layer over `material_name`'s tinted piece in `state`
## (`<skin>__frame__<state>`, kit-spec.md section 5: the ink, gloss and
## outline of a school's neutral face), drawn at the same rect; empty when
## the skin is off or has none.
static func frame(material_name: String, state := "normal") -> Dictionary:
	var k := skin(material_name)
	if k == "" or not is_on(k):
		return {}
	var p: Variant = (_kit.get("pieces", {}) as Dictionary).get("%s__frame__%s" % [k, state])
	return p if p is Dictionary and texture(p) != null else {}


## The overlay or mark `name` (a key of `PARTS`) when its skin is switched
## on, else empty: the caller then draws it in code, as before. A piece the
## atlas lacks is logged.
static func part(name: String) -> Dictionary:
	var at: Array = PARTS.get(name, [])
	return {} if at.is_empty() else face(at[0], at[1])


## Skin `skin_name`'s piece `<skin>__<shape>__<state>` when the skin is
## switched on, else empty: for the faces no material maps onto (the
## toggle's track and knob, the slider's, the popup's box). A piece the atlas
## lacks is logged, and the caller draws in code.
static func face(skin_name: String, shape: String, state := "normal") -> Dictionary:
	if not is_on(skin_name):
		return {}
	var key := "%s__%s__%s" % [skin_name, shape, state]
	var p: Variant = (_kit.get("pieces", {}) as Dictionary).get(key)
	if p is Dictionary and texture(p) != null:
		return p
	if key not in missing:
		missing.append(key)
		push_warning("kit: no piece %s in %s; drawn in code" % [key, MANIFEST])
	return {}


## The rectangle of piece `p` in its page, in pixels.
static func region(p: Dictionary) -> Rect2:
	return Rect2(float(p["x"]), float(p["y"]), float(p["w"]), float(p["h"]))


## What piece `p` keeps outside its face, in the atlas's pixels as
## [left, top, right, bottom]: its ink line's margin with its lip below (a
## 9-slice's bottom margin less its top), or its skin's own `MARGINS`.
static func margins(p: Dictionary) -> Array:
	var px := float(px_per_point())
	var pieces: Dictionary = _kit.get("pieces", {})
	for skin_name: String in MARGINS:
		if pieces.get("%s__box__normal" % skin_name) == p:
			return (MARGINS[skin_name] as Array).map(func(v: float) -> float: return v * px)
	for skin_name: String in RINGS:
		if pieces.get("%s__box__normal" % skin_name) == p:
			return [RING_REACH_POINTS * px, RING_REACH_POINTS * px, RING_REACH_POINTS * px, RING_REACH_POINTS * px]
	var edge := MARGIN_POINTS * px
	var slice: Variant = p.get("slice")
	var lip := maxf(0.0, float(slice["b"]) - float(slice["t"])) if slice is Dictionary else 0.0
	return [edge, edge, edge, edge + lip]


## The ring drawn over `material_name`'s code-drawn box (a rank's frame);
## empty for any other material, while the skin is off, or with no piece.
static func frame_ring(material_name: String) -> Dictionary:
	var k := skin(material_name)
	return face(k, "box") if k in RINGS else {}


## A control that draws the mark `name` (a key of `PARTS`) from the atlas,
## `points` tall (its baked size when negative), in the current contrast
## mode; null while its skin is off or the piece is missing.
static func mark(name: String, points := -1.0) -> Control:
	var p := part(name)
	if p.is_empty():
		return null
	var c := Control.new()
	c.name = name.capitalize()
	c.mouse_filter = Control.MOUSE_FILTER_IGNORE
	c.focus_mode = Control.FOCUS_NONE
	var side := region(p).size * scale()
	if points > 0.0:
		side *= UI.px(points) / side.y
	c.custom_minimum_size = side
	c.size = side
	c.pivot_offset = side / 2.0
	c.draw.connect(func() -> void:
		var q := part(name)
		if not q.is_empty():
			c.draw_texture_rect_region(texture(q), Rect2(Vector2.ZERO, c.size), region(q)))
	return c


## Piece `p` as a texture of its own at the screen's scale, for the theme's
## icons and style boxes (a Slider draws its track and knob itself, at the
## texture's own size); kept per piece and contrast mode. Null for no piece.
static func cut(p: Dictionary) -> Texture2D:
	var tex: Texture2D = null if p.is_empty() else texture(p)
	if tex == null:
		return null
	var at := region(p)
	var key := "%s:%s:%s:%s" % [p.get("page", 1), at, scale(), Tokens.high_contrast]
	if not _cuts.has(key):
		var img := tex.get_image().get_region(Rect2i(at))
		if img.is_compressed():
			img.decompress()
		var side := Vector2i((at.size * scale()).round())
		img.resize(maxi(side.x, 1), maxi(side.y, 1), Image.INTERPOLATE_LANCZOS)
		_cuts[key] = ImageTexture.create_from_image(img)
	return _cuts[key]


## 9-slice piece `p` as a style box for the theme, as tall as the piece
## (its margin and lip within); null for no piece.
static func stylebox(p: Dictionary) -> StyleBoxTexture:
	var tex := cut(p)
	if tex == null or not p.get("slice") is Dictionary:
		return null
	var box := StyleBoxTexture.new()
	box.texture = tex
	var slice: Dictionary = p["slice"]
	box.texture_margin_left = roundf(float(slice["l"]) * scale())
	box.texture_margin_right = roundf(float(slice["r"]) * scale())
	box.texture_margin_top = roundf(float(slice["t"]) * scale())
	box.texture_margin_bottom = roundf(float(slice["b"]) * scale())
	box.content_margin_top = floorf(tex.get_height() / 2.0)
	box.content_margin_bottom = tex.get_height() - box.content_margin_top
	return box


## The spinner: its ring from the atlas, turned in code once every
## `SPIN_SECONDS` (held still under reduced motion: it is said aloud as
## loading either way); null while its skin is off.
static func spinner(points := -1.0) -> Control:
	var ring := mark("spinner", points)
	if ring == null or Settings.reduced_motion:
		return ring
	ring.ready.connect(func() -> void:
		var turn := ring.create_tween().set_loops()
		turn.tween_property(ring, "rotation", TAU, SPIN_SECONDS).from(0.0))
	return ring


## The ground a control at `node` sits on: "parchment" when the nearest
## surface around it (an ancestor dressed by the kit's box) is drawn in the
## parchment skin, else "".
static func ground_of(node: Node) -> String:
	var n := node.get_parent() if node != null else null
	while n != null:
		if n.has_meta("rb_material"):
			return "parchment" if skin(str(n.get_meta("rb_material"))) == "panel_parchment" else ""
		n = n.get_parent()
	return ""


## Numeral `name`'s piece (`num_<finish>_<glyph>`, kit-spec.md section
## 6.1) when the numerals' skin is switched on, else empty. A piece, or its
## page, the atlas lacks is logged and empty: the number is live text.
static func numeral(name: String) -> Dictionary:
	if not is_on("numerals"):
		return {}
	var pieces: Dictionary = _kit.get("pieces", {})
	if pieces.has(name) and texture(pieces[name]) != null:
		return pieces[name]
	if name not in missing:
		missing.append(name)
		push_warning("kit: no numeral %s in %s; drawn as live text" % [name, MANIFEST])
	return {}


## The atlas pieces are cut from, in the current contrast mode.
static func atlas() -> Texture2D:
	_load()
	return _atlas_hc if Tokens.high_contrast and _atlas_hc != null else _atlas


## The page `p` (a piece of the manifest) is cut from, in the current
## contrast mode: page 1 is `atlas()`, a later one its own pair of files.
static func texture(p: Dictionary) -> Texture2D:
	var page := int(p.get("page", 1))
	if page <= 1:
		return atlas()
	if page - 2 >= _pages.size():
		return null
	var pair: Array = _pages[page - 2]
	return pair[1] if Tokens.high_contrast and pair[1] != null else pair[0]


## The atlas's pixels per point.
static func px_per_point() -> int:
	_load()
	return int(_kit.get("px_per_point", 6))


## Pixels on screen per pixel of a piece (kit-spec.md section 6.6).
static func scale() -> float:
	_load()
	return UI.PX_PER_POINT / float(_kit.get("px_per_point", 6))


## Switches skin `name` on or off for this run (the tests' switch; the
## shipped one is the file).
static func switch(name: String, on: bool) -> void:
	_load()
	_on[name] = on


## Uses `manifest` and its atlases instead of the files (the tests' kit);
## `pages` holds the pages from the second on, as [normal, high contrast].
static func use(manifest: Dictionary, normal: Texture2D, high_contrast: Texture2D, pages := []) -> void:
	_load()
	_kit = manifest
	_atlas = normal
	_atlas_hc = high_contrast
	_pages = pages
	_cuts.clear()


## Uses the manifest at `path` and its atlas pages beside it, read straight
## from their files (a baked fixture, which the project does not import).
## False when the manifest is not a JSON object.
static func use_files(path: String) -> bool:
	_load()
	var kit: Variant = JSON.parse_string(FileAccess.get_file_as_string(path))
	if not kit is Dictionary:
		return false
	var pairs := _page_files(kit, path.get_base_dir(), func(file: String) -> Texture2D:
		var img: Image = Image.load_from_file(file) if FileAccess.file_exists(file) else null
		return ImageTexture.create_from_image(img) if img != null else null)
	use(kit, pairs[0][0], pairs[0][1], pairs.slice(1))
	return true


## Reads the files again: every switch as shipped, no piece logged.
static func reset() -> void:
	_read = false
	_on = {}
	_kit = {}
	_atlas = null
	_atlas_hc = null
	_pages = []
	_cuts.clear()
	missing.clear()
	_load()


static func _load() -> void:
	if _read:
		return
	_read = true
	var parsed: Variant = JSON.parse_string(FileAccess.get_file_as_string(FAMILIES_FILE))
	assert(parsed is Dictionary, "%s is not a JSON object" % FAMILIES_FILE)
	_on = parsed if parsed is Dictionary else {}
	if not _on.values().has(true) or not FileAccess.file_exists(MANIFEST):
		return
	var kit: Variant = JSON.parse_string(FileAccess.get_file_as_string(MANIFEST))
	if not kit is Dictionary:
		push_warning("kit: %s is not a JSON object; every skin drawn in code" % MANIFEST)
		return
	_kit = kit
	var pairs := _page_files(_kit, MANIFEST.get_base_dir(), func(file: String) -> Texture2D:
		return load(file) if ResourceLoader.exists(file) else null)
	_atlas = pairs[0][0]
	_atlas_hc = pairs[0][1]
	_pages = pairs.slice(1)


## Every page of manifest `kit` in `dir`, as [normal, high contrast]
## textures read by `read`: `atlas.pages` when the bake wrote it (more than
## one page), else the one page `atlas` names.
static func _page_files(kit: Dictionary, dir: String, read: Callable) -> Array:
	var files: Dictionary = kit.get("atlas", {})
	var pages: Array = files.get("pages", [files])
	var out := []
	for page: Variant in pages:
		var names: Dictionary = page if page is Dictionary else {}
		var pair := []
		for which: String in ["normal", "high_contrast"]:
			pair.append(read.call("%s/%s" % [dir, names.get(which, "")]))
		out.append(pair)
	return out
