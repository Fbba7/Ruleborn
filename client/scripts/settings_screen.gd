class_name SettingsScreen
extends Control
## §20.6's settings and §20.8's accessibility set: the language, a volume
## each for music, effects and alerts, text size, high contrast, reduced
## motion, haptics, left-handed controls, the rehearsal pace and banners that
## stay. Every change is applied and saved as it is made; there is no Save
## button to forget. The screen is built again after each, so what it shows
## is always what the setting does.

## How far the title and a group's heading stand above the body text at
## large text (_grown): at 200% the body is 32 points, the title 48 and a
## heading 35.2, so the title stands well clear of a group's heading too.
const TITLE_LEAD := 1.5
const HEADING_LEAD := 1.1
## The title in the kit's hero slot (34 points), not the title one: the
## settings screen has no main action, so its title must be where the eye
## lands first in the squint (the gate's Hierarchy at 5fc97aac).
const TITLE_ROLE := "hero"
## A group's heading, in points at 100%: a step over the 16-point rows it
## heads and the 20-point heading slot, so the heading outranks its rows.
const HEADING_POINTS := 22.0
## A heading plate's side padding, in points.
const SECTION_PAD := 12.0
## The title plate's side padding, in points.
const HEAD_PAD := 16.0
## The title and heading plates' top and bottom padding, in points: none, as
## the display face's own line height leaves room over and under the words.
## The hero title and the 22-point headings are taller than the slots they
## replaced, and with the old padding they pushed the High contrast row off
## the first screen at 100% in pt_BR and German (AD's objection J).
const PLATE_TOP := 0.0
## The gear beside the title, in points, and how much larger it is at large
## text (key frame 05 at 200%).
const MARK_POINTS := 28.0
const MARK_LARGE := 1.4
## A school's coin on the shapes card: its 24-point shape and 4 points of
## rim a side.
const COIN_POINTS := 32.0
## The glass bar's padding round the back button.
const BAR_PAD := 10.0
## The base frame's width in points (tokens.json's px_per_point: 1080 pixels
## for a 360-point phone).
const SCREEN_POINTS := 360.0
## The text size in the kit's baked figures (KitNumerals, kit-spec.md
## section 3, T3: a cream-to-gold fill, an ink outline that scales with the
## figure and a hard drop), in this type role's slot: 22 points, a step below
## the 28-point title, and at large text the body's size, still under the
## title's 1.5 times it, so the title stays the screen's largest word.
const SIZE_ROLE := "number_m"
## The least gap kept under the list's last whole row for the scroll cue,
## in points.
const CUE_POINTS := 20.0
## Room under a row's edge for its skin's drop, in points.
const DROP_POINTS := 4.0
## The most of the list's window a snap to a row's edge may give up, in
## points; past it (a card taller than what is left, at large text) the
## window cuts through the row instead, above the cue.
const SNAP_POINTS := 48.0

## The tab a player last chose in this session (AD-R52): settings reopens on
## it. It lives in memory only, on the script, never in Settings' file, so a
## fresh start opens on "game".
static var last_tab := "game"

var volume_labels := {}
var text_label: Control
var list_scroll: ScrollContainer
## The cue that more rows lie below: the kit's chevron turned down, in the
## gap under the last whole row, shown while the list can scroll further.
var scroll_cue: Control
var snap_queued := false
## The tab on show: "game" (language, sound, play), "access" or "account".
var tab_shown := last_tab


func _ready() -> void:
	App.ready(self)
	Settings.restore()
	_build()


## Built again after each change, keeping where the list was scrolled to and
## which control had focus, so a player at large text or on a screen reader
## is not sent back to the top by every tap.
func _build() -> void:
	var scrolled := list_scroll.scroll_vertical if list_scroll != null else 0
	var focused := get_viewport().gui_get_focus_owner() if is_inside_tree() else null
	var focus_name := str(focused.get_meta("setting", "")) if focused != null else ""
	for c in get_children():
		remove_child(c)
		c.queue_free()
	_layout()
	if is_inside_tree():
		await get_tree().process_frame
		list_scroll.scroll_vertical = scrolled
		if focus_name != "":
			for b: Button in find_children("*", "Button", true, false):
				if b.get_meta("setting", "") == focus_name:
					b.grab_focus()


func _layout() -> void:
	var column := UI.frame(self)
	var list := UI.scroll(column)
	list_scroll = list.get_parent() as ScrollContainer
	# The title on its plate and the tabs head the list and scroll with it,
	# so nothing fixed sits in the screen's top third (§21.1).
	list.add_child(_head())
	list.add_child(_tabs())

	# The design's tabs: all three are built, the one chosen is shown.
	var game := VBoxContainer.new()
	var access := VBoxContainer.new()
	var account := VBoxContainer.new()
	for tab: VBoxContainer in [game, access, account]:
		tab.name = "Tab" + ["Game", "Access", "Account"][[game, access, account].find(tab)]
		tab.add_theme_constant_override("separation", UI.px(Tokens.number("size", "gap_points")))
	list.add_child(game)
	list.add_child(access)
	list.add_child(account)
	game.visible = tab_shown == "game"
	access.visible = tab_shown == "access"
	account.visible = tab_shown == "account"

	var lang := UI.action(Strings.t("LANGUAGE_" + Settings.locale), next_language, "plate")
	_tag(lang, "language")
	game.add_child(KitPanels.row("settingsandwellbeing/language", Strings.t("SETTINGS_LANGUAGE"), "", lang))
	game.add_child(_section("SCREEN_SETTINGS_SOUND"))
	var icons := {"music": "music", "effects": "effectsvolume", "alerts": "notifications"}
	var sound := UI.panel("card")
	sound.add_theme_stylebox_override("panel", UI.clear_box(12, 10))
	var volumes := VBoxContainer.new()
	volumes.add_theme_constant_override("separation", UI.px(12))
	sound.add_child(volumes)
	for bus: String in Settings.VOLUMES:
		var name := Strings.t("SETTINGS_" + bus.to_upper(), Settings.volume[bus])
		var l := _words(name)
		volume_labels[bus] = l
		volumes.add_child(_stepper(icons.get(bus, "music"), l, step.bind(bus, -1), step.bind(bus, 1),
			Strings.t("SETTINGS_QUIETER", name), Strings.t("SETTINGS_LOUDER", name), bus,
			float(Settings.volume[bus]) / float(Settings.VOLUME_STEPS)))
	game.add_child(sound)
	game.add_child(_section("SCREEN_SETTINGS_PLAY"))
	game.add_child(_toggle("slow_rehearsals", "SETTINGS_SLOW_REHEARSALS", "playtimereminder"))

	# Key frame 05: the text size and the schools' marks, then "Seeing and
	# comfort", each switch a whole row, dark (parchment in high contrast).
	access.add_child(_section("SCREEN_SETTINGS_ACCESS"))
	access.add_child(_text_card())
	access.add_child(_shapes())
	access.add_child(_section("SCREEN_SETTINGS_COMFORT"))
	for toggle: Array in [
			["high_contrast", "SETTINGS_CONTRAST", "accessibility"], ["reduced_motion", "SETTINGS_MOTION", "reducedmotion"],
			["haptics", "SETTINGS_HAPTICS", "haptics"], ["left_handed", "SETTINGS_LEFT_HANDED", "lefthanded"],
			["banners_stay", "SETTINGS_BANNERS_STAY", "notifications"],
			["camera_buttons", "SETTINGS_CAMERA_BUTTONS", "accessibility"]]:
		access.add_child(_toggle(toggle[0], toggle[1], toggle[2]))
	# And "Controls and pace": how long a hold is.
	access.add_child(_section("SCREEN_SETTINGS_PACE"))
	var hold_name := Strings.t("SETTINGS_HOLD", seconds(Settings.hold_ms))
	var holds := Settings.hold_steps()
	var pace := UI.panel("card")
	pace.add_theme_stylebox_override("panel", UI.clear_box(12, 10))
	pace.add_child(_stepper("remindertime", _words(hold_name), hold_step.bind(-1), hold_step.bind(1),
		Strings.t("SETTINGS_SHORTER", hold_name), Strings.t("SETTINGS_LONGER", hold_name), "hold",
		float(holds.find(Settings.hold_ms)) / float(maxi(holds.size() - 1, 1))))
	access.add_child(pace)

	# The account: signing in and out, devices, ways to sign in (auth_panel.gd,
	# T11), with the profile row and the privacy note under it (ScreenAccount).
	# Its group heading is the header pill, as every other group's on the
	# screen (board 5, I): the panel's own small gold caps label, which it
	# draws again each time it is rebuilt, is hidden here.
	account.add_child(_section("AUTH_TITLE"))
	var auth := AuthPanel.new()
	auth.child_entered_tree.connect(_hide_kicker)
	account.add_child(auth)
	account.add_child(ScreenAccount.profile_row())
	account.add_child(ScreenAccount.privacy_note())
	_cue(column)
	column.add_child(_bottom())


## The title on its plate: the settings mark and SETTINGS_TITLE in Marcellus.
func _head() -> Control:
	var plate := PanelContainer.new()
	plate.name = "Head"
	plate.add_theme_stylebox_override("panel", UI.clear_box(HEAD_PAD, PLATE_TOP))
	# The kit's lit feature card, its gold rim and its glow from the top left
	# lifting the title's ground above the night's value, where the dark name
	# plate sank into it (the gate's Hierarchy at 5fc97aac).
	UI.dress(plate, "card_gold")
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", UI.px(10))
	# The gear grows with the title at large text, as key frame 05's does at
	# 200% (board 5's note).
	var gear := MARK_POINTS * (MARK_LARGE if Settings.text_scale > KitLayout.SIDE_BY_SIDE_UP_TO else 1.0)
	var mark := Icons.view("generalui/settings", gear)
	mark.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	row.add_child(mark)
	var t := UI.label(Strings.t("SETTINGS_TITLE"), Tokens.type_role(TITLE_ROLE)["points"], true)
	t.name = "Title"
	t.theme_type_variation = "Title"
	t.horizontal_alignment = HORIZONTAL_ALIGNMENT_LEFT
	t.add_theme_stylebox_override("normal", StyleBoxEmpty.new())
	t.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_stroked(t, 2.0, 3.0)
	_grown(t, TITLE_LEAD)
	# A title wraps between words only, and a word too long for the row
	# ("Einstellungen" at 200%, board 5's objection E) shrinks the title until
	# it fits, rather than breaking: still well above a group's heading.
	t.autowrap_mode = TextServer.AUTOWRAP_WORD
	var room := UI.px(SCREEN_POINTS - 2.0 * (Tokens.number("size", "safe_side_points") + HEAD_PAD) - gear - 10.0
		- 2.0 * 2.0)
	var size := t.get_theme_font_size("font_size")
	var font := Tokens.font("title", 400)
	var longest := 0.0
	for word: String in t.text.split(" ", false):
		longest = maxf(longest, font.get_string_size(word, HORIZONTAL_ALIGNMENT_LEFT, -1, size).x)
	if longest > room:
		t.add_theme_font_size_override("font_size", floori(size * room / longest))
	row.add_child(t)
	plate.add_child(row)
	return plate


## A group's heading on its own dark plate (kit-spec.md 2.2: T0 with its
## drop on a dark ground). Set bare on the starfield, its ink outline was lost
## against the night and the gate read it as display type with no stroke; the
## plate gives the words a quiet ground. The plate hugs the words, so it reads
## as a label for the cards under it and not as one more card; a heading too
## long for one line at large text takes the row and wraps.
func _section(key: String) -> Control:
	var plate := PanelContainer.new()
	plate.name = "SectionPlate"
	plate.add_theme_stylebox_override("panel", UI.clear_box(SECTION_PAD, PLATE_TOP))
	UI.dress(plate, "plate_dark")
	var l := KitPanels.section(Strings.t(key))
	l.set_meta("points", HEADING_POINTS)
	_grown(l, HEADING_LEAD)
	# The kicker's gold top (ScreenParts.section's) and display type's ink
	# outline: in the squint the heading now outranks the cream rows under it
	# (the gate's Hierarchy at 5fc97aac).
	l.add_theme_color_override("font_color", Tokens.color("gold_top"))
	_stroked(l, 1.5, float(Tokens.type_role("heading")["drop"]))
	var font := Tokens.font("title", 400)
	var wide := font.get_string_size(l.text, HORIZONTAL_ALIGNMENT_LEFT, -1,
		l.get_theme_font_size("font_size")).x
	var room := UI.px(SCREEN_POINTS - 2.0 * (Tokens.number("size", "safe_side_points") + SECTION_PAD))
	if wide > room:
		plate.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	else:
		l.autowrap_mode = TextServer.AUTOWRAP_OFF
		plate.size_flags_horizontal = Control.SIZE_SHRINK_BEGIN
	plate.add_child(l)
	return plate


## AuthPanel opens with ScreenParts.section's caps label, its first child; the
## settings screen heads the account group with its own header pill instead.
func _hide_kicker(node: Node) -> void:
	if node.get_index() == 0 and node is Control:
		(node as Control).visible = false


## At large text UI.text_px lets a title or a heading grow only until the body
## text reaches it, so at 200% the title, the headings and the rows are all
## one size and the title no longer leads. Here they keep `ratio` times the
## body text's size, the words a step above the rows they head.
static func _grown(l: Label, ratio: float) -> Label:
	var body := UI.TEXT_POINTS * Settings.text_scale / 100.0
	var points := maxf(float(l.get_meta("points")), body * ratio)
	l.add_theme_font_size_override("font_size", UI.px(points))
	return l


## Display type's stroke on a label: an ink outline of `outline` points all
## round (§21.8) and a hard drop of `drop` points under it. Unlike
## KitNav.logo's, the drop has no outline of its own: an outlined drop needs
## one more glyph texture, so it costs each stroked label a draw call, which
## takes the settings screen past its draw-call budget. The drop does not
## count for contrast.
static func _stroked(l: Label, outline: float, drop: float, drop_colour := "drop") -> Label:
	ScreenKit.inked(l, outline)
	l.add_theme_color_override("font_shadow_color", Tokens.color(drop_colour))
	l.add_theme_constant_override("shadow_offset_x", 0)
	l.add_theme_constant_override("shadow_offset_y", UI.px(drop))
	return l


## The tabs as key frame 05 has them: one light strip, the open tab on the
## kit's chosen segment for parchment (dark leather, cream words), so gold
## stays the main actions' alone (§21.8). The strip is the kit's segment track
## for light segments, a deeper parchment a step under the cards' cream: the
## full cream strip outweighed the title in the squint (the gate's Hierarchy
## at 5fc97aac), and the night's dark track sank under the value steps. Where an icon and its word
## do not fit a third of the strip (large text, a long word), the closed tabs
## keep their icon alone and the open one its word alone, twice as wide; a
## screen reader still hears every word.
func _tabs() -> Control:
	var strip := PanelContainer.new()
	strip.name = "Segments"
	strip.add_theme_stylebox_override("panel", UI.clear_box(2, 2))
	UI.dress(strip, "seg_track_light")
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", UI.px(4))
	strip.add_child(row)
	var tabs := [["game", "SCREEN_SETTINGS_GAME", "generalui/settings"],
		["access", "SCREEN_SETTINGS_ACCESS", "settingsandwellbeing/accessibility"],
		["account", "SCREEN_SETTINGS_ACCOUNT", "settingsandwellbeing/account"]]
	var share := UI.px((KitNav.PHONE_POINTS - 2.0 * Tokens.number("size", "safe_side_points") - 4.0 - 8.0) / 3.0)
	var compact := Settings.text_scale > KitLayout.SIDE_BY_SIDE_UP_TO
	for tab: Array in tabs:
		var wide := UI.bold_font().get_string_size(Strings.t(tab[1]), HORIZONTAL_ALIGNMENT_LEFT, -1, UI.text_px(14)).x
		compact = compact or wide + UI.px(22 + 4 + 18 + 2) > share
	for tab: Array in tabs:
		var key: String = tab[0]
		var words := Strings.t(tab[1])
		var open := key == tab_shown
		var b := UI.action(words, func() -> void:
			tab_shown = key
			last_tab = key
			_build(), "seg_on_light" if open else "seg_light", words)
		b.add_theme_font_size_override("font_size", UI.text_px(14))
		b.set_meta("points", 14.0)
		b.set_meta("chosen", open)
		b.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		b.custom_minimum_size = Vector2(UI.px(UI.CONTROL_POINTS), UI.px(60 if compact else 48))
		b.autowrap_mode = TextServer.AUTOWRAP_OFF
		if compact and open:
			b.size_flags_stretch_ratio = 2.0
			b.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		else:
			b.icon = Icons.texture(tab[2])
			b.expand_icon = true
			b.add_theme_constant_override("icon_max_width", UI.px(32 if compact else 22))
			b.add_theme_constant_override("h_separation", UI.px(4))
			if compact:
				b.text = ""
				b.icon_alignment = HORIZONTAL_ALIGNMENT_CENTER
		row.add_child(_tag(b, "tab_" + key))
	return strip


## A setting's words on a card: bold, to the left, wrapping.
func _words(text: String) -> Label:
	var l := UI.label(text, 16, true)
	l.theme_type_variation = "BodyBold"
	l.horizontal_alignment = HORIZONTAL_ALIGNMENT_LEFT
	l.set_meta("bold", true)
	return l


## A setting with steps: its icon in a well, its words over a bar of where it
## stands, and − and + on leather at its end.
func _stepper(icon: String, words: Label, down: Callable, up: Callable, spoken_down: String, spoken_up: String,
		tag: String, share: float) -> Control:
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", UI.px(8))
	var well := PanelContainer.new()
	# At large text the well hugs its icon, so that a long word ("Hinweise")
	# keeps whole beside it.
	var hug := 4.0 if Settings.text_scale > KitLayout.SIDE_BY_SIDE_UP_TO else 7.0
	well.add_theme_stylebox_override("panel", UI.clear_box(hug, hug))
	UI.dress(well, "well")
	well.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	well.add_child(Icons.view("settingsandwellbeing/" + icon, 26))
	row.add_child(well)
	var mid := VBoxContainer.new()
	mid.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	mid.alignment = BoxContainer.ALIGNMENT_CENTER
	mid.add_theme_constant_override("separation", UI.px(6))
	mid.add_child(words)
	mid.add_child(KitBar.make(share, Color(), 8))
	row.add_child(mid)
	for b: Button in [_tag(UI.action("−", down, "leather", spoken_down), tag + "-"),
			_tag(UI.action("+", up, "leather", spoken_up), tag + "+")]:
		b.add_theme_font_size_override("font_size", UI.text_px(24))
		b.set_meta("points", 24.0)
		b.size_flags_vertical = Control.SIZE_SHRINK_CENTER
		row.add_child(b)
	return row


## A switch as a whole row: the setting's icon, its words (which say On or
## Off), and the switch at its end; the row is the one control. On parchment
## the rows were the heaviest slabs on the access tab in the squint, over the
## title and the gold As (audit 2, AD-R67), so they stand dark with cream
## words, as the law's sample does since the gate at 5fc97aac, and the gold As
## stay the tab's one lead. The dark is the kit's lesser action (`ghost`, the
## card's violet lifted two value steps): the dark plate itself sits at the
## night's value and fails value-steps (0.7 steps off the night; 2 needed). In
## high contrast the rows keep parchment: there the ghost's face darkens and
## stands 1.7 steps off the night between two rows at 200% text.
func _toggle(setting: String, words: String, icon: String) -> Control:
	var on := Settings.flag(setting)
	var look := "parchment" if Settings.high_contrast else "ghost"
	var b := UI.action(Strings.t(words + ("_ON" if on else "_OFF")), flip.bind(setting), look)
	b.alignment = HORIZONTAL_ALIGNMENT_LEFT
	# A row keeps its icon where its longest word, said either way, fits
	# beside it; where one does not ("verschwinden" at 200%, board 5's E),
	# the row drops the icon rather than break the word. The words and the
	# switch still say it all.
	var room := SCREEN_POINTS - 2.0 * Tokens.number("size", "safe_side_points") - 12.0 - (12 + 46 + 10) \
		- 28.0 - 10.0 - 4.0
	var longest := 0.0
	for said: String in [Strings.t(words + "_ON"), Strings.t(words + "_OFF")]:
		for word: String in said.split(" ", false):
			longest = maxf(longest, b.get_theme_font("font").get_string_size(word, HORIZONTAL_ALIGNMENT_LEFT, -1,
				b.get_theme_font_size("font_size")).x)
	if longest <= UI.px(room):
		b.icon = Icons.texture("settingsandwellbeing/" + icon)
	b.expand_icon = true
	b.add_theme_constant_override("icon_max_width", UI.px(28))
	b.add_theme_constant_override("h_separation", UI.px(10))
	b.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	b.custom_minimum_size = Vector2(0, UI.px(UI.CONTROL_POINTS))
	b.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	for state: String in ["normal", "hover", "pressed", "focus", "disabled"]:
		var box := UI.clear_box(12, 5)
		box.content_margin_right = UI.px(12 + 46 + 10)
		b.add_theme_stylebox_override(state, box)
	var sw := ScreenSwitch.make(on)
	# Off, the switch's own dark-plate track would vanish on a dark row
	# (tried and dropped at 5fc97aac), so there it takes the kit switch's off
	# track (KitSwitch: the glass chip with its gold line, the toggle's baked
	# track_off), and the parchment knob stands out on it.
	if not on and look == "ghost":
		UI.dress(sw, "chip", 999).skin_shape = "toggle/track_off"
	sw.anchor_left = 1.0
	sw.anchor_right = 1.0
	sw.anchor_top = 0.5
	sw.anchor_bottom = 0.5
	sw.offset_left = -UI.px(58)
	sw.offset_right = -UI.px(12)
	sw.offset_top = -UI.px(14)
	sw.offset_bottom = UI.px(14)
	b.add_child(sw)
	b.set_meta("on", on)
	return _tag(b, setting)


## §20.8's text size as key frame 05's card: a small A and a large A either
## side of the size in large figures over a dot a step, and a law's card in
## the size chosen, to read before leaving. The As are gold, as key frame 05
## has them (in high contrast too): the text size is the access tab's main
## action, and the one gold on the tab lets it lead in the squint (board 5, F).
func _text_card() -> Control:
	var steps := Settings.text_steps()
	var at := steps.find(Settings.text_scale)
	var size_name := Strings.t("SETTINGS_TEXT_SIZE", Settings.text_scale)
	var large := Settings.text_scale > KitLayout.SIDE_BY_SIDE_UP_TO
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", UI.px(8))
	var mid := VBoxContainer.new()
	mid.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	mid.alignment = BoxContainer.ALIGNMENT_CENTER
	mid.add_theme_constant_override("separation", UI.px(6))
	text_label = KitNumerals.make("%d%%" % Settings.text_scale, "num_gold", SIZE_ROLE, size_name)
	mid.add_child(text_label)
	var dots := HBoxContainer.new()
	dots.alignment = BoxContainer.ALIGNMENT_CENTER
	dots.add_theme_constant_override("separation", UI.px(5))
	for i: int in steps.size():
		var dot := Control.new()
		dot.mouse_filter = Control.MOUSE_FILTER_IGNORE
		dot.custom_minimum_size = Vector2(UI.px(22 if i == at else 9), UI.px(9))
		UI.dress(dot, "plate" if i == at else "plate_dark", 999)
		dots.add_child(dot)
	mid.add_child(dots)
	for side: Array in [[-1, 14.0, "text-", "SETTINGS_SMALLER"], [1, 26.0, "text+", "SETTINGS_LARGER"]]:
		var a := UI.action(Strings.t("SCREEN_TEXT_A"), text_step.bind(side[0]), "gold",
			Strings.t(side[3], size_name))
		a.add_theme_font_size_override("font_size", UI.text_px(side[1]))
		a.set_meta("points", side[1])
		a.custom_minimum_size = Vector2(UI.px(76 if large else 64), UI.px(76.0 if large else UI.CONTROL_POINTS))
		a.size_flags_vertical = Control.SIZE_SHRINK_CENTER
		_tag(a, side[2])
		row.add_child(a)
		if side[0] < 0:
			row.add_child(mid)
	var sample := PanelContainer.new()
	var room := UI.clear_box(10, 6)
	room.content_margin_bottom = UI.px(8)
	sample.add_theme_stylebox_override("panel", room)
	# The law's sample on the dark name plate, not parchment: it is prose to
	# read, not an action, and a cream card larger than the title drew the eye
	# first in the squint (the gate's Hierarchy at 5fc97aac).
	UI.dress(sample, "plate_dark")
	var line := HBoxContainer.new()
	line.add_theme_constant_override("separation", UI.px(8))
	var mark := Icons.view("laws/stillness", 32)
	mark.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	line.add_child(mark)
	var words := VBoxContainer.new()
	words.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	words.alignment = BoxContainer.ALIGNMENT_CENTER
	words.add_theme_constant_override("separation", 0)
	var heading := UI.label(Strings.term("LAW", "stillness"), Tokens.type_role("heading")["points"], true)
	heading.theme_type_variation = "Heading"
	heading.horizontal_alignment = HORIZONTAL_ALIGNMENT_LEFT
	words.add_child(heading)
	var rule := UI.label(Strings.t("LAW_RULE_STILLNESS"), Tokens.type_role("caption")["points"], true)
	rule.theme_type_variation = "Caption"
	rule.horizontal_alignment = HORIZONTAL_ALIGNMENT_LEFT
	# The whole law at every size: the sample shows the rule at the reader's
	# size, and the list scrolls (S3-R7).
	words.add_child(rule)
	line.add_child(words)
	sample.add_child(line)
	var card := PanelContainer.new()
	card.add_theme_stylebox_override("panel", UI.clear_box(10, 8))
	UI.dress(card, "card")
	var box := VBoxContainer.new()
	box.add_theme_constant_override("separation", UI.px(8))
	box.add_child(row)
	box.add_child(sample)
	card.add_child(box)
	return card


## The design's colour-blind card, as the game has it: no mode to choose,
## since each school keeps its own shape in every light (§20.8); the six
## marks on their coins with their names, and that said.
func _shapes() -> Control:
	var card := PanelContainer.new()
	card.add_theme_stylebox_override("panel", UI.clear_box(12, 6))
	UI.dress(card, "card")
	var box := VBoxContainer.new()
	box.add_theme_constant_override("separation", UI.px(4))
	card.add_child(box)
	var grid := GridContainer.new()
	grid.add_theme_constant_override("h_separation", UI.px(4))
	grid.add_theme_constant_override("v_separation", UI.px(4))
	var schools := ["time", "motion", "matter", "energy", "life", "spirit"]
	# Six a row where every name fits a sixth of the card; three where one
	# does not (Portuguese "Movimento", French "Mouvement") or at large text.
	var widest := 0.0
	for school: String in schools:
		widest = maxf(widest, UI.bold_font().get_string_size(Strings.t("SCHOOL_" + school.to_upper()),
			HORIZONTAL_ALIGNMENT_LEFT, -1, UI.text_px(13)).x)
	var room := UI.px(KitNav.PHONE_POINTS - 2.0 * Tokens.number("size", "safe_side_points") - 24.0)
	grid.columns = 6
	while grid.columns > 1 and widest * grid.columns + UI.px(4) * (grid.columns - 1) > room:
		grid.columns = 3 if grid.columns == 6 else (2 if grid.columns == 3 else 1)
	# Where a row holds fewer than six, each coin stands beside its name when
	# both fit the column, so the card keeps two short rows (board 5, C).
	var beside := grid.columns < 6 \
		and widest + UI.px(COIN_POINTS + 4.0) <= (room - UI.px(4) * (grid.columns - 1)) / grid.columns
	for school: String in schools:
		var col: BoxContainer
		if beside:
			col = HBoxContainer.new()
		else:
			col = VBoxContainer.new()
		col.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		# Stacked, a coin's rim is a point thinner and its name sits close
		# under it, so the first screen keeps a switch row (board 5, C).
		col.add_theme_constant_override("separation", UI.px(4) if beside else 0)
		var rim := 4.0 if beside or grid.columns == 6 else 3.0
		var coin := PanelContainer.new()
		coin.add_theme_stylebox_override("panel", UI.clear_box(rim, rim))
		UI.dress(coin, "window_" + school, 999)
		coin.size_flags_horizontal = Control.SIZE_SHRINK_BEGIN if beside else Control.SIZE_SHRINK_CENTER
		coin.size_flags_vertical = Control.SIZE_SHRINK_CENTER
		coin.add_child(Icons.view("schools/" + school, 24))
		col.add_child(coin)
		var name := UI.label(Strings.t("SCHOOL_" + school.to_upper()), Tokens.type_role("caption")["points"])
		name.theme_type_variation = "Caption"
		name.add_theme_font_override("font", UI.bold_font())
		name.set_meta("bold", true)
		if beside:
			name.horizontal_alignment = HORIZONTAL_ALIGNMENT_LEFT
			name.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
		col.add_child(name)
		grid.add_child(col)
	box.add_child(grid)
	var said := UI.label(Strings.t("SCREEN_SETTINGS_SHAPES"), Tokens.type_role("caption")["points"], true)
	said.theme_type_variation = "Caption"
	said.horizontal_alignment = HORIZONTAL_ALIGNMENT_LEFT
	box.add_child(said)
	return card


## The scroll cue (S3-R7): the list's window ends on a whole row's edge,
## never mid-card, and the rows' own chevron (the kit's "hud/next") turned
## down stands in the gap below it while more rows lie further down. No
## fade: a screen draws no chrome of its own (kit-spec.md section 6.3), and
## the kit has no scroll cue yet (S3-R8).
func _cue(column: VBoxContainer) -> void:
	var holder := Control.new()
	holder.name = "ListHolder"
	holder.size_flags_vertical = Control.SIZE_EXPAND_FILL
	holder.clip_contents = true
	column.remove_child(list_scroll)
	holder.add_child(list_scroll)
	list_scroll.set_anchors_preset(Control.PRESET_FULL_RECT)
	column.add_child(holder)
	var chevron := Icons.view("hud/next", 18)
	chevron.name = "ScrollCue"
	chevron.size = chevron.custom_minimum_size
	chevron.pivot_offset = chevron.size / 2.0
	chevron.rotation = PI / 2.0
	chevron.visible = false
	holder.add_child(chevron)
	scroll_cue = chevron
	var bar := list_scroll.get_v_scroll_bar()
	bar.changed.connect(_show_cue)
	bar.value_changed.connect(func(_v: float) -> void: _show_cue())
	holder.resized.connect(_queue_snap)
	var content := list_scroll.get_child(0) as Container
	content.sort_children.connect(_queue_snap)
	for tab: Node in content.get_children():
		if tab is Container:
			(tab as Container).sort_children.connect(_queue_snap)


## The rows take their places after the containers sort, so the window is
## snapped once a frame, after them.
func _queue_snap() -> void:
	if not snap_queued:
		snap_queued = true
		_snap_list.call_deferred()


## Shortens the list's window to the lowest whole row that leaves the cue
## its gap, so the frame ends on a row's edge; a list that fits keeps its
## whole window, and a row too tall for what is left is cut (SNAP_POINTS).
func _snap_list() -> void:
	snap_queued = false
	if list_scroll == null or not is_instance_valid(list_scroll):
		return
	var holder := list_scroll.get_parent() as Control
	var content := list_scroll.get_child(0) as Control
	var room := holder.size.y
	var foot := room
	if content.size.y > room + 1.0:
		var gap := UI.px(CUE_POINTS)
		var drop := UI.px(DROP_POINTS)
		var best := 0.0
		for c: Control in content.get_children():
			if not c.visible:
				continue
			var edges := [c.position.y + c.size.y]
			if c is VBoxContainer:
				for row: Control in c.get_children():
					if row.visible:
						edges.append(c.position.y + row.position.y + row.size.y)
			for edge: float in edges:
				if edge + drop <= room - gap and edge + drop > best:
					best = edge + drop
		foot = best if room - gap - best <= UI.px(SNAP_POINTS) else room - gap
	if absf(list_scroll.offset_bottom + (room - foot)) > 0.5:
		list_scroll.offset_bottom = -(room - foot)
	scroll_cue.position = Vector2((holder.size.x - scroll_cue.size.x) / 2.0,
		foot + (room - foot - scroll_cue.size.y) / 2.0)
	_show_cue()


func _show_cue() -> void:
	if scroll_cue == null or not is_instance_valid(scroll_cue):
		return
	var bar := list_scroll.get_v_scroll_bar()
	scroll_cue.visible = bar.value + bar.page < bar.max_value - 1.0


## Back home, on the glass bar at the foot of the screen. The button, not the
## glass, keeps the corners' lift (ScreenNav.CORNER_LIFT_POINTS), as a
## ScreenNav dock's buttons do: the bar's own foot counts toward it, so the
## first screen keeps both switch rows (board 5, C).
func _bottom() -> Control:
	var dock := MarginContainer.new()
	dock.name = "Dock"
	dock.add_theme_constant_override("margin_bottom", UI.px(ScreenNav.CORNER_LIFT_POINTS - BAR_PAD))
	var bar := PanelContainer.new()
	bar.add_theme_stylebox_override("panel", UI.clear_box(BAR_PAD, BAR_PAD))
	UI.dress(bar, "glass", 22)
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", UI.px(10))
	if Settings.left_handed:
		row.layout_direction = Control.LAYOUT_DIRECTION_RTL
	var back := UI.action(Strings.t("SCREEN_BACK"), func() -> void: App.services.router.go(&"home"), "parchment")
	back.icon = Icons.texture("generalui/back")
	back.expand_icon = true
	back.add_theme_constant_override("icon_max_width", UI.px(28))
	back.add_theme_constant_override("h_separation", UI.px(8))
	var wide := maxf(back.custom_minimum_size.x + UI.px(28 + 8 + 12), UI.px(120))
	back.custom_minimum_size = Vector2(wide, UI.px(UI.CONTROL_POINTS))
	for state: String in ["normal", "hover", "pressed", "focus", "disabled"]:
		var box := UI.clear_box(12, 0)
		box.content_margin_right = UI.px(18)
		box.content_margin_bottom = UI.px(2)
		back.add_theme_stylebox_override(state, box)
	back.set_meta("back", true)
	back.size_flags_horizontal = Control.SIZE_SHRINK_BEGIN
	row.add_child(back)
	bar.add_child(row)
	dock.add_child(bar)
	return dock


func _tag(b: Button, setting: String) -> Button:
	b.set_meta("setting", setting)
	return b


func step(bus: String, by: int) -> void:
	Settings.change(func() -> void: Settings.volume[bus] = clampi(Settings.volume[bus] + by, 0, Settings.VOLUME_STEPS))
	_build()


func text_step(by: int) -> void:
	var steps := Settings.text_steps()
	var i := clampi(steps.find(Settings.text_scale) + by, 0, steps.size() - 1)
	Settings.change(func() -> void: Settings.text_scale = int(steps[i]))
	_build()


## §20.8's hold time, one step shorter or longer.
func hold_step(by: int) -> void:
	var steps := Settings.hold_steps()
	var i := clampi(steps.find(Settings.hold_ms) + by, 0, steps.size() - 1)
	Settings.change(func() -> void: Settings.hold_ms = int(steps[i]))
	_build()


## Milliseconds as seconds in the language's numbers: 0.5, 1, 1.5.
static func seconds(ms: int) -> String:
	var tenths := roundi(ms / 100.0)
	if tenths % 10 == 0:
		return str(tenths / 10)
	return "%d%s%d" % [tenths / 10, Strings.t("NUMBER_DECIMAL"), tenths % 10]


func flip(setting: String) -> void:
	Settings.change(func() -> void: Settings.set_flag(setting, not Settings.flag(setting)))
	_build()


func next_language() -> void:
	var i := Strings.LOCALES.find(Settings.locale)
	Settings.change(func() -> void: Settings.locale = Strings.LOCALES[(i + 1) % Strings.LOCALES.size()])
	_build()
