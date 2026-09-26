class_name HeistScreen
extends Control
## A heist, on screen: `HeistController` holds the heist and turns taps into
## commands; this screen draws it, forwards taps and buttons, runs the clock
## in real time, and when the clock runs out hands the replay to the heist
## repository, which checks it with the server (§24.12) — or, offline, the
## same check runs on the phone.
##
## §21.8 puts crew portraits at the bottom left and actions at the bottom
## right; both rows here sit above the corners, which §21.1 keeps clear.

const Kind := HeistController.Kind

var controller := HeistController.new()
var playing := true
var _owed := 0.0

var view: RealmView
var hud: HeistHud
var hint_label: Label
var gait_button: Button
var crew_buttons: Array[Button] = []

## The lease this heist is played under, when a server gave one.
var lease := {}

signal finished


func _ready() -> void:
	App.ready(self)
	var services: Services = App.services
	var heist: Dictionary = services.store.get_slice(AppState.HEIST)
	controller.world.start(HeistController.SEED, HeistController.TICKS, HeistController.CREW, PackedByteArray())
	_build()
	controller.changed.connect(_refresh)
	controller.clock_out.connect(finish)
	if heist["testing"]:
		begin(HeistController.SEED, HeistController.TICKS, HeistController.CREW, heist["island"])
	elif not services.api.online():
		begin(HeistController.SEED, HeistController.TICKS, HeistController.CREW)
	else:
		playing = false
		hint_label.text = Strings.t("HEIST_ASKING")
		var problem := await begin_online(services)
		if problem != "":
			hint_label.text = Errors.message("HEIST_NONE", problem)


## Start a fresh heist; see `HeistController.begin`.
func begin(seed: String, ticks: int, crew: int, realm := PackedByteArray(), era := "") -> bool:
	if not controller.begin(seed, ticks, crew, realm, era):
		return false
	playing = true
	view.show_replay(controller.world)
	_refresh()
	return true


## §24.12's Lease: sign in, take the first target from the lists, fetch its
## bundle and lease it — "a target snapshot, a seed, a single-use token and an
## expiry a day away". Returns "" or the code of what went wrong.
func begin_online(services: Services) -> String:
	var me := await services.account.sign_in(Services.credential())
	if not me.ok:
		return me.code
	services.store.dispatch(&"signed_in", {"account": me.value["account"]})
	var target := await services.heists.first_target(str(me.value["account"]))
	if not target.ok:
		return target.code
	var bundle := await services.heists.fetch(str(target.value["bundle"]))
	if not bundle.ok:
		return bundle.code
	var leased := await services.heists.lease(str(target.value["bundle"]), str(target.value["owner"]))
	if not leased.ok:
		return leased.code
	lease = leased.value
	if not begin(str(lease["seed"]), int(lease["ticks"]), HeistController.CREW, bundle.value,
			HeistController.lease_era(lease)):
		return "island_does_not_load"
	return ""


## Run `ticks` ticks of the clock; see `HeistController.advance`.
func advance(ticks: int) -> void:
	controller.advance(ticks)


## Write the heist down and have it checked: by the server, which re-simulates
## and settles it (§24.12), or — offline — by the same function on the phone.
## A submission the network cannot carry now waits in the outbox, and the
## result shows the phone's own check, marked confirming.
func finish() -> void:
	if not playing:
		return
	playing = false
	var services: Services = App.services
	var replay := controller.record()
	var local := RulebornReplay.validate(replay, controller.island)
	services.store.dispatch(&"heist_finished", {"replay": replay, "verdict": local})
	if not lease.is_empty():
		hint_label.text = Strings.t("HEIST_CHECKING")
		var answer := await services.heists.submit(str(lease["token"]), replay)
		services.store.dispatch(&"heist_verdict", HeistController.settled(answer, local))
	finished.emit()
	if is_inside_tree():
		services.router.go.call_deferred(&"result")


func _process(delta: float) -> void:
	if not playing:
		return
	_owed += delta * RulebornReplay.ticks_per_second()
	var whole := int(_owed)
	_owed -= whole
	controller.advance(whole)


# -- layout ---------------------------------------------------------------

func _refresh() -> void:
	if hud == null:
		return
	hud.show_state(controller.world)
	var me: Dictionary = controller.world.crew()[controller.selected]
	hint_label.text = Strings.t("HEIST_SKIFF_HINT") if controller.calling_skiff else \
		Strings.t("HEIST_HINT", Strings.term("ROLE", me["role"]))
	gait_button.text = Strings.term("GAIT", me["gait"])
	for i in crew_buttons.size():
		var b := crew_buttons[i]
		b.modulate = Color.WHITE if i == controller.selected else Color(1, 1, 1, 0.6)
	view.queue_redraw()


func _build() -> void:
	var column := UI.frame(self)
	hud = HeistHud.new()
	column.add_child(hud)
	view = RealmView.new()
	view.size_flags_vertical = Control.SIZE_EXPAND_FILL
	view.gui_input.connect(func(event):
		if event is InputEventMouseButton and event.pressed:
			controller.tap_tile(view.tile_at(event.position)))
	column.add_child(view)
	hint_label = UI.label("", UI.TEXT_POINTS, true)
	column.add_child(hint_label)

	var actions := UI.row()
	column.add_child(actions)
	gait_button = UI.button(Strings.term("GAIT", "Walk"), controller.next_gait)
	actions.add_child(gait_button)
	actions.add_child(UI.button(Strings.t("HEIST_HALT"), controller.halt))
	actions.add_child(UI.button(Strings.t("HEIST_DROP"), controller.drop_half))
	actions.add_child(UI.button(Strings.t("HEIST_GET_OUT"), controller.get_out, true))
	# The crew's portraits lowest, where the thumb rests (§21.8 puts them at
	# the bottom); a narrow row, so it stays clear of the corners.
	var crew_row := UI.row()
	column.add_child(crew_row)
	var crew := controller.world.crew()
	for i in crew.size():
		var role: String = crew[i]["role"]
		var b := UI.button(Strings.term("ROLE", role).substr(0, 2), controller.select.bind(i), false, Palette.ROLE.get(role, Palette.PAPER))
		crew_buttons.append(b)
		crew_row.add_child(b)
