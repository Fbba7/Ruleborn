class_name OverlayToolCard
extends RefCounted
## The terrain editor's card for the chosen feature, as the design's: its
## mark on a tile, the tool over its name, its points on a green disc, and
## what it does to movement and to a guard's sight, each on its own fact
## (§6.2's table, `content/terrain.json`, through the catalogue).


## The card for ground feature `id` (a `RulebornIsland.palette()` ground
## id), or null where the catalogue has no card for it.
static func ground(id: String, icon: String) -> Control:
	var key := id.to_upper()
	if id == "" or not Strings.rows().has("GROUND_MOVEMENT_" + key):
		return null
	var card := UI.panel("parchment")
	card.name = "ToolCard"
	var v := VBoxContainer.new()
	v.add_theme_constant_override("separation", UI.px(6))
	var head := HBoxContainer.new()
	head.add_theme_constant_override("separation", UI.px(10))
	var tile := UI.panel("fact")
	tile.add_child(Icons.view(icon, 34.0))
	tile.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	head.add_child(tile)
	var names := VBoxContainer.new()
	names.add_theme_constant_override("separation", 0)
	names.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	names.alignment = BoxContainer.ALIGNMENT_CENTER
	var kicker := UI.label(Strings.t("BUILDER_TOOL_GROUND").to_upper(), 13.0)
	kicker.add_theme_font_override("font", UI.bold_font())
	kicker.add_theme_color_override("font_color", Tokens.color("parchment_text_2"))
	kicker.set_meta("bold", true)
	kicker.horizontal_alignment = HORIZONTAL_ALIGNMENT_LEFT
	names.add_child(kicker)
	var title := UI.label(Strings.t("GROUND_" + key), 20.0, true)
	title.add_theme_font_override("font", Tokens.font("display"))
	title.add_theme_color_override("font_color", Tokens.color("parchment_ink"))
	title.set_meta("bold", true)
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_LEFT
	names.add_child(title)
	head.add_child(names)
	var cost := OverlayHud.badge(Strings.t("GROUND_POINTS_" + key), "green", 13.0)
	cost.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	head.add_child(cost)
	v.add_child(head)
	var facts := HBoxContainer.new()
	facts.add_theme_constant_override("separation", UI.px(6))
	for f: Array in [["BUILDER_CARD_MOVEMENT", "GROUND_MOVEMENT_"], ["BUILDER_CARD_SIGHT", "GROUND_SIGHT_"]]:
		facts.add_child(_fact(Strings.t(f[0]), Strings.t(f[1] + key)))
	v.add_child(facts)
	card.add_child(v)
	return card


static func _fact(kicker: String, words: String) -> Control:
	var p := UI.panel("fact")
	p.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	var v := VBoxContainer.new()
	v.add_theme_constant_override("separation", 0)
	var k := UI.label(kicker.to_upper(), 13.0)
	k.add_theme_font_override("font", UI.bold_font())
	k.add_theme_color_override("font_color", Tokens.color("parchment_text_2"))
	k.set_meta("bold", true)
	k.horizontal_alignment = HORIZONTAL_ALIGNMENT_LEFT
	v.add_child(k)
	var w := UI.label(words, 13.0, true)
	w.add_theme_color_override("font_color", Tokens.color("parchment_ink"))
	w.horizontal_alignment = HORIZONTAL_ALIGNMENT_LEFT
	v.add_child(w)
	p.add_child(v)
	return p
