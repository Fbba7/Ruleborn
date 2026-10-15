class_name LawScreen
extends Control
## The law card (§21.7, §23.2, "Explain one law in seconds"): the school's
## shape and name, the law's name, its one-line rule, its notes as symbols,
## its rank, its tier as pips, its pages and its one weakness (§7.7). It opens
## from the Codex on a law the player has met, and back to it.

var law := ""
var box: VBoxContainer
var status_label: Label


func _ready() -> void:
	App.ready(self)
	law = str(App.services.store.get_slice(AppState.ROUTE)["params"].get("law", ""))
	_build()
	App.services.store.changed.connect(_on_changed)
	_refresh()
	if ((App.services.store.get_slice(CodexState.CODEX)["view"]) as Dictionary).is_empty():
		await App.services.codex_flow.load_codex()


func _on_changed(slice: StringName) -> void:
	if slice == CodexState.CODEX and is_inside_tree():
		_refresh()


func _build() -> void:
	var column := UI.frame(self)
	column.add_child(UI.title(Strings.t("LAW_CARD_TITLE")))
	status_label = UI.status("info", "")
	column.add_child(UI.plate(status_label))
	var list := UI.scroll(column)
	box = VBoxContainer.new()
	list.add_child(UI.plate(box))
	var actions := UI.row(-1.0, true)
	actions.add_child(UI.button(Strings.t("HOME_CODEX"), func() -> void: App.services.router.go(&"codex"), true))
	column.add_child(UI.narrow(actions))


func _refresh() -> void:
	if not is_inside_tree():
		return
	for child in box.get_children():
		box.remove_child(child)
		child.queue_free()
	var c := LawPresenter.from_codex(App.services.store.get_slice(CodexState.CODEX), law)
	if c.is_empty():
		UI.set_status(status_label, "info", Strings.t("COMMON_LOADING"))
		return
	UI.set_status(status_label, "info", "")
	var mark := UI.label(c["mark"], UI.TEXT_POINTS, true)
	mark.set_meta("school", c["school"])
	box.add_child(mark)
	var name := UI.label(c["name"], UI.TEXT_POINTS + 6, true)
	name.set_meta("law", c["law"])
	box.add_child(name)
	for key: String in ["rule", "notes", "rank"]:
		box.add_child(UI.label(c[key], UI.TEXT_POINTS, true))
	var tier := UI.label(c["tier"], UI.TEXT_POINTS, true)
	tier.accessibility_name = c["tier_spoken"]
	box.add_child(tier)
	for key: String in ["pages", "weakness"]:
		box.add_child(UI.label(c[key], UI.TEXT_POINTS, true))
