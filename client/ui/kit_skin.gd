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
## the code-drawn box and is logged, so a screen is never blank.

## Which skins draw from the atlas: every one off until its art passes the
## gate.
const FAMILIES_FILE := "res://ui/kit_families.json"
## The kit's manifest (kit-spec.md section 6.6), beside its two atlases.
const MANIFEST := "res://ui/art/kit.json"

## kit-spec.md section 8.2: each skin and today's materials drawn in it, a
## trailing `*` standing for every material so named. A material named twice
## there takes the first row it is in (`card` the dark panel, not the new
## popup; `tag_success` the success skin), and `tab_bar` is the tab bar's,
## not the header's.
const SKINS := {
	"button_primary": ["gold", "gold_round", "plate_gold", "reward_gold"],
	"button_secondary": ["leather", "plate_leather"],
	"button_tertiary": ["ghost"],
	"button_danger": ["red", "banner_alarm", "tag_alarm"],
	"success": ["green", "green_muted", "banner_success", "tag_success", "reward_green"],
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
	"tag": ["tag", "tag_warn", "tag_violet", "price_chip", "island_label"],
	"tile": ["day_done", "day_today", "day_later", "week_*", "reward_sky", "reward_pink"],
	"locked": ["locked"],
	"pill": ["pill_gold_edge"],
	"toggle": [],
	"slider": [],
}
## The backdrop's materials: gradients, not skins, always drawn in code.
const BACKDROP := ["night", "night_rays", "scrim"]

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

## The pieces a skin switched on fell back from, as "<piece>" (logged once).
static var missing: Array[String] = []

static var _on: Dictionary = {}
static var _kit: Dictionary = {}
static var _atlas: Texture2D = null
static var _atlas_hc: Texture2D = null
static var _read := false


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
## (`<skin>__box__<state>`). Empty when the skin is off, and when the atlas
## lacks the piece, which is logged: the code-drawn box draws instead.
static func piece(material_name: String, state := "normal") -> Dictionary:
	var k := skin(material_name)
	if k == "" or not is_on(k):
		return {}
	var pieces: Dictionary = _kit.get("pieces", {})
	for shape: String in [material_name, "box"]:
		var key := "%s__%s__%s" % [k, shape, state]
		if pieces.has(key) and atlas() != null:
			return pieces[key]
	var lost := "%s__%s__%s" % [k, material_name, state]
	if lost not in missing:
		missing.append(lost)
		push_warning("kit: no piece %s in %s; drawn by the code-drawn box" % [lost, MANIFEST])
	return {}


## The atlas pieces are cut from, in the current contrast mode.
static func atlas() -> Texture2D:
	_load()
	return _atlas_hc if Tokens.high_contrast and _atlas_hc != null else _atlas


## Pixels on screen per pixel of a piece (kit-spec.md section 6.6).
static func scale() -> float:
	_load()
	return UI.PX_PER_POINT / float(_kit.get("px_per_point", 6))


## Switches skin `name` on or off for this run (the tests' switch; the
## shipped one is the file).
static func switch(name: String, on: bool) -> void:
	_load()
	_on[name] = on


## Uses `manifest` and its atlases instead of the files (the tests' kit).
static func use(manifest: Dictionary, normal: Texture2D, high_contrast: Texture2D) -> void:
	_load()
	_kit = manifest
	_atlas = normal
	_atlas_hc = high_contrast


## Reads the files again: every switch as shipped, no piece logged.
static func reset() -> void:
	_read = false
	_on = {}
	_kit = {}
	_atlas = null
	_atlas_hc = null
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
	var files: Dictionary = _kit.get("atlas", {})
	var dir := MANIFEST.get_base_dir()
	for which: String in ["normal", "high_contrast"]:
		var path := "%s/%s" % [dir, files.get(which, "")]
		var tex: Texture2D = load(path) if ResourceLoader.exists(path) else null
		if which == "normal":
			_atlas = tex
		else:
			_atlas_hc = tex
