class_name HeistController
extends RefCounted
## A heist being played, with no screen: each tap becomes a simulation command
## at the tick it is made (§24.10: "a move or an ability with its tick, crew
## member and target"), the world steps when asked, and when the clock runs
## out the command log is the replay a device queues (§24.12). The heist
## screen draws it and forwards taps; tests drive it headless.
##
## One crew member is selected at a time, and a tap on the realm gives it the
## command the tapped thing calls for (see `tap_tile`).

## Something a view shows has changed.
signal changed
## The clock ran out: the heist is over and `record()` is its replay.
signal clock_out

enum Kind { MOVE_TO, GAIT, HALT, CRACK, LOAD, SKIFF, ATTACK, BREAK, DROP, DISARM, DRAG, LAND, ABILITY, SAGE, CAST }

## §5.4's clock at the Heart with no links: 150 seconds, 30 ticks each.
const TICKS := 150 * 30
## The seed an offline heist is played on; a lease brings its own (§24.12).
const SEED := "1"
const CREW := 3
const GAITS := ["Walk", "Crouch", "Run"]

var world := RulebornReplay.new()
## §12.5's load target: how full the crew loads before leaving the Vault,
## the planner's, else full.
var load_target := 100
var selected := 0
var calling_skiff := false
var island := PackedByteArray()
var seed_text := ""
var over := false
## §5.4's landing picker: while `choosing`, the heist waits at tick 0 for the
## player to pick an edge spot. `marks` are the island's spots, each with
## whether a landing there goes unheard, read from the terrain alone; `pick`
## is the one on show.
var choosing := false
var marks: Array = []
var pick := 0
## A heist across a universe (§5.4): the lease's universe as it names it, its
## bundle and its realms' islands. Each mark then carries its realm's place
## and code, its links to the Heart, its clock and its island's side, and a
## fault is a mark of its own with no tile.
var universe := {}
var universe_bytes := PackedByteArray()
var realm_islands: Array[PackedByteArray] = []


## Start a fresh heist on this seed and clock, on `realm` (a bundle; empty for
## the fixture realm), in the week's `era` (§18.3) as a lease names it.
func begin(new_seed: String, ticks: int, crew: int, realm := PackedByteArray(), era := "",
		manifest := PackedByteArray()) -> bool:
	if not world.set_era(era) or not world.start_planned(new_seed, ticks, crew, manifest, realm):
		return false
	island = realm
	seed_text = new_seed
	selected = 0
	calling_skiff = false
	over = false
	# An island of its own is landed on where the player picks; the fixture
	# realm, played with no island, lands on the seed's default.
	marks = world.landing_marks() if not realm.is_empty() else []
	choosing = not marks.is_empty()
	pick = maxi(0, marks.map(func(m: Dictionary) -> Vector2i: return m["at"]).find(default_landing()))
	changed.emit()
	return true


## Start a heist across the universe a lease names (§5.4): `leased` is the
## lease's `universe` — each realm with its clock and fault — `bundle` its
## RBU1 bytes and `islands` its realms' islands in its order. The picker
## offers every outer realm's edge spots and each fault, each with its clock.
func begin_universe(new_seed: String, crew: int, leased: Dictionary, bundle: PackedByteArray,
		islands: Array[PackedByteArray], era := "", manifest := PackedByteArray()) -> bool:
	if not world.set_era(era) or not world.start_universe(new_seed, crew, manifest, bundle, islands):
		return false
	island = PackedByteArray()
	universe = leased
	universe_bytes = bundle
	realm_islands = islands
	seed_text = new_seed
	selected = 0
	calling_skiff = false
	over = false
	marks = _universe_marks()
	choosing = not marks.is_empty()
	pick = 0
	if choosing:
		_show(pick)
	changed.emit()
	return choosing


## Every outer realm's edge spots and each fault, realm by realm in the
## universe's order: a realm with no route to the Heart, and so no clock in
## the lease, offers none.
func _universe_marks() -> Array:
	var ticks := {}
	for r: Dictionary in universe.get("realms", []):
		var name := str(r["realm"])
		var code := 0 if name == "heart" else int(name.trim_prefix("outer-"))
		if r.get("ticks") != null:
			ticks[code] = int(r["ticks"])
	var out: Array = []
	var faults: Array = []
	var realms: Array = world.universe_realms()
	for place: int in realms.size():
		var r: Dictionary = realms[place]
		var code := int(r["code"])
		if code == 0 or not ticks.has(code):
			continue
		var base := {"place": place, "code": code, "links": int(r["links"]), "ticks": ticks[code],
			"side": int(r["side"])}
		world.preview(place, false, ticks[code])
		for m: Dictionary in world.landing_marks():
			var spot := base.duplicate()
			spot["at"] = m["at"]
			spot["covered"] = m["covered"]
			out.append(spot)
		if r["fault"]:
			var fault := base.duplicate()
			fault["fault"] = true
			fault["at"] = Vector2i(-1, -1)
			fault["side"] = int(realms[0]["side"])
			faults.append(fault)
	return out + faults


## The realm the choice `i` lands in, shown: its island, or the Heart for a
## fault, on its own clock.
func _show(i: int) -> void:
	var m: Dictionary = marks[i]
	if m.has("place"):
		world.preview(int(m["place"]), m.get("fault", false), int(m["ticks"]))


## The marks to draw on the realm on show: across a universe, its own
## realm's edge spots; and which of them is on show, -1 for none.
func shown_marks() -> Array:
	if universe.is_empty() or marks.is_empty():
		return marks
	var now: Dictionary = marks[pick]
	return marks.filter(func(m: Dictionary) -> bool:
		return m["place"] == now["place"] and not m.get("fault", false))


func shown_pick() -> int:
	if universe.is_empty() or marks.is_empty():
		return pick
	return shown_marks().find(marks[pick])


## The spot on show, one along or back.
func next_spot(by: int) -> void:
	if marks.is_empty():
		return
	pick = posmod(pick + by, marks.size())
	_show(pick)
	changed.emit()


## Across a universe: the first choice of the next realm, or of its faults.
func next_realm() -> void:
	if marks.is_empty() or universe.is_empty():
		return
	var key := func(m: Dictionary) -> String: return "%s:%s" % [m["place"], m.get("fault", false)]
	var now: String = key.call(marks[pick])
	for k in range(1, marks.size() + 1):
		var i := posmod(pick + k, marks.size())
		if key.call(marks[i]) != now:
			pick = i
			_show(pick)
			changed.emit()
			return


## §5.4: the crew lands on the spot on show, the replay's first command, and
## the heist begins; at a fault, it comes through to the Heart.
func land_here() -> bool:
	if not choosing or marks.is_empty():
		return false
	var at: Vector2i = marks[pick]["at"]
	var landed_ok := land(Vector2i(maxi(at.x, 0), maxi(at.y, 0)))
	choosing = false
	changed.emit()
	return landed_ok


## The era a lease names (§18.3), as `begin` takes it: a lease in none sends
## `null`, which is "" here — `str(null)` is "<null>", which no era is.
static func lease_era(leased: Dictionary) -> String:
	var era: Variant = leased.get("era")
	return "" if era == null else str(era)


func select(member: int) -> void:
	selected = clampi(member, 0, maxi(0, world.crew_size() - 1))
	calling_skiff = false
	changed.emit()


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
	# Choosing where to land: a tap on an edge spot picks it and lands.
	if choosing:
		var shown := shown_marks()
		var at := shown.map(func(m: Dictionary) -> Vector2i: return m["at"]).find(t)
		if at >= 0:
			pick = marks.find(shown[at])
			land_here()
		return
	var at := Vector2i(t.x * 256 + 128, t.y * 256 + 128)
	if calling_skiff:
		world.give(selected, Kind.SKIFF, at.x, at.y)
		calling_skiff = false
		changed.emit()
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
			changed.emit()
			return
	var vault := world.vault()
	if Vector2i(vault["at"]) == t:
		if vault["open"]:
			load_up(load_target)
		else:
			crack()
		changed.emit()
		return
	var features := world.features()
	var size := world.size()
	if features[t.y * size.x + t.x] == RealmView.Tile.PYLON:
		world.give(selected, Kind.BREAK, at.x, at.y)
		changed.emit()
		return
	for w: Dictionary in world.wards():
		if Vector2i(w["at"]) == t and w["live"]:
			world.give(selected, Kind.DISARM, at.x, at.y)
			changed.emit()
			return
	world.give(selected, Kind.MOVE_TO, at.x, at.y)
	changed.emit()


## The selected member's next gait: walk, crouch, run, and round again
## (§12.17 prices all three for eyes and ears).
func next_gait() -> void:
	var now: String = world.crew()[selected]["gait"]
	var next := (GAITS.find(now) + 1) % GAITS.size()
	world.give(selected, Kind.GAIT, next, 0)
	changed.emit()


func halt() -> void:
	world.give(selected, Kind.HALT, 0, 0)
	changed.emit()


## §12.19: dropping loot "costs exactly the fraction dropped"; half, from the
## button.
func drop_half() -> void:
	world.give(selected, Kind.DROP, 50, 0)
	changed.emit()


func crack() -> void:
	world.give(selected, Kind.CRACK, 0, 0)


## Load until the bags are full: §12.19's fill, asked for as a percentage.
func load_up(percent := 100) -> void:
	world.give(selected, Kind.LOAD, percent, 0)


func get_out() -> void:
	calling_skiff = true
	changed.emit()


## Run `ticks` ticks; when the heist's clock runs out, it is over.
func advance(ticks: int) -> void:
	if over:
		return
	for i in ticks:
		if world.tick() == 0 and not landed():
			land(default_landing())
		if not world.step():
			over = true
			changed.emit()
			clock_out.emit()
			return
	changed.emit()


## §5.4: the crew lands on the edge tile `t`, which the log records at tick
## 0. Until there is a landing picker, a heist that has not landed by its
## first step lands on `default_landing()`.
func land(t: Vector2i) -> bool:
	if world.tick() != 0:
		return false
	var given := world.give(0, Kind.LAND, t.x * 256 + 128, t.y * 256 + 128)
	# However the crew lands, the picking is over.
	if given:
		choosing = false
	return given


## A landing the crew can walk to the Vault from, chosen by the heist's seed
## rather than taken first in row order, so a Keeper cannot aim the default
## at a closed pocket of the edge. Until there is a landing picker.
func default_landing() -> Vector2i:
	var spots := world.reaching()
	if spots.is_empty():
		spots = world.landings()
	if spots.is_empty():
		return Vector2i(0, 0)
	return spots[absi(seed_text.hash()) % spots.size()]


func landed() -> bool:
	return world.commands().any(func(c: Dictionary) -> bool: return int(c["kind"]) == Kind.LAND)


## The heist written down, as the replay a device queues (§24.12).
func record() -> PackedByteArray:
	return world.record()


## The server's answer in the result screen's terms. The grade is the server's
## re-simulation's; the haul and fee are what it minted (§9.4, §9.6). A
## repeated answer — one the server settled before — earned its Keeper
## experience then, so it carries none now. An
## answer still in the outbox is the device's own check, marked confirming
## (§24.12: "shown immediately, marked as confirming").
static func settled(r: Result, local: Dictionary) -> Dictionary:
	if r.ok and r.value.get("pending", false):
		var confirming := local.duplicate()
		confirming["confirming"] = true
		return confirming
	if not r.ok:
		return {"ok": false, "refused": r.code, "server": true}
	var out: Dictionary = r.value
	if not out.get("validated", false):
		return {"ok": false, "refused": str(out.get("reason", "refused")), "server": true}
	var verdict: Dictionary = out["verdict"]
	return {"ok": true, "grade": str(verdict["grade"]).capitalize(), "banked": verdict["banked"],
		"haul": out["haul"]["total"], "fee": out["fee"], "server": true,
		"keeper": null if out.get("repeated", false) else out.get("keeper"),
		# §17.6: an invited friend's first heist brings both the gift.
		"gift": out.get("inviteGift") is Dictionary}
