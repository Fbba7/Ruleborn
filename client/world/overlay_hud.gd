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
## A resource bar's width.
const RESOURCE_WIDTH := 104.0
## A section's kicker.
const KICKER_POINTS := 13.0
## Each section's mark.
const SECTION_ICONS := {"island": "realmactions/terrain", "buildings": "realmactions/build",
	"workers": "realmactions/assignworker", "pylons": "buildings/lawpylon", "defence": "realmactions/defence",
	"laws": "hud/strain", "crew": "hud/crew", "loot": "heiststatus/lootbag", "layouts": "realmactions/terrain",
	"posts": "crewroles/warden", "naming": "generalui/new", "law": "buildings/lawpylon",
	"log": "planningactions/defencelog"}
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


## A resource bar (the design's capsules at the top right): its icon, its
## amount in the number face, on glass with a line of the resource's colour
## along its foot.
static func resource(icon: String, amount: String, spoken: String, colour: Color) -> PanelContainer:
	var p := pill(icon, amount, spoken)
	p.custom_minimum_size.x = UI.px(RESOURCE_WIDTH)
	var words := p.find_child("Words", true, false) as Label
	words.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	words.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	var row := words.get_parent() as HBoxContainer
	var stack := VBoxContainer.new()
	stack.add_theme_constant_override("separation", UI.px(1))
	stack.mouse_filter = Control.MOUSE_FILTER_IGNORE
	p.remove_child(row)
	stack.add_child(row)
	var line := ColorRect.new()
	line.color = colour
	line.mouse_filter = Control.MOUSE_FILTER_IGNORE
	line.custom_minimum_size.y = UI.px(2.5)
	line.name = "Line"
	stack.add_child(line)
	p.add_child(stack)
	return p


## A hero number in a gold ring (the design's "~3,300 VAULT"): the number
## in the display face over its kicker, on a round card.
static func ring(number: String, kicker: String, spoken: String, points := 108.0) -> Control:
	var disc := CenterContainer.new()
	disc.custom_minimum_size = Vector2.ONE * UI.px(points)
	disc.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	disc.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var box := UI.dress(disc, "card_selected", points / 2.0)
	box.chosen = true
	var words := VBoxContainer.new()
	words.add_theme_constant_override("separation", -UI.px(2))
	words.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var n := UI.label(number, 24.0)
	n.add_theme_font_override("font", Tokens.font("display"))
	n.name = "Number"
	words.add_child(n)
	var k := UI.label(kicker.to_upper(), KICKER_POINTS)
	k.theme_type_variation = "Kicker"
	words.add_child(k)
	disc.add_child(words)
	disc.accessibility_name = spoken
	disc.name = "Ring"
	return disc


## The screen's main action as a wide gold key with two lines: its name in
## capitals and what it costs or brings beneath (the design's PLAN THE
## HEIST · With Mo, Bramble, Hollow).
static func main_key(title: String, under: String, pressed: Callable, spoken: String) -> Button:
	var b := UI.action("", pressed, "gold", spoken)
	b.custom_minimum_size = Vector2(UI.px(250), UI.px(62))
	b.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	var lines := VBoxContainer.new()
	lines.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	lines.alignment = BoxContainer.ALIGNMENT_CENTER
	lines.add_theme_constant_override("separation", -UI.px(2))
	lines.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var t := UI.label(title.to_upper(), 18.0)
	t.theme_type_variation = "ButtonText"
	t.add_theme_font_override("font", Tokens.font("ui", 800, false, 2))
	t.set_meta("bold", true)
	t.name = "Title"
	lines.add_child(t)
	var u := UI.label(under, 13.0)
	u.theme_type_variation = "Caption"
	u.name = "Under"
	lines.add_child(u)
	b.add_child(lines)
	b.custom_minimum_size.y = maxf(b.custom_minimum_size.y, lines.get_combined_minimum_size().y + UI.px(12))
	return b


## A smaller pill for a pin over the world, where many stand close.
static func tag(icon: String, text: String, look := "glass") -> PanelContainer:
	var p := pill(icon, text, "", look)
	p.add_theme_stylebox_override("panel", UI.clear_box(4, 1))
	var mark := p.find_child("Icon", true, false) as Control
	if mark != null:
		mark.custom_minimum_size = Vector2.ONE * UI.px(15)
	var words := p.find_child("Words", true, false) as Label
	if words != null:
		words.add_theme_font_size_override("font_size", UI.text_px(13))
		words.set_meta("points", 13.0)
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
	holder.size_flags_vertical = Control.SIZE_SHRINK_CENTER
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


## A small round key back to where the player came from (48 points, the
## smallest a control may be), for the dock: §21.1 keeps every control in
## the thumb's reach, never at the top.
static func back_key(pressed: Callable) -> Control:
	var b := UI.action("", pressed, "leather", Strings.t("STAGE_BACK"))
	b.custom_minimum_size = Vector2.ONE * UI.px(48)
	UI.dress(b, "leather", 24.0)
	var middle := CenterContainer.new()
	middle.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	middle.mouse_filter = Control.MOUSE_FILTER_IGNORE
	middle.add_child(Icons.view("generalui/back", 26.0))
	b.add_child(middle)
	b.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	b.name = "Back"
	return b


## A screen's heading on glass: a small kicker over a title in the title
## face (the design's "SCOUT REPORT · Marta's universe").
static func heading(kicker: String, title: String) -> PanelContainer:
	var plate := UI.panel("glass")
	plate.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	var words := VBoxContainer.new()
	words.add_theme_constant_override("separation", 0)
	var k := UI.label(kicker.to_upper(), KICKER_POINTS)
	k.theme_type_variation = "Kicker"
	k.horizontal_alignment = HORIZONTAL_ALIGNMENT_LEFT
	k.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	k.name = "Kicker"
	words.add_child(k)
	var t := UI.title(title)
	t.add_theme_font_size_override("font_size", UI.text_px(20))
	t.set_meta("points", 20.0)
	t.horizontal_alignment = HORIZONTAL_ALIGNMENT_LEFT
	t.name = "Title"
	words.add_child(t)
	plate.add_child(words)
	return plate


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
	var icon: String = SECTION_ICONS.get(id, SECTION_ICONS.get(id.get_slice(":", 0), "generalui/info"))
	mark.add_child(Icons.view(icon, PILL_ICON + 2.0))
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
	return "wards/" + ward.replace("_", "").to_lower()


static func realm_icon(realm_type: String) -> String:
	var id := realm_type.to_lower().replace(" ", "").replace("'", "")
	return "realms/theheart" if id == "heart" else "realms/" + id


static func building_icon(kind: String) -> String:
	if BUILDING_ICONS.has(kind):
		return BUILDING_ICONS[kind]
	var own := "buildings/" + kind.replace("_", "")
	return own if Icons.has(own) else "realmactions/build"
