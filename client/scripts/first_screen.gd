class_name FirstScreen
extends Control
## The first launch (§20.1, §23.2, TD.26): one beat at a time — the title, the
## age check (its own screen), the protections the band sets, and the
## Keeper's name from the word lists — with no skip, resuming where a killed
## app left it. A welcome scene stands above the words: the Archivist and
## three ruleborn of different schools on one small floating island, the
## first look at the game's world (§21.1).

## Who greets a new Keeper: the Archivist among ruleborn of three schools.
const WELCOME := ["featherkin", "archivist", "bloomling", "lantern_wisp"]
## The realms floating behind them, of the other schools.
const FAR := ["time", "energy", "matter", "spirit", "life"]

var controller: FirstController
var body: VBoxContainer
var status_label: Label
var stage: StageHero
## The beat last drawn, so a new one is greeted.
var _beat := ""


func _ready() -> void:
	App.ready(self)
	controller = App.services.first_flow
	_build()
	App.services.store.changed.connect(_on_changed)
	_refresh()
	await controller.resume()


func _on_changed(slice: StringName) -> void:
	if slice == FirstState.FIRST and is_inside_tree():
		_refresh()


func _build() -> void:
	var column := UI.frame(self)
	StageHeroSkin.night(self)
	var safe := column.get_parent() as MarginContainer
	for side: String in ["margin_left", "margin_right", "margin_top"]:
		safe.add_theme_constant_override(side, 0)
	status_label = UI.status("info", "")
	stage = StageHero.new()
	stage.custom_minimum_size = Vector2(0, UI.px(Tokens.number("size", "safe_top_points") + 230.0))
	stage.size_flags_vertical = Control.SIZE_EXPAND_FILL
	stage.size_flags_stretch_ratio = 5.0
	column.add_child(stage)
	stage.headroom = 0.3
	stage.show_kinds(WELCOME, [], "island")
	stage.add_far_islands(FAR)
	# The game's name over the welcome scene as the design's logo: Lilita One
	# in cream and gold, edged in ink on a hard drop; the welcome under it in
	# Marcellus, and the line that says what the game is.
	var title := VBoxContainer.new()
	title.add_theme_constant_override("separation", UI.px(2))
	title.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var logo := UI.label(Strings.t("FIRST_LOGO").to_upper(), 54.0)
	logo.add_theme_font_override("font", StageHeroSkin.numbers_font())
	logo.add_theme_color_override("font_color", Color("#FFE08A"))
	logo.add_theme_color_override("font_outline_color", Color("#3A1E08"))
	logo.add_theme_constant_override("outline_size", UI.px(5))
	logo.add_theme_color_override("font_shadow_color", Color("#120C2A"))
	logo.add_theme_constant_override("shadow_offset_y", UI.px(4))
	logo.add_theme_constant_override("shadow_offset_x", 0)
	logo.add_theme_constant_override("shadow_outline_size", UI.px(5))
	logo.set_meta("own_ink", true)
	logo.set_meta("bold", true)
	title.add_child(logo)
	var welcome := UI.title(Strings.t("FIRST_TITLE"))
	StageHeroSkin.named(welcome)
	welcome.add_theme_font_size_override("font_size", UI.text_px(22))
	welcome.set_meta("points", 22.0)
	welcome.add_theme_color_override("font_color", Color("#FFF3CC"))
	welcome.add_theme_color_override("font_outline_color", Color("#120C2A"))
	welcome.add_theme_constant_override("outline_size", UI.px(3))
	welcome.set_meta("own_ink", true)
	welcome.custom_minimum_size.x = UI.px(200)
	title.add_child(welcome)
	var tagline := StageHeroKit.words(Strings.t("FIRST_TAGLINE"), 16.0, StageHeroSkin.LIGHT, true)
	tagline.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	tagline.custom_minimum_size.x = UI.px(200)
	title.add_child(tagline)
	var top := MarginContainer.new()
	top.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	top.mouse_filter = Control.MOUSE_FILTER_IGNORE
	top.add_theme_constant_override("margin_top", UI.px(Tokens.number("size", "safe_top_points")))
	stage.add_child(top)
	StageHeroSkin.on_stage(top, title, Control.PRESET_CENTER_TOP)
	column.add_child(RosterScreen.padded(StageHeroSkin.plate(status_label)))
	body = UI.scroll(column)


func _refresh() -> void:
	if not is_inside_tree():
		return
	var f := FirstPresenter.screen(App.services.store.get_slice(FirstState.FIRST), App.services.age.band())
	UI.set_status(status_label, "alarm" if f["error"] != "" else "info", f["error"])
	status_label.get_parent().get_parent().visible = status_label.text != ""
	# Each beat the player moves on to, the welcome party cheers them on.
	if _beat != "" and str(f["beat"]) != _beat:
		stage.cheer.call_deferred()
	_beat = str(f["beat"])
	# The title gives the scene the screen; later beats give their words room.
	stage.size_flags_stretch_ratio = 5.0 if _beat == "title" else 2.4
	for child in body.get_children():
		body.remove_child(child)
		child.queue_free()
	var box := VBoxContainer.new()
	box.add_theme_constant_override("separation", UI.px(8))
	box.set_meta("beat", f["beat"])
	for line: String in f["lines"]:
		# The title's own lines, the game's name and what it is, are the
		# logo and tagline over the scene already.
		if f["beat"] == "title":
			break
		var l := StageHeroKit.para(line, 17.0)
		l.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		box.add_child(l)
	if f["beat"] == "name":
		var name := StageHeroKit.para(str(f.get("name", "")), 28.0, Color("#FFE6A0"))
		StageHeroSkin.named(name)
		name.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		name.set_meta("name", true)
		box.add_child(name)
		var row := UI.row(-1.0, true)
		row.alignment = FlowContainer.ALIGNMENT_CENTER
		for part: String in ["adjective", "noun"]:
			var words := Strings.t("FIRST_NEXT_" + part.to_upper())
			var b := StageHeroMaterial.button(UI.button(words, controller.cycle.bind(part, 1)), "leather")
			b.set_meta("key", "cycle:" + part)
			row.add_child(b)
		box.add_child(row)
	if str(f["next"]) != "":
		var go := StageHeroMaterial.button(UI.button(f["next"], controller.keep_name if f["beat"] == "name"
			else controller.next, true), "gold", 18.0)
		go.add_theme_font_size_override("font_size", UI.text_px(20))
		go.set_meta("points", 20.0)
		go.custom_minimum_size.y = UI.px(56)
		go.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		go.set_meta("key", "next")
		box.add_child(go)
	# On the night under the scene, as the design's, no card round it.
	var m := RosterScreen.padded(box)
	m.add_theme_constant_override("margin_top", UI.px(6))
	m.add_theme_constant_override("margin_bottom", UI.px(10))
	body.add_child(m)
