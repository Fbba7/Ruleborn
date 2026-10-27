class_name OverlayTop
extends RefCounted
## The top of a realm screen as the designs draw it (the scout report, the
## planner, curation, rehearsal): a round back key, then a small kicker over
## the screen's title, set straight over the world and inked so it reads on
## any island, with no plate behind. The back key stands at the top, where
## every design screen has it; it is not one of the controls a player
## reaches for often, which §21.1's thumb zone binds.


## The bar: the back key, then the kicker (named "Kicker") over the title
## (named "Title"), both wrapping at large text.
static func bar(back: Callable, kicker: String, title: String) -> HBoxContainer:
	var row := HBoxContainer.new()
	row.name = "TopBar"
	row.add_theme_constant_override("separation", UI.px(12))
	row.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var b := KitNav.back(back)
	b.set_meta("frequent", false)
	b.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	row.add_child(b)
	var words := VBoxContainer.new()
	words.add_theme_constant_override("separation", 0)
	words.alignment = BoxContainer.ALIGNMENT_CENTER
	words.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	words.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var k := UI.label(kicker.to_upper(), OverlayHud.KICKER_POINTS, true)
	k.theme_type_variation = "Kicker"
	k.horizontal_alignment = HORIZONTAL_ALIGNMENT_LEFT
	k.add_theme_color_override("font_color", Tokens.color("gold"))
	k.set_meta("bold", true)
	k.name = "Kicker"
	OverlayLanding.ink(k)
	words.add_child(k)
	var t := UI.title(title)
	t.add_theme_font_size_override("font_size", UI.text_px(22))
	t.set_meta("points", 22.0)
	t.horizontal_alignment = HORIZONTAL_ALIGNMENT_LEFT
	t.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	t.add_theme_stylebox_override("normal", StyleBoxEmpty.new())
	t.name = "Title"
	OverlayLanding.ink(t)
	words.add_child(t)
	row.add_child(words)
	return row


## The designs' segmented tabs (`KitNav.segmented`): each tab its words,
## `picked` called with the chosen one's index; each tab's button carries
## its id as "tab".
static func tabs(ids: Array, words: Array, chosen: String, picked: Callable) -> Control:
	var seg := KitNav.segmented(words, maxi(0, ids.find(chosen)), func(i: int) -> void: picked.call(ids[i]))
	var buttons := seg.find_children("*", "Button", true, false)
	for i: int in buttons.size():
		buttons[i].set_meta("tab", ids[i])
	return seg
