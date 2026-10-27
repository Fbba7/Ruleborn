class_name LabScreen
extends Control
## The Resonance Lab (§8.6, §10.2, §23.2, "Run experiments"): the Lab's
## level and Aether and the next experiment's price and time; each chamber,
## running with its time left and any paradox warning, or idle with its
## spheres — a tap moves a sphere to the next restored law — and the button
## that runs it, which spends on a second tap; each chamber's last result
## and hint; from Lab level 3 the third sphere, which names a chord free; and
## what has been found, hinted and remains by school.

var controller: LabController
var body: VBoxContainer
var header_label: Label
var status_label: Label
## The run tapped once, by its key: the next tap on it spends.
var confirm := ""
var clock: Callable = func() -> int: return int(Time.get_unix_time_from_system() * 1000)
var _aether: PanelContainer


func _ready() -> void:
	App.ready(self)
	controller = App.services.lab_flow
	_build()
	App.services.store.changed.connect(_on_changed)
	_refresh()
	await controller.load_lab()


func _on_changed(slice: StringName) -> void:
	if slice == LabState.LAB and is_inside_tree():
		_refresh()


func _build() -> void:
	var column := ScreenKit.frame(self)
	_aether = ScreenParts.resource("aether", "")
	column.add_child(ScreenNav.header(Strings.t("LAB_TITLE"), _aether))
	header_label = ScreenKit.text("", 13.0, "body", "card", true, true)
	header_label.visible = false
	column.add_child(header_label)
	status_label = UI.status("info", "")
	column.add_child(ScreenParts.status_plate(status_label))
	body = UI.scroll(column)
	column.add_child(ScreenNav.hub("laws", &"lab"))
	column.add_child(ScreenNav.bar("laws"))


func _refresh() -> void:
	if not is_inside_tree():
		return
	var focused := get_viewport().gui_get_focus_owner()
	var focus_item := str(focused.get_meta("item", "")) if focused != null else ""
	var l := LabPresenter.screen(App.services.store.get_slice(LabState.LAB), clock.call())
	if l["error"] != "":
		UI.set_status(status_label, "alarm", l["error"])
	elif l["said"] != "":
		UI.set_status(status_label, "success", l["said"])
	elif l["busy"] != "" or not l["ready"]:
		UI.set_status(status_label, "info", Strings.t("COMMON_LOADING"))
	else:
		UI.set_status(status_label, "info", "")
	ScreenParts.show_status(status_label)
	header_label.text = l.get("header", "")
	for child in body.get_children():
		body.remove_child(child)
		child.queue_free()
	if not l["ready"]:
		if l["error"] != "":
			(status_label.get_parent() as Control).visible = false
			body.add_child(ScreenParts.empty("screens", "resonancelab", l["error"], controller.load_lab))
		return
	ScreenParts.set_resource(_aether, str(l.get("aether", "")))
	var busy: bool = l["busy"] != ""
	var tags := ScreenParts.flow(6.0)
	if l.has("level"):
		tags.add_child(ScreenParts.pill(Strings.t("SCREEN_LAB_LEVEL", int(l["level"])), "glass", "buildings",
			"resonancelab"))
	body.add_child(tags)
	for key: String in ["terms", "none", "chords"]:
		if str(l.get(key, "")) != "":
			body.add_child(ScreenParts.pill(l[key], "glass", "generalui", "timer" if key == "terms" else "info",
				13.0, "words", true))
	for c: Dictionary in l["chambers"]:
		body.add_child(_chamber(c, busy))
	if not (l.get("sphere", {}) as Dictionary).is_empty():
		body.add_child(_sphere(l["sphere"], busy))
	body.add_child(_shelf(l))
	if focus_item != "":
		for b: Button in find_children("*", "Button", true, false):
			if b.get_meta("item", "") == focus_item and b.is_visible_in_tree():
				b.grab_focus.call_deferred()
				break


## A chamber as the design's test bench: two pedestals linked through the
## core, each a law a tap moves along; or the pair running with its time
## left; its last result beneath; and the run button.
func _chamber(c: Dictionary, busy: bool) -> Control:
	var box := VBoxContainer.new()
	box.add_theme_constant_override("separation", UI.px(8))
	var head := HBoxContainer.new()
	var title := ScreenKit.text(c["title"], 20.0, "name", "card_lit")
	title.set_meta("chamber", c["chamber"])
	title.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	head.add_child(title)
	if c.has("left"):
		head.add_child(ScreenParts.pill(c["left"], "cream", "generalui", "timer"))
	box.add_child(head)
	var n := int(c["chamber"])
	# The design's test bench: each law a round gem in its school's ring with
	# its name beneath, joined to the core by a gold thread.
	var bench := HBoxContainer.new()
	bench.add_theme_constant_override("separation", 0)
	bench.alignment = BoxContainer.ALIGNMENT_CENTER
	var running := c.has("running")
	var items: Array = c["running"] if running else c["slots"]
	for i: int in items.size():
		if i == 1:
			bench.add_child(ScreenThread.make(UI.px(64), running))
			bench.add_child(_core(running))
			bench.add_child(ScreenThread.make(UI.px(64), running))
		var law := str(items[i]) if running else str((items[i] as Dictionary)["law"])
		var col := VBoxContainer.new()
		col.add_theme_constant_override("separation", UI.px(4))
		col.custom_minimum_size.x = UI.px(104)
		var gem := ScreenKit.panel("ring_" + LawFxLinks.school(law), ScreenKit.icon("laws", law, 46.0), -1.0, 6.0)
		gem.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
		col.add_child(gem)
		if running:
			var name := ScreenKit.text(Strings.term("LAW", law), 13.0, "words", "card_lit", false, true)
			name.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
			col.add_child(name)
		else:
			var s: Dictionary = items[i]
			# A tap moves the sphere to the next restored law.
			var b := ScreenKit.button(s["text"], controller.cycle.bind(n, int(s["slot"])), "well", s["spoken"], 14.0)
			# Quiet under its gem, as the running pair's names are.
			b.add_theme_font_size_override("font_size", UI.text_px(13))
			b.set_meta("points", 13.0)
			UI.fit(b)
			b.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
			b.custom_minimum_size.x = UI.px(96)
			b.disabled = busy
			b.set_meta("key", s["key"])
			b.set_meta("item", s["key"])
			col.add_child(b)
		bench.add_child(col)
	box.add_child(bench)
	if c.get("unstable", false):
		box.add_child(ScreenParts.pill(Strings.t("LAB_UNSTABLE"), "red", "hud", "warning", 13.0, "words", true))
	# The last result's lines together on one well, a find first and lit.
	var said := VBoxContainer.new()
	said.add_theme_constant_override("separation", UI.px(4))
	var found := str(c.get("found", ""))
	for line: String in c["lines"]:
		if line == Strings.t("LAB_UNSTABLE") or c.has("running") and line == c["lines"][0]:
			continue
		var lit: bool = found != "" and line == c["lines"][0]
		var row := HBoxContainer.new()
		row.add_theme_constant_override("separation", UI.px(8))
		var mark := ScreenKit.icon("harmony", "resonance" if lit else "signature", 20.0)
		mark.size_flags_vertical = Control.SIZE_SHRINK_BEGIN
		row.add_child(mark)
		var words := ScreenKit.text(line, 13.0, "words", "well", not lit, true)
		if lit:
			words.add_theme_color_override("font_color", Tokens.color("success_text_on_night"))
		words.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		row.add_child(words)
		said.add_child(row)
	if said.get_child_count() > 0:
		box.add_child(ScreenKit.panel("well", said, 12.0, 8.0))
	if not (c["run"] as Dictionary).is_empty():
		var shown: Dictionary = (c["run"] as Dictionary).duplicate()
		if confirm == shown["key"]:
			shown["action"] = Strings.t("CODEX_CONFIRM", shown["cost"])
			shown["spoken"] = Strings.t("CODEX_CONFIRM_SPOKEN", [shown["spoken"], shown["cost"]])
		var run := ScreenKit.button(shown["action"], _run.bind(c["run"], n), "gold", shown["spoken"], 14.0)
		run.disabled = busy or not shown["can"]
		run.set_meta("key", shown["key"])
		run.set_meta("item", shown["item"])
		box.add_child(run)
		if shown["why"] != "":
			box.add_child(ScreenKit.text(shown["why"], 13.0, "words", "card_lit", true, true))
	return ScreenKit.panel("card_lit", box, 18.0, 12.0)


## The core between the pedestals: the resonance mark, lit while it runs.
func _core(lit: bool) -> Control:
	var core := ScreenKit.icon("harmony", "resonance", 40.0 if lit else 32.0)
	core.modulate = Color.WHITE if lit else Color(1, 1, 1, 0.55)
	# As tall as the thread's band, so the mark sits on the thread's line.
	core.custom_minimum_size.y = UI.px(64)
	core.size_flags_vertical = Control.SIZE_SHRINK_BEGIN
	return core


## §8.5's third sphere: names a chord woven or crossed, once a day, free.
func _sphere(o: Dictionary, busy: bool) -> Control:
	var b := ScreenKit.button(o["action"], controller.name_chord, "leather", o["spoken"], 14.0)
	b.disabled = busy or not o["can"]
	b.set_meta("key", o["key"])
	b.set_meta("item", o["item"])
	var right := VBoxContainer.new()
	right.add_child(b)
	if o["why"] != "":
		right.add_child(ScreenKit.text(o["why"], 13.0, "words", "card", true, true))
	return ScreenParts.item("harmony", "chord", Strings.t("LAB_SPHERE_TITLE"), "", right)


## The design's resonance grid: one numbered tile for each the Lab has
## found (its mark and name on parchment), the hinted (a lit question and how
## many), and each school's still to find (its mark, dimmed, and how many); the section
## counts found of all (§8.6).
func _shelf(l: Dictionary) -> Control:
	var box := VBoxContainer.new()
	box.add_theme_constant_override("separation", UI.px(8))
	var finds: Array = l.get("finds", [])
	var remaining: Dictionary = l.get("remaining", {})
	var total := finds.size() + int(l.get("hinted", 0))
	for school: String in remaining:
		total += int(remaining[school])
	box.add_child(ScreenParts.section(Strings.t("LAB_FOUND_TITLE"), "%d / %d" % [finds.size(), total]))
	var grid := GridContainer.new()
	grid.columns = ScreenParts.grid_columns(4)
	grid.add_theme_constant_override("h_separation", UI.px(6))
	grid.add_theme_constant_override("v_separation", UI.px(6))
	var n := 0
	for f: Dictionary in finds:
		n += 1
		grid.add_child(_tile(n, ScreenKit.icon("harmony", "chord" if f["kind"] == "chord" else "resonance", 40.0),
			f["name"], "parchment"))
	if int(l.get("hinted", 0)) > 0:
		n += 1
		var hint := _tile(n, ScreenKit.icon("harmony", "unknownlaw", 40.0), "× %d" % int(l["hinted"]), "card_lit",
			Strings.t("LAB_HINTED", int(l["hinted"])))
		grid.add_child(hint)
	for school: String in remaining:
		var coin := ScreenCoin.make("school:" + school.to_lower(), 34.0)
		coin.modulate.a = 0.55
		var said := Strings.t("LAB_REMAINING_SCHOOL", [Strings.t("SCHOOL_" + school.to_upper()),
			int(remaining[school])])
		grid.add_child(_tile(0, coin, "× %d" % int(remaining[school]), "well", said))
	box.add_child(grid)
	if finds.is_empty():
		box.add_child(ScreenKit.text(Strings.t("LAB_FOUND_NONE"), 13.0, "body", "card", true, true))
	return box


## A tile of the grid: its number in the corner (none for a school's count),
## its mark, its words; `said` what a screen reader says for it.
func _tile(n: int, mark: Control, words: String, material: String, said := "") -> PanelContainer:
	var col := VBoxContainer.new()
	col.add_theme_constant_override("separation", UI.px(2))
	var number := ScreenKit.text("%02d" % n if n > 0 else " ", 13.0, "number", material, true)
	col.add_child(number)
	mark.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	col.add_child(mark)
	var name := ScreenKit.text(words, 13.0, "words", material, material == "well", true)
	name.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	col.add_child(name)
	var tile := ScreenKit.panel(material, col, 14.0, 6.0)
	tile.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	if said != "":
		tile.tooltip_text = said
		name.accessibility_name = said
	return tile


## A paid run's first tap shows its price to confirm; the second spends it.
## The first experiment is free and runs on one tap.
func _run(o: Dictionary, n: int) -> void:
	if str(o["cost"]) != "" and confirm != o["key"]:
		confirm = o["key"]
		_refresh()
		return
	confirm = ""
	await controller.start(n)
