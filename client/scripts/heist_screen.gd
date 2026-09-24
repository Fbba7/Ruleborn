class_name HeistScreen
extends Control
## A heist, played: each tap becomes a simulation command at the tick it is
## made (§24.10: "a move or an ability with its tick, crew member and target"),
## the world steps in real time, and when the clock runs out the command log is
## written down as the replay a device queues (§24.12) and checked the way the
## server checks it.
##
## One crew member is selected at a time, and a tap on the realm gives it the
## command the tapped thing calls for (see `tap_tile`). The buttons cycle its
## gait, halt it, drop half its loot, and — Get out — call the skiff (§5.4) to
## the next tile tapped. §21.8 puts crew portraits at the bottom left and actions at the
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
var gait_button: Button
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
		hint_label.text = Strings.t("HEIST_ASKING")
		var problem := await begin_online(Session.server_url())
		if problem != "":
			hint_label.text = Strings.t("HEIST_NONE", problem)


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
	lease = await server.lease(target["bundle"], target["owner"])
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


## A tap on the realm's tile `t`, read by what is on it. Each tap is one
## command the player chose, never one the crew chose for them (§12.18):
##
##   after Get out      call the skiff here (§5.4)
##   a crew member      select it
##   a guard            attack it (§12.20), or drag it if it is down (§12.8)
##   the Vault          crack it (§12.6), or load to full once it is open
##   a law pylon        break it (§12.6)
##   a live ward        disarm it, standing on its tile (§10.3)
##   anything else      walk there (§12.18)
func tap_tile(t: Vector2i) -> void:
	if t.x < 0:
		return
	var at := Vector2i(t.x * 256 + 128, t.y * 256 + 128)
	if calling_skiff:
		world.give(selected, Kind.SKIFF, at.x, at.y)
		calling_skiff = false
		_refresh()
		return
	var crew := world.crew()
	for i in crew.size():
		if Vector2i(crew[i]["at"]) == t and i != selected and crew[i]["standing"] == "Active":
			select(i)
			return
	var guards := world.guards()
	for g in guards.size():
		if Vector2i(guards[g]["at"]) == t:
			world.give(selected, Kind.DRAG if guards[g]["down"] else Kind.ATTACK, g, 0)
			_refresh()
			return
	var vault := world.vault()
	if Vector2i(vault["at"]) == t:
		if vault["open"]:
			load_up(100)
		else:
			crack()
		_refresh()
		return
	var features := world.features()
	var size := world.size()
	if features[t.y * size.x + t.x] == RealmView.Tile.PYLON:
		world.give(selected, Kind.BREAK, at.x, at.y)
		_refresh()
		return
	for w in world.wards():
		if Vector2i(w["at"]) == t and w["live"]:
			world.give(selected, Kind.DISARM, at.x, at.y)
			_refresh()
			return
	world.give(selected, Kind.MOVE_TO, at.x, at.y)
	_refresh()


const GAITS := ["Walk", "Crouch", "Run"]


## The selected member's next gait: walk, crouch, run, and round again
## (§12.17 prices all three for eyes and ears).
func next_gait() -> void:
	var now: String = world.crew()[selected]["gait"]
	var next := (GAITS.find(now) + 1) % GAITS.size()
	world.give(selected, Kind.GAIT, next, 0)
	_refresh()


func halt() -> void:
	world.give(selected, Kind.HALT, 0, 0)
	_refresh()


## §12.19: dropping loot "costs exactly the fraction dropped"; half, from the
## button.
func drop_half() -> void:
	world.give(selected, Kind.DROP, 50, 0)
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
		hint_label.text = Strings.t("HEIST_CHECKING")
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
	var me: Dictionary = world.crew()[selected]
	hint_label.text = Strings.t("HEIST_SKIFF_HINT") if calling_skiff else \
		Strings.t("HEIST_HINT", Strings.term("ROLE", me["role"]))
	gait_button.text = Strings.term("GAIT", me["gait"])
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
	hint_label = UI.label("", UI.TEXT_POINTS, true)
	column.add_child(hint_label)

	var actions := UI.row()
	column.add_child(actions)
	gait_button = UI.button(Strings.term("GAIT", "Walk"), next_gait)
	actions.add_child(gait_button)
	actions.add_child(UI.button(Strings.t("HEIST_HALT"), halt))
	actions.add_child(UI.button(Strings.t("HEIST_DROP"), drop_half))
	actions.add_child(UI.button(Strings.t("HEIST_GET_OUT"), get_out, true))
	# The crew's portraits lowest, where the thumb rests (§21.8 puts them at
	# the bottom); a narrow row, so it stays clear of the corners.
	var crew_row := UI.row()
	column.add_child(crew_row)
	var crew := world.crew()
	for i in crew.size():
		var role: String = crew[i]["role"]
		var b := UI.button(Strings.term("ROLE", role).substr(0, 2), select.bind(i), false, Palette.ROLE.get(role, Palette.PAPER))
		crew_buttons.append(b)
		crew_row.add_child(b)
