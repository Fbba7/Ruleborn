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
	column.add_child(StageHeroSkin.title(UI.title(Strings.t("FIRST_TITLE"))))
	status_label = UI.status("info", "")
	column.add_child(StageHeroSkin.plate(status_label))
	stage = StageHero.new()
	stage.custom_minimum_size = Vector2(0, UI.px(220))
	stage.size_flags_vertical = Control.SIZE_EXPAND_FILL
	stage.size_flags_stretch_ratio = 1.6
	column.add_child(stage)
	stage.show_kinds(WELCOME, [], "island")
	body = UI.scroll(column)


func _refresh() -> void:
	if not is_inside_tree():
		return
	var f := FirstPresenter.screen(App.services.store.get_slice(FirstState.FIRST), App.services.age.band())
	UI.set_status(status_label, "alarm" if f["error"] != "" else "info", f["error"])
	status_label.get_parent().visible = status_label.text != ""
	# Each beat the player moves on to, the welcome party cheers them on.
	if _beat != "" and str(f["beat"]) != _beat:
		stage.cheer.call_deferred()
	_beat = str(f["beat"])
	for child in body.get_children():
		body.remove_child(child)
		child.queue_free()
	var box := VBoxContainer.new()
	box.set_meta("beat", f["beat"])
	for line: String in f["lines"]:
		box.add_child(UI.label(line, UI.TEXT_POINTS, true))
	if f["beat"] == "name":
		var name := StageHeroSkin.named(UI.label(str(f.get("name", "")), UI.TEXT_POINTS + 6, true))
		name.set_meta("name", true)
		box.add_child(name)
		for part: String in ["adjective", "noun"]:
			var words := Strings.t("FIRST_NEXT_" + part.to_upper())
			var b := StageHeroSkin.button(UI.button(words, controller.cycle.bind(part, 1)))
			b.set_meta("key", "cycle:" + part)
			box.add_child(b)
	if str(f["next"]) != "":
		var go := StageHeroSkin.button(UI.button(f["next"], controller.keep_name if f["beat"] == "name" else controller.next,
			true), true)
		go.set_meta("key", "next")
		box.add_child(go)
	body.add_child(StageHeroSkin.plate(box))
