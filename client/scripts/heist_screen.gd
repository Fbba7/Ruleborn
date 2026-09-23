class_name HeistScreen
extends Control
## A heist, played: each tap becomes a simulation command at the tick it is
## made (§24.10: "a move or an ability with its tick, crew member and target"),
## the world steps in real time, and when the clock runs out the command log is
## written down as the replay a device queues (§24.12) and checked the way the
## server checks it.
##
## One crew member is selected at a time. A tap on a crew member selects it; a
## tap on open ground sends the selected member there. Crack, Load and Get out
## act for the selected member; Get out calls the skiff (§5.4) to the next tile
## tapped. §21.8 puts crew portraits at the bottom left and actions at the
## bottom right; both rows here sit above the corners, which §21.1 keeps clear.

enum Kind { MOVE_TO, GAIT, HALT, CRACK, LOAD, SKIFF, ATTACK, BREAK, DROP, DISARM, DRAG }

## §5.4's clock at the Heart with no links: 150 seconds, 30 ticks each.
const TICKS := 150 * 30
## The seed a lease would bring (§24.12). There is no server connection yet,
## so every heist here is played on the same one.
const SEED := "1"
const CREW := 3

var world := RulebornReplay.new()
var selected := 0
var calling_skiff := false
var playing := true
var _owed := 0.0

var view: RealmView
var hud: HeistHud
var hint_label: Label
var crew_buttons: Array[Button] = []


## The server, when there is one, and the lease this heist is played under.
var server: ServerClient
var lease := {}
var island := PackedByteArray()


func _ready() -> void:
	world.start(SEED, TICKS, CREW, PackedByteArray())
	_build()
	if Session.server_url() == "":
		begin(SEED, TICKS, CREW)
	else:
		playing = false
		hint_label.text = "Asking the server for a target"
		var problem := await begin_online(Session.server_url())
		if problem != "":
			hint_label.text = "No heist: %s" % problem


## Start a fresh heist on this seed and clock, on `realm` (a bundle; empty for
## the fixture realm).
func begin(seed: String, ticks: int, crew: int, realm := PackedByteArray()) -> bool:
	if not world.start(seed, ticks, crew, realm):
		return false
	island = realm
	selected = 0
	calling_skiff = false
	playing = true
	view.show_replay(world)
	_refresh()
	return true


## §24.12's Lease: sign in, take the first target from the lists, fetch its
## bundle and lease it — "a target snapshot, a seed, a single-use token and an
## expiry a day away". Returns "" or what went wrong.
func begin_online(url: String) -> String:
	server = ServerClient.new(url)
	add_child(server)
	var me := await server.sign_in(Session.credential())
	if me.has("error"):
		return str(me["error"])
	var target := await server.first_target(me["account"])
	if target.has("error"):
		return str(target["error"])
	var bundle := await server.fetch(target["bundle"])
	lease = await server.lease(target["bundle"])
	if lease.has("error") or bundle.is_empty():
		return str(lease.get("error", "no bundle"))
	if not begin(str(lease["seed"]), int(lease["ticks"]), CREW, bundle):
		return "the leased island does not load"
	return ""


# -- what a tap does ------------------------------------------------------

func select(member: int) -> void:
	selected = clampi(member, 0, CREW - 1)
	calling_skiff = false
	_refresh()


## A tap on the realm's tile `t`: select the crew member standing there, or
## send the selected one there, or — after Get out — call the skiff to it.
func tap_tile(t: Vector2i) -> void:
	if t.x < 0:
		return
	var at := Vector2i(t.x * 256 + 128, t.y * 256 + 128)
	if calling_skiff:
		world.give(selected, Kind.SKIFF, at.x, at.y)
		calling_skiff = false
	else:
		var crew := world.crew()
		for i in crew.size():
			if Vector2i(crew[i]["at"]) == t and i != selected and crew[i]["standing"] == "Active":
				select(i)
				return
		world.give(selected, Kind.MOVE_TO, at.x, at.y)
	_refresh()


func crack() -> void:
	world.give(selected, Kind.CRACK, 0, 0)


## Load until the bags are full: §12.19's fill, asked for as a percentage.
func load_up(percent := 100) -> void:
	world.give(selected, Kind.LOAD, percent, 0)


func get_out() -> void:
	calling_skiff = true
	_refresh()


# -- the clock ------------------------------------------------------------

## Run `ticks` ticks; when the heist's clock runs out, finish it.
func advance(ticks: int) -> void:
	for i in ticks:
		if not world.step():
			finish()
			return
	_refresh()


## Write the heist down and have it checked: by the server, which re-simulates
## and settles it (§24.12), or — offline — by the same function on the phone.
func finish() -> void:
	if not playing:
		return
	playing = false
	Session.replay = world.record()
	Session.island = island
	if server != null and not lease.is_empty():
		hint_label.text = "The server is checking the heist"
		Session.verdict = settled(await server.submit(lease["token"], Session.replay))
	else:
		Session.verdict = RulebornReplay.validate(Session.replay, island)
	finished.emit()
	if is_inside_tree():
		get_tree().change_scene_to_file.call_deferred("res://scenes/result_screen.tscn")


signal finished


## The server's answer in the result screen's terms. The grade is the server's
## re-simulation's; the haul and fee are what it minted (§9.4, §9.6).
static func settled(out: Dictionary) -> Dictionary:
	if out.has("error") or not out.get("validated", false):
		return {"ok": false, "refused": out.get("reason", out.get("error", "refused")), "server": true}
	var verdict: Dictionary = out["verdict"]
	return {"ok": true, "grade": str(verdict["grade"]).capitalize(), "banked": verdict["banked"],
		"haul": out["haul"]["total"], "fee": out["fee"], "server": true}


func _process(delta: float) -> void:
	if not playing:
		return
	_owed += delta * RulebornReplay.ticks_per_second()
	var whole := int(_owed)
	_owed -= whole
	advance(whole)


# -- layout ---------------------------------------------------------------

func _refresh() -> void:
	if hud == null:
		return
	hud.show_state(world)
	hint_label.text = "Tap an edge tile for the skiff" if calling_skiff else \
		"%s selected — tap the ground to move" % world.crew()[selected]["role"]
	for i in crew_buttons.size():
		var b := crew_buttons[i]
		b.modulate = Color.WHITE if i == selected else Color(1, 1, 1, 0.6)
	view.queue_redraw()


func _build() -> void:
	var column := UI.frame(self)
	hud = HeistHud.new()
	column.add_child(hud)
	view = RealmView.new()
	view.size_flags_vertical = Control.SIZE_EXPAND_FILL
	view.gui_input.connect(func(event):
		if event is InputEventMouseButton and event.pressed:
			tap_tile(view.tile_at(event.position)))
	column.add_child(view)
	hint_label = UI.label()
	column.add_child(hint_label)

	var crew_row := UI.row()
	column.add_child(crew_row)
	var crew := world.crew()
	for i in crew.size():
		var role: String = crew[i]["role"]
		var b := UI.button(role.substr(0, 2), select.bind(i), false, Palette.ROLE.get(role, Palette.PAPER))
		crew_buttons.append(b)
		crew_row.add_child(b)

	var actions := UI.row()
	column.add_child(actions)
	actions.add_child(UI.button("Crack", crack))
	actions.add_child(UI.button("Load", load_up.bind(100)))
	actions.add_child(UI.button("Get out", get_out, true))
