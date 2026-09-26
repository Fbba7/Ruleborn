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

enum Kind { MOVE_TO, GAIT, HALT, CRACK, LOAD, SKIFF, ATTACK, BREAK, DROP, DISARM, DRAG, LAND }

## §5.4's clock at the Heart with no links: 150 seconds, 30 ticks each.
const TICKS := 150 * 30
## The seed an offline heist is played on; a lease brings its own (§24.12).
const SEED := "1"
const CREW := 3
const GAITS := ["Walk", "Crouch", "Run"]

## Something a view shows has changed.
signal changed
## The clock ran out: the heist is over and `record()` is its replay.
signal clock_out

var world := RulebornReplay.new()
var selected := 0
var calling_skiff := false
var island := PackedByteArray()
var seed_text := ""
var over := false


## Start a fresh heist on this seed and clock, on `realm` (a bundle; empty for
## the fixture realm), in the week's `era` (§18.3) as a lease names it.
func begin(seed: String, ticks: int, crew: int, realm := PackedByteArray(), era := "") -> bool:
	if not world.set_era(era) or not world.start(seed, ticks, crew, realm):
		return false
	island = realm
	seed_text = seed
	selected = 0
	calling_skiff = false
	over = false
	changed.emit()
	return true


## The era a lease names (§18.3), as `begin` takes it: a lease in none sends
## `null`, which is "" here — `str(null)` is "<null>", which no era is.
static func lease_era(leased: Dictionary) -> String:
	var era: Variant = leased.get("era")
	return "" if era == null else str(era)


func select(member: int) -> void:
	selected = clampi(member, 0, CREW - 1)
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
			load_up(100)
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
	return world.give(0, Kind.LAND, t.x * 256 + 128, t.y * 256 + 128)


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
## re-simulation's; the haul and fee are what it minted (§9.4, §9.6). An
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
		"haul": out["haul"]["total"], "fee": out["fee"], "server": true}
