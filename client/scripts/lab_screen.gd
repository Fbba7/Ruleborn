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
	for line: String in c["lines"]:
		if line == Strings.t("LAB_UNSTABLE") or c.has("running") and line == c["lines"][0]:
			continue
		var found := str(c.get("found", ""))
		box.add_child(ScreenParts.pill(line, "green" if found != "" and line == c["lines"][0] else "well",
			"harmony", "resonance" if found != "" else "signature", 13.0, "words", true))
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


## What the Lab has found, by mark and name; how many are hinted; and how
## many remain in each school (§8.6).
func _shelf(l: Dictionary) -> Control:
	var box := VBoxContainer.new()
	box.add_theme_constant_override("separation", UI.px(8))
	box.add_child(ScreenParts.section(Strings.t("LAB_FOUND_TITLE"), str((l.get("finds", []) as Array).size())))
	var grid := GridContainer.new()
	grid.columns = ScreenParts.grid_columns(3)
	grid.add_theme_constant_override("h_separation", UI.px(6))
	grid.add_theme_constant_override("v_separation", UI.px(6))
	for f: Dictionary in l.get("finds", []):
		var col := VBoxContainer.new()
		col.add_theme_constant_override("separation", UI.px(2))
		var mark := ScreenKit.icon("harmony", "chord" if f["kind"] == "chord" else "resonance", 44.0)
		mark.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
		col.add_child(mark)
		var name := ScreenKit.text(f["name"], 13.0, "words", "parchment", false, true)
		name.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		col.add_child(name)
		var tile := ScreenKit.panel("parchment", col, 14.0, 6.0)
		tile.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		grid.add_child(tile)
	if int(l.get("hinted", 0)) > 0:
		var hint := VBoxContainer.new()
		var q := ScreenKit.icon("harmony", "unknownlaw", 44.0)
		q.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
		hint.add_child(q)
		var words := ScreenKit.text(Strings.t("LAB_HINTED", int(l["hinted"])), 13.0, "words", "well", true, true)
		words.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		hint.add_child(words)
		var tile2 := ScreenKit.panel("well", hint, 14.0, 6.0)
		tile2.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		grid.add_child(tile2)
	box.add_child(grid)
	if (l.get("finds", []) as Array).is_empty():
		box.add_child(ScreenKit.text(Strings.t("LAB_FOUND_NONE"), 13.0, "body", "card", true, true))
	var remaining: Dictionary = l.get("remaining", {})
	if not remaining.is_empty():
		box.add_child(ScreenParts.section(Strings.t("SCREEN_LAB_REMAINING")))
		var row := ScreenParts.flow(6.0)
		for school: String in remaining:
			var p := HBoxContainer.new()
			p.add_theme_constant_override("separation", UI.px(4))
			p.add_child(ScreenCoin.make("school:" + school.to_lower(), 24.0))
			var count := ScreenKit.text(str(int(remaining[school])), 17.0, "number", "well")
			p.add_child(count)
			var plate := ScreenKit.panel("well", p, -1.0, 4.0)
			plate.tooltip_text = Strings.t("LAB_REMAINING_SCHOOL", [Strings.t("SCHOOL_" + school.to_upper()),
				int(remaining[school])])
			count.accessibility_name = plate.tooltip_text
			row.add_child(plate)
		box.add_child(row)
	return ScreenKit.panel("card", box, 18.0, 12.0)


## A paid run's first tap shows its price to confirm; the second spends it.
## The first experiment is free and runs on one tap.
func _run(o: Dictionary, n: int) -> void:
	if str(o["cost"]) != "" and confirm != o["key"]:
		confirm = o["key"]
		_refresh()
		return
	confirm = ""
	await controller.start(n)
