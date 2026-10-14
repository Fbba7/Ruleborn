class_name CodexController
extends RefCounted
## The Codex with no screen: asks the repository and dispatches the answer.
## A screen draws the store; leaving it mid-change loses nothing, since this
## lives on Services. Pages and Aether are spent online only, like every
## spend (G41): §24 lets the device build, weave and assign work offline,
## and nothing else.

var services: Services


func _init(s: Services) -> void:
	services = s


func _store() -> Store:
	return services.store


## The Codex fetched — but not over a change on its way, whose answer brings
## the Codex after it.
func load_codex() -> void:
	var slice: Dictionary = _store().get_slice(CodexState.CODEX)
	if str(slice["busy"]) not in ["", "view"]:
		return
	var changes := int(slice["changes"])
	_store().dispatch(&"codex_asked")
	var r := await services.codex.view()
	if r.ok:
		_store().dispatch(&"codex_loaded", {"view": r.value, "changes": changes})
	else:
		_store().dispatch(&"codex_failed", {"code": r.code, "detail": r.detail})


## §7.6: `law` restored at tier I.
func restore(law: String) -> void:
	await _change("restore:" + law, {"do": "restore", "law": law}, services.codex.restore.bind(law))


## §7.6: `law` raised to tier `to`.
func tier(law: String, to: int) -> void:
	await _change("tier:%s:%d" % [law, to], {"do": "tier", "law": law, "to": to}, services.codex.tier.bind(law, to))


## §7.6: `law` worked on, or none when `law` is "".
func work_on(law: String) -> void:
	var named: Variant = null
	if law != "":
		named = law
	await _change("work:" + law, {"do": "work", "law": law}, services.codex.work_on.bind(named))


## One change at a time: a second tap while one is on its way is ignored.
func _change(key: String, what: Dictionary, call: Callable) -> void:
	if str(_store().get_slice(CodexState.CODEX)["busy"]) != "":
		return
	_store().dispatch(&"codex_change_asked", {"key": key})
	var r: Result = await call.call()
	if not r.ok:
		_store().dispatch(&"codex_failed", {"code": r.code, "detail": r.detail})
		return
	var answer: Dictionary = r.value
	# A restoration and a tier answer {codex, ...}; marking a law worked on
	# answers the Codex itself.
	var view: Dictionary = answer["codex"] if answer.get("codex") is Dictionary else answer
	_store().dispatch(&"codex_change_made", {"view": view, "what": what})
	# §14.2: restoring a law pays the Keeper experience.
	if answer.get("keeper") is Dictionary:
		_store().dispatch(&"keeper_earned", {"keeper": answer["keeper"]})
