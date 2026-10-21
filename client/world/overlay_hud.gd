class_name OverlayHud
extends RefCounted
## The game's interface over a realm, in the design's own parts (Screens v3,
## on T9's kit): a realm medallion with its level badge, glass pills that
## carry an icon and a count, round keys with a name plate under them, small
## badges, and sections of pills that tell a realm's facts as counts and
## icons rather than sentences (§21.8). Every part keeps its full sentence
## as what a screen reader says (§20.8), and every word sits on a material,
## so the kit's contrast checks hold.

## A pill's icon and words, in points.
const PILL_ICON := 20.0
const PILL_POINTS := 15.0
## A section's kicker.
const KICKER_POINTS := 13.0
## Each section's mark.
const SECTION_ICONS := {"island": "realmactions/terrain", "buildings": "realmactions/build",
	"workers": "realmactions/assignworker", "pylons": "buildings/lawpylon", "defence": "realmactions/defence",
	"laws": "hud/strain", "crew": "hud/crew", "loot": "heiststatus/lootbag"}
## The round keys: the main one larger, as the design's BUILD.
const KEY_POINTS := 60.0
const MAIN_KEY_POINTS := 76.0
## A key's name plate.
const PLATE_POINTS := 13.0

## Buildings with no icon of their own take their product's or role's.
const BUILDING_ICONS := {"star_well": "resources/starlight", "aether_spring": "resources/aether",
	"garden": "resources/essence", "hearth": "hud/home", "keepers_spire": "hud/star", "spire": "hud/star",
	"guardian_post": "crewroles/warden", "vault": "heiststatus/lootbag", "workshop": "realmactions/build"}


## A glass pill: an icon and a short count ("3/6", "12×12"), with `spoken`
## as its full sentence. `look` is any kit material.
static func pill(icon: String, text: String, spoken := "", look := "glass") -> PanelContainer:
	var p := PanelContainer.new()
	p.add_theme_stylebox_override("panel", UI.clear_box(7, 3))
	UI.dress(p, look, 99.0)
	p.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", UI.px(4))
	row.mouse_filter = Control.MOUSE_FILTER_IGNORE
	if icon != "" and Icons.has(icon):
		row.add_child(Icons.view(icon, PILL_ICON))
	if text != "":
		var l := UI.label(text, PILL_POINTS)
		l.theme_type_variation = "BodyBold"
		l.add_theme_font_override("font", Tokens.font("ui", 800, true))
		l.set_meta("bold", true)
		l.name = "Words"
		row.add_child(l)
	p.add_child(row)
	p.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	p.accessibility_name = spoken if spoken != "" else text
	p.tooltip_text = spoken
	p.set_meta("spoken", spoken if spoken != "" else text)
	return p


## A small round badge with a number, for a level or a count: gold unless
## `look` says otherwise.
static func badge(text: String, look := "gold_round", points := 14.0) -> PanelContainer:
	var p := PanelContainer.new()
	p.add_theme_stylebox_override("panel", UI.clear_box(5, 0))
	UI.dress(p, look, 99.0)
	p.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var l := UI.label(text, points)
	l.add_theme_font_override("font", Tokens.font("display"))
	l.name = "Words"
	p.add_child(l)
	p.custom_minimum_size = Vector2.ONE * UI.px(points + 10.0)
	p.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	p.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	return p


## The realm's medallion: its realm's mark on a gold round, its level on a
## badge at its foot (the design's 62-point medallion).
static func medallion(icon: String, level: int, points := 58.0) -> Control:
	var holder := Control.new()
	holder.custom_minimum_size = Vector2.ONE * UI.px(points)
	holder.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var disc := CenterContainer.new()
	UI.dress(disc, "gold_round", points / 2.0)
	disc.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	disc.mouse_filter = Control.MOUSE_FILTER_IGNORE
	disc.add_child(Icons.view(icon, points * 0.72))
	holder.add_child(disc)
	var b := badge(str(level), "badge", 13.0)
	b.position = Vector2(UI.px(points - 20.0), UI.px(points - 20.0))
	b.size = b.custom_minimum_size
	holder.add_child(b)
	holder.name = "Medallion"
	return holder


## A round key with an icon and its name on a plate beneath: `look` is
## "leather" for most and "gold_round" for the screen's main action.
static func key(icon: String, name: String, pressed: Callable, look := "leather", points := KEY_POINTS) -> Control:
	var column := VBoxContainer.new()
	column.add_theme_constant_override("separation", -UI.px(8))
	column.alignment = BoxContainer.ALIGNMENT_END
	column.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var b := UI.action("", pressed, look, name)
	b.custom_minimum_size = Vector2.ONE * UI.px(points)
	b.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	UI.dress(b, look, points / 2.0)
	var middle := CenterContainer.new()
	middle.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	middle.mouse_filter = Control.MOUSE_FILTER_IGNORE
	middle.add_child(Icons.view(icon, points * 0.62))
	b.add_child(middle)
	b.name = "Key"
	column.add_child(b)
	var plate := PanelContainer.new()
	plate.add_theme_stylebox_override("panel", UI.clear_box(7, 1))
	UI.dress(plate, "parchment", 8.0)
	plate.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	plate.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var l := UI.label(name, PLATE_POINTS)
	l.add_theme_font_override("font", UI.bold_font())
	l.set_meta("bold", true)
	plate.add_child(l)
	column.add_child(plate)
	column.set_meta("key", b)
	return column


## A section of a realm's facts: its kicker, then a flowing row of pills.
## The section is marked with `id` for the screens' tests.
static func section(id: String, kicker: String) -> VBoxContainer:
	var box := VBoxContainer.new()
	box.set_meta("section", id)
	box.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var row := HFlowContainer.new()
	row.add_theme_constant_override("h_separation", UI.px(5))
	row.add_theme_constant_override("v_separation", UI.px(5))
	row.mouse_filter = Control.MOUSE_FILTER_IGNORE
	row.name = "Pills"
	# A round mark leads the row, so a section of a few pills takes one
	# line; its kicker is what a screen reader says for it.
	var mark := PanelContainer.new()
	mark.add_theme_stylebox_override("panel", UI.clear_box(4, 4))
	UI.dress(mark, "leather", 99.0)
	mark.mouse_filter = Control.MOUSE_FILTER_IGNORE
	mark.add_child(Icons.view(SECTION_ICONS.get(id, "generalui/info"), PILL_ICON + 2.0))
	mark.accessibility_name = kicker
	mark.tooltip_text = kicker
	mark.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	mark.name = "Kicker"
	row.add_child(mark)
	box.accessibility_name = kicker
	box.add_child(row)
	return box


## The pills row of a `section`.
static func pills_of(section_box: VBoxContainer) -> HFlowContainer:
	return section_box.get_node("Pills") as HFlowContainer


## Pills for a card: each an icon and its words, in a flowing row.
static func row_of(pills: Array[Control]) -> HFlowContainer:
	var row := HFlowContainer.new()
	row.add_theme_constant_override("h_separation", UI.px(5))
	row.add_theme_constant_override("v_separation", UI.px(5))
	row.mouse_filter = Control.MOUSE_FILTER_IGNORE
	for p: Control in pills:
		row.add_child(p)
	return row


static func law_icon(law: String) -> String:
	return "laws/" + law.replace("_", "")


static func ground_icon(ground: String) -> String:
	return "terrain/" + ground.replace("_", "")


static func ward_icon(ward: String) -> String:
	return "wards/" + ward.replace("_", "")


static func realm_icon(realm_type: String) -> String:
	var id := realm_type.to_lower().replace(" ", "").replace("'", "")
	return "realms/theheart" if id == "heart" else "realms/" + id


static func building_icon(kind: String) -> String:
	if BUILDING_ICONS.has(kind):
		return BUILDING_ICONS[kind]
	var own := "buildings/" + kind.replace("_", "")
	return own if Icons.has(own) else "realmactions/build"
