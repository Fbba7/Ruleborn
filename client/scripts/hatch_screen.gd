class_name HatchScreen
extends Control
## Hatch (§23.2, "Births at a Nursery"): each Nursery's ready births of the
## three it holds, the price, each kind's odds by §11.9's weights, the form's
## odds on a tie; the strays heists found, offered at the same price; and the
## newborn's traits, the first hatch's free outfit, and a name from the word
## lists (§19.20). Essence is spent on a second tap. It draws the roster's
## store; Services' `roster_flow` asks. A Nursery's egg waits on the hero
## stage, wobbling; when a birth comes, its shell bursts and the newborn
## pops out in its form (the reveal), then idles there for its naming.

var controller: RosterController
var body: VBoxContainer
var header_label: Label
var status_label: Label
var stage: StageHero
var cards: VBoxContainer
## The spend tapped once, by its key: the next tap on it spends.
var confirm := ""
## The name the word lists offer the newborn, as indices.
var pick := {"adjective": 0, "noun": 0}
var clock: Callable = func() -> int: return int(Time.get_unix_time_from_system() * 1000)


func _ready() -> void:
	App.ready(self)
	controller = App.services.roster_flow
	_build()
	App.services.store.changed.connect(_on_changed)
	_refresh()
	await controller.load_roster()
	await controller.load_words()


func _on_changed(slice: StringName) -> void:
	if slice in [RosterState.ROSTER, WorkshopState.WORKSHOP] and is_inside_tree():
		_refresh()


func _build() -> void:
	var column := UI.frame(self)
	StageHeroSkin.night(self)
	var safe := column.get_parent() as MarginContainer
	for side: String in ["margin_left", "margin_right", "margin_top"]:
		safe.add_theme_constant_override(side, 0)
	status_label = UI.status("info", "")
	column.add_child(RosterScreen.padded(StageHeroSkin.plate(status_label)))
	body = UI.scroll(column)
	body.add_theme_constant_override("separation", UI.px(10))
	stage = StageHero.new()
	stage.custom_minimum_size = Vector2(0, UI.px(Tokens.number("size", "safe_top_points") + 250.0))
	stage.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	body.add_child(stage)
	header_label = StageHeroKit.words("", 15.0, StageHeroSkin.LIGHT)
	header_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	cards = VBoxContainer.new()
	cards.add_theme_constant_override("separation", UI.px(10))
	cards.add_child(StageHeroMaterial.panel("glass", header_label, 14.0, 8.0))
	body.add_child(RosterScreen.padded(cards))
	var actions := UI.row(-1.0, true)
	actions.alignment = FlowContainer.ALIGNMENT_CENTER
	var home := UI.button(Strings.t("COMMON_HOME"), func() -> void: App.services.router.go(&"home"))
	actions.add_child(StageHeroMaterial.button(home, "leather"))
	column.add_child(RosterScreen.padded(actions))


func _refresh() -> void:
	if not is_inside_tree():
		return
	var focused := get_viewport().gui_get_focus_owner()
	var focus_item := str(focused.get_meta("item", "")) if focused != null else ""
	var slice: Dictionary = App.services.store.get_slice(RosterState.ROSTER)
	var h := HatchPresenter.screen(slice,
		App.services.store.get_slice(WorkshopState.WORKSHOP)["words"], clock.call(), pick)
	if h["error"] != "":
		UI.set_status(status_label, "alarm", h["error"])
	elif h["said"] != "":
		UI.set_status(status_label, "success", h["said"])
	elif h["busy"] != "" or not h["ready"]:
		UI.set_status(status_label, "info", Strings.t("COMMON_LOADING"))
	else:
		UI.set_status(status_label, "info", "")
	status_label.get_parent().get_parent().visible = status_label.text != ""
	header_label.text = h.get("header", "")
	for c in cards.get_children():
		if c.get_index() > 0:
			cards.remove_child(c)
			c.queue_free()
	stage.visible = h["ready"]
	if not h["ready"]:
		return
	_stand(slice, h["newborn"])
	var busy: bool = h["busy"] != ""
	if not (h["newborn"] as Dictionary).is_empty():
		cards.add_child(_newborn(h["newborn"], busy))
	if h["none"] != "":
		cards.add_child(StageHeroKit.card("", StageHeroKit.para(h["none"], 16.0)))
	var raw := {}
	for n: Dictionary in (slice.get("view", {}) as Dictionary).get("nurseries", []):
		raw[str(n["realm"])] = n
	for n: Dictionary in h["nurseries"]:
		cards.add_child(_nursery(n, raw.get(n["realm"], {}), busy))
	if not (h["strays"] as Array).is_empty():
		var title := StageHeroKit.words(Strings.t("HATCH_STRAYS"), 20.0, Color("#FFE6A0"))
		StageHeroSkin.named(title)
		cards.add_child(title)
	var kinds := {}
	for s: Dictionary in (slice.get("view", {}) as Dictionary).get("strays", []):
		kinds[int(s["id"])] = str(s["kind"])
	for s: Dictionary in h["strays"]:
		cards.add_child(_stray(s, str(kinds.get(int(s["id"]), "")), busy))
	StageHeroSkin.cap_buttons(cards, get_viewport_rect().size.x - UI.px(64))
	if focus_item != "":
		for b: Button in find_children("*", "Button", true, false):
			if b.get_meta("item", "") == focus_item and b.is_visible_in_tree():
				b.grab_focus.call_deferred()
				break


## A Nursery's card: its name, its births ready as eggs of the three it
## holds and when the next comes; what may hatch, each kind's portrait beside
## its odds on a bar; the form's odds on chips; and the hatch button.
func _nursery(n: Dictionary, raw: Dictionary, busy: bool) -> Control:
	var v := VBoxContainer.new()
	v.add_theme_constant_override("separation", UI.px(8))
	var title := StageHeroKit.words(n["title"], 20.0, StageHeroSkin.LIGHT)
	StageHeroSkin.named(title)
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_LEFT
	title.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	v.add_child(title)
	var eggs := HFlowContainer.new()
	eggs.add_theme_constant_override("h_separation", UI.px(6))
	var ready := int(raw.get("ready", 0))
	for i: int in int(raw.get("holds", 0)):
		var egg := StageHeroSkin.badge("●" if i < ready else "○", Color("#E9B65C") if i < ready else Color("#3A2A6A"), 14.0)
		egg.custom_minimum_size = Vector2(UI.px(26), UI.px(30))
		eggs.add_child(egg)
	eggs.add_child(StageHeroKit.chip(n["ready"], "card"))
	if n["next"] != "":
		eggs.add_child(StageHeroKit.chip(n["next"], "card", "⧗"))
	v.add_child(eggs)
	v.add_child(StageHeroKit.kicker(Strings.t("HATCH_KINDS")))
	var odds := {}
	for k: Dictionary in raw.get("kinds", []):
		odds[RosterPresenter.kind_name(str(k["kind"]))] = k
	for line: String in n["kinds"]:
		var k: Dictionary = odds.get(line.get_slice(":", 0), {})
		var row := HBoxContainer.new()
		row.add_theme_constant_override("separation", UI.px(8))
		if not k.is_empty():
			var face := StageHeroSkin.portrait_tile(str(k["kind"]), "", 44.0)
			face.custom_minimum_size.x = UI.px(44)
			row.add_child(face)
		var col := VBoxContainer.new()
		col.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		col.size_flags_vertical = Control.SIZE_SHRINK_CENTER
		var said := StageHeroKit.para(line, 15.0)
		col.add_child(said)
		col.add_child(StageHeroBar.make(float(k.get("odds", 0.0)), Color("#3CC6D8"), "", 10.0))
		row.add_child(col)
		v.add_child(row)
	v.add_child(StageHeroKit.kicker(Strings.t("HATCH_FORMS")))
	var forms := HFlowContainer.new()
	forms.add_theme_constant_override("h_separation", UI.px(6))
	for f: Dictionary in raw.get("forms", []):
		if float(f["odds"]) > 0.0:
			var note := str(f["note"])
			var colour: Color = StageHeroSculpt.NOTE.get(note, StageHeroSkin.OUTLINE)
			forms.add_child(StageHeroKit.chip(Strings.t("HATCH_ODDS", [FormsPresenter.note_name(note),
				HatchPresenter.percent(float(f["odds"]))]), "#" + colour.darkened(0.45).to_html(false),
				str(FormsScreen.GLYPH.get(note, ""))))
	v.add_child(forms)
	v.add_child(_spend(n["button"], busy, "gold"))
	return StageHeroKit.card("", v)


## A stray's card: its portrait, who it is and the law it was born under,
## its traits and form's odds, and the choice to take it in or let it go.
func _stray(s: Dictionary, kind: String, busy: bool) -> Control:
	var v := VBoxContainer.new()
	v.add_theme_constant_override("separation", UI.px(6))
	var head := HBoxContainer.new()
	head.add_theme_constant_override("separation", UI.px(10))
	if kind != "":
		var face := StageHeroSkin.portrait_tile(kind, "", 72.0)
		face.custom_minimum_size.x = UI.px(72)
		head.add_child(face)
	var side := VBoxContainer.new()
	side.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	var title := StageHeroKit.para(s["title"], 17.0)
	StageHeroSkin.named(title)
	side.add_child(title)
	if s["born"] != "":
		side.add_child(StageHeroKit.chip(s["born"], "#5A3FB0", "", true))
	head.add_child(side)
	v.add_child(head)
	for line: String in [s["traits"], s["forms"]]:
		if line != "":
			v.add_child(StageHeroKit.para(line, 15.0, StageHeroSkin.LIGHT_SOFT))
	var buttons := HFlowContainer.new()
	buttons.add_theme_constant_override("h_separation", UI.px(8))
	buttons.add_child(_spend(s["take"], busy, "gold"))
	var decline := RosterScreen.offer(s["decline"], busy, controller.decline_stray.bind(int(s["id"])))
	for b: Button in decline.find_children("*", "Button", true, false):
		StageHeroMaterial.button(b, "leather")
	buttons.add_child(decline)
	v.add_child(buttons)
	return StageHeroKit.card("", v)


## The egg, or the newborn in its form: a new birth bursts from the egg.
func _stand(slice: Dictionary, born: Dictionary) -> void:
	var kind := "egg"
	var form := ""
	if not born.is_empty():
		for c: Dictionary in (slice.get("view", {}) as Dictionary).get("characters", []):
			if int(c["id"]) == int(born["id"]):
				kind = str(c["kind"])
				form = str(c.get("form", ""))
	var key := "%s/%s/%s" % [kind, form, born.get("id", "")]
	if str(stage.get_meta("showing", "")) == key:
		return
	var was_egg := str(stage.get_meta("showing", "egg")).begins_with("egg")
	stage.set_meta("showing", key)
	stage.show_kinds([kind], [form])
	if kind != "egg" and was_egg:
		stage.reveal()


## The newborn's card: who it is in Marcellus, its form and traits, the
## first hatch's outfit, and the name the word lists offer, with a word
## changed by a tap.
func _newborn(n: Dictionary, busy: bool) -> Control:
	var box := VBoxContainer.new()
	box.add_theme_constant_override("separation", UI.px(6))
	var title := StageHeroKit.para(n["title"], 22.0, Color("#FFE6A0"))
	StageHeroSkin.named(title)
	box.add_child(title)
	for line: String in [n["form"], n["traits"]]:
		if line != "":
			box.add_child(StageHeroKit.para(line, 15.0))
	if n["outfit"] != "":
		box.add_child(StageHeroKit.chip(n["outfit"], "gold", "✦", true))
	if n["name"] != "":
		var named := StageHeroKit.para(n["name"], 18.0)
		StageHeroSkin.named(named)
		box.add_child(named)
	if n["naming"]:
		var words: Dictionary = App.services.store.get_slice(WorkshopState.WORKSHOP)["words"]
		var r := UI.row()
		r.add_child(_word("adjective", Strings.t("SOCIAL_OTHER_ADJECTIVE"), (words.get("adjectives", []) as Array).size()))
		r.add_child(_word("noun", Strings.t("SOCIAL_OTHER_NOUN"), (words.get("nouns", []) as Array).size()))
		box.add_child(r)
		var a: Dictionary = n["give"]["args"]
		var give := RosterScreen.offer(n["give"], busy, controller.name_character.bind(int(a["id"]),
			int(a["adjective"]), int(a["noun"])))
		for b: Button in give.find_children("*", "Button", true, false):
			StageHeroMaterial.button(b, "gold")
		box.add_child(give)
	return StageHeroKit.card("", box, "card")


func _word(which: String, text: String, size: int) -> Button:
	var b := StageHeroMaterial.button(UI.button(text, func() -> void:
		pick[which] = (int(pick[which]) + 1) % maxi(1, size)
		_refresh()), "leather")
	b.set_meta("item", "word:" + which)
	return b


## A spend's button: the first tap shows the price to confirm; the second
## spends.
func _spend(o: Dictionary, busy: bool, kind := "leather") -> Control:
	var shown := o.duplicate()
	if confirm == o["key"]:
		shown["action"] = Strings.t("CHARACTER_CONFIRM", o["cost"])
		shown["spoken"] = Strings.t("CHARACTER_CONFIRM_SPOKEN", [o["spoken"], o["cost"]])
	var r := RosterScreen.offer(shown, busy, _tap.bind(o))
	for b: Button in r.find_children("*", "Button", true, false):
		StageHeroMaterial.button(b, kind)
	for l: Label in r.find_children("*", "Label", true, false):
		l.add_theme_color_override("font_color", StageHeroSkin.LIGHT)
	return r


func _tap(o: Dictionary) -> void:
	if confirm != o["key"]:
		confirm = o["key"]
		_refresh()
		return
	confirm = ""
	var a: Dictionary = o["args"]
	if a.has("realm"):
		await controller.hatch(str(a["realm"]))
	else:
		await controller.take_stray(int(a["stray"]))
