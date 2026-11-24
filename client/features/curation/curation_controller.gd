class_name CurationController
extends RefCounted
## Curation with no screen (§13.3, "Swap a law, move a post, turn a post,
## pick a different generated layout, name it"): the realm's curation view
## and its island, fetched by its bundle; the verbs on the draft, which a
## save publishes; a layout laid and a swap woven, online only (G41).

var services: Services


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
	_store().dispatch(&"curation_loaded", {"view": r.value, "said": "laid"})
	await _fetch(r.value)


## The post on tile `at` picked, for the dial and the moves.
func pick_post(at: Vector2i) -> void:
	_store().dispatch(&"curation_picked", {"post": at})


## "Move a post": the picked post a tile along `step`, onto open ground only,
## so the terrain stays the layout's.
func move_post(step: Vector2i) -> void:
	var at: Vector2i = _slice()["post"]
	var island := CurationPresenter.draft_island(_slice())
	if island == null or at == CurationState.NO_POST:
		return
	if not CurationPresenter.moved(island, at, at + step):
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
## draft published with it.
func apply_swap() -> void:
	var swap: Dictionary = _slice()["swap"]
	if swap.is_empty() or str(_slice()["busy"]) != "":
		return
	_store().dispatch(&"curation_asked", {"what": "swap"})
	var r := await services.curation.swap(_realm(), int(swap["slot"]), str(swap["law"]))
	if not r.ok:
		_store().dispatch(&"curation_failed", {"code": r.code})
		return
	await _publish("swapped")


## The draft published: still generated while only curation's verbs have
## changed it (§13.3).
func save() -> void:
	if str(_slice()["busy"]) != "":
		return
	_store().dispatch(&"curation_asked", {"what": "save"})
	await _publish("saved")


func _publish(said: String) -> void:
	var draft: PackedByteArray = _slice()["draft"]
	if not draft.is_empty() and draft != _slice()["base"]:
		var r := await services.curation.publish(_realm(), draft)
		if not r.ok:
			_store().dispatch(&"curation_failed", {"code": r.code})
			return
	var v := await services.curation.view(_realm(), int(_slice()["page"]))
	if not v.ok:
		_store().dispatch(&"curation_failed", {"code": v.code})
		return
	_store().dispatch(&"curation_loaded", {"view": v.value, "said": said})
	await _fetch(v.value)


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
