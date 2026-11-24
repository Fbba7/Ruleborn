class_name CurationController
extends RefCounted
## Curation with no screen (§13.3, "Swap a law, move a post, turn a post,
## pick a different generated layout, name it"): the realm's curation view
## and its island, fetched by its bundle; the verbs on the draft, which a
## save publishes; a layout laid and a swap woven, online only (G41).
##
## A swap weaves for §5.6's time, and the server takes only woven laws on an
## island (SR-16): while the slot weaves the island is published without the
## old law's pylon, its tile kept here, and once the slot is woven the next
## publish (curation opened, a save, a swap) sets the new law's pylon there
## (CLI-1).

## The swaps still to be placed, kept across launches.
const WEAVING_FILE := "user://curation-weaving.json"

var services: Services
## The time now in milliseconds, which the slots' ready times are read against.
var clock := func() -> int: return int(Time.get_unix_time_from_system() * 1000)


func _init(s: Services) -> void:
	services = s


func _store() -> Store:
	return services.store


func _slice() -> Dictionary:
	return _store().get_slice(CurationState.CURATION)


func _realm() -> String:
	return str(_slice()["realm"])


## Curation of `realm`, opened from the realm view.
func open(realm: String) -> void:
	_store().dispatch(&"curation_opened", {"realm": realm})
	services.router.go(&"curation")


func load_curation(page := -1) -> void:
	if str(_slice()["busy"]) != "":
		return
	_store().dispatch(&"curation_asked", {"what": "view"})
	var r := await services.curation.view(_realm(), int(_slice()["page"]) if page < 0 else page)
	if not r.ok:
		_store().dispatch(&"curation_failed", {"code": r.code})
		return
	_store().dispatch(&"curation_loaded", {"view": r.value})
	await _fetch(r.value)
	if (_slice()["words"] as Dictionary).is_empty():
		var w := await services.first_repo.words()
		if w.ok:
			_store().dispatch(&"curation_words", {"words": w.value})
	await _settle(r.value)


## The realm's swaps against the island just fetched: one swapped again or
## laid over is forgotten; one the island does not show yet (woven since, or
## its publish failed) is published now (CLI-1).
func _settle(view: Dictionary) -> void:
	if str(_slice()["error"]) != "":
		return
	var realm := _realm()
	var all := _records()
	var kept := all.filter(func(w: Dictionary) -> bool:
		return str(w["realm"]) != realm or CurationPresenter.slot_law(view, int(w["slot"])) == str(w["law"]))
	if kept.size() != all.size():
		_keep(kept)
	var island := CurationPresenter.draft_island(_slice())
	var now: int = clock.call()
	if island == null or not _settled(island, _realm_records(), now):
		_show_weaving()
		return
	var woven := _realm_records().any(func(w: Dictionary) -> bool: return int(w["ready_at"]) <= now)
	_store().dispatch(&"curation_asked", {"what": "swap"})
	await _publish("woven" if woven else "swapped")


## The next page of the generator's layouts.
func more_layouts() -> void:
	await load_curation(int(_slice()["page"]) + 1)


## The island the view names, fetched by its bundle (§24.8); none yet is
## an empty draft.
func _fetch(view: Dictionary) -> void:
	var bundle: Variant = view.get("island")
	if not (bundle is String):
		_store().dispatch(&"curation_island", {"island": PackedByteArray()})
		return
	var r := await services.heists.fetch(str(bundle))
	if r.ok:
		_store().dispatch(&"curation_island", {"island": r.value})
	else:
		_store().dispatch(&"curation_failed", {"code": r.code})


## "Pick a different generated layout": the one from `layout_seed`, laid and
## published by the server.
func lay(layout_seed: String) -> void:
	if str(_slice()["busy"]) != "":
		return
	_store().dispatch(&"curation_asked", {"what": "layout"})
	var r := await services.curation.layout(_realm(), layout_seed)
	if not r.ok:
		_store().dispatch(&"curation_failed", {"code": r.code})
		return
	# The server lays the layout's own pylons: the tiles kept are not its.
	var realm := _realm()
	_keep(_records().filter(func(w: Dictionary) -> bool: return str(w["realm"]) != realm))
	_store().dispatch(&"curation_loaded", {"view": r.value, "said": "laid"})
	await _fetch(r.value)
	_show_weaving()


## The post on tile `at` picked, for the dial and the moves.
func pick_post(at: Vector2i) -> void:
	_store().dispatch(&"curation_picked", {"post": at})


## "Move a post": the picked post a tile along `step`, onto open ground only,
## so the terrain stays the layout's, and never onto the tile a weaving
## swap's pylon is kept for (CLI-1).
func move_post(step: Vector2i) -> void:
	var at: Vector2i = _slice()["post"]
	var island := CurationPresenter.draft_island(_slice())
	if island == null or at == CurationState.NO_POST:
		return
	var held := _realm_records().any(func(w: Dictionary) -> bool: return _tile(w) == at + step)
	if held or not CurationPresenter.moved(island, at, at + step):
		_store().dispatch(&"curation_failed", {"code": "post_cannot_move"})
		return
	_store().dispatch(&"curation_drafted", {"draft": island.bytes(), "post": at + step})


## "Turn a post" on the four-way dial (G56): the picked post faces `facing`,
## 0 north to 3 west.
func face_post(facing: int) -> void:
	var at: Vector2i = _slice()["post"]
	var island := CurationPresenter.draft_island(_slice())
	if island == null or at == CurationState.NO_POST or not CurationPresenter.face(island, at, facing):
		return
	_store().dispatch(&"curation_drafted", {"draft": island.bytes()})


## A swap previewed, at once and free (G54): `law` on the pylon of the law
## woven in slot `slot`, on the draft only. A swap previewed before is taken
## back first, so the draft shows the one swap that would be woven (CLI-6);
## a slot whose law has no pylon on the island is refused, as the swap would
## change nothing the island shows (CLI-7).
func preview_swap(slot: int, law: String) -> void:
	var view: Dictionary = _slice()["view"]
	var before: Dictionary = _slice()["swap"]
	var island := CurationPresenter.draft_island(_slice())
	if island != null and not before.is_empty():
		CurationPresenter.swapped(island, str(before["law"]), CurationPresenter.slot_law(view, int(before["slot"])))
	if island != null and not CurationPresenter.swapped(island, CurationPresenter.slot_law(view, slot), law):
		_store().dispatch(&"curation_drafted", {"draft": island.bytes(), "swap": {}})
		_store().dispatch(&"curation_failed", {"code": "swap_not_on_island"})
		return
	_store().dispatch(&"curation_drafted", {"draft": island.bytes() if island != null else _slice()["draft"],
		"swap": {"slot": slot, "law": law}})


## The draft back to the published island.
func revert() -> void:
	_store().dispatch(&"curation_drafted", {"draft": _slice()["base"], "swap": {}, "post": CurationState.NO_POST})


## The previewed swap applied: woven at §5.6's price and time, then the
## draft published. While the slot weaves the island goes without the old
## law's pylon, its tile kept for the new law's once woven (CLI-1); a weave
## refused publishes nothing and charges nothing.
func apply_swap() -> void:
	var swap: Dictionary = _slice()["swap"]
	if swap.is_empty() or str(_slice()["busy"]) != "":
		return
	var slot := int(swap["slot"])
	var law := str(swap["law"])
	var old := CurationPresenter.slot_law(_slice()["view"], slot)
	_store().dispatch(&"curation_asked", {"what": "swap"})
	var r := await services.curation.swap(_realm(), slot, law)
	if not r.ok:
		_store().dispatch(&"curation_failed", {"code": r.code})
		return
	var ready := _ready_at(r.value, _realm(), slot)
	var island := CurationPresenter.draft_island(_slice())
	var at := CurationPresenter.pylon(island, law) if island != null else CurationState.NO_POST
	if ready > 0 and at != CurationState.NO_POST:
		var others := _records().filter(func(w: Dictionary) -> bool:
			return str(w["realm"]) != _realm() or int(w["slot"]) != slot)
		others.append({"realm": _realm(), "slot": slot, "law": law, "old": old, "at": [at.x, at.y],
			"ready_at": ready})
		_keep(others)
	await _publish("swapped")


## When the weave answer says slot `slot` of `realm` is ready, or 0.
static func _ready_at(answer: Variant, realm: String, slot: int) -> int:
	var weaving: Variant = answer.get("weaving") if answer is Dictionary else null
	if not (weaving is Dictionary):
		return 0
	for r: Variant in weaving.get("realms", []):
		if r is Dictionary and str(r.get("realm", "")) == realm:
			for s: Variant in r.get("slots", []):
				if s is Dictionary and int(s.get("slot", 0)) == slot:
					return int(s.get("ready_at", 0))
	return 0


## The draft published: still generated while only curation's verbs have
## changed it (§13.3).
func save() -> void:
	if str(_slice()["busy"]) != "":
		return
	_store().dispatch(&"curation_asked", {"what": "save"})
	await _publish("saved")


## The draft published, with the realm's swaps settled on it: a weaving
## slot's tile bare, a woven one's pylon set (CLI-1). A publish that fails
## while a swap waits on it says so and keeps the swap, which the next
## publish carries; it is never said done.
func _publish(said: String) -> void:
	var draft: PackedByteArray = _slice()["draft"]
	var island := CurationPresenter.draft_island(_slice())
	var waiting := _realm_records()
	var now: int = clock.call()
	if island != null and _settled(island, waiting, now):
		draft = island.bytes()
		_store().dispatch(&"curation_drafted", {"draft": draft})
	if not draft.is_empty() and draft != _slice()["base"]:
		var r := await services.curation.publish(_realm(), draft)
		if not r.ok:
			_store().dispatch(&"curation_failed", {"code": "swap_unsaved" if not waiting.is_empty() else r.code})
			_show_weaving()
			return
		var realm := _realm()
		_keep(_records().filter(func(w: Dictionary) -> bool:
			return str(w["realm"]) != realm or int(w["ready_at"]) > now))
	var v := await services.curation.view(_realm(), int(_slice()["page"]))
	if not v.ok:
		_store().dispatch(&"curation_failed", {"code": v.code})
		return
	_store().dispatch(&"curation_loaded", {"view": v.value, "said": said})
	await _fetch(v.value)
	_show_weaving()


## The realm's swaps on `island`: a slot still weaving leaves its tile bare,
## a woven one's law stands on it. True when that changed the island.
static func _settled(island: RulebornIsland, waiting: Array, now: int) -> bool:
	var changed := false
	for w: Dictionary in waiting:
		var at := _tile(w)
		var on := str(island.occupant(at.x, at.y))
		var law := "pylon:" + str(w["law"])
		if int(w["ready_at"]) > now:
			if on == law or on == "pylon:" + str(w.get("old", "")):
				island.clear(at.x, at.y)
				changed = true
		elif on == "" and CurationPresenter.pylon(island, str(w["law"])) == CurationState.NO_POST:
			changed = island.weave(str(w["law"]), at.x, at.y) or changed
	return changed


## The slots of this realm still weaving, by slot, with when each is ready.
func _show_weaving() -> void:
	var now: int = clock.call()
	var weaving := {}
	for w: Dictionary in _realm_records():
		if int(w["ready_at"]) > now:
			weaving[int(w["slot"])] = int(w["ready_at"])
	_store().dispatch(&"curation_weaving", {"weaving": weaving})


static func _tile(w: Dictionary) -> Vector2i:
	var at: Array = w.get("at", [-1, -1])
	return Vector2i(int(at[0]), int(at[1]))


## The swaps file: the game's own, or beside a test's outbox.
func _path() -> String:
	var outbox := services.outbox.path
	return WEAVING_FILE if outbox == Outbox.FILE else outbox.get_basename() + "-curation.json"


func _records() -> Array:
	var f := FileAccess.open(_path(), FileAccess.READ)
	if f == null:
		return []
	var data: Variant = JSON.parse_string(f.get_as_text())
	if not (data is Array):
		return []
	return (data as Array).filter(_whole)


## A kept swap with every field it is read by.
static func _whole(w: Variant) -> bool:
	if not (w is Dictionary):
		return false
	var at: Variant = w.get("at")
	return w.has("realm") and w.has("slot") and w.has("law") and w.has("ready_at") and at is Array \
		and (at as Array).size() == 2


func _realm_records() -> Array:
	var realm := _realm()
	return _records().filter(func(w: Dictionary) -> bool: return str(w["realm"]) == realm)


func _keep(records: Array) -> void:
	var f := FileAccess.open(_path(), FileAccess.WRITE)
	if f != null:
		f.store_string(JSON.stringify(records))


## The name's next word: `part` "adjective" or "noun", `step` +1 or -1
## through its list.
func cycle_name(part: String, step := 1) -> void:
	var pick: Dictionary = (_slice()["pick"] as Dictionary).duplicate()
	var list: Array = (_slice()["words"] as Dictionary).get(part + "s", [])
	if list.is_empty():
		return
	pick[part] = posmod(int(pick[part]) + step, list.size())
	_store().dispatch(&"curation_naming", {"pick": pick})


## "Name it", from the word lists.
func name_island() -> void:
	if str(_slice()["busy"]) != "":
		return
	var pick: Dictionary = _slice()["pick"]
	_store().dispatch(&"curation_asked", {"what": "name"})
	var r := await services.curation.name_island(_realm(), int(pick["adjective"]), int(pick["noun"]))
	if not r.ok:
		_store().dispatch(&"curation_failed", {"code": r.code})
		return
	_store().dispatch(&"curation_loaded", {"view": r.value, "said": "named", "fetch": false})
